"""Application use cases for group-scoped outing lifecycle."""

from __future__ import annotations

from collections.abc import Iterator, Mapping
from contextlib import contextmanager
from datetime import UTC, datetime
from types import SimpleNamespace
from typing import Any, cast
from uuid import uuid4

from backend.app.application.authorization import ForbiddenError
from backend.app.application.ports import (
    GroupId,
    InvalidationPublisher,
    OutingRecord,
)
from backend.app.domain.errors import DomainError

MAX_OUTING_NAME_LENGTH = 255
_MISSING = object()


class InvalidOutingNameError(DomainError):
    """Raised when an outing name is blank or exceeds the existing bound."""

    def __init__(self):
        super().__init__("invalid_outing_name", "Outing name must not be blank.")


class OutingNotFoundError(DomainError):
    """Raised when an outing is absent from the requested group."""

    def __init__(self):
        super().__init__("not_found", "Outing was not found in this group.")


class ArchivedOutingReadOnlyError(DomainError):
    """Raised when an archived outing is targeted by a non-unarchive write."""

    def __init__(self):
        super().__init__(
            "archived_outing_read_only",
            "Archived outings are read-only; unarchive it before editing.",
        )


class OutingNotEmptyError(DomainError):
    """Raised when deletion would remove outing expense history."""

    def __init__(self):
        super().__init__(
            "outing_not_empty",
            "An outing with expenses cannot be deleted.",
        )


def normalize_outing_name(value: object) -> str:
    """Trim and validate an outing name without adding uniqueness semantics."""

    if not isinstance(value, str):
        raise InvalidOutingNameError()
    name = value.strip()
    if not name or len(name) > MAX_OUTING_NAME_LENGTH:
        raise InvalidOutingNameError()
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
    return default


def _archived(record: object) -> bool:
    return _value(record, "archived_at", default=None) is not None or bool(
        _value(record, "archived", default=False)
    )


def _same_identifier(left: object, right: object) -> bool:
    return left == right or str(left) == str(right)


