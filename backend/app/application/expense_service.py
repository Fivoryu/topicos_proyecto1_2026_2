"""Atomic application use cases for source expenses."""

from __future__ import annotations

from collections.abc import Iterator, Mapping
from contextlib import contextmanager
from datetime import UTC, datetime
from types import SimpleNamespace
from typing import Any, cast
from uuid import uuid4

from backend.app.application.ports import ExpenseRecord
from backend.app.domain.errors import (
    DomainError,
    InvalidParticipantReferenceError,
)
from backend.app.domain.expense_rules import _normalise_expense
from backend.app.domain.split_service import equal_split

from .derived_service import DerivedService


class ExpenseNotFoundError(DomainError):
    """Raised when an expense is outside the requested group."""

    def __init__(self):
        super().__init__("not_found", "Expense was not found in this group.")


class InvalidExpenseDescriptionError(DomainError):
    """Raised when a source expense has no usable description."""

    def __init__(self):
        super().__init__(
            "invalid_description", "Expense description must not be blank."
        )


def _value(record: object, *names: str, default: object = None) -> object:
    if isinstance(record, Mapping):
        for name in names:
            if name in record:
                return record[name]
    else:
        for name in names:
            value = getattr(record, name, default)
            if value is not default:
                return value
    return default


def _participant_id(record: object) -> str:
    value = _value(record, "id", "participant_id")
    if value is None:
        raise InvalidParticipantReferenceError()
    return str(value)


def _is_archived(record: object) -> bool:
    archived_at = _value(record, "archived_at", default=None)
    if archived_at is not None:
        return True
    return bool(_value(record, "archived", default=False))


def _description(value: object) -> str:
    if not isinstance(value, str) or not value.strip():
        raise InvalidExpenseDescriptionError()
    return value.strip()


