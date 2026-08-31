"""Application reads for balances and settlement derived from source rows."""

from __future__ import annotations

from collections.abc import Hashable, Mapping
from typing import Any, cast

from backend.app.domain.balance_service import compute_balances
from backend.app.domain.settlement_service import build_settlement

_MISSING = object()


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


def _id(record: object, *names: str):
    value = _value(record, *names)
    if value is _MISSING:
        raise ValueError("source record is missing an id")
    return value


def _child_id(record: object):
    if isinstance(record, (tuple, list)) and record:
        return record[0]
    value = _value(record, "participant_id", "id")
    return record if value is _MISSING else value


def _child_amount(record: object) -> int:
    if isinstance(record, (tuple, list)) and len(record) > 1:
        record = record[1]
    if isinstance(record, int) and not isinstance(record, bool):
        return record
    value = _value(record, "amount_cents", "amount", "contribution_cents")
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError("contribution source must contain integer cents")
    return value


class DerivedService:
    """Compute all monetary read models from current group source records."""

    def __init__(self, participant_repository, expense_repository):
        self._participants = participant_repository
        self._expenses = expense_repository

    def get_balances(self, group_id: str):
        """Return stable participant balance rows computed from source expenses."""

        participants = self._list(self._participants, group_id)
        expenses = self._source_expenses(group_id)
        return compute_balances(participants, expenses)

    def balances(self, group_id: str):
        """Compatibility spelling for the balance read use case."""

        return self.get_balances(group_id)

    def get_settlement(self, group_id: str):
        """Return deterministic transfers computed from current balances."""

        return build_settlement(self.get_balances(group_id))

    def settlement(self, group_id: str):
        """Compatibility spelling for the settlement read use case."""

        return self.get_settlement(group_id)

    def read(self, group_id: str) -> dict[str, Any]:
        """Return balances and settlement as one group-scoped read model."""

        balances = self.get_balances(group_id)
        return {
            "group_id": group_id,
            "balances": balances,
            "settlement": build_settlement(balances),
        }

    @staticmethod
    def _list(repository, group_id: str):
        lister = getattr(repository, "list_by_group", None) or getattr(
            repository, "list", None
        )
        if lister is None:
            raise TypeError("repository cannot list group records")
        return list(lister(group_id))

    def _source_expenses(self, group_id: str) -> list[dict[str, object]]:
        expenses = self._list(self._expenses, group_id)
        result = []
        for expense in expenses:
            expense_id = _id(expense, "id", "expense_id")
            contributors = _value(expense, "contributors", "contributions")
            beneficiaries = _value(expense, "beneficiaries", "beneficiary_ids")
            if contributors is _MISSING:
                contributors = self._list_children(
                    "list_contributions", group_id, expense_id
                )
            if beneficiaries is _MISSING:
                beneficiaries = self._list_children(
                    "list_beneficiaries", group_id, expense_id
                )
            result.append(
                {
                    "id": expense_id,
                    "amount_cents": _value(expense, "amount_cents", "amount"),
                    "contributors": self._contributors(contributors),
                    "beneficiaries": self._beneficiaries(beneficiaries),
                }
            )
        return result

    def _list_children(self, method_name: str, group_id: str, expense_id):
        method = getattr(self._expenses, method_name, None)
        if method is None:
            return ()
        return method(group_id, expense_id)

    @staticmethod
    def _contributors(value) -> dict[object, int]:
        if isinstance(value, Mapping):
            if "participant_id" in value or "id" in value:
                return {cast(Hashable, _child_id(value)): _child_amount(value)}
            return {
                cast(Hashable, participant_id): _child_amount(amount)
                for participant_id, amount in value.items()
            }
        return {_child_id(row): _child_amount(row) for row in value}

    @staticmethod
    def _beneficiaries(value) -> tuple[object, ...]:
        if isinstance(value, Mapping):
            if "participant_id" in value or "id" in value:
                return (_child_id(value),)
            return tuple(value)
        return tuple(_child_id(row) for row in value)


__all__ = ["DerivedService"]
