"""Application use cases for account-scoped group workspaces."""

from __future__ import annotations

from collections.abc import Iterator, Mapping
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Literal, cast
from uuid import UUID, uuid4

from backend.app.application.auth_service import UnauthorizedError
from backend.app.application.authorization import ForbiddenError
from backend.app.application.ports import AccountId, GroupId
from backend.app.domain.errors import DomainError

Role = Literal["owner", "member"]
MAX_GROUP_NAME_LENGTH = 255
_MISSING = object()


@dataclass(frozen=True, slots=True)
class WorkspaceGroupRecord:
    """Server-authoritative group data returned by workspace use cases."""

    id: GroupId
    name: str
    owner_account_id: AccountId
    role: Role
    settlement_policy: str = "owner_only"
    member_count: int | None = None
    outings_count: int | None = None
    participants_count: int | None = None
    expenses_count: int | None = None


WorkspaceGroup = WorkspaceGroupRecord
GroupSummary = WorkspaceGroupRecord


class InvalidGroupNameError(DomainError):
    """Raised when a group name is blank or exceeds the existing bound."""

    def __init__(self):
        super().__init__("invalid_group_name", "Group name must not be blank.")


class WorkspaceInvariantError(DomainError):
    """Raised when creation cannot establish the owner membership invariant."""

    def __init__(self):
        super().__init__(
            "owner_membership_required",
            "A created group must have an active owner membership.",
        )


class WorkspaceGroupNotFoundError(DomainError):
    """Raised when a selected group does not exist in the requested scope."""

    def __init__(self):
        super().__init__("not_found", "Group was not found.")


def normalize_group_name(value: object) -> str:
    """Trim and validate a group name before opening a transaction."""

    if not isinstance(value, str):
        raise InvalidGroupNameError()
    name = value.strip()
    if not name or len(name) > MAX_GROUP_NAME_LENGTH:
        raise InvalidGroupNameError()
    return name


def _value(record: object, *names: str, default: object = _MISSING) -> object:
    if isinstance(record, Mapping):
        for name in names:
            if name in record:
                return record[name]
    else:
        for name in names:
            value = getattr(record, name, _MISSING)
            if value is not _MISSING:
                return value
    return default if default is not _MISSING else None


def _account_id(value: object) -> AccountId:
    if isinstance(value, (UUID, str)):
        if isinstance(value, str) and not value.strip():
            raise UnauthorizedError()
        return value
    account_id = _value(value, "account_id", "accountId", default=None)
    if account_id is None:
        account = _value(value, "account", default=None)
        account_id = _value(account, "id", "account_id", default=None)
    if not isinstance(account_id, (UUID, str)) or (
        isinstance(account_id, str) and not account_id.strip()
    ):
        raise UnauthorizedError()
    return account_id


def _group_id(group: object) -> GroupId:
    group_id = _value(group, "id", "group_id", "groupId", default=None)
    if not isinstance(group_id, (UUID, str)):
        raise WorkspaceInvariantError()
    return group_id


def _active_membership(
    membership: object | None, account_id: AccountId, group_id: GroupId | None = None
) -> bool:
    if membership is None or _value(membership, "ended_at", default=None) is not None:
        return False
    matches = _value(membership, "account_id", "accountId", default=None) == account_id
    if group_id is not None:
        matches = (
            matches
            and _value(membership, "group_id", "groupId", default=None) == group_id
        )
    return matches


def _count(group: object, *names: str) -> int | None:
    value = _value(group, *names, default=None)
    if isinstance(value, int) and value >= 0:
        return value
    if isinstance(value, (list, tuple, set, frozenset)):
        return len(value)
    return None


