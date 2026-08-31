"""Protected group and settlement-policy routes."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends

from backend.app.api.deps import AuthenticatedActor, require_csrf
from backend.app.api.routes._common import (
    call_with_actor,
    coerce_identifier,
    get_group_service,
    identifier,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.groups import GroupResponse, GroupUpdateRequest

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
