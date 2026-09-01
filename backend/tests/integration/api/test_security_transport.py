"""API security transport tests for session, CSRF, and origin boundaries."""

from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from backend.app.adapters.security.sessions import (
    CSRF_COOKIE_NAME,
    CSRF_HEADER_NAME,
    SESSION_COOKIE_NAME,
    set_session_cookies,
)
from backend.app.api.deps import (
    get_auth_service,
    get_group_repository,
    get_membership_repository,
    require_csrf,
    require_group_access,
)
from backend.app.api.errors import register_error_handlers
from backend.app.application.auth_service import (
    SessionExpiredError,
    UnauthorizedError,
)
from fastapi import Depends, FastAPI
from httpx import ASGITransport, AsyncClient


class FakeAuthService:
    def __init__(self, identities=None, failures=None):
        self.identities = identities or {}
        self.failures = failures or {}
        self.calls = []

    def session_identity(self, token):
        self.calls.append(token)
        failure = self.failures.get(token)
        if failure is not None:
            raise failure
        identity = self.identities.get(token)
        if identity is None:
            raise UnauthorizedError()
        return identity


class FakeMembershipRepository:
    def __init__(self, memberships):
        self.memberships = memberships
        self.calls = []

    def find_for_account_in_group(self, account_id, group_id):
        self.calls.append((account_id, group_id))
        return self.memberships.get((account_id, group_id))


class FakeGroupRepository:
    def __init__(self, groups):
        self.groups = groups
        self.calls = []

    def find_by_id(self, group_id):
        self.calls.append(group_id)
        return self.groups.get(group_id)


@pytest.fixture
def security_app():
    app = FastAPI()
    register_error_handlers(app)
    mutation_calls = []

    @app.post("/groups/{group_id}/mutate")
    def mutate(
        _csrf=Depends(require_csrf),
        actor=Depends(require_group_access),
    ):
        mutation_calls.append(actor)
        return {"account_id": actor.account_id, "role": actor.role}

    @app.get("/groups/{group_id}/identity")
    def identity(actor=Depends(require_group_access)):
        return {"account_id": actor.account_id, "role": actor.role}

    app.state.mutation_calls = mutation_calls
    return app


@pytest.mark.asyncio
async def test_valid_session_propagates_server_identity_and_requested_group_role(
    security_app,
):
    identity = SimpleNamespace(
        account_id="account-member",
        login_name="demo.member",
        active_group_id="group-demo",
        expires_at=datetime(2026, 1, 1, tzinfo=UTC),
    )
    auth = FakeAuthService({"valid-token": identity})
    membership = FakeMembershipRepository(
        {
            ("account-member", "group-demo"): SimpleNamespace(
                account_id="account-member",
                group_id="group-demo",
                owner_account_id="account-owner",
            )
        }
    )
    groups = FakeGroupRepository(
        {
            "group-demo": SimpleNamespace(
                id="group-demo",
                owner_account_id="account-owner",
                settlement_policy="owner_only",
            )
        }
    )
    security_app.dependency_overrides.update(
        {
            get_auth_service: lambda: auth,
            get_membership_repository: lambda: membership,
            get_group_repository: lambda: groups,
        }
    )

    async with AsyncClient(
        transport=ASGITransport(app=security_app),
        base_url="http://testserver",
        cookies={SESSION_COOKIE_NAME: "valid-token"},
    ) as client:
        response = await client.get("/groups/group-demo/identity")

    assert response.status_code == 200
    assert response.json() == {"account_id": "account-member", "role": "member"}
    assert membership.calls == [("account-member", "group-demo")]
    assert groups.calls == ["group-demo"]


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("token", "failure", "code"),
    [
        (None, None, "unauthorized"),
        ("revoked-token", UnauthorizedError(), "unauthorized"),
        ("expired-token", SessionExpiredError(), "session_expired"),
    ],
)
async def test_missing_revoked_and_expired_sessions_are_rejected_before_group_access(
    security_app, token, failure, code
):
    auth = FakeAuthService(
        failures={token: failure} if token is not None else {},
    )
    membership = FakeMembershipRepository({})
    groups = FakeGroupRepository({})
    security_app.dependency_overrides.update(
        {
            get_auth_service: lambda: auth,
            get_membership_repository: lambda: membership,
            get_group_repository: lambda: groups,
        }
    )

    cookies = {} if token is None else {SESSION_COOKIE_NAME: token}
    async with AsyncClient(
        transport=ASGITransport(app=security_app),
        base_url="http://testserver",
        cookies=cookies,
    ) as client:
        response = await client.get("/groups/group-demo/identity")

    assert response.status_code == 401
    assert response.json()["error_code"] == code
    assert membership.calls == []
    assert groups.calls == []


@pytest.mark.asyncio
async def test_csrf_mismatch_and_disallowed_origin_are_403_without_mutation(
    security_app,
):
    identity = SimpleNamespace(
        account_id="account-owner",
        login_name="demo.owner",
        active_group_id="group-demo",
        expires_at=datetime(2026, 1, 1, tzinfo=UTC),
    )
    auth = FakeAuthService({"valid-token": identity})
    membership = FakeMembershipRepository(
        {
            ("account-owner", "group-demo"): SimpleNamespace(
                account_id="account-owner",
                group_id="group-demo",
                owner_account_id="account-owner",
            )
        }
    )
    groups = FakeGroupRepository(
        {
            "group-demo": SimpleNamespace(
                id="group-demo",
                owner_account_id="account-owner",
                settlement_policy="owner_only",
            )
        }
    )
    security_app.dependency_overrides.update(
        {
            get_auth_service: lambda: auth,
            get_membership_repository: lambda: membership,
            get_group_repository: lambda: groups,
        }
    )

    async with AsyncClient(
        transport=ASGITransport(app=security_app),
        base_url="http://testserver",
        cookies={SESSION_COOKIE_NAME: "valid-token", CSRF_COOKIE_NAME: "expected"},
    ) as client:
        mismatch = await client.post(
            "/groups/group-demo/mutate",
            headers={
                "Origin": "http://localhost:5173",
                CSRF_HEADER_NAME: "wrong",
            },
        )
        disallowed = await client.post(
            "/groups/group-demo/mutate",
            headers={
                "Origin": "https://evil.example",
                CSRF_HEADER_NAME: "expected",
            },
        )
        missing_origin = await client.post(
            "/groups/group-demo/mutate",
            headers={CSRF_HEADER_NAME: "expected"},
        )

    assert mismatch.status_code == 403
    assert mismatch.json()["error_code"] == "csrf_failed"
    assert disallowed.status_code == 403
    assert disallowed.json()["error_code"] == "csrf_failed"
    assert missing_origin.status_code == 403
    assert missing_origin.json()["error_code"] == "csrf_failed"
    assert auth.calls == []
    assert membership.calls == []
    assert groups.calls == []
    assert security_app.state.mutation_calls == []


def test_session_and_csrf_cookie_flags_are_scoped_and_distinct():
    from fastapi import Response

    response = Response()
    set_session_cookies(response, "opaque-token", "csrf-token")
    headers = response.headers.getlist("set-cookie")

    session_cookie = next(value for value in headers if value.startswith("cc_session="))
    csrf_cookie = next(value for value in headers if value.startswith("cc_csrf="))
    assert "HttpOnly" in session_cookie
    assert "SameSite=lax" in session_cookie
    assert "Path=/api" in session_cookie
    assert "HttpOnly" not in csrf_cookie
    assert "Path=/" in csrf_cookie