class WorkspaceService:
    """Coordinate group discovery, selected-group authorization, and creation."""

    def __init__(
        self,
        group_repository: Any,
        membership_repository: Any,
        unit_of_work: Any | None = None,
        invalidation_publisher: Any = None,
    ):
        self._groups = group_repository
        self._memberships = membership_repository
        self._unit_of_work = unit_of_work
        self._publisher = invalidation_publisher

    def list_groups(self, account_id: object) -> list[WorkspaceGroupRecord]:
        """Return only active groups visible to the authenticated account."""

        account = _account_id(account_id)
        memberships = self._memberships.list_for_account(account, active_only=True)
        result = []
        for membership in memberships:
            if not _active_membership(membership, account):
                continue
            group_id = _value(membership, "group_id", "groupId", default=None)
            if not isinstance(group_id, (UUID, str)):
                continue
            group = self._groups.find_by_id(group_id)
            if group is not None:
                result.append(self._record(group, account))
        return result

    list_for_account = list_groups

    def get_selected_group(
        self, account_id: object, group_id: GroupId
    ) -> WorkspaceGroupRecord:
        """Recheck active membership before returning a selected group."""

        account = _account_id(account_id)
        membership = self._memberships.find_for_account_in_group(account, group_id)
        if not _active_membership(membership, account, group_id):
            raise ForbiddenError()
        group = self._groups.find_by_id(group_id)
        if group is None:
            raise WorkspaceGroupNotFoundError()
        return self._record(group, account)

    selected_group = get_selected_group

    def create_group(self, account_id: object, name: object) -> WorkspaceGroupRecord:
        """Create a group and its owner membership in one transaction."""

        account = _account_id(account_id)
        group = WorkspaceGroupRecord(
            id=uuid4(),
            name=normalize_group_name(name),
            owner_account_id=account,
            role="owner",
            outings_count=0,
            participants_count=0,
            expenses_count=0,
        )
        with self._transaction() as transaction:
            groups = getattr(transaction, "groups", None) or self._groups
            memberships = getattr(transaction, "memberships", None) or self._memberships
            persisted = groups.create(group) or group
            persisted_id = _group_id(persisted)
            membership = memberships.create_or_reactivate(persisted_id, account)
            if not (
                _active_membership(membership, account, persisted_id)
                and _value(membership, "owner_account_id", "ownerAccountId")
                == _value(persisted, "owner_account_id", "ownerAccountId")
                == account
            ):
                raise WorkspaceInvariantError()
            flush = getattr(transaction, "flush", None)
            if callable(flush):
                flush()
        if self._publisher is not None:
            self._publisher.publish(persisted_id)
        return self._record(persisted, account)

    create = create_group

    def _record(self, group: object, account_id: AccountId) -> WorkspaceGroupRecord:
        owner = _value(group, "owner_account_id", "ownerAccountId", default=None)
        name = _value(group, "name", default=None)
        if not isinstance(owner, (UUID, str)) or not isinstance(name, str):
            raise WorkspaceInvariantError()
        policy = _value(
            group, "settlement_policy", "settlementPolicy", default="owner_only"
        )
        if policy not in {"owner_only", "any_member"}:
            policy = "owner_only"
        return WorkspaceGroupRecord(
            id=_group_id(group),
            name=name,
            owner_account_id=owner,
            role="owner" if account_id == owner else "member",
            settlement_policy=str(policy),
            member_count=_count(group, "member_count", "members_count"),
            outings_count=_count(group, "outings_count", "outing_count", "outings"),
            participants_count=_count(
                group, "participants_count", "participant_count", "participants"
            ),
            expenses_count=_count(group, "expenses_count", "expense_count", "expenses"),
        )

    @contextmanager
    def _transaction(self) -> Iterator[Any]:
        candidate = self._unit_of_work
        if callable(candidate) and not hasattr(candidate, "__enter__"):
            candidate = candidate()
        if candidate is None or not hasattr(candidate, "__enter__"):
            raise TypeError("a unit of work is required for group creation")
        with cast(Any, candidate) as transaction:
            yield transaction


__all__ = [
    "GroupSummary",
    "InvalidGroupNameError",
    "MAX_GROUP_NAME_LENGTH",
    "WorkspaceGroup",
    "WorkspaceGroupNotFoundError",
    "WorkspaceGroupRecord",
    "WorkspaceInvariantError",
    "WorkspaceService",
    "normalize_group_name",
]
