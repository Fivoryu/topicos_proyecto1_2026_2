"""Verify the committed OpenAPI contract and generated clients are reproducible."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from pathlib import Path

_REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
if __package__ in {None, ""}:  # pragma: no cover - direct script execution
    sys.path.insert(0, str(_REPOSITORY_ROOT))

from backend.scripts.export_openapi import export_contract  # noqa: E402

_WEB_GENERATOR = "typescript-fetch"
_MOBILE_GENERATOR = "dart-dio"
_LEGACY_DART_SDK = "sdk: '>=3.5.0 <4.0.0'"
_HOST_DART_SDK = "sdk: '>=3.10.0 <4.0.0'"


def _executable(name: str, windows_name: str | None = None) -> str:
    """Resolve npm/dart executables on Windows (cmd shims need explicit names)."""

    resolved = shutil.which(windows_name or name) or shutil.which(name)
    if resolved is None:
        raise RuntimeError(f"required executable not found: {name}")
    return resolved


def _normalized_bytes(path: Path) -> bytes:
    """Read bytes while normalizing platform line endings for reproducible
    drift checks."""

    return path.read_bytes().replace(b"\r\n", b"\n")


def compare_directories(committed: Path, regenerated: Path) -> list[str]:
    """Return deterministic content and presence differences between directories."""

    committed_files = _relative_files(committed)
    regenerated_files = _relative_files(regenerated)
    differences: list[str] = []
    for relative in sorted(committed_files | regenerated_files):
        committed_file = committed / relative
        regenerated_file = regenerated / relative
        if relative not in committed_files:
            differences.append(f"{relative.as_posix()} (missing from committed)")
        elif relative not in regenerated_files:
            differences.append(f"{relative.as_posix()} (missing from regenerated)")
        elif _normalized_bytes(committed_file) != _normalized_bytes(regenerated_file):
            differences.append(f"{relative.as_posix()} (content differs)")
    return differences


def find_drift(
    committed_contract: Path,
    exported_contract: Path,
    committed_clients: Path,
    regenerated_clients: Path,
) -> list[str]:
    """Compare one contract snapshot and one generated-client directory."""

    differences: list[str] = []
    if _normalized_bytes(committed_contract) != _normalized_bytes(exported_contract):
        differences.append(f"{committed_contract.name} (content differs)")
    differences.extend(compare_directories(committed_clients, regenerated_clients))
    return differences


def generate_clients(
    contract: Path,
    web_output: Path,
    mobile_output: Path,
    repository_root: Path = _REPOSITORY_ROOT,
) -> None:
    """Run the repository's pinned OpenAPI Generator CLI for both clients."""

    web_output.parent.mkdir(parents=True, exist_ok=True)
    mobile_output.parent.mkdir(parents=True, exist_ok=True)
    _run_generator(
        repository_root,
        contract,
        web_output,
        _WEB_GENERATOR,
        "supportsES6=true",
    )
    _run_generator(
        repository_root,
        contract,
        mobile_output,
        _MOBILE_GENERATOR,
        "serializationLibrary=json_serializable",
    )
    _normalize_mobile_pubspec(mobile_output)


def _run_generator(
    repository_root: Path,
    contract: Path,
    output: Path,
    generator: str,
    *additional_properties: str,
) -> None:
    npm = _executable("npm", "npm.cmd")
    command = [
        npm,
        "--prefix",
        str(repository_root / "web"),
        "exec",
        "--",
        "openapi-generator-cli",
        "generate",
        "-i",
        str(contract),
        "-g",
        generator,
        "-o",
        str(output),
        "--skip-validate-spec",
    ]
    if additional_properties:
        command.append("--additional-properties=" + ",".join(additional_properties))
    subprocess.run(command, cwd=repository_root, check=True)


def _confined_generated_path(
    temporary_root: Path, candidate: Path, *, operation: str
) -> Path:
    """Return a canonical generated path confined to the temporary root."""

    try:
        resolved_root = temporary_root.resolve()
        resolved_candidate = candidate.resolve()
    except (OSError, RuntimeError) as exc:
        raise RuntimeError(
            f"cannot validate generated path for {operation}: {candidate}"
        ) from exc
    try:
        resolved_candidate.relative_to(resolved_root)
    except ValueError as exc:
        raise RuntimeError(
            f"refusing to {operation} path outside generated temporary root: "
            f"{candidate}"
        ) from exc
    return resolved_candidate


