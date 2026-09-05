# pyright: reportMissingImports=false
"""FastAPI dependencies for server-authoritative sessions and CSRF."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Literal, cast

from fastapi import Depends, Request

from backend.app.adapters.config import get_settings
from backend.app.adapters.security.sessions import (
    CSRF_COOKIE_NAME,
    CSRF_HEADER_NAME,
    NATIVE_CLIENT_HEADER_NAME,
    NATIVE_CLIENT_MARKER,
    SESSION_COOKIE_NAME,
    csrf_tokens_match,
    origin_is_allowed,
)
from backend.app.api.errors import CsrfFailedError
from backend.app.application.auth_service import (
    AuthenticationError,
    AuthService,
    InvalidCredentialsError,
    UnauthorizedError,
)
from backend.app.application.authorization import AuthorizationService

Role = Literal["owner", "member"]


class _UnavailableAuthService:
    """Keep an unconfigured app fail-closed instead of allowing anonymous access."""

    def login(self, _login_name: str, _password: str) -> Any:
        raise InvalidCredentialsError()

    def session_identity(self, _token: str | None) -> Any:
        raise UnauthorizedError()

    def logout(self, _token: str | None) -> None:
        raise UnauthorizedError()


_UNAVAILABLE_AUTH_SERVICE = _UnavailableAuthService()


@dataclass(frozen=True, slots=True)
class AuthenticatedActor:
    """Identity authorized for one requested group."""

    account_id: Any
    login_name: str
    group_id: Any
    role: Role
    expires_at: datetime
    identity: Any


CurrentActor = AuthenticatedActor


def _attr(record: object, *names: str, default: object = None) -> object:
    if isinstance(record, Mapping):
        for name in names:
            if name in record:
                return record[name]
    else:
        for name in names:
            value = getattr(record, name, None)
            if value is not None:
                return value
    return default


def _state_value(request: Request, name: str, default: Any = None) -> Any:
    """Prefer HTTP request state while retaining app-state compatibility."""

    value = getattr(request.state, name, None)
    if value is not None:
        return value
    return getattr(request.app.state, name, default)


def get_auth_service(request: Request) -> AuthService:
    """Resolve the request application's configured auth service."""

    return cast(
        AuthService,
        _state_value(request, "auth_service", _UNAVAILABLE_AUTH_SERVICE),
    )


def get_membership_repository(
    request: Request,
    auth_service: AuthService = Depends(get_auth_service),
) -> Any:
    """Resolve the requested-group membership repository."""

    return _state_value(
        request,
        "membership_repository",
        getattr(auth_service, "_memberships", None),
    )


def get_group_repository(
    request: Request,
    auth_service: AuthService = Depends(get_auth_service),
) -> Any:
    """Resolve the server-owned group repository."""

    return _state_value(
        request,
        "group_repository",
        getattr(auth_service, "_groups", None),
    )


def get_current_identity(
    request: Request,
    auth_service: AuthService = Depends(get_auth_service),
) -> Any:
    """Validate the exact session cookie before accessing group data."""

    token = request.cookies.get(SESSION_COOKIE_NAME)
    try:
        return auth_service.session_identity(token)
    except AuthenticationError:
        raise
    except (AttributeError, KeyError, TypeError, ValueError) as error:
        raise UnauthorizedError() from error


current_identity = get_current_identity


def require_group_access(
    group_id: Any,
    identity: Any = Depends(get_current_identity),
    membership_repository: Any = Depends(get_membership_repository),
    group_repository: Any = Depends(get_group_repository),
) -> AuthenticatedActor:
    """Check requested-group membership and derive owner/member from the server."""

    context = AuthorizationService(membership_repository, group_repository).authorize(
        identity, group_id, "read_group"
    )
    account_id = _attr(identity, "account_id", "accountId")
    login_name = _attr(identity, "login_name", "loginName", default="")
    expires_at = _attr(identity, "expires_at", "expiresAt")
    if account_id is None or not isinstance(login_name, str):
        raise UnauthorizedError()
    if not isinstance(expires_at, datetime):
        raise UnauthorizedError()
    return AuthenticatedActor(
        account_id=account_id,
        login_name=login_name,
        group_id=group_id,
        role=cast(Role, context.role),
        expires_at=expires_at,
        identity=identity,
    )


require_authenticated_group = require_group_access


def require_csrf(request: Request) -> None:
    """Reject origin or double-submit failures before an unsafe endpoint runs."""

    settings = getattr(request.app.state, "settings", None) or get_settings()
    origin = request.headers.get("origin")
    origin_allowed = (
        origin_is_allowed(origin, settings.cors_origins)
        if origin is not None
        else request.headers.get(NATIVE_CLIENT_HEADER_NAME) == NATIVE_CLIENT_MARKER
    )
    if not origin_allowed or not csrf_tokens_match(
        request.cookies.get(CSRF_COOKIE_NAME),
        request.headers.get(CSRF_HEADER_NAME),
    ):
        raise CsrfFailedError()


validate_csrf = require_csrf

__all__ = [
    "AuthenticatedActor",
    "CurrentActor",
    "current_identity",
    "get_auth_service",
    "get_current_identity",
    "get_group_repository",
    "get_membership_repository",
    "require_authenticated_group",
    "require_csrf",
    "require_group_access",
    "validate_csrf",
]
