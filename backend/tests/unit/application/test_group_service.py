from dataclasses import dataclass
from types import TracebackType

import pytest
from backend.app.application.authorization import AuthorizationService, ForbiddenError
from backend.app.application.group_service import GroupService


@dataclass
class Group:
    id: str
    owner_account_id: str
    name: str = "Trip"
    settlement_policy: str = "owner_only"


@dataclass
class Membership:
    account_id: str
    group_id: str
    owner_account_id: str


class Memberships:
    def __init__(self):
        self.members = {
            "owner": Membership("owner", "group-one", "owner"),
            "member": Membership("member", "group-one", "owner"),
        }

    def find_for_account_in_group(self, account_id: str, group_id: str):
        membership = self.members.get(account_id)
        return membership if membership and membership.group_id == group_id else None


class Groups:
    def __init__(self):
        self.group = Group("group-one", "owner")

    def find_by_id(self, group_id: str):
        return self.group if group_id == self.group.id else None


class UnitOfWork:
    def __init__(self, groups):
        self.groups = groups
        self.commits = 0
        self.rollbacks = 0
        self.fail_commit = False

    def __enter__(self):
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool:
        if exc_type is None:
            if self.fail_commit:
                raise RuntimeError("commit failed")
            self.commits += 1
        else:
            self.rollbacks += 1
        return False

    def flush(self):
        return None


class Publisher:
    def __init__(self):
        self.groups = []

    def publish(self, group_id: str):
        self.groups.append(group_id)


@pytest.fixture
def fixture():
    groups = Groups()
    memberships = Memberships()
    uow = UnitOfWork(groups)
    publisher = Publisher()
    authorization = AuthorizationService(memberships, groups)
    service = GroupService(groups, uow, authorization, publisher)
    return service, groups, uow, publisher


def test_owner_can_read_default_and_change_policy_after_commit(fixture):
    service, groups, uow, publisher = fixture

    assert (
        service.read("group-one", {"account_id": "owner"}).settlement_policy
        == "owner_only"
    )
    updated = service.update_policy("group-one", "any_member", {"account_id": "owner"})

    assert updated.settlement_policy == "any_member"
    assert groups.group.settlement_policy == "any_member"
    assert uow.commits == 1
    assert publisher.groups == ["group-one"]


def test_member_is_denied_under_owner_only_without_mutation_or_invalidation(fixture):
    service, groups, uow, publisher = fixture

    with pytest.raises(ForbiddenError) as error:
        service.update_policy("group-one", "any_member", {"account_id": "member"})

    assert error.value.code == "forbidden"
    assert groups.group.settlement_policy == "owner_only"
    assert uow.commits == 0
    assert uow.rollbacks == 1
    assert publisher.groups == []


def test_member_can_change_policy_when_current_value_is_any_member(fixture):
    service, groups, uow, publisher = fixture
    groups.group.settlement_policy = "any_member"

    updated = service.update_policy("group-one", "owner_only", {"account_id": "member"})

    assert updated.settlement_policy == "owner_only"
    assert uow.commits == 1
    assert publisher.groups == ["group-one"]


def test_invalidation_is_not_published_when_commit_fails(fixture):
    service, groups, uow, publisher = fixture
    uow.fail_commit = True

    with pytest.raises(RuntimeError, match="commit failed"):
        service.update_policy("group-one", "any_member", {"account_id": "owner"})

    assert groups.group.settlement_policy == "any_member"
    assert publisher.groups == []
