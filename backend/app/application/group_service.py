"""Application use cases for group reads and settlement policy changes."""

from __future__ import annotations

from collections.abc import Callable, Iterator, Mapping, MutableMapping
from contextlib import contextmanager
from types import SimpleNamespace, TracebackType
from typing import Any, Protocol, cast

from backend.app.domain.errors import DomainError


class _AuthorizationPort(Protocol):
    def authorize(
        self,
        actor: object | None,
        group_id: str,
        operation: object,
        *,
        group: object | None = None,
    ) -> object: ...


class _Transaction(Protocol):
    def __enter__(self) -> Any: ...

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool: ...


class GroupNotFoundError(DomainError):
    """Raised when a group is outside the requested scope."""

    def __init__(self):
        super().__init__("not_found", "Group was not found.")


class InvalidSettlementPolicyError(DomainError):
    """Raised for values outside the two supported settlement policies."""

    def __init__(self):
        super().__init__("invalid_settlement_policy", "Settlement policy is invalid.")


class GroupService:
    """Read group settings and publish changes only after commit."""

    def __init__(
        self,
        group_repository: Any,
        unit_of_work: _Transaction | Callable[[], _Transaction] | None = None,
        authorization_service: _AuthorizationPort | None = None,
        invalidation_publisher: Any = None,
    ):
        # Accept both (repository, uow, authorization, publisher) and the natural
        # (repository, authorization, uow, publisher) injection order.
        if (
            authorization_service is not None
            and hasattr(unit_of_work, "authorize")
            and not hasattr(authorization_service, "authorize")
        ):
            unit_of_work, authorization_service = (
                cast(Any, authorization_service),
                cast(Any, unit_of_work),
            )
        self._groups = group_repository
        self._unit_of_work = unit_of_work
        self._authorization = authorization_service
        self._publisher = invalidation_publisher

    def read(self, group_id: str, actor: object | None = None):
        """Return a group with its persisted/default settlement policy."""

        group = self._find(self._groups, group_id)
        if group is None:
            raise GroupNotFoundError()
        if self._authorization is not None:
            self._authorization.authorize(actor, group_id, "read_group", group=group)
        return group

    get = read

    def update_policy(
        self,
        group_id: str,
        settlement_policy: object,
        actor: object | None = None,
    ):
        """Update policy atomically and invalidate clients after commit."""

        if not isinstance(settlement_policy, str) or settlement_policy not in {
            "owner_only",
            "any_member",
        }:
            raise InvalidSettlementPolicyError()
        policy = settlement_policy

        with self._transaction() as transaction:
            groups = getattr(transaction, "groups", None) or self._groups
            group = self._find(groups, group_id)
            if group is None:
                raise GroupNotFoundError()
            if self._authorization is not None:
                self._authorization.authorize(
                    actor, group_id, "update_group_policy", group=group
                )
            updated = self._set_policy(groups, group, group_id, policy)
            self._flush(transaction, groups)
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return updated

    update = update_policy
    set_settlement_policy = update_policy

    @staticmethod
    def _find(repository: Any, group_id: str):
        finder: Any = getattr(repository, "find_by_id", None) or getattr(
            repository, "find", None
        )
        if finder is None:
            raise TypeError("group repository cannot find groups")
        return finder(group_id)

    @staticmethod
    def _policy(group: object) -> str:
        if isinstance(group, Mapping):
            value = group.get("settlement_policy", group.get("settlementPolicy"))
        else:
            value = getattr(group, "settlement_policy", None)
            if value is None:
                value = getattr(group, "settlementPolicy", None)
        return value if value in {"owner_only", "any_member"} else "owner_only"

    @classmethod
    def _set_policy(cls, repository: Any, group: Any, group_id: str, policy: str):
        updater: Any = getattr(repository, "update_policy", None) or getattr(
            repository, "set_settlement_policy", None
        )
        if updater is not None:
            try:
                return updater(group_id, policy)
            except TypeError:
                return updater(group, policy)
        if isinstance(group, Mapping):
            mutable_group = cast(MutableMapping[Any, Any], group)
            mutable_group["settlement_policy"] = policy
            mutable_group["settlementPolicy"] = policy
            return group
        if hasattr(group, "settlement_policy"):
            group.settlement_policy = policy
        elif hasattr(group, "settlementPolicy"):
            setattr(group, "settlementPolicy", policy)
        else:
            raise TypeError("group record cannot store settlement policy")
        return group

    @staticmethod
    def _flush(transaction: Any, repository: Any) -> None:
        flush: Any = getattr(transaction, "flush", None)
        if callable(flush):
            flush()
            return
        session = getattr(repository, "session", None)
        flush = getattr(session, "flush", None)
        if callable(flush):
            flush()

    @contextmanager
    def _transaction(self) -> Iterator[Any]:
        candidate = self._unit_of_work
        if candidate is None:
            yield SimpleNamespace(groups=self._groups)
            return
        if callable(candidate):
            candidate = candidate()
        with candidate as transaction:
            yield transaction


__all__ = [
    "GroupNotFoundError",
    "GroupService",
    "InvalidSettlementPolicyError",
]
