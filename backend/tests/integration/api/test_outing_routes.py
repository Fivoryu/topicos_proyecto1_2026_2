from dataclasses import dataclass, field
from datetime import UTC, datetime
from types import SimpleNamespace
from typing import Any, cast

import pytest
from backend.app.adapters.events.broadcaster import GroupEventBroadcaster
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
from backend.app.api.routes.groups import router as groups_router
from backend.app.api.routes.outings import get_outing_service, nested_router
from backend.app.api.routes.outings import router as outings_router
from backend.app.application.authorization import AuthorizationService, ForbiddenError
from backend.app.application.outing_service import (
    ArchivedOutingReadOnlyError,
    InvalidOutingNameError,
    OutingNotFoundError,
)
from backend.app.application.outing_service import (
    OutingService as ApplicationOutingService,
)
from backend.app.main import _wire_request_services
from backend.app.main import app as application
from fastapi import FastAPI, Request
from httpx import ASGITransport, AsyncClient

GROUP_ID = "group-one"
OWNER_ID = "account-owner"
MEMBER_ID = "account-member"
ORIGIN = "http://localhost:5173"


@dataclass
class Outing:
    id: str
    group_id: str = GROUP_ID
    name: str = "Weekend"
    archived_at: datetime | None = None
    created_at: datetime = field(
        default_factory=lambda: datetime(2026, 1, 1, tzinfo=UTC)
    )
    updated_at: datetime = field(
        default_factory=lambda: datetime(2026, 1, 1, tzinfo=UTC)
    )


class Auth:
    def session_identity(self, token):
        if token in {"owner-token", "member-token"}:
            account_id = OWNER_ID if token == "owner-token" else MEMBER_ID
            return SimpleNamespace(
                account_id=account_id,
                login_name=account_id,
                active_group_id=GROUP_ID,
                role="owner" if account_id == OWNER_ID else "member",
                expires_at=datetime(2027, 1, 1, tzinfo=UTC),
            )
        from backend.app.application.auth_service import UnauthorizedError

        raise UnauthorizedError()


class Memberships:
    def find_for_account_in_group(self, account_id, group_id):
        if group_id != GROUP_ID or account_id not in {OWNER_ID, MEMBER_ID}:
            return None
        return SimpleNamespace(
            account_id=account_id, group_id=GROUP_ID, owner_account_id=OWNER_ID
        )


class Groups:
    def find_by_id(self, group_id):
        if group_id != GROUP_ID:
            return None
        return SimpleNamespace(id=GROUP_ID, owner_account_id=OWNER_ID)


class OutingService:
    def __init__(self):
        self.rows = [Outing("outing-one")]

    def list(self, group_id, actor=None):
        return [row for row in self.rows if row.group_id == group_id]

    def get(self, group_id, outing_id, actor=None):
        row = next((row for row in self.list(group_id) if row.id == outing_id), None)
        if row is None:
            raise OutingNotFoundError()
        return row

    def create(self, group_id, name, actor=None):
        clean = name.strip()
        if not clean:
            raise InvalidOutingNameError()
        row = Outing(str(len(self.rows) + 1), group_id, clean)
        self.rows.append(row)
        return row

    def edit(self, group_id, outing_id, name, actor=None):
        row = self.get(group_id, outing_id, actor)
        if row.archived_at is not None:
            raise ArchivedOutingReadOnlyError()
        row.name = name.strip()
        return row

    def archive(self, group_id, outing_id, actor=None):
        if getattr(actor, "role", None) != "owner":
            raise ForbiddenError()
        row = self.get(group_id, outing_id, actor)
        row.archived_at = datetime(2026, 1, 2, tzinfo=UTC)
        return row

    def unarchive(self, group_id, outing_id, actor=None):
        if getattr(actor, "role", None) != "owner":
            raise ForbiddenError()
        row = self.get(group_id, outing_id, actor)
        row.archived_at = None
        return row

    def delete(self, group_id, outing_id, actor=None):
        if getattr(actor, "role", None) != "owner":
            raise ForbiddenError()
        row = self.get(group_id, outing_id, actor)
        if row.archived_at is not None:
            raise ArchivedOutingReadOnlyError()
        self.rows.remove(row)


@pytest.fixture
def outing_app():
    app = FastAPI()
    register_error_handlers(app)
    app.include_router(outings_router)
    service = OutingService()
    app.dependency_overrides.update(
        {
            get_auth_service: Auth,
            get_membership_repository: Memberships,
            get_group_repository: Groups,
            get_outing_service: lambda: service,
        }
    )
    return app, service


def test_source_openapi_exposes_outings_once_with_only_the_outings_tag():
    path = "/api/v1/groups/{group_id}/outings"
    document = application.openapi()

    assert list(document["paths"]).count(path) == 1
    assert document["paths"][path]["get"]["tags"] == ["outings"]
    assert not any(
        getattr(route, "original_router", None) is nested_router
        for route in groups_router.routes
    )


