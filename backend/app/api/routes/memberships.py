from typing import Any

from fastapi import APIRouter, Depends, Response

from backend.app.api.deps import AuthenticatedActor, require_csrf
from backend.app.api.routes._common import (
    call_with_actor,
    coerce_identifier,
    get_membership_service,
    identifier,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.memberships import MemberResponse

router = APIRouter(prefix="/api/v1/groups", tags=["memberships"])


def _call(service: Any, method: str, *args: object, actor: AuthenticatedActor):
    return call_with_actor(getattr(service, method), *args, actor=actor)


def _response(row: object) -> MemberResponse:
    participant = value(row, "participant_id", "participantId", default=None)
    return MemberResponse(
        account_id=identifier(row, "account_id", "accountId"),
        login_name=value(row, "login_name", "loginName", default=""),  # type: ignore[arg-type]
        role=value(row, "role", default="member"),  # type: ignore[arg-type]
        active=bool(value(row, "active", default=True)),
        participant_id=str(participant) if participant is not None else None,
    )


@router.get("/{group_id}/members", response_model=list[MemberResponse])
def list_members(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_membership_service),
) -> list[MemberResponse]:
    rows = call_with_actor(
        service.list_members,
        coerce_identifier(group_id),
        actor=actor,
    )
    return [_response(row) for row in rows]


@router.post(
    "/{group_id}/leave",
    status_code=204,
    dependencies=[Depends(require_csrf)],
)
def leave_group(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_membership_service),
) -> Response:
    _call(service, "leave_group", coerce_identifier(group_id), actor=actor)
    return Response(status_code=204)


@router.delete(
    "/{group_id}/members/{account_id}",
    status_code=204,
    dependencies=[Depends(require_csrf)],
)
def remove_member(
    group_id: str,
    account_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_membership_service),
) -> Response:
    _call(
        service,
        "remove_member",
        coerce_identifier(group_id),
        coerce_identifier(account_id),
        actor=actor,
    )
    return Response(status_code=204)
