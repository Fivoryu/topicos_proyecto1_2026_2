"""Integration coverage for the protected authentication HTTP surface."""

from dataclasses import dataclass
from datetime import UTC, datetime

import pytest
from backend.app.adapters.security.sessions import (
    CSRF_COOKIE_NAME,
    CSRF_HEADER_NAME,
    SESSION_COOKIE_NAME,
)
from backend.app.api.deps import get_auth_service
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes.auth import router as auth_router
from backend.app.application.auth_service import (
    InvalidCredentialsError,
    SessionIdentity,
    UnauthorizedError,
)
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient


@dataclass
class FakeAuthService:
    identities: dict[str, SessionIdentity]
    credentials: dict[tuple[str, str], SessionIdentity]
    revoked: set[str]

    def login(self, login_name: str, password: str) -> SessionIdentity:
        identity = self.credentials.get((login_name, password))
        if identity is None:
            raise InvalidCredentialsError()
        token = identity.token
        assert token is not None
        self.identities[token] = identity
        return identity

    def session_identity(self, token: str | None) -> SessionIdentity:
        identity = self.identities.get(token or "")
        if identity is None or identity.token in self.revoked:
            raise UnauthorizedError()
        return identity

    def logout(self, token: str | None) -> None:
        identity = self.session_identity(token)
        self.revoked.add(identity.token or "")


def _identity(
    account_id: str, login_name: str, role: str, token: str
) -> SessionIdentity:
    from typing import Literal, cast

    return SessionIdentity(
        account_id=account_id,
        login_name=login_name,
        active_group_id="group-demo",
        role=cast(Literal["owner", "member"], role),
        expires_at=datetime(2026, 1, 1, 20, tzinfo=UTC),
        token=token,
    )


@pytest.fixture
def auth_app():
    app = FastAPI()
    register_error_handlers(app)
    app.include_router(auth_router)
    return app


@pytest.fixture
def auth_service():
    owner = _identity("owner-id", "demo.owner", "owner", "owner-token")
    member = _identity("member-id", "demo.member", "member", "member-token")
    return FakeAuthService(
        identities={},
        credentials={
            ("demo.owner", "owner-password"): owner,
            ("demo.member", "member-password"): member,
        },
        revoked=set(),
    )


def _security_headers(csrf: str = "csrf-token"):
    return {
        "Origin": "http://localhost:5173",
        CSRF_HEADER_NAME: csrf,
    }


def _set_cookies(client: AsyncClient, cookies: dict[str, str]) -> None:
    client.cookies.clear()
    client.cookies.update(cookies)


@pytest.mark.asyncio
async def test_owner_and_member_login_return_server_roles_without_client_role_field(
    auth_app, auth_service
):
    auth_app.dependency_overrides[get_auth_service] = lambda: auth_service

    async with AsyncClient(
        transport=ASGITransport(app=auth_app), base_url="http://testserver"
    ) as client:
        for login_name, password, expected_role in (
            ("demo.owner", "owner-password", "owner"),
            ("demo.member", "member-password", "member"),
        ):
            _set_cookies(client, {CSRF_COOKIE_NAME: "csrf-token"})
            response = await client.post(
                "/api/v1/auth/login",
                headers=_security_headers(),
                json={"login_name": login_name, "password": password},
            )
            assert response.status_code == 200
            payload = response.json()
            assert payload["role"] == expected_role
            assert "client_role" not in payload
            assert "token" not in payload
            assert "cc_session=" in response.headers.get("set-cookie", "")
            assert "cc_csrf=" in response.headers.get("set-cookie", "")


@pytest.mark.asyncio
async def test_invalid_credentials_are_401_and_do_not_create_a_session(
    auth_app, auth_service
):
    auth_app.dependency_overrides[get_auth_service] = lambda: auth_service

    async with AsyncClient(
        transport=ASGITransport(app=auth_app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, {CSRF_COOKIE_NAME: "csrf-token"})
        response = await client.post(
            "/api/v1/auth/login",
            headers=_security_headers(),
            json={"login_name": "demo.owner", "password": "wrong"},
        )

    assert response.status_code == 401
    assert response.json()["error_code"] == "invalid_credentials"
    assert auth_service.identities == {}


@pytest.mark.asyncio
async def test_session_survives_refresh_and_logout_invalidates_old_cookie(
    auth_app, auth_service
):
    auth_app.dependency_overrides[get_auth_service] = lambda: auth_service

    async with AsyncClient(
        transport=ASGITransport(app=auth_app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, {CSRF_COOKIE_NAME: "csrf-token"})
        login = await client.post(
            "/api/v1/auth/login",
            headers=_security_headers(),
            json={"login_name": "demo.owner", "password": "owner-password"},
        )
        assert login.status_code == 200
        _set_cookies(
            client,
            {
                SESSION_COOKIE_NAME: "owner-token",
                CSRF_COOKIE_NAME: "csrf-token",
            },
        )
        session = await client.get("/api/v1/auth/session")
        assert session.status_code == 200
        assert session.json()["role"] == "owner"

        _set_cookies(
            client,
            {
                SESSION_COOKIE_NAME: "owner-token",
                CSRF_COOKIE_NAME: "csrf-token",
            },
        )
        logout = await client.post(
            "/api/v1/auth/logout",
            headers=_security_headers(),
        )
        _set_cookies(client, {SESSION_COOKIE_NAME: "owner-token"})
        rejected = await client.get("/api/v1/auth/session")

    assert logout.status_code == 204
    assert 'cc_session=""' in logout.headers.get("set-cookie", "")
    assert rejected.status_code == 401
    assert rejected.json()["error_code"] == "unauthorized"
    assert "group" not in rejected.text.lower()


@pytest.mark.asyncio
async def test_session_initializes_csrf_cookie_even_when_no_session_exists(
    auth_app, auth_service
):
    auth_app.dependency_overrides[get_auth_service] = lambda: auth_service

    async with AsyncClient(
        transport=ASGITransport(app=auth_app), base_url="http://testserver"
    ) as client:
        response = await client.get("/api/v1/auth/session")

    assert response.status_code == 401
    assert response.json()["error_code"] == "unauthorized"
    assert "cc_csrf=" in response.headers.get("set-cookie", "")
