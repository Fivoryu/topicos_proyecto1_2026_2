"""Fake-based tests for the application-layer workspace service."""

from __future__ import annotations

from copy import deepcopy
from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from backend.app.application.auth_service import UnauthorizedError
from backend.app.application.authorization import ForbiddenError
from backend.app.application.ports import MembershipRecord
from backend.app.application.workspace_service import (
    InvalidGroupNameError,
    WorkspaceInvariantError,
    WorkspaceService,
)


def group(group_id, name, owner):
    return SimpleNamespace(
        id=group_id,
        name=name,
        owner_account_id=owner,
        settlement_policy="owner_only",
        outings=[],
        participants=[],
        expenses=[],
    )


def membership(account_id, group_id, *, ended_at=None, owner_account_id="forged"):
    return MembershipRecord(account_id, group_id, owner_account_id, ended_at)


class FakeGroups:
    def __init__(self, rows=()):
        self.rows = {row.id: row for row in rows}
        self.find_calls = []

    def find_by_id(self, group_id):
        self.find_calls.append(group_id)
        return self.rows.get(group_id)

    def create(self, row):
        self.rows[row.id] = row
        return row


class FakeMemberships:
    def __init__(self, rows=(), *, create_error=None, owner_account_id=None):
        self.rows = list(rows)
        self.create_error = create_error
        self.owner_account_id = owner_account_id
        self.active_only_calls = []

    def list_for_account(self, account_id, *, active_only=True):
        self.active_only_calls.append(active_only)
        rows = [row for row in self.rows if row.account_id == account_id]
        return [row for row in rows if not active_only or row.ended_at is None]

    def find_for_account_in_group(self, account_id, group_id):
        return next(
            (
                row
                for row in self.rows
                if row.account_id == account_id
                and row.group_id == group_id
                and row.ended_at is None
            ),
            None,
        )

    def create_or_reactivate(self, group_id, account_id):
        if self.create_error:
            raise self.create_error
        row = membership(
            account_id,
            group_id,
            owner_account_id=self.owner_account_id or account_id,
        )
        self.rows.append(row)
        return row


class RecordingPublisher:
    def __init__(self, events, commits):
        self.events = events
        self.commits = commits

    def publish(self, group_id):
        assert self.commits() == 1
        self.events.append(group_id)


class FakeUnitOfWork:
    def __init__(self, groups, memberships):
        self.groups, self.memberships = groups, memberships
        self.commits = self.rollbacks = self.flushes = 0

    def __enter__(self):
        self.snapshot = (deepcopy(self.groups.rows), deepcopy(self.memberships.rows))
        return self

    def __exit__(self, exc_type, _value, _traceback):
        if exc_type is None:
            self.commits += 1
        else:
            self.rollbacks += 1
            self.groups.rows, self.memberships.rows = deepcopy(self.snapshot)
        return False

    def flush(self):
        self.flushes += 1


@pytest.fixture
def fixture():
    account = "account-one"
    groups = FakeGroups(
        (
            group("group-one", "First trip", account),
            group("group-two", "Second trip", "account-two"),
            group("group-three", "Other trip", "account-two"),
        )
    )
    memberships = FakeMemberships(
        (membership(account, "group-one"), membership(account, "group-two"))
    )
    uow = FakeUnitOfWork(groups, memberships)
    return SimpleNamespace(
        account=account,
        groups=groups,
        memberships=memberships,
        uow=uow,
        service=WorkspaceService(groups, memberships, uow),
    )


def test_list_is_account_scoped_and_roles_come_from_group_owner(fixture):
    result = fixture.service.list_groups(fixture.account)

    assert [(row.id, row.name, row.role) for row in result] == [
        ("group-one", "First trip", "owner"),
        ("group-two", "Second trip", "member"),
    ]
    assert fixture.memberships.active_only_calls == [True]


def test_list_excludes_ended_memberships_and_supports_zero_group_accounts():
    groups = FakeGroups((group("group-one", "Trip", "owner"),))
    memberships = FakeMemberships(
        (membership("account-one", "group-one", ended_at=datetime.now(UTC)),)
    )
    service = WorkspaceService(groups, memberships, FakeUnitOfWork(groups, memberships))

    assert service.list_groups("account-one") == []
    assert service.list_groups("account-without-groups") == []


