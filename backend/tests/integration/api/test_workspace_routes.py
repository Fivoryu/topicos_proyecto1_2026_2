"""Integration coverage for account-scoped workspace group routes."""

from __future__ import annotations

from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from backend.app.adapters.security.sessions import (
    CSRF_COOKIE_NAME,
    CSRF_HEADER_NAME,
    SESSION_COOKIE_NAME,
)
from backend.app.api.deps import (
    get_auth_service,
    get_group_repository,
    get_membership_repository,
)
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes._common import get_group_service, get_workspace_service
from backend.app.api.routes.auth import router as auth_router
from backend.app.api.routes.groups import router as groups_router
from backend.app.application.auth_service import UnauthorizedError
from backend.app.application.authorization import AuthorizationService
from backend.app.application.group_service import GroupNotFoundError
from backend.app.application.workspace_service import InvalidGroupNameError
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

GROUP_ID = "group-demo"
OWNER_ID = "account-owner"
MEMBER_ID = "account-member"
ORIGIN = "http://localhost:5173"
EXPIRY = datetime(2027, 1, 1, tzinfo=UTC)


class _Auth:
    def session_identity(self, token: str | None):
        identities = {
            "owner-token": SimpleNamespace(
                account_id=OWNER_ID,
                login_name="demo.owner",
                active_group_id=GROUP_ID,
                role="owner",
                expires_at=EXPIRY,
            ),
            "member-token": SimpleNamespace(
                account_id=MEMBER_ID,
                login_name="demo.member",
                active_group_id=GROUP_ID,
                role="member",
                expires_at=EXPIRY,
            ),
            "zero-group-token": SimpleNamespace(
                account_id="account-zero-group",
                login_name="demo.zero-group",
                active_group_id=None,
                role=None,
                expires_at=EXPIRY,
            ),
        }
        identity = identities.get(token or "")
        if identity is None:
            raise UnauthorizedError()
        return identity


class _WorkspaceService:
    def __init__(self, groups=None, created=None, failure=None):
        self.groups = list(groups or [])
        self.created = created or SimpleNamespace(
            id="created-group",
            name="New group",
            owner_account_id=OWNER_ID,
            settlement_policy="owner_only",
            role="owner",
            member_count=None,
            outings_count=0,
            participants_count=0,
            expenses_count=0,
        )
        self.failure = failure
        self.list_calls: list[object] = []
        self.create_calls: list[tuple[object, object]] = []

    def list_groups(self, account_id):
        self.list_calls.append(account_id)
        return list(self.groups)

    def create_group(self, account_id, name):
        self.create_calls.append((account_id, name))
        if self.failure is not None:
            raise self.failure
        return self.created


class _GroupService:
    def read(self, group_id, actor=None):
        if group_id != GROUP_ID:
            raise GroupNotFoundError()
        return SimpleNamespace(
            id=GROUP_ID,
            name="Samaipata",
            owner_account_id=OWNER_ID,
            settlement_policy="owner_only",
        )


class _Memberships:
    def find_for_account_in_group(self, account_id, group_id):
        if group_id != GROUP_ID or account_id not in {OWNER_ID, MEMBER_ID}:
            return None
        return SimpleNamespace(
            account_id=account_id,
            group_id=GROUP_ID,
            owner_account_id=OWNER_ID,
        )


class _Groups:
    def find_by_id(self, group_id):
        if group_id != GROUP_ID:
            return None
        return SimpleNamespace(
            id=GROUP_ID,
            name="Samaipata",
            owner_account_id=OWNER_ID,
            settlement_policy="owner_only",
        )


def _summary(group_id: str, name: str, role: str, owner: str):
    return SimpleNamespace(
        id=group_id,
        name=name,
        owner_account_id=owner,
        settlement_policy="owner_only",
        role=role,
        member_count=None,
        outings_count=None,
        participants_count=None,
        expenses_count=None,
    )


@pytest.fixture
def workspace_app():
    app = FastAPI()
    register_error_handlers(app)
    workspace = _WorkspaceService(
        groups=[
            _summary(GROUP_ID, "Samaipata", "owner", OWNER_ID),
            _summary("group-two", "Other group", "member", "account-other"),
        ]
    )
    app.include_router(groups_router)
    app.dependency_overrides.update(
        {
            get_auth_service: _Auth,
            get_workspace_service: lambda: workspace,
            get_group_service: lambda: _GroupService(),
            get_membership_repository: _Memberships,
            get_group_repository: _Groups,
        }
    )
    return app, workspace


def _cookies(token: str = "owner-token"):
    return {
        SESSION_COOKIE_NAME: token,
        CSRF_COOKIE_NAME: "csrf-token",
    }


def _headers():
    return {"Origin": ORIGIN, CSRF_HEADER_NAME: "csrf-token"}


def _set_cookies(client: AsyncClient, cookies: dict[str, str]) -> None:
    client.cookies.clear()
    client.cookies.update(cookies)


@pytest.mark.asyncio
async def test_authenticated_group_list_is_account_scoped_and_server_derived(
    workspace_app,
):
    app, workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.get("/api/v1/groups")

    assert response.status_code == 200
    assert response.json() == [
        {
            "id": GROUP_ID,
            "name": "Samaipata",
            "owner_account_id": OWNER_ID,
            "settlementPolicy": "owner_only",
            "role": "owner",
            "member_count": None,
            "outings_count": None,
            "participants_count": None,
            "expenses_count": None,
        },
        {
            "id": "group-two",
            "name": "Other group",
            "owner_account_id": "account-other",
            "settlementPolicy": "owner_only",
            "role": "member",
            "member_count": None,
            "outings_count": None,
            "participants_count": None,
            "expenses_count": None,
        },
    ]
    assert workspace.list_calls == [OWNER_ID]