class OutingService:
    """Coordinate outing writes through one transaction and one post-commit signal."""

    def __init__(
        self,
        outing_repository: Any,
        unit_of_work: Any = None,
        authorization_service: Any = None,
        *,
        clock: Any = None,
        invalidation_publisher: InvalidationPublisher | None = None,
    ):
        self._outings = outing_repository
        self._unit_of_work = unit_of_work
        self._authorization = authorization_service
        self._clock = clock
        self._publisher = invalidation_publisher

    def list(self, group_id: object, actor: object | None = None):
        """Return active and archived outings for the already-authorized group."""

        self._require_member(group_id, actor)
        finder = getattr(self._outings, "list_by_group", None)
        if finder is None:
            raise TypeError("outing repository cannot list outings")
        return list(finder(group_id))

    list_by_group = list

    def get(self, group_id: object, outing_id: object, actor: object | None = None):
        """Return one readable outing only inside the requested group."""

        self._require_member(group_id, actor)
        row = self._find(self._outings, group_id, outing_id)
        if row is None:
            raise OutingNotFoundError()
        return row

    read = get

    def create(
        self, group_id: object, name: object, actor: object | None = None
    ) -> OutingRecord:
        clean_name = normalize_outing_name(name)
        self._require_member(group_id, actor)
        now = self._now()

        outing = OutingRecord(
            id=uuid4(),
            group_id=cast(GroupId, group_id),
            name=clean_name,
            created_at=now,
            updated_at=now,
        )
        with self._transaction() as transaction:
            repository = self._repository(transaction)
            creator = getattr(repository, "create", None) or getattr(
                repository, "add", None
            )
            if creator is None:
                raise TypeError("outing repository cannot create outings")
            result = creator(group_id, outing)
            self._flush(transaction, repository)
        self._publish(group_id)
        return result or outing

    def edit(
        self,
        group_id: object,
        outing_id: object,
        name: object,
        actor: object | None = None,
    ):
        clean_name = normalize_outing_name(name)
        self._require_member(group_id, actor)
        with self._transaction() as transaction:
            repository = self._repository(transaction)
            current = self._require(repository, group_id, outing_id)
            if _archived(current):
                raise ArchivedOutingReadOnlyError()
            updater = getattr(repository, "update_active", None)
            if updater is None:
                raise TypeError("outing repository cannot edit outings")
            result = updater(group_id, outing_id, clean_name, self._now())
            if result is None:
                raise OutingNotFoundError()
            self._flush(transaction, repository)
        self._publish(group_id)
        return result

    update = edit

    def archive(self, group_id: object, outing_id: object, actor: object | None = None):
        self._require_owner(group_id, actor)
        with self._transaction() as transaction:
            repository = self._repository(transaction)
            current = self._require(repository, group_id, outing_id)
            if _archived(current):
                raise ArchivedOutingReadOnlyError()
            changer = getattr(repository, "archive", None)
            if changer is None:
                raise TypeError("outing repository cannot archive outings")
            result = changer(group_id, outing_id, self._now())
            if result is None:
                raise OutingNotFoundError()
            self._flush(transaction, repository)
        self._publish(group_id)
        return result

    def unarchive(
        self, group_id: object, outing_id: object, actor: object | None = None
    ):
        self._require_owner(group_id, actor)
        with self._transaction() as transaction:
            repository = self._repository(transaction)
            current = self._require(repository, group_id, outing_id)
            if not _archived(current):
                return current
            changer = getattr(repository, "unarchive", None)
            if changer is None:
                raise TypeError("outing repository cannot unarchive outings")
            result = changer(group_id, outing_id, self._now())
            if result is None:
                raise OutingNotFoundError()
            self._flush(transaction, repository)
        self._publish(group_id)
        return result

    def delete(
        self, group_id: object, outing_id: object, actor: object | None = None
    ) -> None:
        self._require_owner(group_id, actor)
        with self._transaction() as transaction:
            repository = self._repository(transaction)
            current = self._require(repository, group_id, outing_id)
            if _archived(current):
                raise ArchivedOutingReadOnlyError()
            checker = getattr(repository, "has_expenses", None)
            if checker is not None and checker(group_id, outing_id):
                raise OutingNotEmptyError()
            deleter = getattr(repository, "delete_if_empty", None)
            if deleter is None or not deleter(group_id, outing_id):
                if checker is not None and checker(group_id, outing_id):
                    raise OutingNotEmptyError()
                raise OutingNotFoundError()
            self._flush(transaction, repository)
        self._publish(group_id)

    def _authorization_context(self, group_id: object, actor: object | None):
        if self._authorization is not None:
            authorize = getattr(self._authorization, "authorize", None)
            if not callable(authorize):
                raise ForbiddenError()
            context = authorize(actor, group_id, "read_group")
            if context is None:
                raise ForbiddenError()
            return context

        # Compatibility fallback for isolated unit fakes only. Production
        # callers must inject AuthorizationService; actor.role is never
        # consulted when that server-authoritative collaborator is present.
        if actor is None:
            raise ForbiddenError()
        if _value(actor, "account_id", "accountId", default=None) is None:
            raise ForbiddenError()
        actor_group = _value(actor, "group_id", "groupId", default=_MISSING)
        if actor_group is _MISSING or actor_group is None:
            raise ForbiddenError()
        if not _same_identifier(actor_group, group_id):
            raise ForbiddenError()
        return actor

    def _require_member(self, group_id: object, actor: object | None) -> None:
        self._authorization_context(group_id, actor)

    def _require_owner(self, group_id: object, actor: object | None) -> None:
        context = self._authorization_context(group_id, actor)
        if _value(context, "role", default=None) != "owner":
            raise ForbiddenError()

    @staticmethod
    def _find(repository: Any, group_id: object, outing_id: object):
        finder = getattr(repository, "find_by_id", None)
        if finder is None:
            raise TypeError("outing repository cannot find outings")
        return finder(group_id, outing_id)

    @classmethod
    def _require(cls, repository: Any, group_id: object, outing_id: object):
        row = cls._find(repository, group_id, outing_id)
        if row is None:
            raise OutingNotFoundError()
        return row

    def _repository(self, transaction: Any):
        return getattr(transaction, "outings", None) or self._outings

    def _publish(self, group_id: object) -> None:
        if self._publisher is not None:
            self._publisher.publish(cast(GroupId, group_id))

    def _now(self) -> datetime:
        if self._clock is not None:
            value = self._clock.now()
            if isinstance(value, datetime):
                return value
        return datetime.now(UTC)

    @staticmethod
    def _flush(transaction: Any, repository: Any) -> None:
        flush = getattr(transaction, "flush", None)
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
            yield SimpleNamespace(outings=self._outings)
            return
        if callable(candidate) and not hasattr(candidate, "__enter__"):
            candidate = candidate()
        with cast(Any, candidate) as transaction:
            yield transaction


__all__ = [
    "ArchivedOutingReadOnlyError",
    "InvalidOutingNameError",
    "MAX_OUTING_NAME_LENGTH",
    "OutingNotEmptyError",
    "OutingNotFoundError",
    "OutingService",
    "normalize_outing_name",
]