def cookies(token="member-token"):
    return {SESSION_COOKIE_NAME: token, CSRF_COOKIE_NAME: "csrf-token"}


def headers():
    return {"Origin": ORIGIN, CSRF_HEADER_NAME: "csrf-token"}


def test_production_wiring_exposes_request_scoped_authorized_outing_service():
    app = FastAPI()
    broadcaster = GroupEventBroadcaster()
    app.state.broadcaster = broadcaster
    request_state = SimpleNamespace()

    _wire_request_services(app, cast(Any, object()), target_state=request_state)

    service = request_state.outing_service
    assert isinstance(service, ApplicationOutingService)
    assert isinstance(service._authorization, AuthorizationService)
    assert service._authorization._memberships is request_state.membership_repository
    assert service._authorization._groups is request_state.group_repository
    assert service._publisher is broadcaster

    request = Request(
        {
            "type": "http",
            "app": app,
            "method": "GET",
            "path": "/",
            "headers": [],
            "query_string": b"",
        }
    )
    request.state.outing_service = service
    assert get_outing_service(request) is service


def test_compatibility_fallback_builds_server_authorization_from_request_state():
    app = FastAPI()
    membership_repository = object()
    group_repository = SimpleNamespace(session=object())
    broadcaster = object()
    request = Request(
        {
            "type": "http",
            "app": app,
            "method": "GET",
            "path": "/",
            "headers": [],
            "query_string": b"",
        }
    )
    request.state.membership_repository = membership_repository
    request.state.group_repository = group_repository
    request.state.broadcaster = broadcaster

    service = get_outing_service(request)

    assert isinstance(service, ApplicationOutingService)
    assert isinstance(service._authorization, AuthorizationService)
    assert service._authorization._memberships is membership_repository
    assert service._authorization._groups is group_repository
    assert service._publisher is broadcaster


@pytest.mark.asyncio
async def test_get_outing_service_fails_closed_without_request_scoped_state():
    app = FastAPI()
    app.state.membership_repository = object()
    app.state.group_repository = SimpleNamespace(session=object())
    request = Request(
        {
            "type": "http",
            "app": app,
            "method": "GET",
            "path": "/",
            "headers": [],
            "query_string": b"",
        }
    )

    with pytest.raises(RuntimeError, match="outing_service"):
        get_outing_service(request)


@pytest.mark.asyncio
async def test_member_create_edit_read_and_owner_lifecycle_are_protected(outing_app):
    app, service = outing_app
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
        cookies=cookies(),
    ) as client:
        created = await client.post(
            f"/api/v1/groups/{GROUP_ID}/outings",
            headers=headers(),
            json={"name": "  Friday  "},
        )
        edited = await client.patch(
            f"/api/v1/groups/{GROUP_ID}/outings/{created.json()['id']}",
            headers=headers(),
            json={"name": " Friday final "},
        )
        listed = await client.get(f"/api/v1/groups/{GROUP_ID}/outings")
        owner_client = client
        owner_client.cookies.update(cookies("owner-token"))
        archived = await owner_client.post(
            f"/api/v1/groups/{GROUP_ID}/outings/outing-one/archive",
            headers=headers(),
        )
        read = await owner_client.get(f"/api/v1/groups/{GROUP_ID}/outings/outing-one")
        archived_edit = await owner_client.patch(
            f"/api/v1/groups/{GROUP_ID}/outings/outing-one",
            headers=headers(),
            json={"name": "Archived edit"},
        )

    assert created.status_code == 201
    assert created.json()["name"] == "Friday"
    assert edited.status_code == 200
    assert edited.json()["name"] == "Friday final"
    assert listed.status_code == 200
    assert len(listed.json()) == 2
    assert archived.status_code == 200
    assert archived.json()["archived"] is True
    assert read.json()["archived"] is True
    assert archived_edit.status_code == 409
    assert archived_edit.json()["error_code"] == "archived_outing_read_only"
    assert len(service.rows) == 2


@pytest.mark.asyncio
async def test_member_forbidden_archived_write_blank_and_stale_ids_have_stable_errors(
    outing_app,
):
    app, _service = outing_app
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
        cookies=cookies(),
    ) as client:
        forbidden = await client.post(
            f"/api/v1/groups/{GROUP_ID}/outings/outing-one/archive",
            headers=headers(),
        )
        blank = await client.post(
            f"/api/v1/groups/{GROUP_ID}/outings",
            headers=headers(),
            json={"name": "  "},
        )
        stale = await client.get(f"/api/v1/groups/{GROUP_ID}/outings/missing")

    assert forbidden.status_code == 403
    assert forbidden.json()["error_code"] == "forbidden"
    assert blank.status_code == 422
    assert blank.json()["error_code"] == "invalid_outing_name"
    assert stale.status_code == 404
    assert stale.json()["error_code"] == "not_found"
