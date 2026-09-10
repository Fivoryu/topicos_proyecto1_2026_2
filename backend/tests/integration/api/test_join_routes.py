# ruff: noqa: E501, I001
from datetime import UTC, datetime
from types import SimpleNamespace
import pytest
from backend.app.adapters.security.sessions import CSRF_COOKIE_NAME, CSRF_HEADER_NAME, SESSION_COOKIE_NAME
from backend.app.api.deps import get_auth_service, get_group_repository, get_membership_repository
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes._common import get_join_service
from backend.app.api.routes.join import router
from backend.app.application.auth_service import UnauthorizedError
from backend.app.application.authorization import ForbiddenError
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

G = "group-one"

@pytest.fixture
def app():
    calls = []
    def identity(token):
        if token not in {"owner-token", "member-token"}:
            raise UnauthorizedError()
        return SimpleNamespace(account_id=token.removesuffix("-token"), login_name="x", expires_at=datetime(2027, 1, 1, tzinfo=UTC))
    membership = SimpleNamespace(find_for_account_in_group=lambda account, group: SimpleNamespace(account_id=account, group_id=G, owner_account_id="owner") if group == G else None)
    group = SimpleNamespace(find_by_id=lambda group_id: SimpleNamespace(id=G, owner_account_id="owner", settlement_policy="owner_only") if group_id == G else None)
    def generate(group_id, actor):
        if actor.account_id != "owner":
            raise ForbiddenError()
        return SimpleNamespace(group_id=group_id, code="raw-token", generation=2)
    service = SimpleNamespace(
        status=lambda group_id, actor: SimpleNamespace(group_id=group_id, generation=2, active=True),
        generate=generate, revoke=lambda group_id, actor: SimpleNamespace(group_id=group_id, generation=2, active=False),
    )
    service.regenerate = service.generate
    def consume(code, actor, *, participant_id=None, new_participant_name=None):
        calls.append((code, actor.account_id, participant_id, new_participant_name))
        return SimpleNamespace(group_id=G, account_id=actor.account_id, participant_id=participant_id or "new")
    service.consume = consume
    api = FastAPI()
    register_error_handlers(api)
    api.include_router(router)
    api.dependency_overrides.update({get_auth_service: lambda: SimpleNamespace(session_identity=identity), get_membership_repository: lambda: membership, get_group_repository: lambda: group, get_join_service: lambda: service})
    return api, calls
def cookies(token="owner-token"):
    return {SESSION_COOKIE_NAME: token, CSRF_COOKIE_NAME: "csrf"}
def headers():
    return {"Origin": "http://localhost:5173", CSRF_HEADER_NAME: "csrf"}
@pytest.mark.asyncio
async def test_lifecycle_is_owner_only_and_status_revoke_never_return_token(app):
    api, _ = app
    async with AsyncClient(transport=ASGITransport(app=api), base_url="http://test", cookies=cookies()) as client:
        client.cookies.update(cookies())
        status = await client.get(f"/api/v1/groups/{G}/join-code")
        generated = await client.post(f"/api/v1/groups/{G}/join-code", headers=headers())
        revoked = await client.delete(f"/api/v1/groups/{G}/join-code", headers=headers())
        client.cookies.update(cookies("member-token"))
        denied = await client.post(f"/api/v1/groups/{G}/join-code", headers=headers())
    assert status.status_code == revoked.status_code == 200
    assert "code" not in status.json() and "code" not in revoked.json()
    assert generated.json()["code"] == "raw-token"
    assert denied.status_code == 403 and denied.json()["error_code"] == "forbidden"
@pytest.mark.asyncio
async def test_consume_is_authenticated_reusable_and_requires_one_choice(app):
    api, calls = app
    async with AsyncClient(transport=ASGITransport(app=api), base_url="http://test", cookies=cookies()) as client:
        first = await client.post("/api/v1/groups/join", headers=headers(), json={"code": "raw", "new_participant_name": "Ana"})
        second = await client.post("/api/v1/groups/join", headers=headers(), json={"code": "raw", "participant_id": "new"})
        neither = await client.post("/api/v1/groups/join", headers=headers(), json={"code": "raw"})
        both = await client.post("/api/v1/groups/join", headers=headers(), json={"code": "raw", "participant_id": "new", "new_participant_name": "Ana"})
    assert first.status_code == second.status_code == 200 and len(calls) == 2
    assert calls[0][3] == "Ana" and calls[1][2] == "new"
    assert neither.status_code == both.status_code == 422


@pytest.mark.asyncio
async def test_consume_requires_an_authenticated_session(app):
    api, calls = app
    async with AsyncClient(transport=ASGITransport(app=api), base_url="http://test", cookies=cookies()) as client:
        client.cookies.update(cookies("invalid-token"))
        response = await client.post(
            "/api/v1/groups/join",
            headers=headers(),
            json={"code": "raw", "new_participant_name": "Ana"},
        )
    assert response.status_code == 401
    assert response.json()["error_code"] == "unauthorized"
    assert calls == []


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("method", "path", "payload"),
    [
        ("POST", f"/api/v1/groups/{G}/join-code", None),
        ("POST", f"/api/v1/groups/{G}/join-code/regenerate", None),
        ("DELETE", f"/api/v1/groups/{G}/join-code", None),
        ("POST", "/api/v1/groups/join", {"code": "raw", "new_participant_name": "Ana"}),
    ],
)
async def test_join_mutations_reject_missing_csrf_and_disallowed_origin(app, method, path, payload):
    api, calls = app
    async with AsyncClient(transport=ASGITransport(app=api), base_url="http://test", cookies=cookies()) as client:
        missing_csrf = await client.request(
            method, path, headers={"Origin": "http://localhost:5173"}, json=payload,
        )
        disallowed_origin = await client.request(
            method, path, headers={"Origin": "https://evil.example", CSRF_HEADER_NAME: "csrf"}, json=payload,
        )
    assert missing_csrf.status_code == disallowed_origin.status_code == 403
    assert missing_csrf.json()["error_code"] == disallowed_origin.json()["error_code"] == "csrf_failed"
    assert calls == []
