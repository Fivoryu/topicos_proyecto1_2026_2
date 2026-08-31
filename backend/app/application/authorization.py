"""Server-authoritative authorization for group-scoped application operations."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any, Literal, Protocol, cast

from .auth_service import AuthenticationError, UnauthorizedError

Role = Literal["owner", "member"]
SettlementPolicy = Literal["owner_only", "any_member"]


class GroupMembershipRepository(Protocol):
    """Resolve an account's membership in a requested group."""

    def find_for_account_in_group(
        self, account_id: str, group_id: str
    ) -> object | None:
        """Return the membership or ``None`` when it is absent."""
        ...


class GroupRepository(Protocol):
    """Load the server-owned group used for role and policy decisions."""

    def find_by_id(self, group_id: str) -> object | None:
        """Return the requested group or ``None``."""
        ...


@dataclass(frozen=True, slots=True)
class GroupRecord:
    """Small server-side group record required by authorization."""

    id: str
    owner_account_id: str
    settlement_policy: str = "owner_only"


@dataclass(frozen=True, slots=True)
class AuthorizationContext:
    """Derived identity and operation context passed to an application use case."""

    account_id: str
    group_id: str
    role: Role
    operation: str
    settlement_policy: SettlementPolicy


class AuthorizationError(AuthenticationError):
    """Base error for expected authorization failures."""


class ForbiddenError(AuthorizationError):
    """Raised when membership or the operation policy denies access."""

    def __init__(self):
        super().__init__(
            "forbidden",
            "You do not have permission to access this group or perform "
            "this operation.",
        )


READ_OPERATIONS = frozenset(
    {
        "read_group",
        "read_participants",
        "read_expenses",
        "read_balances",
        "read_settlement",
    }
)
PARTICIPANT_MUTATION_OPERATIONS = frozenset(
    {
        "add_participant",
        "archive_participant",
        "reactivate_participant",
        "rename_participant",
        "delete_participant",
    }
)
EXPENSE_MUTATION_OPERATIONS = frozenset(
    {"create_expense", "edit_expense", "delete_expense"}
)
WEBSOCKET_OPERATIONS = frozenset({"websocket"})
ORDINARY_OPERATIONS = frozenset(
    READ_OPERATIONS
    | PARTICIPANT_MUTATION_OPERATIONS
    | EXPENSE_MUTATION_OPERATIONS
    | WEBSOCKET_OPERATIONS
)
POLICY_UPDATE_OPERATION = "update_group_policy"
_OPERATION_ALIASES = {"patch /groups/{id}": POLICY_UPDATE_OPERATION, "ws": "websocket"}
_MISSING = object()


def _value(record: object, *names: str, default: object = _MISSING) -> object:
    if isinstance(record, Mapping):
        mapping = cast(Mapping[Any, Any], record)
        for name in names:
            if name in mapping:
                return mapping[name]
    else:
        for name in names:
            value = getattr(record, name, _MISSING)
            if value is not _MISSING:
                return value
    if default is not _MISSING:
        return default
    raise ValueError(f"Record is missing one of: {', '.join(names)}")


def _account_id(actor: object) -> str:
    if actor is None:
        raise UnauthorizedError()
    account_id = _value(actor, "account_id", "accountId", default=None)
    if account_id is None:
        account = _value(actor, "account", default=None)
        if account is not None:
            account_id = _value(account, "id", "account_id", default=None)
    if account_id is None:
        raise UnauthorizedError()
    return cast(str, account_id)


def _operation_name(operation: object) -> str:
    value = getattr(operation, "value", operation)
    if not isinstance(value, str):
        raise ForbiddenError()
    value = value.strip().lower()
    return _OPERATION_ALIASES.get(value, value)


