"""Shared dependency and serialization helpers for protected REST routes."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any
from uuid import UUID

from fastapi import Depends, Request

from backend.app.api.deps import (
    get_current_identity,
    get_group_repository,
    get_membership_repository,
    require_group_access,
)

MISSING = object()
Identifier = UUID | str


def _state_value(request: Request, name: str, default: Any = None) -> Any:
    value = getattr(request.state, name, None)
    if value is not None:
        return value
    return getattr(request.app.state, name, default)


def _required_state(request: Request, name: str) -> Any:
    value = _state_value(request, name)
    if value is None:
        raise RuntimeError(f"The API service {name!r} is not configured.")
    return value


def get_group_service(request: Request) -> Any:
    return _required_state(request, "group_service")


def get_participant_service(request: Request) -> Any:
    return _required_state(request, "participant_service")


def get_expense_service(request: Request) -> Any:
    return _required_state(request, "expense_service")


def get_derived_service(request: Request) -> Any:
    return _required_state(request, "derived_service")


def get_participant_repository(
    request: Request,
    participant_service: Any = Depends(get_participant_service),
) -> Any:
    return _state_value(
        request,
        "participant_repository",
        getattr(participant_service, "_participants", participant_service),
    )


def get_expense_repository(
    request: Request,
    expense_service: Any = Depends(get_expense_service),
) -> Any:
    return _state_value(
        request,
        "expense_repository",
        getattr(expense_service, "_expenses", expense_service),
    )


def coerce_identifier(value: Identifier) -> Identifier:
    """Bind UUID columns as UUIDs while retaining readable fake identifiers in tests."""

    if isinstance(value, UUID):
        return value
    try:
        return UUID(value)
    except (TypeError, ValueError):
        return value


def require_group_scoped_access(
    group_id: str,
    identity: Any = Depends(get_current_identity),
    membership_repository: Any = Depends(get_membership_repository),
    group_repository: Any = Depends(get_group_repository),
):
    """Run the shared auth boundary with a DB-safe group identifier."""

    return require_group_access(
        coerce_identifier(group_id),
        identity,
        membership_repository,
        group_repository,
    )


def value(record: object, *names: str, default: object = MISSING) -> object:
    if isinstance(record, Mapping):
        for name in names:
            if name in record:
                return record[name]
    else:
        for name in names:
            candidate = getattr(record, name, MISSING)
            if candidate is not MISSING:
                return candidate
    return default


def identifier(record: object, *names: str) -> str:
    """Return a response-safe identifier: UUIDs normalize to canonical strings."""

    candidate = value(record, *names)
    if candidate is MISSING:
        raise ValueError("record is missing an identifier")
    if isinstance(candidate, str):
        return candidate
    if hasattr(candidate, "hex"):
        return str(candidate)
    raise ValueError("record identifier is not string-compatible")


def archived(record: object) -> bool:
    archived_at = value(record, "archived_at", default=None)
    return archived_at is not None or bool(value(record, "archived", default=False))


def call_with_actor(method: Any, *args: Any, actor: Any) -> Any:
    """Call application services while keeping simple test doubles compatible."""

    try:
        return method(*args, actor=actor)
    except TypeError as error:
        if "actor" not in str(error):
            raise
        return method(*args)


def list_group(repository: Any, group_id: Identifier) -> list[Any]:
    method = getattr(repository, "list_by_group", None) or getattr(
        repository, "list", None
    )
    if method is None:
        raise RuntimeError("repository cannot list group records")
    return list(method(group_id))


def find_group_record(repository: Any, group_id: Identifier, record_id: Identifier):
    method = getattr(repository, "find_by_id", None) or getattr(repository, "get", None)
    if method is None:
        raise RuntimeError("repository cannot find group records")
    try:
        return method(group_id, record_id)
    except TypeError:
        return method(record_id)


def lookup_by_id(rows: list[Any], record_id: Identifier) -> Any:
    for row in rows:
        row_id = identifier(row, "id", "participant_id", "expense_id")
        if row_id == record_id or str(row_id) == str(record_id):
            return row
    return None


def balance_value(row: object, name: str) -> int:
    candidate = value(row, name, default=MISSING)
    if not isinstance(candidate, int) or isinstance(candidate, bool):
        raise ValueError(f"balance row is missing integer {name}")
    return candidate


__all__ = [
    "Identifier",
    "MISSING",
    "archived",
    "balance_value",
    "call_with_actor",
    "coerce_identifier",
    "find_group_record",
    "get_derived_service",
    "get_expense_repository",
    "get_expense_service",
    "get_group_service",
    "get_participant_repository",
    "get_participant_service",
    "identifier",
    "list_group",
    "lookup_by_id",
    "require_group_scoped_access",
    "value",
]
