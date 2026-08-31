"""Fake-based unit tests for server-authoritative group authorization."""

from dataclasses import dataclass
from types import SimpleNamespace

import pytest
from backend.app.application.auth_service import UnauthorizedError
from backend.app.application.authorization import (
    ORDINARY_OPERATIONS,
    AuthorizationService,
    ForbiddenError,
    GroupRecord,
)


@dataclass(frozen=True)
class FakeMembership:
    account_id: str
    group_id: str
    owner_account_id: str


class FakeMembershipRepository:
    def __init__(self, memberships: tuple[FakeMembership, ...]):
        self.memberships = memberships
        self.calls: list[tuple[str, str]] = []

    def find_for_account_in_group(self, account_id: str, group_id: str):
        self.calls.append((account_id, group_id))
        return next(
            (
                membership
                for membership in self.memberships
                if membership.account_id == account_id
                and membership.group_id == group_id
            ),
            None,
        )


class FakeGroupRepository:
    def __init__(self, groups: tuple[GroupRecord, ...]):
        self.groups = {group.id: group for group in groups}
        self.calls: list[str] = []

    def find_by_id(self, group_id: str):
        self.calls.append(group_id)
        return self.groups.get(group_id)


@pytest.fixture
def fixtures():
    group = GroupRecord(
        id="group-one",
        owner_account_id="account-owner",
        settlement_policy="owner_only",
    )
    memberships = FakeMembershipRepository(
        (
            FakeMembership("account-owner", group.id, group.owner_account_id),
            FakeMembership("account-member", group.id, group.owner_account_id),
            FakeMembership("account-other", "group-two", "account-other"),
        )
    )
    groups = FakeGroupRepository((group,))
    return SimpleNamespace(
        service=AuthorizationService(memberships, groups),
        memberships=memberships,
        groups=groups,
        group=group,
    )


def actor(account_id: str, role: str = "member"):
    """The role is intentionally a caller-controlled claim in these tests."""

    return SimpleNamespace(account_id=account_id, role=role)


def test_missing_actor_is_unauthorized_before_membership_or_group_access(fixtures):
    with pytest.raises(UnauthorizedError) as error:
        fixtures.service.authorize(None, "group-one", "read_group")

    assert error.value.code == "unauthorized"
    assert fixtures.memberships.calls == []
    assert fixtures.groups.calls == []


def test_owner_and_member_roles_are_derived_from_server_group_owner(fixtures):
    owner = fixtures.service.authorize(
        actor("account-owner", role="member"),
        "group-one",
        "read_group",
    )
    member = fixtures.service.authorize(
        actor("account-member", role="owner"),
        "group-one",
        "read_group",
    )

    assert owner.role == "owner"
    assert member.role == "member"
    assert owner.account_id == member.account_id.replace("member", "owner")
    assert owner.group_id == member.group_id == "group-one"


def test_out_of_group_actor_is_forbidden_before_group_data_access(fixtures):
    with pytest.raises(ForbiddenError) as error:
        fixtures.service.authorize(
            actor("account-other", role="owner"),
            "group-one",
            "read_expenses",
        )

    assert error.value.code == "forbidden"
    assert fixtures.groups.calls == []


def test_member_cannot_change_policy_when_current_policy_is_owner_only(fixtures):
    with pytest.raises(ForbiddenError) as error:
        fixtures.service.authorize(
            actor("account-member", role="owner"),
            "group-one",
            "update_group_policy",
        )

    assert error.value.code == "forbidden"
    assert "permission" in error.value.message.lower()


def test_member_can_change_policy_when_current_policy_is_any_member(fixtures):
    fixtures.groups.groups["group-one"] = GroupRecord(
        id="group-one",
        owner_account_id="account-owner",
        settlement_policy="any_member",
    )

    decision = fixtures.service.authorize(
        actor("account-member", role="owner"),
        "group-one",
        "update_group_policy",
    )

    assert decision.role == "member"
    assert decision.operation == "update_group_policy"


@pytest.mark.parametrize("operation", sorted(ORDINARY_OPERATIONS))
def test_both_derived_roles_can_access_ordinary_reads_and_mutations(
    fixtures, operation
):
    owner = fixtures.service.authorize(
        actor("account-owner", role="member"),
        "group-one",
        operation,
    )
    member = fixtures.service.authorize(
        actor("account-member", role="owner"),
        "group-one",
        operation,
    )

    assert owner.role == "owner"
    assert member.role == "member"


def test_owner_can_change_policy_when_current_policy_is_owner_only(fixtures):
    decision = fixtures.service.authorize(
        actor("account-owner", role="member"),
        "group-one",
        "PATCH /groups/{id}",
    )

    assert decision.role == "owner"
    assert decision.settlement_policy == "owner_only"


def test_forged_client_owner_claim_does_not_bypass_owner_only_policy(fixtures):
    with pytest.raises(ForbiddenError):
        fixtures.service.authorize(
            {"account_id": "account-member", "role": "owner"},
            "group-one",
            "PATCH /groups/{id}",
        )


def test_missing_account_id_is_unauthorized_before_membership_access(fixtures):
    with pytest.raises(UnauthorizedError) as error:
        fixtures.service.authorize({"role": "owner"}, "group-one", "read_group")

    assert error.value.code == "unauthorized"
    assert fixtures.memberships.calls == []
    assert fixtures.groups.calls == []


def test_membership_lookup_is_scoped_to_requested_group(fixtures):
    with pytest.raises(ForbiddenError) as error:
        fixtures.service.authorize(
            actor("account-owner"),
            "group-two",
            "read_group",
        )

    assert error.value.code == "forbidden"
    assert fixtures.memberships.calls[-1] == ("account-owner", "group-two")
    assert fixtures.groups.calls == []


def test_malformed_membership_cannot_grant_access(fixtures):
    fixtures.memberships.memberships = (
        FakeMembership("account-member", "group-one", "account-other"),
    )

    with pytest.raises(ForbiddenError):
        fixtures.service.authorize(
            actor("account-member"),
            "group-one",
            "read_group",
        )


def test_incomplete_membership_is_forbidden_instead_of_leaking_a_shape_error(
    fixtures,
):
    fixtures.memberships.memberships = (SimpleNamespace(owner_account_id="owner"),)

    with pytest.raises(ForbiddenError) as error:
        fixtures.service.authorize(
            actor("account-member"),
            "group-one",
            "read_group",
        )

    assert error.value.code == "forbidden"


def test_unknown_operation_is_denied_by_the_explicit_matrix(fixtures):
    with pytest.raises(ForbiddenError) as error:
        fixtures.service.authorize(
            actor("account-member"),
            "group-one",
            "delete_group",
        )

    assert error.value.code == "forbidden"
