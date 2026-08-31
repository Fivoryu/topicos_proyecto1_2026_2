"""Unit tests for derived participant balances."""

import pytest
from backend.app.domain.balance_service import (
    PersistenceCorruptedError,
    compute_balances,
)

PARTICIPANTS = (
    {"id": "ana", "archived": False},
    {"id": "beto", "archived": False},
    {"id": "carla", "archived": False},
    {"id": "diego", "archived": False},
)


SAMAIPATA_EXPENSES = (
    {
        "amount_cents": 96_000,
        "contributors": {"ana": 96_000},
        "beneficiaries": ("ana", "beto", "carla", "diego"),
    },
    {
        "amount_cents": 40_000,
        "contributors": {"beto": 40_000},
        "beneficiaries": ("ana", "beto", "carla", "diego"),
    },
    {
        "amount_cents": 24_000,
        "contributors": {"carla": 24_000},
        "beneficiaries": ("ana", "beto", "carla", "diego"),
    },
)


def test_da01_computes_samaipata_balances_in_participant_order():
    balances = compute_balances(PARTICIPANTS, SAMAIPATA_EXPENSES)

    assert balances == {
        "ana": {"paid_cents": 96_000, "owed_cents": 40_000, "balance_cents": 56_000},
        "beto": {"paid_cents": 40_000, "owed_cents": 40_000, "balance_cents": 0},
        "carla": {"paid_cents": 24_000, "owed_cents": 40_000, "balance_cents": -16_000},
        "diego": {"paid_cents": 0, "owed_cents": 40_000, "balance_cents": -40_000},
    }
    assert list(balances) == ["ana", "beto", "carla", "diego"]


def test_balance_sum_is_exactly_zero_cents():
    balances = compute_balances(PARTICIPANTS, SAMAIPATA_EXPENSES)

    assert sum((row["balance_cents"] for row in balances.values()), 0) == 0


def test_referenced_archived_zero_balance_remains_listed():
    participants = PARTICIPANTS + ({"id": "legacy", "archived": True},)
    expenses = SAMAIPATA_EXPENSES + (
        {
            "amount_cents": 1_000,
            "contributors": {"legacy": 1_000},
            "beneficiaries": ("legacy",),
        },
    )

    balances = compute_balances(participants, expenses)

    assert list(balances) == ["ana", "beto", "carla", "diego", "legacy"]
    assert balances["legacy"] == {
        "paid_cents": 1_000,
        "owed_cents": 1_000,
        "balance_cents": 0,
    }


def test_corrupt_contribution_data_fails_closed_instead_of_fabricating_balances():
    corrupt_expense = {
        "amount_cents": 10_000,
        "contributors": {"ana": 9_000},
        "beneficiaries": ("ana",),
    }

    with pytest.raises(PersistenceCorruptedError) as error:
        compute_balances(({"id": "ana", "archived": False},), (corrupt_expense,))

    assert error.value.code == "persistence_corrupted"


def test_corrupt_split_data_fails_closed_too():
    corrupt_expense = {
        "amount_cents": 10_000,
        "contributors": {"ana": 10_000},
        "beneficiaries": (),
    }

    with pytest.raises(PersistenceCorruptedError, match="beneficiar"):
        compute_balances(({"id": "ana", "archived": False},), (corrupt_expense,))


def test_single_participant_without_expenses_is_neutral():
    balances = compute_balances(({"id": "ana", "archived": False},), ())

    assert balances == {"ana": {"paid_cents": 0, "owed_cents": 0, "balance_cents": 0}}


def test_empty_group_without_expenses_has_no_balance_rows():
    assert compute_balances((), ()) == {}


def test_empty_expense_history_keeps_every_participant_in_order():
    balances = compute_balances(PARTICIPANTS, ())

    assert list(balances) == ["ana", "beto", "carla", "diego"]
    assert all(
        row == {"paid_cents": 0, "owed_cents": 0, "balance_cents": 0}
        for row in balances.values()
    )


def test_record_shaped_expense_and_explicit_matching_shares_are_supported():
    expense = {
        "amount_cents": 1_000,
        "contributions": ({"participant_id": "ana", "amount_cents": 1_000},),
        "beneficiary_ids": ("ana",),
        "shares": {"ana": 1_000, "beto": 0},
    }

    balances = compute_balances(
        (
            {"id": "ana", "archived": False},
            {"id": "beto", "archived": False},
        ),
        (expense,),
    )

    assert balances["ana"].balance == 0
    assert balances["beto"].balance == 0


def test_invalid_source_reference_fails_closed():
    corrupt_expense = {
        "amount_cents": 1_000,
        "contributors": {"outsider": 1_000},
        "beneficiaries": ("ana",),
    }

    with pytest.raises(PersistenceCorruptedError, match="invalid participant"):
        compute_balances(({"id": "ana", "archived": False},), (corrupt_expense,))
