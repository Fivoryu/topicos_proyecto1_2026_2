"""Export the live FastAPI OpenAPI document as the repository contract."""

from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path
from typing import Any

_REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
if __package__ in {None, ""}:  # pragma: no cover - direct script execution
    sys.path.insert(0, str(_REPOSITORY_ROOT))

from backend.app.main import app  # noqa: E402

_HTTP_METHODS = {"delete", "get", "patch", "post", "put"}
_UNSAFE_METHODS = {"delete", "patch", "post", "put"}
_GROUP_ERROR_CODES = (401, 403, 404, 409, 422, 500)
_AUTH_ERROR_CODES = (401, 403, 422)


def export_contract(output: Path | str) -> dict[str, Any]:
    """Write the enriched OpenAPI snapshot and return its JSON document.

    FastAPI remains the source of every route and Pydantic schema.  The small
    additions here document transport behavior implemented by dependencies and
    exception handlers, which FastAPI cannot infer from direct Request access.
    """

    document = copy.deepcopy(app.openapi())
    # The pinned Dart-Dio generator targets the OpenAPI 3.0 dialect.  The
    # FastAPI 3.1 document uses only 3.0-compatible constructs for this API.
    document["openapi"] = "3.0.3"
    _add_transport_and_error_contract(document)
    _drop_framework_validation_schemas(document)
    destination = Path(output)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(
        json.dumps(document, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return document


def _add_transport_and_error_contract(document: dict[str, Any]) -> None:
    components = document.setdefault("components", {})
    security_schemes = components.setdefault("securitySchemes", {})
    security_schemes["cc_session"] = {
        "type": "apiKey",
        "in": "cookie",
        "name": "cc_session",
        "description": "Opaque server-recognized session cookie.",
    }
    security_schemes["csrf_token"] = {
        "type": "apiKey",
        "in": "header",
        "name": "X-CSRF-Token",
        "description": "Required on unsafe cookie-authenticated operations.",
    }
    _ensure_error_components(components)

    for path, path_item in document.get("paths", {}).items():
        if not isinstance(path_item, dict):
            continue
        for method, operation in path_item.items():
            if method not in _HTTP_METHODS or not isinstance(operation, dict):
                continue
            is_auth = path.startswith("/api/v1/auth/")
            is_session_probe = path == "/api/v1/auth/session"
            is_group = path.startswith("/api/v1/groups/")
            if is_group or path == "/api/v1/auth/logout":
                operation["security"] = [{"cc_session": []}]
            if method in _UNSAFE_METHODS and (is_group or is_auth):
                _require_csrf_header(operation)
            if is_group:
                _add_error_responses(operation, _GROUP_ERROR_CODES)
            elif is_auth and not is_session_probe:
                _add_error_responses(operation, _AUTH_ERROR_CODES)
            elif is_session_probe:
                _add_error_responses(operation, (401,))


def _drop_framework_validation_schemas(document: dict[str, Any]) -> None:
    """Replace FastAPI's default validation schemas with the stable envelope.

    HTTPValidationError/ValidationError are framework-generated and force the
    Dart generator to emit unusable wrapper models (anonymous anyOf items); the
    repository contract already defines ErrorResponse as the error shape.
    """

    schemas = document.get("components", {}).get("schemas", {})
    for name in ("HTTPValidationError", "ValidationError"):
        schemas.pop(name, None)
    target = "#/components/schemas/ErrorResponse"
    for path_item in document.get("paths", {}).values():
        if not isinstance(path_item, dict):
            continue
        for operation in path_item.values():
            if not isinstance(operation, dict):
                continue
            for response in operation.get("responses", {}).values():
                if not isinstance(response, dict):
                    continue
                content = response.get("content", {})
                for media in content.values():
                    if not isinstance(media, dict):
                        continue
                    schema = media.get("schema")
                    if isinstance(schema, dict) and "$ref" in schema:
                        if "ValidationError" in schema["$ref"]:
                            media["schema"] = {"$ref": target}


def _ensure_error_components(components: dict[str, Any]) -> None:
    schemas = components.setdefault("schemas", {})
    schemas["FieldError"] = {
        "type": "object",
        "additionalProperties": False,
        "required": ["field", "message"],
        "properties": {
            "field": {"type": "string"},
            "message": {"type": "string"},
        },
    }
    schemas["ErrorResponse"] = {
        "type": "object",
        "additionalProperties": False,
        "required": ["error_code", "message"],
        "properties": {
            "error_code": {"type": "string"},
            "message": {"type": "string"},
            "field_errors": {
                "type": "array",
                "items": {"$ref": "#/components/schemas/FieldError"},
            },
        },
    }
    responses = components.setdefault("responses", {})
    responses["ErrorResponse"] = {
        "description": "Stable machine-readable error envelope.",
        "content": {
            "application/json": {
                "schema": {"$ref": "#/components/schemas/ErrorResponse"}
            }
        },
    }


def _require_csrf_header(operation: dict[str, Any]) -> None:
    parameters = operation.setdefault("parameters", [])
    if any(
        isinstance(parameter, dict)
        and parameter.get("in") == "header"
        and parameter.get("name") == "X-CSRF-Token"
        for parameter in parameters
    ):
        return
    parameters.append(
        {
            "name": "X-CSRF-Token",
            "in": "header",
            "required": True,
            "description": "Must match the readable cc_csrf cookie.",
            "schema": {"type": "string"},
        }
    )


def _add_error_responses(operation: dict[str, Any], statuses: tuple[int, ...]) -> None:
    responses = operation.setdefault("responses", {})
    for status in statuses:
        responses[str(status)] = {"$ref": "#/components/responses/ErrorResponse"}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=_REPOSITORY_ROOT / "contracts" / "openapi.json",
        help="OpenAPI snapshot destination.",
    )
    args = parser.parse_args(argv)
    export_contract(args.output)
    return 0


if __name__ == "__main__":  # pragma: no cover - exercised by the CLI
    raise SystemExit(main())


__all__ = ["export_contract", "main"]