class AuthorizationService:
    """Check group membership, derive role, and apply the MVP operation matrix."""

    def __init__(
        self,
        membership_repository: GroupMembershipRepository,
        group_repository: GroupRepository | None = None,
    ):
        self._memberships = membership_repository
        self._groups = group_repository

    def authorize(
        self,
        actor: object | None,
        group_id: str,
        operation: object,
        *,
        client_role: object | None = None,
        group: object | None = None,
    ) -> AuthorizationContext:
        """Return a server-derived context or raise a stable auth error."""

        del client_role  # A client claim is never an authorization input.
        account_id = _account_id(actor)
        operation_name = _operation_name(operation)
        membership = self._find_membership(account_id, group_id)
        if membership is None or not self._membership_matches(
            membership, account_id, group_id
        ):
            raise ForbiddenError()
        if (
            operation_name not in ORDINARY_OPERATIONS
            and operation_name != POLICY_UPDATE_OPERATION
        ):
            raise ForbiddenError()

        server_group = group if group is not None else self._find_group(group_id)
        if server_group is None:
            server_group = self._membership_group_fallback(membership, group_id)
        if server_group is None:
            raise ForbiddenError()
        server_group_id = _value(server_group, "id", "group_id", default=None)
        if server_group_id is not None and server_group_id != group_id:
            raise ForbiddenError()
        owner_account_id = _value(
            server_group, "owner_account_id", "ownerAccountId", default=None
        )
        if owner_account_id is None:
            raise ForbiddenError()
        membership_owner_id = _value(
            membership, "owner_account_id", "ownerAccountId", default=None
        )
        if membership_owner_id is not None and membership_owner_id != owner_account_id:
            raise ForbiddenError()

        policy = self._settlement_policy(server_group, membership)
        role: Role = "owner" if account_id == owner_account_id else "member"
        if operation_name == POLICY_UPDATE_OPERATION and (
            policy == "owner_only" and role != "owner"
        ):
            raise ForbiddenError()
        return AuthorizationContext(account_id, group_id, role, operation_name, policy)

    def _find_membership(self, account_id: str, group_id: str) -> object | None:
        finder: Any = getattr(self._memberships, "find_for_account_in_group", None)
        if finder is None:
            finder = getattr(self._memberships, "find_for_account_and_group", None)
        try:
            if finder is not None:
                return finder(account_id, group_id)
            finder = getattr(self._memberships, "find_for_account", None)
            return finder(account_id) if finder is not None else None
        except (AttributeError, KeyError, TypeError, ValueError) as error:
            raise ForbiddenError() from error

    def _find_group(self, group_id: str) -> object | None:
        if self._groups is None:
            return None
        finder: Any = getattr(self._groups, "find_by_id", None) or getattr(
            self._groups, "find", None
        )
        if finder is None:
            raise ForbiddenError()
        try:
            return finder(group_id)
        except (AttributeError, KeyError, TypeError, ValueError) as error:
            raise ForbiddenError() from error

    @staticmethod
    def _membership_matches(membership: object, account_id: str, group_id: str) -> bool:
        try:
            return (
                _value(membership, "account_id", "accountId", default=None)
                == account_id
                and _value(membership, "group_id", "groupId", default=None) == group_id
            )
        except (AttributeError, KeyError, TypeError, ValueError):
            return False

    @staticmethod
    def _membership_group_fallback(
        membership: object, group_id: str
    ) -> GroupRecord | None:
        owner_account_id = _value(
            membership, "owner_account_id", "ownerAccountId", default=None
        )
        if owner_account_id is None:
            return None
        policy = _value(
            membership,
            "settlement_policy",
            "settlementPolicy",
            "policy",
            default="owner_only",
        )
        return GroupRecord(group_id, cast(str, owner_account_id), str(policy))

    @staticmethod
    def _settlement_policy(group: object, membership: object) -> SettlementPolicy:
        policy = _value(
            group,
            "settlement_policy",
            "settlementPolicy",
            "policy",
            default=None,
        )
        if policy is None:
            policy = _value(
                membership,
                "settlement_policy",
                "settlementPolicy",
                "policy",
                default="owner_only",
            )
        if policy not in {"owner_only", "any_member"}:
            raise ForbiddenError()
        return cast(SettlementPolicy, policy)
