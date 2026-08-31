"""Protected participant lifecycle routes."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, Response, status

from backend.app.api.deps import AuthenticatedActor, require_csrf
from backend.app.api.routes._common import (
    archived,
    call_with_actor,
    coerce_identifier,
    get_participant_service,
    identifier,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.participants import (
    ParticipantResponse,
    ParticipantWriteRequest,
    RenameParticipantRequest,
)

router = APIRouter(
    prefix="/api/v1/groups/{group_id}/participants", tags=["participants"]
)


def _response(row: object) -> ParticipantResponse:
    created_at = value(row, "created_at", default=None)
    return ParticipantResponse(
        id=identifier(row, "id", "participant_id"),
        group_id=identifier(row, "group_id"),
        name=value(row, "name"),  # type: ignore[arg-type]
        archived=archived(row),
        created_at=created_at,  # type: ignore[arg-type]
    )


@router.get("", response_model=list[ParticipantResponse])
def list_participants(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_participant_service),
) -> list[ParticipantResponse]:
    """List active and archived participants in stable creation order."""

    rows = call_with_actor(
        getattr(service, "list"), coerce_identifier(group_id), actor=actor
    )
    return [_response(row) for row in rows]


@router.post(
    "",
    response_model=ParticipantResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_csrf)],
)
def add_participant(
    group_id: str,
    payload: ParticipantWriteRequest,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_participant_service),
) -> ParticipantResponse:
    """Add a normalized, group-scoped participant."""

    row = call_with_actor(
        getattr(service, "add"),
        coerce_identifier(group_id),
        payload.name,
        actor=actor,
    )
    return _response(row)


@router.patch(
    "/{participant_id}",
    response_model=ParticipantResponse,
    dependencies=[Depends(require_csrf)],
)
def rename_participant(
    group_id: str,
    participant_id: str,
    payload: RenameParticipantRequest,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_participant_service),
) -> ParticipantResponse:
    """Rename only the participant display identity."""

    row = call_with_actor(
        getattr(service, "rename"),
        coerce_identifier(group_id),
        coerce_identifier(participant_id),
        payload.name,
        actor=actor,
    )
    return _response(row)


@router.post(
    "/{participant_id}/archive",
    response_model=ParticipantResponse,
    dependencies=[Depends(require_csrf)],
)
def archive_participant(
    group_id: str,
    participant_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_participant_service),
) -> ParticipantResponse:
    """Archive a participant without deleting historical references."""

    row = call_with_actor(
        getattr(service, "archive"),
        coerce_identifier(group_id),
        coerce_identifier(participant_id),
        actor=actor,
    )
    return _response(row)


@router.post(
    "/{participant_id}/reactivate",
    response_model=ParticipantResponse,
    dependencies=[Depends(require_csrf)],
)
def reactivate_participant(
    group_id: str,
    participant_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_participant_service),
) -> ParticipantResponse:
    """Reactivate an archived participant."""

    row = call_with_actor(
        getattr(service, "reactivate"),
        coerce_identifier(group_id),
        coerce_identifier(participant_id),
        actor=actor,
    )
    return _response(row)


@router.delete(
    "/{participant_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_csrf)],
)
def delete_participant(
    group_id: str,
    participant_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_participant_service),
) -> Response:
    """Physically delete only a never-referenced participant."""

    call_with_actor(
        getattr(service, "delete"),
        coerce_identifier(group_id),
        coerce_identifier(participant_id),
        actor=actor,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


__all__ = ["router"]
