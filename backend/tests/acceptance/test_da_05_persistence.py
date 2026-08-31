"""DA-05: restart persistence keeps renamed names, policy, balances, settlement."""

import pytest
from conftest import (
    DEMO_PARTICIPANT_IDS,
    GROUP_PATH,
    OWNER_LOGIN,
    OWNER_PASSWORD,
    api_snapshot,
    monetary_source_snapshot,
    security_headers,
)

RENAMED_NAME = "Ana Renovada"


@pytest.mark.asyncio
async def test_da_05_restart_preserves_renamed_source_and_derived_state(seeded_api):
    api = seeded_api
    before = None
    async with api.client() as client:
        login = await api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        assert login.status_code == 200
        rename = await client.patch(
            f"{GROUP_PATH}/participants/{DEMO_PARTICIPANT_IDS[0]}",
            headers=security_headers(),
            json={"name": RENAMED_NAME},
        )
        assert rename.status_code == 200, rename.text
        assert rename.json()["name"] == RENAMED_NAME
        before = await api_snapshot(client)

    money_before = monetary_source_snapshot(api)
    api.restart()

    async with api.client() as client:
        after_login = await api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        after = await api_snapshot(client)

    assert after_login.status_code == 200
    assert after["group"] == before["group"]
    assert after["balances"] == before["balances"]
    assert after["settlement"] == before["settlement"]
    participants = after["participants"]
    ana = next(row for row in participants if row["id"] == str(DEMO_PARTICIPANT_IDS[0]))
    assert ana["name"] == RENAMED_NAME
    money_after = monetary_source_snapshot(api)
    assert money_after["expenses"] == money_before["expenses"]
    assert money_after["contributions"] == money_before["contributions"]
    assert money_after["beneficiaries"] == money_before["beneficiaries"]
