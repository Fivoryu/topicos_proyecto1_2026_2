"""DA-06: auth acceptance — roles, invalid credentials, 401s, logout, policy matrix."""

import pytest
from conftest import (
    GROUP_PATH,
    MEMBER_LOGIN,
    MEMBER_PASSWORD,
    OWNER_LOGIN,
    OWNER_PASSWORD,
    security_headers,
)


@pytest.mark.asyncio
async def test_da_06_owner_and_member_roles_with_protected_boundaries(seeded_api):
    async with seeded_api.client() as client:
        owner = await seeded_api.login(client, OWNER_LOGIN, OWNER_PASSWORD)
        member = await seeded_api.login(client, MEMBER_LOGIN, MEMBER_PASSWORD)
        assert owner.status_code == 200
        assert owner.json()["role"] == "owner"
        assert member.status_code == 200
        assert member.json()["role"] == "member"

        invalid = await client.post(
            "/api/v1/auth/login",
            headers=security_headers(),
            json={"login_name": OWNER_LOGIN, "password": "wrong-password"},
        )
        assert invalid.status_code == 401
        assert invalid.json()["error_code"] == "invalid_credentials"

        logout = await client.post("/api/v1/auth/logout", headers=security_headers())
        assert logout.status_code in (204, 200)

        rejected = await client.get(f"{GROUP_PATH}/balances")
        assert rejected.status_code == 401
        assert rejected.json()["error_code"] == "unauthorized"

    async with seeded_api.client() as anonymous:
        no_session = await anonymous.get(f"{GROUP_PATH}/balances")
        assert no_session.status_code == 401
        assert no_session.json()["error_code"] == "unauthorized"


@pytest.mark.asyncio
async def test_da_06_policy_matrix_owner_only_then_any_member(seeded_api):
    async with seeded_api.client() as owner_client:
        owner_login = await seeded_api.login(owner_client, OWNER_LOGIN, OWNER_PASSWORD)
        assert owner_login.status_code == 200

    async with seeded_api.client() as member_client:
        member_login = await seeded_api.login(
            member_client, MEMBER_LOGIN, MEMBER_PASSWORD
        )
        assert member_login.status_code == 200
        assert member_login.json()["role"] == "member"

        member_change_under_owner_only = await member_client.patch(
            GROUP_PATH,
            headers=security_headers(),
            json={"settlementPolicy": "any_member"},
        )
        assert member_change_under_owner_only.status_code == 403
        assert member_change_under_owner_only.json()["error_code"] == "forbidden"

    async with seeded_api.client() as owner_client:
        await seeded_api.login(owner_client, OWNER_LOGIN, OWNER_PASSWORD)
        owner_change = await owner_client.patch(
            GROUP_PATH,
            headers=security_headers(),
            json={"settlementPolicy": "any_member"},
        )
        assert owner_change.status_code == 200, owner_change.text
        assert owner_change.json()["settlementPolicy"] == "any_member"

    async with seeded_api.client() as member_client:
        await seeded_api.login(member_client, MEMBER_LOGIN, MEMBER_PASSWORD)
        member_change_allowed = await member_client.patch(
            GROUP_PATH,
            headers=security_headers(),
            json={"settlementPolicy": "owner_only"},
        )
        assert member_change_allowed.status_code == 200, member_change_allowed.text
        assert member_change_allowed.json()["settlementPolicy"] == "owner_only"
