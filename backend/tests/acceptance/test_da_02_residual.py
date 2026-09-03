"""DA-02: the API preserves the deterministic residual and zero invariant."""

import pytest
from conftest import (
    DEMO_PARTICIPANT_IDS,
    GROUP_PATH,
    OWNER_LOGIN,
    OWNER_PASSWORD,
    delete_seed_expenses,
    security_headers,
)


@pytest.mark.asyncio
async def test_da_02_multi_contributor_residual_and_zero_sum(seeded_api):
    async with seeded_api.client() as client:
        login = await seeded_api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        deleted = await delete_seed_expenses(client)
        created = await client.post(
            f"{GROUP_PATH}/expenses",
            headers=security_headers(),
            json={
                "description": "Residual test",
                "amount": "100.00",
                "contributors": [
                    {
                        "participant_id": str(DEMO_PARTICIPANT_IDS[0]),
                        "amount": "100.00",
                    },
                ],
                "beneficiary_ids": [
                    str(DEMO_PARTICIPANT_IDS[0]),
                    str(DEMO_PARTICIPANT_IDS[1]),
                    str(DEMO_PARTICIPANT_IDS[2]),
                ],
            },
        )
        balances = await client.get(f"{GROUP_PATH}/balances")

    assert login.status_code == 200
    assert deleted == [204, 204, 204, 204]
    assert created.status_code == 201, created.text
    expense = created.json()
    assert expense["amount_cents"] == 10_000
    assert sum(row["amount_cents"] for row in expense["contributors"]) == 10_000
    assert [row["participant_id"] for row in expense["beneficiaries"]] == [
        str(DEMO_PARTICIPANT_IDS[0]),
        str(DEMO_PARTICIPANT_IDS[1]),
        str(DEMO_PARTICIPANT_IDS[2]),
    ]
    assert balances.status_code == 200
    rows = balances.json()["participants"]
    assert [(row["owed_cents"], row["balance_cents"]) for row in rows] == [
        (3_334, 6_666),
        (3_333, -3_333),
        (3_333, -3_333),
        (0, 0),
    ]
    assert sum(row["owed_cents"] for row in rows) == 10_000
    assert sum(row["balance_cents"] for row in rows) == 0