class ExpenseService:
    """Validate and persist complete expense replacements atomically."""

    def __init__(
        self,
        expense_repository,
        participant_repository=None,
        unit_of_work=None,
        derived_service=None,
        *,
        clock=None,
    ):
        self._expenses: Any = expense_repository
        self._participants: Any = participant_repository
        self._unit_of_work: Any = unit_of_work
        self._derived: Any = derived_service
        self._clock: Any = clock

    def create(
        self,
        group_id: str,
        description: object,
        amount_cents: object,
        contributors,
        beneficiaries,
        actor: object | None = None,
    ) -> ExpenseRecord:
        """Create a fully validated source expense in one transaction."""

        del actor
        with self._transaction() as transaction:
            expenses, participants = self._repositories(transaction)
            participant_rows = self._list_participants(participants, group_id)
            normalized = self._validate(
                description,
                amount_cents,
                contributors,
                beneficiaries,
                participant_rows,
                allow_archived=False,
            )
            expense = self._new_record(
                group_id,
                normalized[0],
                normalized[1],
                normalized[2],
                normalized[3],
            )
            result = self._create_source(expenses, group_id, expense, normalized)
            self._flush(transaction, expenses)
            self._verify_zero_sum(group_id, participants, expenses)
        return result or expense

    def edit(
        self,
        group_id: str,
        expense_id: str,
        description: object,
        amount_cents: object,
        contributors,
        beneficiaries,
        actor: object | None = None,
    ) -> ExpenseRecord:
        """Replace an expense only after its complete replacement is valid."""

        del actor
        with self._transaction() as transaction:
            expenses, participants = self._repositories(transaction)
            current = self._find_expense(expenses, group_id, expense_id)
            if current is None:
                raise ExpenseNotFoundError()
            participant_rows = self._list_participants(participants, group_id)
            normalized = self._validate(
                description,
                amount_cents,
                contributors,
                beneficiaries,
                participant_rows,
                allow_archived=True,
            )
            replacement = self._new_record(
                group_id,
                normalized[0],
                normalized[1],
                normalized[2],
                normalized[3],
                expense_id=expense_id,
                created_at=_value(current, "created_at", default=None),
            )
            result = self._update_source(
                expenses, group_id, expense_id, current, replacement, normalized
            )
            self._flush(transaction, expenses)
            self._verify_zero_sum(group_id, participants, expenses)
        return result or replacement

    def delete(
        self,
        group_id: str,
        expense_id: str,
        actor: object | None = None,
    ) -> None:
        """Delete a source expense and verify the remaining derived invariant."""

        del actor
        with self._transaction() as transaction:
            expenses, participants = self._repositories(transaction)
            if self._find_expense(expenses, group_id, expense_id) is None:
                raise ExpenseNotFoundError()
            deleter = getattr(expenses, "delete", None)
            if deleter is None:
                raise TypeError("expense repository cannot delete expenses")
            deleted = deleter(group_id, expense_id)
            if deleted is False:
                raise ExpenseNotFoundError()
            self._flush(transaction, expenses)
            self._verify_zero_sum(group_id, participants, expenses)

    def _validate(
        self,
        description: object,
        amount_cents: object,
        contributors,
        beneficiaries,
        participant_rows,
        *,
        allow_archived: bool,
    ) -> tuple[str, int, dict[str, int], tuple[str, ...]]:
        clean_description = _description(description)
        stable_ids = tuple(_participant_id(row) for row in participant_rows)
        normalized: Any = _normalise_expense(
            amount_cents=amount_cents,
            contributors=contributors,
            beneficiaries=beneficiaries,
            participants=stable_ids,
        )
        by_id: dict[str, Any] = {_participant_id(row): row for row in participant_rows}
        if not allow_archived:
            selected_ids = tuple(normalized.contributors) + tuple(
                normalized.beneficiaries
            )
            if any(
                _is_archived(by_id[participant_id]) for participant_id in selected_ids
            ):
                raise InvalidParticipantReferenceError(
                    "Archived participants cannot be selected for a new expense."
                )
        # Evaluate the complete candidate before any repository mutation. This both
        # enforces CC-01 and catches malformed stable-order data at the boundary.
        equal_split(
            amount_cents=normalized.amount_cents,
            beneficiaries=normalized.beneficiaries,
            contributors=normalized.contributors,
            stable_order=stable_ids,
        )
        contributors = cast(dict[str, int], dict(normalized.contributors))
        beneficiaries = cast(tuple[str, ...], tuple(normalized.beneficiaries))
        return (clean_description, normalized.amount_cents, contributors, beneficiaries)

    def _new_record(
        self,
        group_id: str,
        description: str,
        amount_cents: int,
        contributors: dict[str, int],
        beneficiaries: tuple[str, ...],
        *,
        expense_id: str | None = None,
        created_at: object = None,
    ) -> ExpenseRecord:
        now = self._now()
        created = created_at if isinstance(created_at, datetime) else now
        return ExpenseRecord(
            id=expense_id or str(uuid4()),
            group_id=group_id,
            description=description,
            amount_cents=amount_cents,
            contributors=dict(contributors),
            beneficiaries=tuple(beneficiaries),
            created_at=created,
            updated_at=now,
        )

    def _now(self) -> datetime:
        if self._clock is not None:
            value = self._clock.now()
            if isinstance(value, datetime):
                return value
        return datetime.now(UTC)

    @staticmethod
    def _create_source(expenses, group_id, expense, normalized):
        method = getattr(expenses, "create", None) or getattr(expenses, "add", None)
        if method is None:
            raise TypeError("expense repository cannot create expenses")
        contributions = tuple(normalized[2].items())
        beneficiaries = tuple(normalized[3])
        try:
            return method(group_id, expense, contributions, beneficiaries)
        except TypeError:
            return method(group_id, expense)

    @staticmethod
    def _update_source(
        expenses, group_id, expense_id, current, replacement, normalized
    ):
        method = getattr(expenses, "update", None) or getattr(
            expenses, "update_expense", None
        )
        contributions = tuple(normalized[2].items())
        beneficiaries = tuple(normalized[3])
        if method is not None:
            try:
                return method(
                    group_id,
                    expense_id,
                    replacement,
                    contributions,
                    beneficiaries,
                )
            except TypeError:
                try:
                    return method(group_id, expense_id, replacement)
                except TypeError:
                    return method(group_id, replacement, contributions, beneficiaries)

        # The fallback is useful for simple repositories and keeps the atomic
        # guarantee: validation has completed before these mutable fields change.
        for name, value in (
            ("description", replacement.description),
            ("amount_cents", replacement.amount_cents),
            ("updated_at", replacement.updated_at),
            ("contributors", dict(replacement.contributors)),
            ("beneficiaries", tuple(replacement.beneficiaries)),
        ):
            if hasattr(current, name):
                setattr(current, name, value)
        return current

    @staticmethod
    def _find_expense(expenses, group_id, expense_id):
        finder = getattr(expenses, "find_by_id", None) or getattr(expenses, "get", None)
        if finder is not None:
            try:
                return finder(group_id, expense_id)
            except TypeError:
                try:
                    return finder(expense_id, group_id)
                except TypeError:
                    return finder(expense_id)
        lister = getattr(expenses, "list_by_group", None) or getattr(
            expenses, "list", None
        )
        if lister is None:
            raise TypeError("expense repository cannot find expenses")
        return next(
            (
                expense
                for expense in lister(group_id)
                if _value(expense, "id", "expense_id") == expense_id
            ),
            None,
        )

    @staticmethod
    def _list_participants(participants, group_id):
        if participants is None:
            raise TypeError("participant repository is required")
        lister = getattr(participants, "list_by_group", None) or getattr(
            participants, "list", None
        )
        if lister is None:
            raise TypeError("participant repository cannot list participants")
        rows = list(lister(group_id))
        return sorted(
            rows,
            key=lambda row: (
                _value(row, "created_at", default=datetime.min),
                str(_participant_id(row)),
            ),
        )

    def _repositories(self, transaction: Any) -> tuple[Any, Any]:
        expenses = getattr(transaction, "expenses", None) or self._expenses
        participants = getattr(transaction, "participants", None) or self._participants
        return expenses, participants

    @staticmethod
    def _flush(transaction, expenses) -> None:
        flush = getattr(transaction, "flush", None)
        if callable(flush):
            flush()
            return
        session = getattr(expenses, "session", None)
        flush = getattr(session, "flush", None)
        if callable(flush):
            flush()

    def _verify_zero_sum(self, group_id, participants, expenses) -> None:
        derived = self._derived or DerivedService(participants, expenses)
        derived.get_balances(group_id)

    @contextmanager
    def _transaction(self) -> Iterator[object]:
        candidate: Any = self._unit_of_work
        if candidate is None:
            yield SimpleNamespace(
                expenses=self._expenses, participants=self._participants
            )
            return
        if callable(candidate) and not hasattr(candidate, "__enter__"):
            candidate = candidate()
        if hasattr(candidate, "__enter__"):
            with cast(Any, candidate) as transaction:
                yield transaction
            return
        yield candidate


__all__ = [
    "ExpenseNotFoundError",
    "ExpenseService",
    "InvalidExpenseDescriptionError",
]