@pytest.mark.asyncio
async def test_authenticated_account_with_no_groups_gets_empty_list(workspace_app):
    app, workspace = workspace_app
    workspace.groups = []
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.get("/api/v1/groups")

    assert response.status_code == 200
    assert response.json() == []
    assert workspace.list_calls == [OWNER_ID]


@pytest.mark.asyncio
async def test_session_probe_preserves_anonymous_authenticated_and_unusable_statuses(
    workspace_app,
):
    app, _workspace = workspace_app
    app.include_router(auth_router)
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        anonymous = await client.get("/api/v1/auth/session")
        _set_cookies(client, _cookies())
        authenticated = await client.get("/api/v1/auth/session")
        _set_cookies(client, _cookies("zero-group-token"))
        zero_group = await client.get("/api/v1/auth/session")
        _set_cookies(client, _cookies("unusable-token"))
        unusable = await client.get("/api/v1/auth/session")

    assert anonymous.status_code == 204
    assert authenticated.status_code == 200
    assert authenticated.json()["active_group_id"] == GROUP_ID
    assert authenticated.json()["role"] == "owner"
    assert "token" not in authenticated.json()
    assert zero_group.status_code == 200
    assert zero_group.json()["active_group_id"] is None
    assert zero_group.json()["role"] is None
    assert unusable.status_code == 401
    assert unusable.json()["error_code"] == "unauthorized"


@pytest.mark.asyncio
async def test_group_list_without_a_valid_identity_returns_structured_401(
    workspace_app,
):
    app, workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        response = await client.get("/api/v1/groups")

    assert response.status_code == 401
    assert response.json() == {
        "error_code": "unauthorized",
        "message": "A valid authenticated session is required.",
    }
    assert workspace.list_calls == []


@pytest.mark.asyncio
async def test_group_create_requires_csrf_and_origin_before_calling_service(
    workspace_app,
):
    app, workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, {SESSION_COOKIE_NAME: "owner-token"})
        response = await client.post(
            "/api/v1/groups", json={"name": "Should not be created"}
        )

    assert response.status_code == 403
    assert response.json()["error_code"] == "csrf_failed"
    assert workspace.create_calls == []


@pytest.mark.asyncio
@pytest.mark.asyncio
async def test_group_create_rejects_missing_origin_even_with_matching_csrf(
    workspace_app,
):
    app, workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.post(
            "/api/v1/groups",
            headers={CSRF_HEADER_NAME: "csrf-token"},
            json={"name": "Should not be created"},
        )

    assert response.status_code == 403
    assert response.json()["error_code"] == "csrf_failed"
    assert workspace.create_calls == []


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "payload",
    [
        {"name": "New group", "role": "member"},
        {"name": "New group", "group_id": "forged-group"},
    ],
)
async def test_group_create_does_not_accept_client_role_or_group_id(
    workspace_app, payload
):
    app, workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.post("/api/v1/groups", headers=_headers(), json=payload)

    assert response.status_code == 422
    assert response.json()["error_code"] == "invalid_request"
    assert workspace.create_calls == []


@pytest.mark.asyncio
async def test_group_create_returns_empty_owner_summary_and_uses_authenticated_account(
    workspace_app,
):
    app, workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.post(
            "/api/v1/groups", headers=_headers(), json={"name": "New group"}
        )

    assert response.status_code == 200
    assert response.json() == {
        "id": "created-group",
        "name": "New group",
        "owner_account_id": OWNER_ID,
        "settlementPolicy": "owner_only",
        "role": "owner",
        "member_count": None,
        "outings_count": 0,
        "participants_count": 0,
        "expenses_count": 0,
    }
    assert workspace.create_calls == [(OWNER_ID, "New group")]


@pytest.mark.asyncio
async def test_group_create_domain_validation_uses_stable_error_handler(workspace_app):
    app, workspace = workspace_app
    workspace.failure = InvalidGroupNameError()
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.post(
            "/api/v1/groups", headers=_headers(), json={"name": "   "}
        )

    assert response.status_code == 422
    assert response.json()["error_code"] == "invalid_group_name"
    assert workspace.create_calls == [(OWNER_ID, "   ")]


@pytest.mark.asyncio
async def test_dynamic_group_route_remains_protected_and_compatible(workspace_app):
    app, _workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.get(f"/api/v1/groups/{GROUP_ID}")

    assert response.status_code == 200
    assert response.json() == {
        "id": GROUP_ID,
        "name": "Samaipata",
        "owner_account_id": OWNER_ID,
        "settlementPolicy": "owner_only",
    }


@pytest.mark.asyncio
async def test_stale_selected_group_is_denied_before_group_data_is_returned(
    workspace_app,
):
    app, _workspace = workspace_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        response = await client.get("/api/v1/groups/group-two")

    assert response.status_code == 403
    assert response.json()["error_code"] == "forbidden"
    assert "Other group" not in response.text


def test_authorization_derives_role_and_ignores_client_role_claims():
    identity = SimpleNamespace(account_id=OWNER_ID, role="member")

    context = AuthorizationService(_Memberships(), _Groups()).authorize(
        identity,
        GROUP_ID,
        "read_group",
        client_role="member",
    )

    assert context.role == "owner"
