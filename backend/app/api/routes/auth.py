"""Login, logout, and current-session routes."""

from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, Request, Response

from backend.app.adapters.security.sessions import (
    CSRF_COOKIE_NAME,
    SESSION_COOKIE_NAME,
    clear_session_cookies,
    set_csrf_cookie,
    set_session_cookies,
)
from backend.app.api.deps import get_auth_service, require_csrf
from backend.app.api.errors import error_response
from backend.app.api.schemas.auth import LoginRequest, SessionIdentityResponse
from backend.app.application.auth_service import AuthenticationError

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def _secure_for(request: Request) -> bool:
    """Use Secure cookies for HTTPS while keeping local HTTP development usable."""

    return request.url.scheme == "https"


@router.post("/login", response_model=SessionIdentityResponse)
def login(
    payload: LoginRequest,
    request: Request,
    response: Response,
    _csrf: None = Depends(require_csrf),
    auth_service: Any = Depends(get_auth_service),
) -> SessionIdentityResponse:
    """Authenticate seeded credentials and establish both transport cookies."""

    identity = auth_service.login(payload.login_name, payload.password)
    token = getattr(identity, "token", None)
    if not isinstance(token, str) or not token:
        raise AuthenticationError(
            "unauthorized", "The authenticated session could not be established."
        )
    csrf_token = request.cookies.get(CSRF_COOKIE_NAME)
    set_session_cookies(
        response,
        token,
        csrf_token,
        secure=_secure_for(request),
    )
    return SessionIdentityResponse.from_identity(identity)


@router.get("/session", response_model=SessionIdentityResponse)
def session(
    request: Request,
    response: Response,
    auth_service: Any = Depends(get_auth_service),
) -> SessionIdentityResponse | Response:
    """Return server identity and initialize CSRF even for an anonymous probe."""

    token = request.cookies.get(SESSION_COOKIE_NAME)
    try:
        identity = auth_service.session_identity(token)
    except AuthenticationError as error:
        failure = error_response(error.error_code, str(error))
        if request.cookies.get(CSRF_COOKIE_NAME) is None:
            set_csrf_cookie(failure, secure=_secure_for(request))
        return failure
    if request.cookies.get(CSRF_COOKIE_NAME) is None:
        set_csrf_cookie(response, secure=_secure_for(request))
    return SessionIdentityResponse.from_identity(identity)


@router.post("/logout", status_code=204)
def logout(
    request: Request,
    _csrf: None = Depends(require_csrf),
    auth_service: Any = Depends(get_auth_service),
) -> Response:
    """Revoke the current session and expire both browser-visible cookies."""

    auth_service.logout(request.cookies.get(SESSION_COOKIE_NAME))
    response = Response(status_code=204)
    clear_session_cookies(response)
    return response


__all__ = ["router"]
