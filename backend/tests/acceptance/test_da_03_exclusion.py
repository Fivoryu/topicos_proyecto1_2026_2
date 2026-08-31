"""DA-03: an expense among three of four keeps the excluded participant at zero."""

import pytest
from conftest import (
    DEMO_PARTICIPANT_IDS,
    GROUP_PATH,
    MEMBER_LOGIN,
    MEMBER_PASSWORD,
    OWNER_LOGIN,
    OWNER_PASSWORD,
    delete_seed_expenses,
    security_headers,
)


@pytest.mark.asyncio
async def test_da_03_excluded_participant_is_not_owed(seeded_api):
    async with seeded_api.client() as client:
        login = await seeded_api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        deleted = await delete_seed_expenses(client)
        created = await client.post(
            f"{GROUP_PATH}/expenses",
            headers=security_headers(),
            json={
                "description": "Dinner for three",
                "amount": "300.00",
                "contributors": [
                    {
                        "participant_id": str(DEMO_PARTICIPANT_IDS[0]),
                        "amount": "300.00",
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
    assert deleted == [204, 204, 204]
    assert created.status_code == 201, created.text
    assert balances.status_code == 200
    rows = balances.json()["participants"]
    by_name = {row["name"]: row for row in rows}
    assert by_name["Ana"]["paid_cents"] == 30_000
    assert by_name["Ana"]["owed_cents"] == 10_000
    assert by_name["Beto"]["owed_cents"] == 10_000
    assert by_name["Carla"]["owed_cents"] == 10_000
    assert by_name["Diego"]["owed_cents"] == 0
    assert by_name["Diego"]["balance_cents"] == 0
    assert sum(row["balance_cents"] for row in rows) == 0


@pytest.mark.asyncio
async def test_da_03_member_can_read_after_owner_login(seeded_api):
    async with seeded_api.client() as client:
        member_login = await seeded_api.login(client, MEMBER_LOGIN, MEMBER_PASSWORD)
        group = await client.get(GROUP_PATH)
        balances = await client.get(f"{GROUP_PATH}/balances")

    assert member_login.status_code == 200
    assert member_login.json()["role"] == "member"
    assert group.status_code == 200
    assert balances.status_code == 200
