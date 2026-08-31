"""DA-04: equal contributions make the group settled with an empty transfer list."""

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
async def test_da_04_settled_true_and_no_transfers(seeded_api):
    async with seeded_api.client() as client:
        login = await seeded_api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        deleted = await delete_seed_expenses(client)
        created = await client.post(
            f"{GROUP_PATH}/expenses",
            headers=security_headers(),
            json={
                "description": "Equal dinner",
                "amount": "400.00",
                "contributors": [
                    {
                        "participant_id": str(DEMO_PARTICIPANT_IDS[index]),
                        "amount": "100.00",
                    }
                    for index in range(4)
                ],
                "beneficiary_ids": [
                    str(participant) for participant in DEMO_PARTICIPANT_IDS
                ],
            },
        )
        settlement = await client.get(f"{GROUP_PATH}/settlement")

    assert login.status_code == 200
    assert deleted == [204, 204, 204]
    assert created.status_code == 201, created.text
    assert settlement.status_code == 200
    body = settlement.json()
    assert body["settled"] is True
    assert body["transfers"] == []