def test_selected_group_rechecks_membership_and_returns_server_role(fixture):
    result = fixture.service.get_selected_group(fixture.account, "group-two")

    assert (result.id, result.owner_account_id, result.role) == (
        "group-two",
        "account-two",
        "member",
    )
    with pytest.raises(ForbiddenError) as error:
        fixture.service.get_selected_group(fixture.account, "group-three")
    assert error.value.code == "forbidden"


def test_create_trims_name_and_persists_empty_owner_workspace(fixture):
    result = fixture.service.create_group(fixture.account, "  Weekend away  ")

    assert (result.name, result.role, result.owner_account_id) == (
        "Weekend away",
        "owner",
        fixture.account,
    )
    assert (
        result.outings_count == result.participants_count == result.expenses_count == 0
    )
    assert len(fixture.groups.rows) == 4
    assert len(fixture.memberships.rows) == 3
    assert fixture.memberships.rows[-1].group_id == result.id
    assert fixture.uow.commits == 1
    assert fixture.uow.rollbacks == 0
    assert fixture.uow.flushes == 1


@pytest.mark.parametrize("name", ["", "  \t\n", None, "x" * 256])
def test_create_rejects_invalid_names_before_opening_transaction(fixture, name):
    with pytest.raises(InvalidGroupNameError) as error:
        fixture.service.create_group(fixture.account, name)

    assert error.value.code == "invalid_group_name"
    assert len(fixture.groups.rows) == 3
    assert fixture.uow.commits == fixture.uow.rollbacks == 0


def test_create_publishes_once_after_commit(fixture):
    events = []
    publisher = RecordingPublisher(events, lambda: fixture.uow.commits)
    service = WorkspaceService(
        fixture.groups,
        fixture.memberships,
        fixture.uow,
        invalidation_publisher=publisher,
    )

    result = service.create_group(fixture.account, "Trip")

    assert events == [result.id]
    assert fixture.uow.commits == 1


def test_create_does_not_publish_when_transaction_fails(fixture):
    events = []
    fixture.memberships.create_error = RuntimeError("membership insert failed")
    service = WorkspaceService(
        fixture.groups,
        fixture.memberships,
        fixture.uow,
        invalidation_publisher=RecordingPublisher(events, lambda: fixture.uow.commits),
    )

    with pytest.raises(RuntimeError, match="membership insert failed"):
        service.create_group(fixture.account, "Trip")

    assert events == []
    assert fixture.uow.commits == 0


def test_create_rolls_back_group_when_owner_membership_fails(fixture):
    fixture.memberships.create_error = RuntimeError("membership insert failed")

    with pytest.raises(RuntimeError, match="membership insert failed"):
        fixture.service.create_group(fixture.account, "Trip")

    assert len(fixture.groups.rows) == 3
    assert len(fixture.memberships.rows) == 2
    assert (fixture.uow.commits, fixture.uow.rollbacks) == (0, 1)


def test_create_rolls_back_when_owner_membership_is_not_server_owned(fixture):
    fixture.memberships.owner_account_id = "another-account"

    with pytest.raises(WorkspaceInvariantError) as error:
        fixture.service.create_group(fixture.account, "Trip")

    assert error.value.code == "owner_membership_required"
    assert len(fixture.groups.rows) == 3
    assert len(fixture.memberships.rows) == 2
    assert (fixture.uow.commits, fixture.uow.rollbacks) == (0, 1)


def test_list_and_create_require_an_authenticated_account(fixture):
    with pytest.raises(UnauthorizedError) as list_error:
        fixture.service.list_groups(None)
    with pytest.raises(UnauthorizedError) as create_error:
        fixture.service.create_group(None, "Trip")

    assert list_error.value.code == create_error.value.code == "unauthorized"
    assert len(fixture.groups.rows) == 3
    assert len(fixture.memberships.rows) == 2
