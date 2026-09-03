"""Contract export and generated-client drift tests."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from backend.scripts import check_contract_drift, export_openapi


def test_export_describes_the_protected_wire_contract(tmp_path: Path) -> None:
    output = tmp_path / "openapi.json"

    export_openapi.export_contract(output)
    document = json.loads(output.read_text(encoding="utf-8"))

    security_scheme = document["components"]["securitySchemes"]["cc_session"]
    assert security_scheme["type"] == "apiKey"
    assert security_scheme["in"] == "cookie"
    assert security_scheme["name"] == "cc_session"

    rename = document["components"]["schemas"]["RenameParticipantRequest"]
    assert rename["required"] == ["name"]
    assert rename["properties"] == {"name": {"type": "string", "title": "Name"}}
    assert rename["additionalProperties"] is False

    error = document["components"]["schemas"]["ErrorResponse"]
    assert error["required"] == ["error_code", "message"]
    assert "field_errors" in error["properties"]

    session = document["components"]["schemas"]["SessionIdentityResponse"]
    assert session["properties"]["role"]["enum"] == ["owner", "member"]
    assert "role" not in document["components"]["schemas"]["LoginRequest"]["properties"]

    login = document["paths"]["/api/v1/auth/login"]["post"]
    assert _required_header(login, "X-CSRF-Token")
    rename_operation = document["paths"][
        "/api/v1/groups/{group_id}/participants/{participant_id}"
    ]["patch"]
    assert rename_operation["security"] == [{"cc_session": []}]
    assert _required_header(rename_operation, "X-CSRF-Token")

    for path_item in document["paths"].values():
        for operation in path_item.values():
            if not isinstance(operation, dict) or "responses" not in operation:
                continue
            for response in operation["responses"].values():
                if isinstance(response, dict) and response.get("$ref") == (
                    "#/components/responses/ErrorResponse"
                ):
                    break
            else:
                continue
            assert "ErrorResponse" in document["components"]["schemas"]

    monetary_fields = {
        name
        for schema in document["components"]["schemas"].values()
        if isinstance(schema, dict)
        for name, value in schema.get("properties", {}).items()
        if name.endswith("_cents")
    }
    assert monetary_fields
    assert all(
        document["components"]["schemas"][schema_name]["properties"][field]["type"]
        == "integer"
        for schema_name, schema in document["components"]["schemas"].items()
        if isinstance(schema, dict)
        for field in schema.get("properties", {})
        if field.endswith("_cents")
    )


def _required_header(operation: dict[str, object], name: str) -> bool:
    parameters = operation.get("parameters", [])
    if not isinstance(parameters, list):
        return False
    return any(
        parameter.get("in") == "header"
        and parameter.get("name") == name
        and parameter.get("required") is True
        for parameter in parameters
        if isinstance(parameter, dict)
    )


def test_drift_comparison_detects_mutated_contract_and_generated_output(
    tmp_path: Path,
) -> None:
    committed_contract = tmp_path / "contract.json"
    exported_contract = tmp_path / "exported.json"
    committed_clients = tmp_path / "committed-clients"
    regenerated_clients = tmp_path / "regenerated-clients"

    committed_contract.write_text('{"version": 1}\n', encoding="utf-8")
    exported_contract.write_text('{"version": 1}\n', encoding="utf-8")
    (committed_clients / "client.ts").parent.mkdir()
    (regenerated_clients / "client.ts").parent.mkdir()
    (committed_clients / "client.ts").write_text("generated\n", encoding="utf-8")
    (regenerated_clients / "client.ts").write_text("generated\n", encoding="utf-8")

    assert (
        check_contract_drift.find_drift(
            committed_contract,
            exported_contract,
            committed_clients,
            regenerated_clients,
        )
        == []
    )

    exported_contract.write_text('{"version": 2}\n', encoding="utf-8")
    (regenerated_clients / "client.ts").write_text("mutated\n", encoding="utf-8")

    drift = check_contract_drift.find_drift(
        committed_contract,
        exported_contract,
        committed_clients,
        regenerated_clients,
    )
    assert any("contract.json" in item for item in drift)
    assert any("client.ts" in item for item in drift)


def test_drift_comparison_handles_added_and_removed_generated_files(
    tmp_path: Path,
) -> None:
    committed = tmp_path / "committed"
    regenerated = tmp_path / "regenerated"
    committed.mkdir()
    regenerated.mkdir()
    (committed / "kept.ts").write_text("same", encoding="utf-8")
    (committed / "removed.ts").write_text("old", encoding="utf-8")
    (regenerated / "kept.ts").write_text("same", encoding="utf-8")
    (regenerated / "added.ts").write_text("new", encoding="utf-8")

    drift = check_contract_drift.compare_directories(committed, regenerated)

    assert drift == [
        "added.ts (missing from committed)",
        "removed.ts (missing from regenerated)",
    ]


@pytest.mark.parametrize("method", ["post", "patch", "delete"])
def test_export_marks_unsafe_group_operations_with_csrf(
    tmp_path: Path, method: str
) -> None:
    output = tmp_path / "openapi.json"
    export_openapi.export_contract(output)
    document = json.loads(output.read_text(encoding="utf-8"))

    operations = [
        operation
        for path, path_item in document["paths"].items()
        if path.startswith("/api/v1/groups/")
        for operation_name, operation in path_item.items()
        if operation_name == method
    ]

    assert operations
    assert all(_required_header(operation, "X-CSRF-Token") for operation in operations)

def test_drift_comparison_ignores_platform_line_endings(tmp_path: Path) -> None:
    committed = tmp_path / "committed"
    regenerated = tmp_path / "regenerated"
    committed.mkdir()
    regenerated.mkdir()

    (committed / "client.ts").write_bytes(b"line one\r\nline two\r\n")
    (regenerated / "client.ts").write_bytes(b"line one\nline two\n")

    assert check_contract_drift.compare_directories(committed, regenerated) == []