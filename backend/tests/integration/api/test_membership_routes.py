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
from backend.app.api.routes._common import get_membership_service
from backend.app.api.routes.memberships import router
from backend.app.application.auth_service import UnauthorizedError
from backend.app.application.membership_service import (
    FinalOwnerExitError,
    MemberNotFoundError,
)
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

GROUP, OWNER, MEMBER = "group-one", "account-owner", "account-member"
ORIGIN = "http://localhost:5173"
EXPIRY = datetime(2027, 1, 1, tzinfo=UTC)


def session_identity(token):
    if token not in {"owner-token", "member-token"}:
        raise UnauthorizedError()
    account = OWNER if token == "owner-token" else MEMBER
    return SimpleNamespace(
        account_id=account,
        login_name=account.removeprefix("account-"),
        expires_at=EXPIRY,
    )


def member_record(account_id, role, participant_id=None):
    return SimpleNamespace(
        account_id=account_id,
        group_id=GROUP,
        login_name=account_id.removeprefix("account-"),
        role=role,
        active=True,
        participant_id=participant_id,
    )


@pytest.fixture
def app():
    calls = {"remove": [], "leave": []}
    rows = [
        member_record(OWNER, "owner", "participant-owner"),
        member_record(MEMBER, "member"),
    ]
    service = SimpleNamespace(
        list_members=lambda group_id, actor=None: rows,
        remove_member=lambda group_id, account_id, actor=None: calls["remove"].append(
            (group_id, account_id, actor.account_id)
        ),
        leave_group=lambda group_id, actor=None: calls["leave"].append(
            (group_id, actor.account_id)
        ),
    )
    memberships = SimpleNamespace(
        find_for_account_in_group=lambda account_id, group_id: (
            SimpleNamespace(
                account_id=account_id,
                group_id=GROUP,
            )
            if group_id == GROUP and account_id in {OWNER, MEMBER}
            else None
        )
    )
    groups = SimpleNamespace(
        find_by_id=lambda group_id: (
            SimpleNamespace(
                id=GROUP,
                owner_account_id=OWNER,
            )
            if group_id == GROUP
            else None
        )
    )
    api = FastAPI()
    register_error_handlers(api)
    api.include_router(router)
    api.dependency_overrides.update(
        {
            get_auth_service: lambda: SimpleNamespace(
                session_identity=session_identity
            ),
            get_membership_repository: lambda: memberships,
            get_group_repository: lambda: groups,
            get_membership_service: lambda: service,
        }
    )
    api.state.test_memberships = memberships
    return api, calls


def cookies(token="owner-token"):
    return {SESSION_COOKIE_NAME: token, CSRF_COOKIE_NAME: "csrf"}


def headers():
    return {"Origin": ORIGIN, CSRF_HEADER_NAME: "csrf"}


@pytest.mark.asyncio
async def test_members_are_active_account_safe_and_group_protected(app):
    api, _ = app
    async with AsyncClient(
        transport=ASGITransport(app=api), base_url="http://test", cookies=cookies()
    ) as client:
        listed = await client.get(f"/api/v1/groups/{GROUP}/members")
    assert listed.json()[0] == {
        "account_id": OWNER,
        "login_name": "owner",
        "role": "owner",
        "active": True,
        "participant_id": "participant-owner",
    }
    assert "password_hash" not in listed.text and "token" not in listed.text


@pytest.mark.asyncio
async def test_mutations_require_csrf_and_use_server_identity(app):
    api, calls = app
    async with AsyncClient(
        transport=ASGITransport(app=api), base_url="http://test", cookies=cookies()
    ) as client:
        denied_remove = await client.delete(
            f"/api/v1/groups/{GROUP}/members/{MEMBER}", headers={"Origin": ORIGIN}
        )
        denied_leave = await client.post(
            f"/api/v1/groups/{GROUP}/leave", headers={"Origin": ORIGIN}
        )
        removed = await client.delete(
            f"/api/v1/groups/{GROUP}/members/{MEMBER}", headers=headers()
        )
        client.cookies.update(cookies("member-token"))
        left = await client.post(f"/api/v1/groups/{GROUP}/leave", headers=headers())
    assert denied_remove.status_code == denied_leave.status_code == 403
    assert (
        denied_remove.json()["error_code"]
        == denied_leave.json()["error_code"]
        == "csrf_failed"
    )
    assert removed.status_code == left.status_code == 204
    assert calls["remove"] == [(GROUP, MEMBER, OWNER)]
    assert calls["leave"] == [(GROUP, MEMBER)]


@pytest.mark.asyncio
async def test_ended_membership_cannot_read_with_an_existing_session(app):
    api, _ = app
    api.state.test_memberships.find_for_account_in_group = (
        lambda account_id, group_id: (
            SimpleNamespace(
                account_id=MEMBER,
                group_id=GROUP,
                owner_account_id=OWNER,
                ended_at=datetime(2026, 1, 2, tzinfo=UTC),
            )
            if account_id == MEMBER and group_id == GROUP
            else None
        )
    )
    async with AsyncClient(
        transport=ASGITransport(app=api),
        base_url="http://test",
        cookies=cookies("member-token"),
    ) as client:
        response = await client.get(f"/api/v1/groups/{GROUP}/members")

    assert response.status_code == 403
    assert response.json()["error_code"] == "forbidden"
    assert "participant_id" not in response.text


def _raise(error):
    def handler(*_args, **_kwargs):
        raise error

    return handler


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("method", "path", "error", "status", "error_code"),
    [
        (
            "POST",
            f"/api/v1/groups/{GROUP}/leave",
            FinalOwnerExitError(),
            409,
            "final_owner_exit",
        ),
        (
            "DELETE",
            f"/api/v1/groups/{GROUP}/members/{MEMBER}",
            MemberNotFoundError(),
            404,
            "member_not_found",
        ),
    ],
)
async def test_membership_domain_errors_use_stable_api_envelopes(
    app, method, path, error, status, error_code
):
    api, _ = app
    api.dependency_overrides[get_membership_service] = lambda: SimpleNamespace(
        leave_group=_raise(error), remove_member=_raise(error)
    )
    async with AsyncClient(
        transport=ASGITransport(app=api), base_url="http://test", cookies=cookies()
    ) as client:
        response = await client.request(method, path, headers=headers())

    assert response.status_code == status
    assert response.json()["error_code"] == error_code
    assert set(response.json()) >= {"error_code", "message"}
