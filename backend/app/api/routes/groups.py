"""Protected group and settlement-policy routes."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends

from backend.app.api.deps import (
    AuthenticatedActor,
    get_current_identity,
    require_csrf,
)
from backend.app.api.routes._common import (
    MISSING,
    call_with_actor,
    coerce_identifier,
    get_group_service,
    get_workspace_service,
    identifier,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.groups import (
    GroupCreateRequest,
    GroupResponse,
    GroupSummaryResponse,
    GroupUpdateRequest,
)
from backend.app.application.auth_service import UnauthorizedError

router = APIRouter(prefix="/api/v1/groups", tags=["groups"])


def _response(group: object) -> GroupResponse:
    policy = value(
        group,
        "settlement_policy",
        "settlementPolicy",
        default="owner_only",
    )
    return GroupResponse(
        id=identifier(group, "id", "group_id"),
        name=value(group, "name"),  # type: ignore[arg-type]
        owner_account_id=identifier(group, "owner_account_id", "ownerAccountId"),
        settlement_policy=policy,  # type: ignore[arg-type]
    )


def _read_method(service: Any) -> Any:
    return getattr(service, "read", None) or getattr(service, "get")


def _account_id(identity: Any) -> Any:
    account_id = value(identity, "account_id", "accountId", default=MISSING)
    if account_id is MISSING:
        account = value(identity, "account", default=None)
        account_id = value(account, "id", "account_id", default=MISSING)
    if account_id is MISSING or account_id is None:
        raise UnauthorizedError()
    return account_id


def _summary(group: object) -> GroupSummaryResponse:
    policy = value(
        group,
        "settlement_policy",
        "settlementPolicy",
        default="owner_only",
    )
    return GroupSummaryResponse(
        id=identifier(group, "id", "group_id"),
        name=value(group, "name"),  # type: ignore[arg-type]
        owner_account_id=identifier(group, "owner_account_id", "ownerAccountId"),
        settlement_policy=policy,  # type: ignore[arg-type]
        role=value(group, "role"),  # type: ignore[arg-type]
        member_count=value(group, "member_count", default=None),  # type: ignore[arg-type]
        outings_count=value(group, "outings_count", default=None),  # type: ignore[arg-type]
        participants_count=value(group, "participants_count", default=None),  # type: ignore[arg-type]
        expenses_count=value(group, "expenses_count", default=None),  # type: ignore[arg-type]
    )


@router.get("", response_model=list[GroupSummaryResponse])
def list_groups(
    identity: Any = Depends(get_current_identity),
    service: Any = Depends(get_workspace_service),
) -> list[GroupSummaryResponse]:
    """List only groups belonging to the authenticated account."""

    account_id = _account_id(identity)
    return [_summary(group) for group in service.list_groups(account_id)]


@router.post("", response_model=GroupSummaryResponse)
def create_group(
    payload: GroupCreateRequest,
    _csrf: None = Depends(require_csrf),
    identity: Any = Depends(get_current_identity),
    service: Any = Depends(get_workspace_service),
) -> GroupSummaryResponse:
    """Create an empty owner workspace for the authenticated account."""

    account_id = _account_id(identity)
    return _summary(service.create_group(account_id, payload.name))


@router.get("/{group_id}", response_model=GroupResponse)
def get_group(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_group_service),
) -> GroupResponse:
    """Return the authenticated group's server-owned settings."""

    group = call_with_actor(
        _read_method(service), coerce_identifier(group_id), actor=actor
    )
    return _response(group)


@router.patch("/{group_id}", response_model=GroupResponse)
def update_group(
    group_id: str,
    payload: GroupUpdateRequest,
    _csrf: None = Depends(require_csrf),
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_group_service),
) -> GroupResponse:
    """Update only settlement policy; authorization remains in GroupService."""

    group = call_with_actor(
        getattr(service, "update_policy"),
        coerce_identifier(group_id),
        payload.settlement_policy,
        actor=actor,
    )
    return _response(group)


__all__ = ["router"]