def _normalize_mobile_pubspec(
    mobile_output: Path, temporary_root: Path | None = None
) -> None:
    """Pin the generated package's SDK floor to the host app's floor.

    The dart-dio json_serializable template emits a >=3.5 floor, but the Dart
    CFE rejects part files when a path dependency's SDK floor differs from the
    host app's; the host floor is >=3.10, and current json_serializable output
    also needs Dart 3.8+.  Pinning to >=3.10 keeps the generated package
    compiling under the host SDK.  Applied to both committed and regenerated
    output so drift comparisons stay clean.
    """

    generated_root = temporary_root or mobile_output.parent
    path = _confined_generated_path(
        generated_root,
        mobile_output / "pubspec.yaml",
        operation="read generated output",
    )
    try:
        source = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise RuntimeError(
            f"generated mobile output is malformed or unreadable: {path}"
        ) from exc
    if _LEGACY_DART_SDK not in source and _HOST_DART_SDK not in source:
        raise RuntimeError(
            f"generated mobile output is malformed: unsupported SDK constraint in "
            f"{path}"
        )
    updated = source.replace(_LEGACY_DART_SDK, _HOST_DART_SDK)
    if updated != source:
        try:
            path.write_text(updated, encoding="utf-8", newline="")
        except OSError as exc:
            raise RuntimeError(
                f"cannot normalize generated mobile output: {path}"
            ) from exc


def _build_mobile_parts(
    mobile_output: Path, temporary_root: Path | None = None
) -> None:
    """Run the package's pub get and build_runner so .g.dart files exist."""

    dart = _executable("dart")
    subprocess.run([dart, "pub", "get"], cwd=mobile_output, check=True)
    subprocess.run(
        [dart, "run", "build_runner", "build", "--delete-conflicting-outputs"],
        cwd=mobile_output,
        check=True,
    )
    generated_root = temporary_root or mobile_output.parent
    for transient in ("pubspec.lock",):
        path = _confined_generated_path(
            generated_root,
            mobile_output / transient,
            operation="remove generated file",
        )
        try:
            path.unlink()
        except FileNotFoundError:
            continue
        except OSError as exc:
            raise RuntimeError(f"cannot clean generated file: {path}") from exc
    for transient in (".dart_tool", ".build"):
        path = _confined_generated_path(
            generated_root,
            mobile_output / transient,
            operation="remove generated directory",
        )
        try:
            shutil.rmtree(path)
        except FileNotFoundError:
            continue
        except OSError as exc:
            raise RuntimeError(f"cannot clean generated directory: {path}") from exc


def run_drift_check(repository_root: Path = _REPOSITORY_ROOT) -> list[str]:
    """Export and regenerate into temporary paths, then report any drift."""

    committed_contract = repository_root / "contracts" / "openapi.json"
    committed_web = repository_root / "web" / "src" / "generated" / "api"
    committed_mobile = repository_root / "mobile" / "lib" / "generated" / "api"
    with tempfile.TemporaryDirectory(prefix="cuentas-claras-drift-") as temporary:
        temporary_root = Path(temporary)
        exported_contract = temporary_root / "contracts" / "openapi.json"
        regenerated_web = temporary_root / "web"
        regenerated_mobile = temporary_root / "mobile"
        export_contract(exported_contract)
        generate_clients(
            exported_contract,
            regenerated_web,
            regenerated_mobile,
            repository_root,
        )
        _build_mobile_parts(regenerated_mobile, temporary_root)
        differences = find_drift(
            committed_contract,
            exported_contract,
            committed_web,
            regenerated_web,
        )
        differences.extend(
            f"mobile/{difference}"
            for difference in compare_directories(committed_mobile, regenerated_mobile)
        )
    return differences


def _relative_files(directory: Path) -> set[Path]:
    if not directory.is_dir():
        return set()
    return {
        path.relative_to(directory) for path in directory.rglob("*") if path.is_file()
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--cwd",
        type=Path,
        default=_REPOSITORY_ROOT,
        help="Repository root containing contracts, web, and mobile.",
    )
    args = parser.parse_args(argv)
    differences = run_drift_check(args.cwd.resolve())
    if differences:
        print("Contract drift detected:")
        print("\n".join(f"- {difference}" for difference in differences))
        return 1
    print("Contract and generated clients are drift-free.")
    return 0


if __name__ == "__main__":  # pragma: no cover - exercised by the CLI
    raise SystemExit(main())


__all__ = [
    "compare_directories",
    "find_drift",
    "generate_clients",
    "main",
    "run_drift_check",
]
