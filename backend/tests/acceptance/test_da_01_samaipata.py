"""DA-01: the seeded Samaipata balances and deterministic settlement."""

import pytest
from conftest import (
    DEMO_GROUP_ID,
    DEMO_PARTICIPANT_IDS,
    OWNER_LOGIN,
    OWNER_PASSWORD,
)


@pytest.mark.asyncio
async def test_da_01_seeded_samaipata_balances_and_transfers(seeded_api):
    async with seeded_api.client() as client:
        login = await seeded_api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        expenses = await client.get(f"/api/v1/groups/{DEMO_GROUP_ID}/expenses")
        balances = await client.get(f"/api/v1/groups/{DEMO_GROUP_ID}/balances")
        settlement = await client.get(f"/api/v1/groups/{DEMO_GROUP_ID}/settlement")

    assert login.status_code == 200
    assert login.json()["role"] == "owner"
    assert expenses.status_code == 200
    assert balances.status_code == 200
    assert settlement.status_code == 200
    expense_rows = expenses.json()
    assert [
        (row["description"], row["amount_cents"]) for row in expense_rows
    ] == [
        ("Cabaña", 80_000),
        ("Entradas a El Fuerte", 16_000),
        ("Cena", 40_000),
        ("Gasolina", 24_000),
    ]
    expected_payers = [
        str(DEMO_PARTICIPANT_IDS[0]),
        str(DEMO_PARTICIPANT_IDS[0]),
        str(DEMO_PARTICIPANT_IDS[1]),
        str(DEMO_PARTICIPANT_IDS[2]),
    ]
    for row, payer_id in zip(expense_rows, expected_payers, strict=True):
        assert row["contributors"] == [
            {
                "participant_id": payer_id,
                "name": next(
                    item["name"]
                    for item in row["contributors"]
                    if item["participant_id"] == payer_id
                ),
                "archived": False,
                "amount_cents": row["amount_cents"],
            }
        ]
        assert {item["participant_id"] for item in row["beneficiaries"]} == {
            str(participant_id) for participant_id in DEMO_PARTICIPANT_IDS
        }
    assert [
        (
            row["participant_id"],
            row["paid_cents"],
            row["owed_cents"],
            row["balance_cents"],
        )
        for row in balances.json()["participants"]
    ] == [
        (str(DEMO_PARTICIPANT_IDS[0]), 96_000, 40_000, 56_000),
        (str(DEMO_PARTICIPANT_IDS[1]), 40_000, 40_000, 0),
        (str(DEMO_PARTICIPANT_IDS[2]), 24_000, 40_000, -16_000),
        (str(DEMO_PARTICIPANT_IDS[3]), 0, 40_000, -40_000),
    ]
    assert sum(row["balance_cents"] for row in balances.json()["participants"]) == 0
    assert [
        (
            row["from_participant_id"],
            row["to_participant_id"],
            row["amount_cents"],
        )
        for row in settlement.json()["transfers"]
    ] == [
        (str(DEMO_PARTICIPANT_IDS[3]), str(DEMO_PARTICIPANT_IDS[0]), 40_000),
        (str(DEMO_PARTICIPANT_IDS[2]), str(DEMO_PARTICIPANT_IDS[0]), 16_000),
    ]
