"""Unit tests for deterministic greedy settlement transfers."""

import pytest
from backend.app.domain.balance_service import PersistenceCorruptedError
from backend.app.domain.settlement_service import build_settlement

SAMAIPATA_BALANCES = {
    "ana": {"balance_cents": 56_000},
    "beto": {"balance_cents": 0},
    "carla": {"balance_cents": -16_000},
    "diego": {"balance_cents": -40_000},
}


def test_da01_orders_transfers_by_most_negative_debtor_first():
    settlement = build_settlement(SAMAIPATA_BALANCES)

    assert settlement == {
        "settled": False,
        "transfers": [
            {
                "from_participant_id": "diego",
                "to_participant_id": "ana",
                "amount_cents": 40_000,
            },
            {
                "from_participant_id": "carla",
                "to_participant_id": "ana",
                "amount_cents": 16_000,
            },
        ],
    }
    assert all(
        transfer["from_participant_id"] != "beto"
        and transfer["to_participant_id"] != "beto"
        for transfer in settlement["transfers"]
    )


def test_cb13_all_zero_balances_are_settled_without_transfers():
    settlement = build_settlement(
        {
            "ana": {"balance_cents": 0},
            "beto": {"balance_cents": 0},
        }
    )

    assert settlement == {"settled": True, "transfers": []}


def test_cb14_single_participant_is_settled():
    assert build_settlement({"ana": 0}) == {"settled": True, "transfers": []}


def test_cb15_payer_excluded_from_split_is_repaid_in_stable_order():
    settlement = build_settlement(
        {
            "ana": 30_000,
            "beto": -10_000,
            "carla": -10_000,
            "diego": -10_000,
        }
    )

    assert settlement == {
        "settled": False,
        "transfers": [
            {
                "from_participant_id": "beto",
                "to_participant_id": "ana",
                "amount_cents": 10_000,
            },
            {
                "from_participant_id": "carla",
                "to_participant_id": "ana",
                "amount_cents": 10_000,
            },
            {
                "from_participant_id": "diego",
                "to_participant_id": "ana",
                "amount_cents": 10_000,
            },
        ],
    }


def test_ties_use_stable_order_after_amount_sorting():
    settlement = build_settlement(
        {
            "debtor_a": {"balance_cents": -100},
            "debtor_b": {"balance_cents": -50},
            "creditor_a": {"balance_cents": 75},
            "creditor_b": {"balance_cents": 75},
        }
    )

    assert settlement["transfers"] == [
        {
            "from_participant_id": "debtor_a",
            "to_participant_id": "creditor_a",
            "amount_cents": 75,
        },
        {
            "from_participant_id": "debtor_a",
            "to_participant_id": "creditor_b",
            "amount_cents": 25,
        },
        {
            "from_participant_id": "debtor_b",
            "to_participant_id": "creditor_b",
            "amount_cents": 50,
        },
    ]


def test_debtors_and_creditors_are_each_sorted_by_amount_first():
    settlement = build_settlement(
        {
            "small_debtor": {"balance_cents": -40},
            "large_debtor": {"balance_cents": -60},
            "small_creditor": {"balance_cents": 20},
            "large_creditor": {"balance_cents": 80},
        }
    )

    assert settlement["transfers"] == [
        {
            "from_participant_id": "large_debtor",
            "to_participant_id": "large_creditor",
            "amount_cents": 60,
        },
        {
            "from_participant_id": "small_debtor",
            "to_participant_id": "large_creditor",
            "amount_cents": 20,
        },
        {
            "from_participant_id": "small_debtor",
            "to_participant_id": "small_creditor",
            "amount_cents": 20,
        },
    ]


def test_malformed_balance_rows_fail_closed():
    with pytest.raises(PersistenceCorruptedError) as error:
        build_settlement({"ana": {"balance_cents": "56000"}, "beto": -56_000})

    assert error.value.code == "persistence_corrupted"


def test_unbalanced_input_fails_instead_of_leaving_residuals():
    with pytest.raises(PersistenceCorruptedError, match="invariant"):
        build_settlement({"ana": 1, "beto": -2})
