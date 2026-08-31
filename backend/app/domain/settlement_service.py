"""Deterministic greedy settlement derived from participant balances."""

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from typing import cast

from .balance_service import PersistenceCorruptedError

_MISSING = object()


@dataclass
class _BalanceEntry:
    participant_id: object
    balance_cents: int
    order: int


@dataclass
class _Residual:
    participant_id: object
    cents: int
    order: int


def _corrupted(message: str, error: object = _MISSING) -> None:
    """Raise the domain error used when derived monetary input is untrustworthy."""

    if error is _MISSING:
        raise PersistenceCorruptedError(message)
    if isinstance(error, BaseException):
        raise PersistenceCorruptedError(message) from error
    raise PersistenceCorruptedError(message)


def _mapping_dict(value: object) -> dict[object, object]:
    """Copy a mapping through a dynamic boundary for safe value access."""

    return dict(value)  # type: ignore[arg-type]


def _extract_balance(value: object) -> int:
    if isinstance(value, bool):
        _corrupted("Balances must be integer cents.")
        raise AssertionError("unreachable")
    if isinstance(value, int):
        return value

    raw_value: object = value
    if isinstance(value, Mapping):
        mapping_value = _mapping_dict(value)
        for name in ("balance_cents", "balance"):
            candidate = mapping_value.get(name, _MISSING)
            if candidate is not _MISSING:
                raw_value = candidate
                break
        else:
            _corrupted("Balance row is missing a balance value.")
    else:
        for name in ("balance_cents", "balance"):
            attribute = getattr(value, name, _MISSING)
            if attribute is not _MISSING:
                raw_value = attribute
                break
        else:
            _corrupted("Balance row is missing a balance value.")

    if not isinstance(raw_value, int) or isinstance(raw_value, bool):
        _corrupted("Balances must be integer cents.")
        raise AssertionError("unreachable")
    return raw_value


def _pair_values(value: object) -> tuple[object, ...]:
    """Materialize a pair-like entry without relying on checker indexing stubs."""

    return tuple(cast(Iterable[object], value))


def _normalise_balances(balances: object) -> tuple[_BalanceEntry, ...]:
    mapping_input = False
    entries: tuple[object, ...] = ()
    if isinstance(balances, Mapping):
        mapping_input = True
        entries = tuple(_mapping_dict(balances).items())
    elif isinstance(balances, (str, bytes)):
        _corrupted("Balances must be a participant mapping or sequence.")
    else:
        try:
            entries = tuple(cast(Iterable[object], balances))
        except TypeError as error:
            _corrupted("Balances must be a participant mapping or sequence.", error)

    normalized: list[_BalanceEntry] = []
    seen: list[object] = []
    for order, entry in enumerate(entries):
        participant_id: object = _MISSING
        value: object = _MISSING

        if mapping_input:
            pair = _pair_values(entry)
            if len(pair) != 2:
                _corrupted("Balance mapping entries must contain an id and value.")
            participant_id, value = pair
        elif isinstance(entry, Mapping):
            entry_mapping = _mapping_dict(entry)
            for name in ("participant_id", "id"):
                candidate = entry_mapping.get(name, _MISSING)
                if candidate is not _MISSING:
                    participant_id = candidate
                    break
            if participant_id is _MISSING:
                _corrupted("Balance row is missing a participant id.")
            value = entry
        else:
            pair = _pair_values(entry)
            if len(pair) == 2:
                participant_id, value = pair
            else:
                for name in ("participant_id", "id"):
                    attribute = getattr(entry, name, _MISSING)
                    if attribute is not _MISSING:
                        participant_id = attribute
                        break
                if participant_id is _MISSING:
                    _corrupted("Balance row is missing a participant id.")
                value = entry

        if participant_id is _MISSING:
            _corrupted("Balance row is missing a participant id.")
        try:
            hash(participant_id)
        except TypeError as error:
            _corrupted("Participant ids in balances must be hashable.", error)
        if participant_id is None:
            _corrupted("Participant ids in balances cannot be null.")
        if participant_id in seen:
            _corrupted("Balances contain duplicate participant ids.")
        seen.append(participant_id)
        normalized.append(
            _BalanceEntry(
                participant_id=participant_id,
                balance_cents=_extract_balance(value),
                order=order,
            )
        )

    return tuple(normalized)


def build_settlement(balances: object) -> dict:
    """Build ordered greedy transfers from a stable participant balance mapping.

    The input iteration order is the stable participant creation order. Neutral
    participants are omitted from both sides, while debtors and creditors are
    sorted by amount and retain that stable order for ties.
    """

    normalized = _normalise_balances(balances)
    total_balance = sum((entry.balance_cents for entry in normalized), 0)
    if total_balance != 0:
        _corrupted(
            f"Settlement invariant violated: expected 0 cents, got {total_balance}."
        )

    debtors = [
        _Residual(entry.participant_id, -entry.balance_cents, entry.order)
        for entry in normalized
        if entry.balance_cents < 0
    ]
    creditors = [
        _Residual(entry.participant_id, entry.balance_cents, entry.order)
        for entry in normalized
        if entry.balance_cents > 0
    ]
    # Pop from the end so the largest residual is selected first; the negative
    # order key keeps the original stable order for equal residuals.
    debtors.sort(key=lambda item: (item.cents, -item.order))
    creditors.sort(key=lambda item: (item.cents, -item.order))
    all_debtors = tuple(debtors)
    all_creditors = tuple(creditors)

    transfers: list[dict[str, object]] = []
    if debtors and creditors:
        debtor = debtors.pop()
        creditor = creditors.pop()
        while True:
            if debtor.cents <= 0 or creditor.cents <= 0:
                _corrupted("Settlement contains a non-positive residual balance.")

            amount_cents = (
                debtor.cents if debtor.cents <= creditor.cents else creditor.cents
            )
            if amount_cents <= 0:
                _corrupted("Settlement transfers must be positive integer cents.")
            transfers.append(
                {
                    "from_participant_id": debtor.participant_id,
                    "to_participant_id": creditor.participant_id,
                    "amount_cents": amount_cents,
                }
            )
            debtor.cents -= amount_cents
            creditor.cents -= amount_cents

            if debtor.cents == 0:
                if not debtors:
                    break
                debtor = debtors.pop()
            if creditor.cents == 0:
                if not creditors:
                    break
                creditor = creditors.pop()

    if any(debtor.cents != 0 for debtor in all_debtors) or any(
        creditor.cents != 0 for creditor in all_creditors
    ):
        _corrupted("Settlement did not resolve all balance residuals.")

    return {"settled": not transfers, "transfers": transfers}
