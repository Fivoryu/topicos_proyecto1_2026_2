"""Protected group-scoped outing lifecycle routes."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, Request, Response, status
from fastapi.responses import JSONResponse

from backend.app.adapters.db.repositories import OutingRepositoryAdapter
from backend.app.adapters.db.uow import SqlAlchemyUnitOfWork
from backend.app.api.deps import AuthenticatedActor, require_csrf
from backend.app.api.routes._common import (
    call_with_actor,
    coerce_identifier,
    identifier,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.outings import OutingResponse, OutingWriteRequest
from backend.app.application.authorization import AuthorizationService
from backend.app.application.outing_service import (
    ArchivedOutingReadOnlyError,
    OutingNotEmptyError,
    OutingService,
)

_ROUTE_PREFIX = "/api/v1/groups/{group_id}"
_routes = APIRouter(prefix="/outings")


def get_outing_service(request: Request) -> Any:
    """Resolve the request-scoped, server-authorized outing service."""

    service = getattr(request.state, "outing_service", None)
    if service is not None:
        return service

    membership_repository = getattr(request.state, "membership_repository", None)
    group_repository = getattr(request.state, "group_repository", None)
    session = getattr(group_repository, "session", None)
    if membership_repository is None or group_repository is None or session is None:
        raise RuntimeError("The API service 'outing_service' is not configured.")

    authorization = getattr(request.state, "authorization_service", None)
    if authorization is None:
        authorization = AuthorizationService(membership_repository, group_repository)
    publisher = getattr(request.state, "broadcaster", None)
    return OutingService(
        OutingRepositoryAdapter(session),
        SqlAlchemyUnitOfWork(session=session),
        authorization_service=authorization,
        invalidation_publisher=publisher,
    )


def _response(row: object) -> OutingResponse:
    archived_at = value(row, "archived_at", default=None)
    is_archived = value(row, "archived", default=archived_at is not None)
    return OutingResponse(
        id=identifier(row, "id", "outing_id"),
        group_id=identifier(row, "group_id"),
        name=value(row, "name"),  # type: ignore[arg-type]
        archived=bool(is_archived),
        archived_at=archived_at,  # type: ignore[arg-type]
        created_at=value(row, "created_at", default=None),  # type: ignore[arg-type]
        updated_at=value(row, "updated_at", default=None),  # type: ignore[arg-type]
    )


def _error_response(error: ArchivedOutingReadOnlyError | OutingNotEmptyError):
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={"error_code": error.error_code, "message": str(error)},
    )


def _call(method: Any, *args: Any, actor: Any) -> Any:
    try:
        return call_with_actor(method, *args, actor=actor)
    except (ArchivedOutingReadOnlyError, OutingNotEmptyError) as error:
        return _error_response(error)


@_routes.get("", response_model=list[OutingResponse])
def list_outings(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_outing_service),
) -> list[OutingResponse]:
    """List active and archived outings in stable creation order."""

    rows = _call(getattr(service, "list"), coerce_identifier(group_id), actor=actor)
    return [_response(row) for row in rows]


@_routes.post(
    "",
    response_model=OutingResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_csrf)],
)
def create_outing(
    group_id: str,
    payload: OutingWriteRequest,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_outing_service),
) -> OutingResponse:
    """Create an active outing for any active group member."""

    row = _call(
        getattr(service, "create"),
        coerce_identifier(group_id),
        payload.name,
        actor=actor,
    )
    return _response(row)


@_routes.get("/{outing_id}", response_model=OutingResponse)
def get_outing(
    group_id: str,
    outing_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_outing_service),
) -> OutingResponse:
    """Read an active or archived outing in the requested group."""

    row = _call(
        getattr(service, "get"),
        coerce_identifier(group_id),
        coerce_identifier(outing_id),
        actor=actor,
    )
    return _response(row)


@_routes.patch(
    "/{outing_id}",
    response_model=OutingResponse,
    dependencies=[Depends(require_csrf)],
)
def edit_outing(
    group_id: str,
    outing_id: str,
    payload: OutingWriteRequest,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_outing_service),
) -> OutingResponse:
    """Edit only the name of an active outing."""

    row = _call(
        getattr(service, "edit"),
        coerce_identifier(group_id),
        coerce_identifier(outing_id),
        payload.name,
        actor=actor,
    )
    if isinstance(row, JSONResponse):
        return row  # type: ignore[return-value]
    return _response(row)


@_routes.post(
    "/{outing_id}/archive",
    response_model=OutingResponse,
    dependencies=[Depends(require_csrf)],
)
def archive_outing(
    group_id: str,
    outing_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_outing_service),
) -> OutingResponse:
    """Archive an outing as a server-authorized owner operation."""

    row = _call(
        getattr(service, "archive"),
        coerce_identifier(group_id),
        coerce_identifier(outing_id),
        actor=actor,
    )
    if isinstance(row, JSONResponse):
        return row  # type: ignore[return-value]
    return _response(row)


@_routes.post(
    "/{outing_id}/unarchive",
    response_model=OutingResponse,
    dependencies=[Depends(require_csrf)],
)
def unarchive_outing(
    group_id: str,
    outing_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_outing_service),
) -> OutingResponse:
    """Restore an archived outing to active state as its owner."""

    row = _call(
        getattr(service, "unarchive"),
        coerce_identifier(group_id),
        coerce_identifier(outing_id),
        actor=actor,
    )
    if isinstance(row, JSONResponse):
        return row  # type: ignore[return-value]
    return _response(row)


@_routes.delete(
    "/{outing_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_csrf)],
)
def delete_outing(
    group_id: str,
    outing_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_outing_service),
) -> Response:
    """Delete an empty active outing as its server-authorized owner."""

    result = _call(
        getattr(service, "delete"),
        coerce_identifier(group_id),
        coerce_identifier(outing_id),
        actor=actor,
    )
    if isinstance(result, JSONResponse):
        return result
    return Response(status_code=status.HTTP_204_NO_CONTENT)


router = APIRouter(prefix=_ROUTE_PREFIX, tags=["outings"])
router.include_router(_routes)
nested_router = APIRouter(prefix="/{group_id}", tags=["outings"])
nested_router.include_router(_routes)

__all__ = ["get_outing_service", "nested_router", "router"]
