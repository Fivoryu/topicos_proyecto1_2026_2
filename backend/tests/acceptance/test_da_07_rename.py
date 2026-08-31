"""DA-07: rename keeps identity; invalid renames change nothing."""

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


def _settlement_money(settlement: dict) -> tuple[bool, list[tuple]]:
    """Compare settlement by settled flag and transfer participant/amount only."""

    return (
        settlement["settled"],
        [
            (row["from_participant_id"], row["to_participant_id"], row["amount_cents"])
            for row in settlement["transfers"]
        ],
    )


def _money_rows(balances: dict) -> list[tuple]:
    """Compare balances by participant and cents, never by display name."""

    return [
        (
            row["participant_id"],
            row["paid_cents"],
            row["owed_cents"],
            row["balance_cents"],
        )
        for row in balances["participants"]
    ]


RENAMED_NAME = "Ana Renamed"


@pytest.mark.asyncio
async def test_da_07_rename_preserves_id_money_references_and_archive_state(seeded_api):
    api = seeded_api
    async with api.client() as client:
        await api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        before = await api_snapshot(client)

        rename = await client.patch(
            f"{GROUP_PATH}/participants/{DEMO_PARTICIPANT_IDS[0]}",
            headers=security_headers(),
            json={"name": RENAMED_NAME},
        )
        assert rename.status_code == 200, rename.text
        renamed = rename.json()
        assert renamed["id"] == str(DEMO_PARTICIPANT_IDS[0])
        assert renamed["name"] == RENAMED_NAME
        assert renamed["archived"] is False

        after = await api_snapshot(client)
        assert _money_rows(after["balances"]) == _money_rows(before["balances"])
        assert _settlement_money(after["settlement"]) == _settlement_money(
            before["settlement"]
        )
        participants = after["participants"]
        ana = next(
            row for row in participants if row["id"] == str(DEMO_PARTICIPANT_IDS[0])
        )
        assert ana["name"] == RENAMED_NAME

    money = monetary_source_snapshot(api)
    assert money["expenses"]
    assert money["contributions"]
    assert money["beneficiaries"]
    # The monetary source rows still reference the same participant UUID.
    referenced = {row[1] for row in money["contributions"]} | {
        row[1] for row in money["beneficiaries"]
    }
    assert DEMO_PARTICIPANT_IDS[0] in referenced

    async with api.client() as client:
        await api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        unknown_field = await client.patch(
            f"{GROUP_PATH}/participants/{DEMO_PARTICIPANT_IDS[0]}",
            headers=security_headers(),
            json={"name": RENAMED_NAME, "role": "owner"},
        )
        assert unknown_field.status_code == 422

        blank_rename = await client.patch(
            f"{GROUP_PATH}/participants/{DEMO_PARTICIPANT_IDS[0]}",
            headers=security_headers(),
            json={"name": "   "},
        )
        assert blank_rename.status_code == 422
        assert blank_rename.json()["error_code"] == "invalid_participant_name"

        conflict_rename = await client.patch(
            f"{GROUP_PATH}/participants/{DEMO_PARTICIPANT_IDS[1]}",
            headers=security_headers(),
            json={"name": RENAMED_NAME},
        )
        assert conflict_rename.status_code == 422
        assert conflict_rename.json()["error_code"] == "duplicate_participant_name"

        unchanged = await api_snapshot(client)
        assert _money_rows(unchanged["balances"]) == _money_rows(after["balances"])
        assert _money_rows(after["balances"]) == _money_rows(before["balances"])
        assert _settlement_money(unchanged["settlement"]) == _settlement_money(
            after["settlement"]
        )
        assert _settlement_money(after["settlement"]) == _settlement_money(
            before["settlement"]
        )
        still_ana = next(
            row
            for row in unchanged["participants"]
            if row["id"] == str(DEMO_PARTICIPANT_IDS[1])
        )
        assert still_ana["name"] != RENAMED_NAME


@pytest.mark.asyncio
async def test_da_07_archived_participant_rename_is_name_only(seeded_api):
    async with seeded_api.client() as client:
        await seeded_api.login(client, OWNER_LOGIN, OWNER_PASSWORD)

        archive_response = await client.post(
            f"{GROUP_PATH}/participants/{DEMO_PARTICIPANT_IDS[1]}/archive",
            headers=security_headers(),
        )
        assert archive_response.status_code == 200, archive_response.text

        rename_archived = await client.patch(
            f"{GROUP_PATH}/participants/{DEMO_PARTICIPANT_IDS[1]}",
            headers=security_headers(),
            json={"name": "Beto Archivado"},
        )
        assert rename_archived.status_code == 200, rename_archived.text
        body = rename_archived.json()
        assert body["id"] == str(DEMO_PARTICIPANT_IDS[1])
        assert body["name"] == "Beto Archivado"
        assert body["archived"] is True

        balances = await client.get(f"{GROUP_PATH}/balances")
        assert balances.status_code == 200
        beto = next(
            row
            for row in balances.json()["participants"]
            if row["participant_id"] == str(DEMO_PARTICIPANT_IDS[1])
        )
        assert beto["name"] == "Beto Archivado"
        assert beto["archived"] is True
        assert beto["balance_cents"] == 0
