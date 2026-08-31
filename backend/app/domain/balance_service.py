"""Derived exact-cent balance computation from source expenses."""

from collections.abc import Mapping

from .errors import DomainError
from .expense_rules import (
    _field,
    _identifier,
    _normalise_expense,
    _participant_ids,
)
from .split_service import equal_split


class PersistenceCorruptedError(DomainError):
    """Raised when source expense data cannot produce trustworthy balances."""

    def __init__(self, message: str):
        super().__init__("persistence_corrupted", message)


class BalanceRow(dict):
    """A balance row with mapping access and convenient domain properties."""

    def __init__(self, paid_cents: int, owed_cents: int, balance_cents: int):
        super().__init__(
            {
                "paid_cents": paid_cents,
                "owed_cents": owed_cents,
                "balance_cents": balance_cents,
            }
        )

    @property
    def paid_cents(self) -> int:
        return self["paid_cents"]

    @property
    def owed_cents(self) -> int:
        return self["owed_cents"]

    @property
    def balance_cents(self) -> int:
        return self["balance_cents"]

    @property
    def paid(self) -> int:
        return self.paid_cents

    @property
    def owed(self) -> int:
        return self.owed_cents

    @property
    def balance(self) -> int:
        return self.balance_cents


def _source_field(expense, *names):
    try:
        return _field(expense, *names)
    except ValueError as error:
        raise PersistenceCorruptedError(
            f"Expense source is missing required field: {', '.join(names)}."
        ) from error


def _share_items(shares):
    if not isinstance(shares, Mapping):
        raise PersistenceCorruptedError("Expense shares must be a participant mapping.")

    normalized = {}
    for participant, share in shares.items():
        participant_id = _identifier(participant)
        if participant_id in normalized:
            raise PersistenceCorruptedError("Expense shares contain duplicate ids.")
        if not isinstance(share, int) or isinstance(share, bool) or share < 0:
            raise PersistenceCorruptedError(
                "Expense shares must be non-negative integer cents."
            )
        normalized[participant_id] = share
    return normalized


def _explicit_shares(expense):
    if isinstance(expense, Mapping):
        for name in ("shares", "split_shares"):
            if name in expense:
                return expense[name]
        return None
    for name in ("shares", "split_shares"):
        if hasattr(expense, name):
            attribute = getattr(expense, name, None)
            if attribute is not None:
                return attribute
    return None


def _beneficiaries_from_shares(shares):
    return tuple(participant for participant, share in shares.items() if share > 0)


def _normalise_source_expense(expense, participant_ids):
    try:
        amount_cents = _source_field(expense, "amount_cents", "amount")
        contributors = _source_field(expense, "contributors", "contributions")

        try:
            beneficiaries = _source_field(
                expense,
                "beneficiaries",
                "beneficiary_ids",
            )
        except PersistenceCorruptedError:
            explicit = _explicit_shares(expense)
            if not isinstance(explicit, Mapping):
                raise
            beneficiaries = _beneficiaries_from_shares(explicit)

        return _normalise_expense(
            amount_cents=amount_cents,
            contributors=contributors,
            beneficiaries=beneficiaries,
            participants=participant_ids,
        )
    except PersistenceCorruptedError:
        raise
    except Exception as error:
        raise PersistenceCorruptedError(
            f"Expense source violates domain rules: {error}"
        ) from error


def compute_balances(participants, expenses) -> dict:
    """Compute paid, owed, and balance rows in stable participant order.

    ``participants`` must be supplied in the group's stable creation order.
    Every participant is returned, including archived or zero-balance records.
    Expenses are source records: their split shares are derived with the same
    deterministic split rule used for new expenses. If an optional ``shares``
    field is present, it is checked against that derived result and cannot
    override it.
    """

    try:
        participant_ids = _participant_ids(participants, allow_empty=True)
    except Exception as error:
        if isinstance(error, PersistenceCorruptedError):
            raise
        raise PersistenceCorruptedError(
            f"Participant source is invalid: {error}"
        ) from error

    paid = dict.fromkeys(participant_ids, 0)
    owed = dict.fromkeys(participant_ids, 0)

    try:
        source_expenses = tuple(expenses)
    except TypeError as error:
        raise PersistenceCorruptedError("Expense source must be iterable.") from error

    for expense in source_expenses:
        normalized = _normalise_source_expense(expense, participant_ids)
        try:
            shares = equal_split(
                amount_cents=normalized.amount_cents,
                beneficiaries=normalized.beneficiaries,
                contributors=normalized.contributors,
                stable_order=participant_ids,
            )
        except PersistenceCorruptedError:
            raise
        except Exception as error:
            raise PersistenceCorruptedError(
                f"Expense split cannot be derived: {error}"
            ) from error

        explicit = _explicit_shares(expense)
        if explicit is not None:
            supplied_shares = _share_items(explicit)
            expected_shares = {
                participant_id: shares[participant_id]
                for participant_id in participant_ids
            }
            if supplied_shares != expected_shares:
                raise PersistenceCorruptedError(
                    "Expense split shares do not match the deterministic source split."
                )

        for participant_id, contribution in normalized.contributors.items():
            paid[participant_id] += contribution
        for participant_id, share in shares.items():
            owed[participant_id] += share

    balances = {}
    total_balance = 0
    for participant_id in participant_ids:
        balance_cents = paid[participant_id] - owed[participant_id]
        balances[participant_id] = BalanceRow(
            paid_cents=paid[participant_id],
            owed_cents=owed[participant_id],
            balance_cents=balance_cents,
        )
        total_balance += balance_cents

    if total_balance != 0:
        raise PersistenceCorruptedError(
            f"Balance invariant violated: expected 0 cents, got {total_balance}."
        )

    return balances
