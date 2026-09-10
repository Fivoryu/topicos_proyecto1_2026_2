from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from backend.app.application.membership_service import (
    FinalOwnerExitError,
    MemberNotFoundError,
    MembershipService,
)

NOW = datetime(2026, 1, 1, tzinfo=UTC)
GROUP, OWNER, MEMBER = "group-one", "account-owner", "account-member"


def membership(account_id, group=GROUP, ended_at=None):
    return SimpleNamespace(
        account_id=account_id, group_id=group, owner_account_id=OWNER, ended_at=ended_at
    )


def active(rows, group, account):
    return next(
        (
            row
            for row in rows
            if (row.group_id, row.account_id) == (group, account)
            and row.ended_at is None
        ),
        None,
    )


class Memberships:
    def __init__(self, rows):
        self.rows = rows

    def end(self, group, account, ended_at=None):
        row = active(self.rows, group, account)
        if row is None:
            return False
        row.ended_at = ended_at or NOW
        return True

    def list_active_by_group(self, group):
        return [
            row for row in self.rows if row.group_id == group and row.ended_at is None
        ]

    def find_active_by_group_account(self, group, account, *, for_update=False):
        del for_update
        return active(self.rows, group, account)


class UnitOfWork:
    def __init__(self, memberships, links, fail_commit=False):
        self.memberships, self.account_participant_links = memberships, links
        self.fail_commit, self.commits, self.rollbacks = fail_commit, 0, 0

    def __enter__(self):
        rows = self.memberships.rows + self.account_participant_links.rows
        self.snapshot = [(row, row.ended_at) for row in rows]
        return self

    def __exit__(self, exc_type, _value, _traceback):
        if exc_type is not None or self.fail_commit:
            for row, ended_at in self.snapshot:
                row.ended_at = ended_at
            self.rollbacks += 1
            if self.fail_commit and exc_type is None:
                raise RuntimeError("commit failed")
        else:
            self.commits += 1


def service(*, rows=None, fail_commit=False):
    memberships = Memberships(
        rows if rows is not None else [membership(OWNER, GROUP), membership(MEMBER, GROUP)]  # noqa: E501
    )
    links = Memberships(
        [SimpleNamespace(group_id=GROUP, account_id=MEMBER, ended_at=None)]
    )
    uow, publisher = UnitOfWork(memberships, links, fail_commit), SimpleNamespace(groups=[])  # noqa: E501
    publisher.publish = lambda group: publisher.groups.append(group)
    service_ = MembershipService(
        memberships,
        uow,
        SimpleNamespace(authorize=lambda *_: None),
        invalidation_publisher=publisher,
        now=lambda: NOW,
    )
    return service_, memberships, links, publisher, uow


def test_owner_removes_member_and_ends_link_once():
    service_, memberships, links, publisher, uow = service()
    service_.remove_member(GROUP, MEMBER, SimpleNamespace(account_id=OWNER))
    assert active(memberships.rows, GROUP, MEMBER) is None
    assert links.rows[0].ended_at == NOW
    assert (uow.commits, publisher.groups) == (1, [GROUP])


def test_member_leaves_but_final_owner_cannot_exit():
    member_service, memberships, links, publisher, _ = service()
    member_service.leave_group(GROUP, SimpleNamespace(account_id=MEMBER))
    assert active(memberships.rows, GROUP, MEMBER) is None
    assert links.rows[0].ended_at == NOW
    assert publisher.groups == [GROUP]
    owner_service, memberships, _links, publisher, uow = service()
    with pytest.raises(FinalOwnerExitError):
        owner_service.leave_group(GROUP, SimpleNamespace(account_id=OWNER))
    assert (publisher.groups, uow.commits) == ([], 0)


def test_owner_cannot_remove_owner_or_non_active_targets():
    service_, memberships, _links, publisher, uow = service()
    with pytest.raises(FinalOwnerExitError):
        service_.remove_member(GROUP, OWNER, SimpleNamespace(account_id=OWNER))
    cases = (
        ("missing", [membership(OWNER, GROUP), membership(MEMBER, GROUP)]),
        (MEMBER, [membership(OWNER, GROUP), membership(MEMBER, GROUP, ended_at=NOW)]),
        (MEMBER, [membership(OWNER, GROUP), membership(MEMBER, "other-group")]),
    )
    for target, rows in cases:
        target_service, *_ = service(rows=rows)
        with pytest.raises(MemberNotFoundError):
            target_service.remove_member(
                GROUP, target, SimpleNamespace(account_id=OWNER)
            )
    assert (publisher.groups, uow.commits) == ([], 0)


@pytest.mark.parametrize("action", ["remove_member", "leave_group"])
def test_second_concurrent_style_exit_is_rejected_without_second_invalidation(action):
    service_, _memberships, _links, publisher, uow = service()
    actor = SimpleNamespace(account_id=OWNER if action == "remove_member" else MEMBER)

    if action == "remove_member":
        service_.remove_member(GROUP, MEMBER, actor)
        with pytest.raises(MemberNotFoundError):
            service_.remove_member(GROUP, MEMBER, actor)
    else:
        service_.leave_group(GROUP, actor)
        with pytest.raises(MemberNotFoundError):
            service_.leave_group(GROUP, actor)

    assert publisher.groups == [GROUP]
    assert uow.commits == 1


def test_missing_or_failed_commit_publishes_nothing_and_rolls_back():
    failing, memberships, links, publisher, uow = service(fail_commit=True)
    with pytest.raises(RuntimeError, match="commit failed"):
        failing.remove_member(GROUP, MEMBER, SimpleNamespace(account_id=OWNER))
    assert active(memberships.rows, GROUP, MEMBER) is not None
    assert links.rows[0].ended_at is None
    assert (publisher.groups, uow.rollbacks) == ([], 1)
