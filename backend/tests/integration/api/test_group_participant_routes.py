"""Integration coverage for protected group and participant routes."""

from dataclasses import dataclass, field
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
from backend.app.api.routes._common import (
    get_group_service,
    get_participant_service,
)
from backend.app.api.routes.groups import router as groups_router
from backend.app.api.routes.participants import router as participants_router
from backend.app.application.authorization import ForbiddenError
from backend.app.application.participant_service import ParticipantNotFoundError
from backend.app.domain.errors import (
    DuplicateParticipantNameError,
    InvalidParticipantNameError,
    ParticipantInUseError,
)
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

GROUP_ID = "group-demo"
OWNER_ID = "account-owner"
MEMBER_ID = "account-member"


@dataclass
class Group:
    id: str = GROUP_ID
    name: str = "Samaipata"
    owner_account_id: str = OWNER_ID
    settlement_policy: str = "owner_only"


class Auth:
    def session_identity(self, token):
        if token == "owner-token":
            return SimpleNamespace(
                account_id=OWNER_ID,
                login_name="demo.owner",
                active_group_id=GROUP_ID,
                role="owner",
                expires_at=datetime(2027, 1, 1, tzinfo=UTC),
            )
        if token == "member-token":
            return SimpleNamespace(
                account_id=MEMBER_ID,
                login_name="demo.member",
                active_group_id=GROUP_ID,
                role="member",
                expires_at=datetime(2027, 1, 1, tzinfo=UTC),
            )
        from backend.app.application.auth_service import UnauthorizedError

        raise UnauthorizedError()


class Memberships:
    def find_for_account_in_group(self, account_id, group_id):
        if group_id != GROUP_ID or account_id not in {OWNER_ID, MEMBER_ID}:
            return None
        return SimpleNamespace(
            account_id=account_id,
            group_id=GROUP_ID,
            owner_account_id=OWNER_ID,
        )


class Groups:
    def __init__(self, group):
        self.group = group

    def find_by_id(self, group_id):
        return self.group if group_id == GROUP_ID else None


class GroupService:
    def __init__(self, group):
        self.group = group

    def read(self, group_id, actor=None):
        if group_id != GROUP_ID:
            from backend.app.application.group_service import GroupNotFoundError

            raise GroupNotFoundError()
        return self.group

    def update_policy(self, group_id, settlement_policy, actor=None):
        if group_id != GROUP_ID:
            from backend.app.application.group_service import GroupNotFoundError

            raise GroupNotFoundError()
        if (
            self.group.settlement_policy == "owner_only"
            and getattr(actor, "role", None) != "owner"
        ):
            raise ForbiddenError()
        self.group.settlement_policy = settlement_policy
        return self.group


@dataclass
class Participant:
    id: str
    group_id: str
    name: str
    normalized_name: str
    archived_at: datetime | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))


class ParticipantService:
    def __init__(self):
        self.rows = [
            Participant("ana", GROUP_ID, "Ana", "ana"),
            Participant("beto", GROUP_ID, "Beto", "beto"),
            Participant("carla", GROUP_ID, "Carla", "carla"),
        ]
        self.references: set[str] = {"carla"}

    def list(self, group_id, actor=None):
        return [row for row in self.rows if row.group_id == group_id]

    def _get(self, group_id, participant_id):
        row = next(
            (
                row
                for row in self.rows
                if row.group_id == group_id and row.id == participant_id
            ),
            None,
        )
        if row is None:
            raise ParticipantNotFoundError()
        return row

    def add(self, group_id, name, actor=None):
        clean = name.strip()
        if not clean:
            raise InvalidParticipantNameError()
        normalized = clean.casefold()
        if any(row.normalized_name == normalized for row in self.rows):
            raise DuplicateParticipantNameError()
        row = Participant(str(len(self.rows) + 1), group_id, clean, normalized)
        self.rows.append(row)
        return row

    def rename(self, group_id, participant_id, name, actor=None):
        row = self._get(group_id, participant_id)
        clean = name.strip()
        if not clean:
            raise InvalidParticipantNameError()
        normalized = clean.casefold()
        if any(
            other.id != participant_id and other.normalized_name == normalized
            for other in self.rows
        ):
            raise DuplicateParticipantNameError()
        row.name = clean
        row.normalized_name = normalized
        return row

    def archive(self, group_id, participant_id, actor=None):
        row = self._get(group_id, participant_id)
        row.archived_at = datetime(2026, 1, 2, tzinfo=UTC)
        return row

    def reactivate(self, group_id, participant_id, actor=None):
        row = self._get(group_id, participant_id)
        row.archived_at = None
        return row

    def delete(self, group_id, participant_id, actor=None):
        row = self._get(group_id, participant_id)
        if participant_id in self.references:
            raise ParticipantInUseError()
        self.rows.remove(row)


@pytest.fixture
def group_participant_app():
    group = Group()
    participant_service = ParticipantService()
    group_service = GroupService(group)
    app = FastAPI()
    register_error_handlers(app)
    app.include_router(groups_router)
    app.include_router(participants_router)
    app.dependency_overrides.update(
        {
            get_auth_service: Auth,
            get_membership_repository: Memberships,
            get_group_repository: lambda: Groups(group),
            get_group_service: lambda: group_service,
            get_participant_service: lambda: participant_service,
        }
    )
    return app, group, participant_service


