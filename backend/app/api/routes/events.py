"""Authenticated, invalidation-only WebSocket events."""

from __future__ import annotations

from typing import Any, cast

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect

from backend.app.adapters.security.sessions import (
    SESSION_COOKIE_NAME,
    origin_is_allowed,
)
from backend.app.api.deps import (
    get_auth_service,
    get_group_repository,
    get_membership_repository,
)
from backend.app.api.routes._common import coerce_identifier
from backend.app.application.auth_service import AuthenticationError, AuthService
from backend.app.application.authorization import (
    AuthorizationService,
    ForbiddenError,
)

router = APIRouter(tags=["events"])


async def _reject(websocket: WebSocket) -> None:
    """Reject an invalid handshake without exposing authentication details."""

    await websocket.close(code=1008)


@router.websocket("/api/v1/groups/{group_id}/events")
async def group_events(
    websocket: WebSocket,
    group_id: str,
    auth_service: AuthService = Depends(get_auth_service),
    membership_repository: Any = Depends(get_membership_repository),
    group_repository: Any = Depends(get_group_repository),
) -> None:
    """Stream only ``data_changed`` signals for an authorized group."""

    settings = getattr(websocket.app.state, "settings", None)
    allowed_origins = getattr(settings, "cors_origins", ())
    if not origin_is_allowed(websocket.headers.get("origin"), allowed_origins):
        await _reject(websocket)
        return

    token = websocket.cookies.get(SESSION_COOKIE_NAME)
    try:
        identity = auth_service.session_identity(token)
        requested_group = coerce_identifier(group_id)
        AuthorizationService(membership_repository, group_repository).authorize(
            identity, cast(str, requested_group), "websocket"
        )
    except (AuthenticationError, ForbiddenError):
        await _reject(websocket)
        return
    except (AttributeError, KeyError, TypeError, ValueError):
        await _reject(websocket)
        return

    broadcaster = getattr(websocket.app.state, "broadcaster", None)
    if broadcaster is None:
        await websocket.close(code=1011)
        return

    subscription = broadcaster.subscribe(requested_group)
    await websocket.accept()
    try:
        while True:
            await websocket.send_json(await subscription.get())
    except WebSocketDisconnect:
        pass
    finally:
        broadcaster.unsubscribe(requested_group, subscription)


__all__ = ["router"]
