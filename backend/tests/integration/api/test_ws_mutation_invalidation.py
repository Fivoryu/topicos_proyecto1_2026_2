"""End-to-end mutation invalidation tests for the protected API."""

from __future__ import annotations

from datetime import UTC, datetime
from types import SimpleNamespace
from typing import cast

import pytest
from backend.app.adapters.events.broadcaster import GroupEventBroadcaster
from backend.app.api.deps import (
    CSRF_COOKIE_NAME,
    CSRF_HEADER_NAME,
    SESSION_COOKIE_NAME,
    get_auth_service,
    get_group_repository,
    get_membership_repository,
)
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes.events import router as events_router
from backend.app.api.routes.expenses import router as expenses_router
from backend.app.api.routes.groups import router as groups_router
from backend.app.api.routes.participants import router as participants_router
from backend.app.application.authorization import AuthorizationService
from backend.app.application.derived_service import DerivedService
from backend.app.application.expense_service import ExpenseService
from backend.app.application.group_service import GroupService
from backend.app.application.participant_service import ParticipantService
from backend.app.application.ports import ExpenseRecord, ParticipantRecord
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

GROUP_ONE = "group-one"
GROUP_TWO = "group-two"
OWNER = "account-owner"
ORIGIN = "http://localhost:5173"
SESSION_ONE = "session-one"
SESSION_TWO = "session-two"
CSRF_TOKEN = "csrf-token"
EXPIRY = datetime(2027, 1, 1, tzinfo=UTC)


class _Auth:
    def session_identity(self, token: str | None):
        identities = {
            SESSION_ONE: SimpleNamespace(
                account_id=OWNER,
                login_name="owner.one",
                expires_at=EXPIRY,
            ),
            SESSION_TWO: SimpleNamespace(
                account_id=OWNER,
                login_name="owner.two",
                expires_at=EXPIRY,
            ),
        }
        if token not in identities:
            raise ValueError("invalid session")
        return identities[token]


class _Memberships:
    def find_for_account_in_group(self, account_id: object, group_id: object):
        if account_id != OWNER or str(group_id) not in {GROUP_ONE, GROUP_TWO}:
            return None
        return SimpleNamespace(
            account_id=OWNER,
            group_id=str(group_id),
            owner_account_id=OWNER,
        )


class _Groups:
    def __init__(self):
        self.rows = {
            GROUP_ONE: SimpleNamespace(
                id=GROUP_ONE,
                name="Group One",
                owner_account_id=OWNER,
                settlement_policy="owner_only",
            ),
            GROUP_TWO: SimpleNamespace(
                id=GROUP_TWO,
                name="Group Two",
                owner_account_id=OWNER,
                settlement_policy="owner_only",
            ),
        }

    def find_by_id(self, group_id: object):
        return self.rows.get(str(group_id))

    def update_policy(self, group_id: object, policy: str):
        group = self.rows[str(group_id)]
        group.settlement_policy = policy
        return group


class _Participants:
    def __init__(self):
        self.rows = [
            ParticipantRecord(
                id="p1",
                group_id=GROUP_ONE,
                name="Alice",
                normalized_name="alice",
                created_at=datetime(2026, 1, 1, tzinfo=UTC),
            ),
            ParticipantRecord(
                id="p2",
                group_id=GROUP_ONE,
                name="Bob",
                normalized_name="bob",
                created_at=datetime(2026, 1, 2, tzinfo=UTC),
            ),
        ]

    def list_by_group(self, group_id: object):
        return [row for row in self.rows if str(row.group_id) == str(group_id)]

    def find_by_id(
        self, group_id: object, participant_id: object, *, for_update: bool = False
    ):
        del for_update
        return next(
            (
                row
                for row in self.list_by_group(group_id)
                if str(row.id) == str(participant_id)
            ),
            None,
        )

    def find_by_normalized_name(
        self, group_id: object, normalized_name: str, exclude_id: str | None = None
    ):
        return next(
            (
                row
                for row in self.list_by_group(group_id)
                if row.normalized_name == normalized_name
                and str(row.id) != str(exclude_id)
            ),
            None,
        )

    def add(self, group_id: object, participant: ParticipantRecord):
        assert str(participant.group_id) == str(group_id)
        self.rows.append(participant)
        return participant

    def update_name(
        self,
        group_id: object,
        participant_id: object,
        name: str,
        normalized_name: str,
    ):
        row = self.find_by_id(group_id, participant_id)
        if row is None:
            return None
        row.name = name
        row.normalized_name = normalized_name
        return row

    def set_archived(self, group_id: object, participant_id: object, archived_at):
        row = self.find_by_id(group_id, participant_id)
        if row is None:
            return None
        row.archived_at = archived_at
        return row

    def has_references(self, _group_id: object, _participant_id: object):
        return False

    def delete(self, group_id: object, participant_id: object):
        row = self.find_by_id(group_id, participant_id)
        if row is None:
            return False
        self.rows.remove(row)
        return True