def _cookies(token="owner-token"):
    return {
        SESSION_COOKIE_NAME: token,
        CSRF_COOKIE_NAME: "csrf-token",
    }


def _set_cookies(client: AsyncClient, cookies: dict[str, str]) -> None:
    client.cookies.clear()
    client.cookies.update(cookies)


def _headers():
    return {"Origin": "http://localhost:5173", CSRF_HEADER_NAME: "csrf-token"}


@pytest.mark.asyncio
async def test_group_and_participant_routes_are_protected_and_return_server_shapes(
    group_participant_app,
):
    app, _group, participants = group_participant_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        unauthorized = await client.get(f"/api/v1/groups/{GROUP_ID}")
        _set_cookies(client, _cookies())
        group = await client.get(f"/api/v1/groups/{GROUP_ID}")
        _set_cookies(client, _cookies())
        listed = await client.get(f"/api/v1/groups/{GROUP_ID}/participants")
        _set_cookies(client, _cookies())
        added = await client.post(
            f"/api/v1/groups/{GROUP_ID}/participants",
            headers=_headers(),
            json={"name": "  Diego  ", "role": "owner"},
        )

    assert unauthorized.status_code == 401
    assert unauthorized.json()["error_code"] == "unauthorized"
    assert group.status_code == 200
    assert group.json()["settlementPolicy"] == "owner_only"
    assert listed.status_code == 200
    assert [row["name"] for row in listed.json()] == ["Ana", "Beto", "Carla"]
    assert added.status_code == 422
    assert added.json()["error_code"] == "invalid_request"
    assert len(participants.rows) == 3


@pytest.mark.asyncio
async def test_participant_lifecycle_rename_and_dependency_errors_have_stable_envelopes(
    group_participant_app,
):
    app, _group, participants = group_participant_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        renamed = await client.patch(
            f"/api/v1/groups/{GROUP_ID}/participants/ana",
            headers=_headers(),
            json={"name": " Ana L. "},
        )
        _set_cookies(client, _cookies())
        blank = await client.patch(
            f"/api/v1/groups/{GROUP_ID}/participants/ana",
            headers=_headers(),
            json={"name": "   "},
        )
        _set_cookies(client, _cookies())
        conflict = await client.patch(
            f"/api/v1/groups/{GROUP_ID}/participants/ana",
            headers=_headers(),
            json={"name": " BETO "},
        )
        _set_cookies(client, _cookies())
        archived = await client.post(
            f"/api/v1/groups/{GROUP_ID}/participants/beto/archive",
            headers=_headers(),
        )
        _set_cookies(client, _cookies())
        reactivated = await client.post(
            f"/api/v1/groups/{GROUP_ID}/participants/beto/reactivate",
            headers=_headers(),
        )
        _set_cookies(client, _cookies())
        protected_delete = await client.delete(
            f"/api/v1/groups/{GROUP_ID}/participants/carla",
            headers=_headers(),
        )
        _set_cookies(client, _cookies())
        missing = await client.patch(
            f"/api/v1/groups/{GROUP_ID}/participants/unknown",
            headers=_headers(),
            json={"name": "Nobody"},
        )

    assert renamed.status_code == 200
    assert renamed.json()["id"] == "ana"
    assert renamed.json()["name"] == "Ana L."
    assert blank.status_code == 422
    assert blank.json()["error_code"] == "invalid_participant_name"
    assert conflict.status_code == 422
    assert conflict.json()["error_code"] == "duplicate_participant_name"
    assert archived.status_code == 200
    assert archived.json()["archived"] is True
    assert reactivated.json()["archived"] is False
    assert protected_delete.status_code == 409
    assert protected_delete.json()["error_code"] == "participant_in_use"
    assert missing.status_code == 404
    assert missing.json()["error_code"] == "not_found"
    assert [row.id for row in participants.rows] == ["ana", "beto", "carla"]


@pytest.mark.asyncio
async def test_group_policy_matrix_rejects_member_and_forbids_unknown_fields(
    group_participant_app,
):
    app, group, _participants = group_participant_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        unknown = await client.patch(
            f"/api/v1/groups/{GROUP_ID}",
            headers=_headers(),
            json={"settlementPolicy": "any_member", "name": "forged"},
        )
        _set_cookies(client, _cookies("member-token"))
        denied = await client.patch(
            f"/api/v1/groups/{GROUP_ID}",
            headers=_headers(),
            json={"settlementPolicy": "any_member"},
        )
        _set_cookies(client, _cookies())
        changed = await client.patch(
            f"/api/v1/groups/{GROUP_ID}",
            headers=_headers(),
            json={"settlementPolicy": "any_member"},
        )
        _set_cookies(client, _cookies("member-token"))
        member_allowed = await client.patch(
            f"/api/v1/groups/{GROUP_ID}",
            headers=_headers(),
            json={"settlementPolicy": "owner_only"},
        )

    assert unknown.status_code == 422
    assert denied.status_code == 403
    assert denied.json()["error_code"] == "forbidden"
    assert changed.status_code == 200
    assert changed.json()["settlementPolicy"] == "any_member"
    assert member_allowed.status_code == 200
    assert member_allowed.json()["settlementPolicy"] == "owner_only"
    assert group.settlement_policy == "owner_only"
