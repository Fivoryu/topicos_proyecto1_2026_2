from collections.abc import Mapping
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from backend.app.application.auth_service import UnauthorizedError
from backend.app.domain.errors import DomainError


@dataclass(frozen=True, slots=True)
class MemberView:
    account_id: object
    group_id: object
    login_name: str
    role: str
    active: bool
    participant_id: object | None = None


class FinalOwnerExitError(DomainError):
    def __init__(self) -> None:
        super().__init__(
            "final_owner_exit",
            "The group owner cannot leave or be removed without ownership transfer.",
        )


class MemberNotFoundError(DomainError):
    def __init__(self) -> None:
        super().__init__(
            "member_not_found", "The requested member is not active in this group."
        )


def _value(record: object, *names: str, default: object = None) -> object:
    if isinstance(record, Mapping):
        return next((record[name] for name in names if name in record), default)
    return next((getattr(record, n) for n in names if hasattr(record, n)), default)


def _account_id(actor: object | None) -> object:
    if actor is None:
        raise UnauthorizedError()
    account_id = _value(actor, "account_id", "accountId", default=None)
    if account_id is None:
        account = _value(actor, "account", default=None)
        account_id = _value(account, "id", "account_id", default=None)
    if not isinstance(account_id, str) and not hasattr(account_id, "hex"):
        raise UnauthorizedError()
    return account_id


def _member_view(row: object, *, active: bool | None = None) -> MemberView:
    account_id = _value(row, "account_id", "accountId", default=None)
    group_id = _value(row, "group_id", "groupId", default=None)
    owner_id = _value(row, "owner_account_id", "ownerAccountId", default=None)
    if account_id is None or group_id is None or owner_id is None:
        raise MemberNotFoundError()
    if active is None:
        active = _value(row, "ended_at", default=None) is None
    return MemberView(
        account_id,
        group_id,
        str(_value(row, "login_name", "loginName", default=account_id)),
        "owner" if account_id == owner_id else "member",
        active,
        _value(row, "participant_id", "participantId", default=None),
    )


class MembershipService:

    def __init__(
        self,
        membership_repository: Any,
        unit_of_work: Any,
        authorization_service: Any,
        *,
        invalidation_publisher: Any = None,
        now: Any = None,
    ) -> None:
        self._memberships = membership_repository
        self._unit_of_work = unit_of_work
        self._authorization = authorization_service
        self._publisher = invalidation_publisher
        self._now = now or (lambda: datetime.now(UTC))

    def list_members(self, group_id: object, actor=None) -> list[MemberView]:
        self._authorize(actor, group_id, "read_group")
        finder = getattr(self._memberships, "list_active_by_group", None)
        if finder is None:  # pragma: no cover - repository contract guard
            raise TypeError("membership repository cannot list group members")
        return [_member_view(row) for row in finder(group_id)]

    def remove_member(self, group_id: object, account_id: object, actor=None):
        self._authorize(actor, group_id, "remove_member")
        return self._end_member(group_id, account_id)

    def leave_group(self, group_id: object, actor=None):
        account_id = _account_id(actor)
        self._authorize(actor, group_id, "leave_group")
        return self._end_member(group_id, account_id)

    def _end_member(self, group_id: object, account_id: object) -> MemberView:
        with self._transaction() as transaction:
            memberships = getattr(transaction, "memberships", None) or self._memberships
            target = self._find_active(
                memberships, group_id, account_id, for_update=True
            )
            if target is None:
                raise MemberNotFoundError()
            owner_id = _value(
                target, "owner_account_id", "ownerAccountId", default=None
            )
            if owner_id is None:
                raise MemberNotFoundError()
            if account_id == owner_id:
                raise FinalOwnerExitError()
            ended_at = self._now()
            if not memberships.end(group_id, account_id, ended_at):
                raise MemberNotFoundError()
            links = getattr(transaction, "account_participant_links", None)
            if links is not None:
                links.end(group_id, account_id, ended_at)
            result = _member_view(target, active=False)
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return result

    def _authorize(self, actor: object | None, group_id: object, operation: str):
        if self._authorization is None:
            raise TypeError("authorization service is required")
        return self._authorization.authorize(actor, group_id, operation)

    @staticmethod
    def _find_active(repository, group_id, account_id, *, for_update=False):
        finder = getattr(repository, "find_active_by_group_account", None) or getattr(
            repository, "find_for_account_in_group", None
        )
        if finder is None:
            return None
        try:
            return finder(group_id, account_id, for_update=for_update)
        except TypeError as error:
            if "for_update" not in str(error):
                raise
            return finder(account_id, group_id)

    def _transaction(self):
        source = self._unit_of_work
        transaction = source() if callable(source) else source
        if transaction is None or not hasattr(transaction, "__enter__"):
            raise TypeError("a unit of work is required")
        return transaction