class _Expenses:
    def __init__(self):
        self.rows: list[ExpenseRecord] = []

    def list_by_group(self, group_id: object):
        return [row for row in self.rows if str(row.group_id) == str(group_id)]

    def find_by_id(self, group_id: object, expense_id: object):
        return next(
            (
                row
                for row in self.list_by_group(group_id)
                if str(row.id) == str(expense_id)
            ),
            None,
        )

    def create(
        self,
        group_id: object,
        expense: ExpenseRecord,
        _contributions=(),
        _beneficiaries=(),
    ):
        assert str(expense.group_id) == str(group_id)
        self.rows.append(expense)
        return expense

    def update(
        self,
        group_id: object,
        expense_id: object,
        replacement: ExpenseRecord,
        _contributions=(),
        _beneficiaries=(),
    ):
        current = self.find_by_id(group_id, expense_id)
        if current is None:
            return None
        self.rows[self.rows.index(current)] = replacement
        return replacement

    def delete(self, group_id: object, expense_id: object):
        current = self.find_by_id(group_id, expense_id)
        if current is None:
            return False
        self.rows.remove(current)
        return True


class _Probe:
    def __init__(self):
        self.frames: list[dict[str, str]] = []

    def put_nowait(self, frame: dict[str, str]):
        self.frames.append(frame)


class _RecordingPublisher:
    def __init__(self, events: list[tuple[str, str]]):
        self.events = events

    def publish(self, group_id: object):
        self.events.append(("publish", str(group_id)))


class _CommitUnitOfWork:
    def __init__(self, events: list[tuple[str, str]]):
        self.events = events

    def __enter__(self):
        self.events.append(("enter", ""))
        return self

    def __exit__(self, exc_type, _exc, _traceback):
        self.events.append(("rollback" if exc_type else "commit", ""))
        return False


class _FailingCommitUnitOfWork(_CommitUnitOfWork):
    def __exit__(self, exc_type, _exc, _traceback):
        super().__exit__(exc_type, _exc, _traceback)
        if exc_type is None:
            raise RuntimeError("commit failed")
        return False


@pytest.fixture
def mutation_app():
    app = FastAPI()
    register_error_handlers(app)
    broadcaster = GroupEventBroadcaster()
    groups = _Groups()
    memberships = _Memberships()
    participants = _Participants()
    expenses = _Expenses()
    publisher = broadcaster

    app.state.settings = SimpleNamespace(cors_origins=[ORIGIN])
    app.state.broadcaster = broadcaster
    app.state.auth_service = _Auth()
    app.state.group_repository = groups
    app.state.membership_repository = memberships
    app.state.participant_repository = participants
    app.state.expense_repository = expenses
    app.state.group_service = GroupService(
        groups,
        authorization_service=AuthorizationService(memberships, groups),
        invalidation_publisher=publisher,
    )
    app.state.participant_service = ParticipantService(
        participants, invalidation_publisher=publisher
    )
    app.state.expense_service = ExpenseService(
        expenses,
        participants,
        derived_service=DerivedService(participants, expenses),
        invalidation_publisher=publisher,
    )
    app.dependency_overrides.update(
        {
            get_auth_service: lambda: app.state.auth_service,
            get_group_repository: lambda: groups,
            get_membership_repository: lambda: memberships,
        }
    )

    app.include_router(groups_router)
    app.include_router(participants_router)
    app.include_router(expenses_router)
    app.include_router(events_router)
    return app, broadcaster, participants, expenses


