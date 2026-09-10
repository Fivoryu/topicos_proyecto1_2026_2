"""Protected join-code lifecycle and authenticated consumption routes."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends

from backend.app.api.deps import (
    AuthenticatedActor,
    get_current_identity,
    require_csrf,
)
from backend.app.api.routes._common import (
    call_with_actor,
    coerce_identifier,
    get_join_service,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.join import (
    JoinCodeConsumeRequest,
    JoinCodeResponse,
    JoinCodeStatus,
    JoinResponse,
)

router = APIRouter(prefix="/api/v1/groups", tags=["join"])


def _response(model: Any, record: object, *fields: str) -> Any:
    return model(**{field: str(value(record, field)) if field.endswith("_id") else value(record, field) for field in fields})  # noqa: E501


@router.get("/{group_id}/join-code", response_model=JoinCodeStatus)
def get_join_code_status(group_id: str, actor: AuthenticatedActor = Depends(require_group_scoped_access), service: Any = Depends(get_join_service)) -> JoinCodeStatus:  # noqa: E501
    result = call_with_actor(getattr(service, "status"), coerce_identifier(group_id), actor=actor)  # noqa: E501
    return _response(JoinCodeStatus, result, "group_id", "generation", "active")


@router.post("/{group_id}/join-code", response_model=JoinCodeResponse, dependencies=[Depends(require_csrf)])  # noqa: E501
def generate_join_code(group_id: str, actor: AuthenticatedActor = Depends(require_group_scoped_access), service: Any = Depends(get_join_service)) -> JoinCodeResponse:  # noqa: E501
    result = call_with_actor(getattr(service, "generate"), coerce_identifier(group_id), actor=actor)  # noqa: E501
    return _response(JoinCodeResponse, result, "group_id", "code", "generation")


@router.post("/{group_id}/join-code/regenerate", response_model=JoinCodeResponse, dependencies=[Depends(require_csrf)])  # noqa: E501
def regenerate_join_code(group_id: str, actor: AuthenticatedActor = Depends(require_group_scoped_access), service: Any = Depends(get_join_service)) -> JoinCodeResponse:  # noqa: E501
    result = call_with_actor(getattr(service, "regenerate"), coerce_identifier(group_id), actor=actor)  # noqa: E501
    return _response(JoinCodeResponse, result, "group_id", "code", "generation")


@router.delete("/{group_id}/join-code", response_model=JoinCodeStatus, dependencies=[Depends(require_csrf)])  # noqa: E501
def revoke_join_code(group_id: str, actor: AuthenticatedActor = Depends(require_group_scoped_access), service: Any = Depends(get_join_service)) -> JoinCodeStatus:  # noqa: E501
    result = call_with_actor(getattr(service, "revoke"), coerce_identifier(group_id), actor=actor)  # noqa: E501
    return _response(JoinCodeStatus, result, "group_id", "generation", "active")


@router.post("/join", response_model=JoinResponse, dependencies=[Depends(require_csrf)])
def consume_join_code(payload: JoinCodeConsumeRequest, identity: Any = Depends(get_current_identity), service: Any = Depends(get_join_service)) -> JoinResponse:  # noqa: E501
    result = service.consume(payload.code, actor=identity, participant_id=payload.participant_id, new_participant_name=payload.new_participant_name)  # noqa: E501
    return _response(JoinResponse, result, "group_id", "account_id", "participant_id")


__all__ = ["router"]
