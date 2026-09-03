"""Participant lifecycle use cases and the atomic CC-04 rename."""

from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, datetime
from typing import Any, cast
from unicodedata import normalize
from uuid import uuid4

from backend.app.application.ports import InvalidationPublisher, ParticipantRecord
from backend.app.domain.errors import (
    DomainError,
    DuplicateParticipantNameError,
    InvalidParticipantNameError,
    ParticipantInUseError,
)


class ParticipantNotFoundError(DomainError):
    """Raised when a participant is not in the requested group."""

    def __init__(self):
        super().__init__("not_found", "Participant was not found in this group.")


def normalize_participant_name(value: object) -> tuple[str, str]:
    """Return the trimmed display name and its Unicode/case-folded key."""

    if not isinstance(value, str):
        raise InvalidParticipantNameError()
    display_name = normalize("NFKC", value.strip())
    if not display_name:
        raise InvalidParticipantNameError()
    return display_name, display_name.casefold()


class ParticipantService:
    """Coordinate group-scoped participant mutations through one transaction."""

    def __init__(
        self,
        participant_repository,
        unit_of_work=None,
        *,
        invalidation_publisher: InvalidationPublisher | None = None,
    ):
        self._participants: Any = participant_repository
        self._unit_of_work: Any = unit_of_work
        self._publisher = invalidation_publisher

    def list(self, group_id: str, actor: object | None = None):
        """List active and archived participants in stable creation order."""

        del actor
        finder: Any = getattr(self._participants, "list_by_group", None) or getattr(
            self._participants, "list", None
        )
        if finder is None:
            raise TypeError("participant repository cannot list participants")
        return list(finder(group_id))

    def add(
        self, group_id: str, name: object, actor: object | None = None
    ) -> ParticipantRecord:
        """Add a participant after checking the complete normalized-name key."""

        del actor
        display_name, normalized_name = normalize_participant_name(name)
        self._ensure_no_conflict(group_id, normalized_name)
        participant = ParticipantRecord(
            id=uuid4(),
            group_id=group_id,
            name=display_name,
            normalized_name=normalized_name,
            created_at=datetime.now(UTC),
        )
        with self._transaction():
            adder: Any = getattr(self._participants, "add", None) or getattr(
                self._participants, "create", None
            )
            if adder is None:
                raise TypeError("participant repository cannot add participants")
            try:
                result = adder(group_id, participant)
            except TypeError:
                result = adder(participant)
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return result or participant

    def archive(self, group_id: str, participant_id: str, actor: object | None = None):
        """Archive without changing identity or historical references."""

        del actor
        participant = self._require(group_id, participant_id)
        with self._transaction():
            result = self._set_archived(group_id, participant_id, datetime.now(UTC))
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return result or participant

    def reactivate(
        self, group_id: str, participant_id: str, actor: object | None = None
    ):
        """Restore a participant to the active selection set."""

        del actor
        participant = self._require(group_id, participant_id)
        with self._transaction():
            result = self._set_archived(group_id, participant_id, None)
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return result or participant

    def delete(
        self, group_id: str, participant_id: str, actor: object | None = None
    ) -> None:
        """Delete only a participant with no contribution or beneficiary rows."""

        del actor
        self._require(group_id, participant_id)
        if self._has_references(group_id, participant_id):
            raise ParticipantInUseError()
        with self._transaction():
            deleter: Any = getattr(self._participants, "delete", None)
            if deleter is None:
                raise ParticipantNotFoundError()
            deleted = deleter(group_id, participant_id)
            if deleted is False:
                raise ParticipantNotFoundError()
        if self._publisher is not None:
            self._publisher.publish(group_id)

    def rename(
        self,
        group_id: str,
        participant_id: str,
        name: object,
        actor: object | None = None,
    ):
        """Atomically update only ``name`` and ``normalized_name``."""

        del actor
        display_name, normalized_name = normalize_participant_name(name)
        self._require(group_id, participant_id)
        self._ensure_no_conflict(group_id, normalized_name, exclude_id=participant_id)
        with self._transaction():
            updater: Any = getattr(self._participants, "update_name", None) or getattr(
                self._participants, "rename", None
            )
            if updater is None:
                raise TypeError("participant repository cannot rename participants")
            try:
                result = updater(
                    group_id, participant_id, display_name, normalized_name
                )
            except TypeError:
                result = updater(
                    group_id=group_id,
                    participant_id=participant_id,
                    name=display_name,
                    normalized_name=normalized_name,
                )
            if result is None:
                raise ParticipantNotFoundError()
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return result

    def _require(self, group_id: str, participant_id: str):
        finder: Any = getattr(self._participants, "find_by_id", None) or getattr(
            self._participants, "get", None
        )
        if finder is None:
            raise TypeError("participant repository cannot find participants")
        try:
            participant = finder(group_id, participant_id)
        except TypeError:
            participant = finder(participant_id, group_id)
        if participant is None:
            raise ParticipantNotFoundError()
        return participant

    def _ensure_no_conflict(
        self, group_id: str, normalized_name: str, exclude_id: str | None = None
    ) -> None:
        finder: Any = getattr(self._participants, "find_by_normalized_name", None)
        conflict = None
        if finder is not None:
            try:
                conflict = finder(group_id, normalized_name, exclude_id=exclude_id)
            except TypeError:
                conflict = finder(group_id, normalized_name)
        else:
            conflict = next(
                (
                    participant
                    for participant in self.list(group_id)
                    if participant.normalized_name == normalized_name
                    and participant.id != exclude_id
                ),
                None,
            )
        if conflict is not None:
            raise DuplicateParticipantNameError()

    def _set_archived(
        self, group_id: str, participant_id: str, archived_at: datetime | None
    ):
        setter: Any = getattr(self._participants, "set_archived", None)
        if setter is not None:
            return setter(group_id, participant_id, archived_at)
        method_name = "archive" if archived_at is not None else "reactivate"
        method: Any = getattr(self._participants, method_name, None)
        if method is None:
            raise TypeError("participant repository cannot change archive state")
        return method(group_id, participant_id)

    def _has_references(self, group_id: str, participant_id: str) -> bool:
        checker: Any = getattr(self._participants, "has_references", None) or getattr(
            self._participants, "is_referenced", None
        )
        if checker is None:
            raise TypeError("participant repository cannot check references")
        return bool(checker(group_id, participant_id))

    @contextmanager
    def _transaction(self) -> Iterator[Any]:
        """Use an injected context manager or begin/commit/rollback protocol."""

        if self._unit_of_work is None:
            yield None
            return
        candidate: Any = self._unit_of_work
        if callable(candidate) and not hasattr(candidate, "__enter__"):
            candidate = candidate()
        if hasattr(candidate, "__enter__"):
            with cast(Any, candidate) as transaction:
                yield transaction
            return
        begin: Any = getattr(candidate, "begin", None)
        if begin is not None:
            begin()
        try:
            yield candidate
        except Exception:
            rollback: Any = getattr(candidate, "rollback", None)
            if rollback is not None:
                rollback()
            raise
        else:
            commit: Any = getattr(candidate, "commit", None)
            if commit is not None:
                commit()


__all__ = [
    "ParticipantNotFoundError",
    "ParticipantService",
    "normalize_participant_name",
]