def _client(app: FastAPI, token: str) -> TestClient:
    client = TestClient(app)
    client.cookies.set(SESSION_COOKIE_NAME, token, path="/api")
    client.cookies.set(CSRF_COOKIE_NAME, CSRF_TOKEN, path="/api")
    return client


def _mutation_headers(*, csrf: bool = True):
    headers = {"Origin": ORIGIN}
    if csrf:
        headers[CSRF_HEADER_NAME] = CSRF_TOKEN
    return headers


def test_rest_mutations_publish_one_isolated_frame_per_group(mutation_app):
    app, broadcaster, _participants, _expenses = mutation_app
    unrelated_probe = _Probe()
    broadcaster._subscribers.setdefault(GROUP_TWO, set()).add(unrelated_probe)

    with _client(app, SESSION_ONE) as group_one_client:
        with _client(app, SESSION_TWO) as group_two_client:
            with group_one_client.websocket_connect(
                f"/api/v1/groups/{GROUP_ONE}/events",
                headers={"Origin": ORIGIN},
            ) as group_one_socket:
                with group_two_client.websocket_connect(
                    f"/api/v1/groups/{GROUP_TWO}/events",
                    headers={"Origin": ORIGIN},
                ):
                    policy_response = group_one_client.patch(
                        f"/api/v1/groups/{GROUP_ONE}",
                        json={"settlementPolicy": "any_member"},
                        headers=_mutation_headers(),
                    )
                    assert policy_response.status_code == 200
                    assert group_one_socket.receive_json() == {"type": "data_changed"}

                    participant_response = group_one_client.post(
                        f"/api/v1/groups/{GROUP_ONE}/participants",
                        json={"name": "Carol"},
                        headers=_mutation_headers(),
                    )
                    assert participant_response.status_code == 201
                    assert group_one_socket.receive_json() == {"type": "data_changed"}

                    expense_response = group_one_client.post(
                        f"/api/v1/groups/{GROUP_ONE}/expenses",
                        json={
                            "description": "Lunch",
                            "amount": "10.00",
                            "contributors": [
                                {"participant_id": "p1", "amount": "10.00"}
                            ],
                            "beneficiary_ids": ["p2"],
                        },
                        headers=_mutation_headers(),
                    )
                    assert expense_response.status_code == 201
                    assert group_one_socket.receive_json() == {"type": "data_changed"}

    assert unrelated_probe.frames == []


def test_failed_csrf_mutation_does_not_publish(mutation_app):
    app, broadcaster, _participants, _expenses = mutation_app
    probe = _Probe()
    broadcaster._subscribers.setdefault(GROUP_ONE, set()).add(probe)

    with _client(app, SESSION_ONE) as client:
        response = client.post(
            f"/api/v1/groups/{GROUP_ONE}/participants",
            json={"name": "Rejected"},
            headers=_mutation_headers(csrf=False),
        )

    assert response.status_code == 403
    assert probe.frames == []


def test_participant_publishes_only_after_commit():
    events: list[tuple[str, str]] = []
    participants = _Participants()
    service = ParticipantService(
        participants,
        _CommitUnitOfWork(events),
        invalidation_publisher=_RecordingPublisher(events),
    )

    service.add(GROUP_ONE, "Carol")

    assert events == [("enter", ""), ("commit", ""), ("publish", GROUP_ONE)]


def test_commit_failure_skips_participant_publication():
    events: list[tuple[str, str]] = []
    participants = _Participants()
    service = ParticipantService(
        participants,
        _FailingCommitUnitOfWork(events),
        invalidation_publisher=_RecordingPublisher(events),
    )

    with pytest.raises(RuntimeError, match="commit failed"):
        service.add(GROUP_ONE, "Carol")

    assert events == [("enter", ""), ("commit", "")]


def test_wire_request_services_shares_the_app_broadcaster():
    from backend.app.main import _wire_request_services

    app = FastAPI()
    broadcaster = GroupEventBroadcaster()
    app.state.broadcaster = broadcaster

    _wire_request_services(app, cast(Session, object()))

    assert app.state.group_service._publisher is broadcaster
    assert app.state.participant_service._publisher is broadcaster
    assert app.state.expense_service._publisher is broadcaster
