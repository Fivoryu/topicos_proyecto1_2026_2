"""Integration coverage for protected expense and derived read routes."""

from dataclasses import dataclass, field
from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from backend.app.adapters.security.sessions import (
    CSRF_COOKIE_NAME,
    CSRF_HEADER_NAME,
    SESSION_COOKIE_NAME,
)
from backend.app.api.deps import (
    get_auth_service,
    get_group_repository,
    get_membership_repository,
)
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes._common import (
    get_derived_service,
    get_expense_service,
    get_group_service,
    get_participant_service,
)
from backend.app.api.routes.balances import router as balances_router
from backend.app.api.routes.expenses import router as expenses_router
from backend.app.api.routes.settlement import router as settlement_router
from backend.app.application.expense_service import ExpenseNotFoundError
from backend.app.domain.balance_service import compute_balances
from backend.app.domain.expense_rules import _normalise_expense
from backend.app.domain.settlement_service import build_settlement
from backend.app.domain.split_service import equal_split
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient

GROUP_ID = "group-demo"
OWNER_ID = "account-owner"


@dataclass
class Group:
    id: str = GROUP_ID
    name: str = "Samaipata"
    owner_account_id: str = OWNER_ID
    settlement_policy: str = "owner_only"


@dataclass
class Participant:
    id: str
    group_id: str
    name: str
    normalized_name: str
    archived_at: datetime | None = None
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))


@dataclass
class Expense:
    id: str
    group_id: str
    description: str
    amount_cents: int
    contributors: dict[str, int]
    beneficiaries: tuple[str, ...]
    created_at: datetime
    updated_at: datetime


class Auth:
    def session_identity(self, token):
        if token == "owner-token":
            return SimpleNamespace(
                account_id=OWNER_ID,
                login_name="demo.owner",
                active_group_id=GROUP_ID,
                role="owner",
                expires_at=datetime(2027, 1, 1, tzinfo=UTC),
            )
        from backend.app.application.auth_service import UnauthorizedError

        raise UnauthorizedError()


class Memberships:
    def find_for_account_in_group(self, account_id, group_id):
        if account_id != OWNER_ID or group_id != GROUP_ID:
            return None
        return SimpleNamespace(
            account_id=OWNER_ID,
            group_id=GROUP_ID,
            owner_account_id=OWNER_ID,
        )


class Groups:
    def __init__(self, group):
        self.group = group

    def find_by_id(self, group_id):
        return self.group if group_id == GROUP_ID else None


class GroupService:
    def __init__(self, group):
        self.group = group

    def read(self, group_id, actor=None):
        if group_id != GROUP_ID:
            from backend.app.application.group_service import GroupNotFoundError

            raise GroupNotFoundError()
        return self.group


class ParticipantService:
    def __init__(self):
        self.rows = [
            Participant("ana", GROUP_ID, "Ana", "ana"),
            Participant("beto", GROUP_ID, "Beto", "beto"),
            Participant("carla", GROUP_ID, "Carla", "carla"),
            Participant(
                "diego", GROUP_ID, "Diego", "diego", archived_at=datetime.now(UTC)
            ),
        ]

    def list(self, group_id, actor=None):
        return [row for row in self.rows if row.group_id == group_id]


class ExpenseService:
    def __init__(self, participants):
        self._participants = participants
        self.rows = [
            Expense(
                "expense-1",
                GROUP_ID,
                "Lunch",
                10_000,
                {"ana": 10_000},
                ("ana", "beto"),
                datetime(2026, 1, 1, tzinfo=UTC),
                datetime(2026, 1, 1, tzinfo=UTC),
            )
        ]
        self.mutation_calls = 0

    def list(self, group_id, actor=None):
        return [row for row in self.rows if row.group_id == group_id]

    def list_by_group(self, group_id):
        return self.list(group_id)

    def find_by_id(self, group_id, expense_id):
        return next(
            (
                row
                for row in self.rows
                if row.group_id == group_id and row.id == expense_id
            ),
            None,
        )

    def _validate(self, group_id, amount_cents, contributors, beneficiaries):
        participants = [row.id for row in self._participants.list(group_id)]
        normalized = _normalise_expense(
            amount_cents=amount_cents,
            contributors=contributors,
            beneficiaries=beneficiaries,
            participants=participants,
        )
        equal_split(
            normalized.amount_cents,
            normalized.beneficiaries,
            normalized.contributors,
            participants,
        )
        return normalized

    def create(
        self,
        group_id,
        description,
        amount_cents,
        contributors,
        beneficiaries,
        actor=None,
    ):
        self.mutation_calls += 1
        normalized = self._validate(group_id, amount_cents, contributors, beneficiaries)
        now = datetime(2026, 1, 2, tzinfo=UTC)
        row = Expense(
            f"expense-{len(self.rows) + 1}",
            group_id,
            description.strip(),
            normalized.amount_cents,
            dict(normalized.contributors),
            tuple(str(participant_id) for participant_id in normalized.beneficiaries),
            now,
            now,
        )
        self.rows.append(row)
        return row

    def edit(
        self,
        group_id,
        expense_id,
        description,
        amount_cents,
        contributors,
        beneficiaries,
        actor=None,
    ):
        current = self.find_by_id(group_id, expense_id)
        if current is None:
            raise ExpenseNotFoundError()
        self.mutation_calls += 1
        normalized = self._validate(group_id, amount_cents, contributors, beneficiaries)
        current.description = description.strip()
        current.amount_cents = normalized.amount_cents
        current.contributors = dict(normalized.contributors)
        current.beneficiaries = tuple(
            str(participant_id) for participant_id in normalized.beneficiaries
        )
        current.updated_at = datetime(2026, 1, 3, tzinfo=UTC)
        return current

    def delete(self, group_id, expense_id, actor=None):
        current = self.find_by_id(group_id, expense_id)
        if current is None:
            raise ExpenseNotFoundError()
        self.mutation_calls += 1
        self.rows.remove(current)


class Derived:
    def __init__(self, participants, expenses):
        self.participants = participants
        self.expenses = expenses

    def get_balances(self, group_id):
        rows = self.participants.list(group_id)
        return compute_balances(rows, self.expenses.list(group_id))

    def get_settlement(self, group_id):
        return build_settlement(self.get_balances(group_id))


@pytest.fixture
def expense_app():
    group = Group()
    participants = ParticipantService()
    expenses = ExpenseService(participants)
    derived = Derived(participants, expenses)
    app = FastAPI()
    register_error_handlers(app)
    app.include_router(expenses_router)
    app.include_router(balances_router)
    app.include_router(settlement_router)
    app.dependency_overrides.update(
        {
            get_auth_service: Auth,
            get_membership_repository: Memberships,
            get_group_repository: lambda: Groups(group),
            get_group_service: lambda: GroupService(group),
            get_participant_service: lambda: participants,
            get_expense_service: lambda: expenses,
            get_derived_service: lambda: derived,
        }
    )
    return app, group, participants, expenses


def _cookies():
    return {SESSION_COOKIE_NAME: "owner-token", CSRF_COOKIE_NAME: "csrf-token"}


def _set_cookies(client: AsyncClient, cookies: dict[str, str]) -> None:
    client.cookies.clear()
    client.cookies.update(cookies)


def _headers():
    return {"Origin": "http://localhost:5173", CSRF_HEADER_NAME: "csrf-token"}


def _write_payload(amount: object = "10.00", contribution: object = "10.00"):
    return {
        "description": "  Coffee  ",
        "amount": amount,
        "contributors": [{"participant_id": "ana", "amount": contribution}],
        "beneficiary_ids": ["ana", "beto"],
    }


@pytest.mark.asyncio
async def test_expense_crud_parses_decimal_strings_once_and_wires_integer_wire_shapes(
    expense_app,
):
    app, _group, _participants, expenses = expense_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        listed = await client.get(f"/api/v1/groups/{GROUP_ID}/expenses")
        _set_cookies(client, _cookies())
        created = await client.post(
            f"/api/v1/groups/{GROUP_ID}/expenses",
            headers=_headers(),
            json=_write_payload("100.01", "100.01"),
        )
        expense_id = created.json()["id"]
        _set_cookies(client, _cookies())
        fetched = await client.get(f"/api/v1/groups/{GROUP_ID}/expenses/{expense_id}")
        _set_cookies(client, _cookies())
        edited = await client.patch(
            f"/api/v1/groups/{GROUP_ID}/expenses/{expense_id}",
            headers=_headers(),
            json=_write_payload("100.02", "100.02"),
        )
        _set_cookies(client, _cookies())
        deleted = await client.delete(
            f"/api/v1/groups/{GROUP_ID}/expenses/{expense_id}",
            headers=_headers(),
        )

    assert listed.status_code == 200
    assert listed.json()[0]["amount_cents"] == 10_000
    assert "amount" not in listed.json()[0]
    assert created.status_code == 201
    assert created.json()["amount_cents"] == 10_001
    assert isinstance(created.json()["amount_cents"], int)
    assert created.json()["contributors"][0]["amount_cents"] == 10_001
    assert created.json()["contributors"][0]["name"] == "Ana"
    assert fetched.status_code == 200
    assert edited.status_code == 200
    assert edited.json()["amount_cents"] == 10_002
    assert deleted.status_code == 204
    assert expenses.mutation_calls == 3


@pytest.mark.asyncio
async def test_invalid_expense_mutations_preserve_source_state(
    expense_app,
):
    app, _group, _participants, expenses = expense_app
    before = [
        (row.id, row.amount_cents, row.contributors, row.beneficiaries)
        for row in expenses.rows
    ]
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        too_precise = await client.post(
            f"/api/v1/groups/{GROUP_ID}/expenses",
            headers=_headers(),
            json=_write_payload("10.001", "10.001"),
        )
        _set_cookies(client, _cookies())
        float_wire = await client.post(
            f"/api/v1/groups/{GROUP_ID}/expenses",
            headers=_headers(),
            json=_write_payload(10.0, 10.0),
        )
        mismatch_payload = _write_payload("10.00", "9.00")
        _set_cookies(client, _cookies())
        mismatch = await client.post(
            f"/api/v1/groups/{GROUP_ID}/expenses",
            headers=_headers(),
            json=mismatch_payload,
        )
        _set_cookies(client, _cookies())
        no_beneficiaries = await client.post(
            f"/api/v1/groups/{GROUP_ID}/expenses",
            headers=_headers(),
            json={**_write_payload(), "beneficiary_ids": []},
        )
        _set_cookies(client, _cookies())
        missing_reference = await client.post(
            f"/api/v1/groups/{GROUP_ID}/expenses",
            headers=_headers(),
            json={**_write_payload(), "beneficiary_ids": ["missing"]},
        )

    assert too_precise.status_code == 422
    assert too_precise.json()["error_code"] == "invalid_amount"
    assert float_wire.status_code == 422
    assert float_wire.json()["error_code"] == "invalid_request"
    assert mismatch.status_code == 422
    assert mismatch.json()["error_code"] == "contribution_mismatch"
    assert no_beneficiaries.status_code == 422
    assert no_beneficiaries.json()["error_code"] == "no_beneficiaries"
    assert missing_reference.status_code == 422
    assert missing_reference.json()["error_code"] == "invalid_participant_reference"
    assert expenses.mutation_calls == 3
    assert [
        (row.id, row.amount_cents, row.contributors, row.beneficiaries)
        for row in expenses.rows
    ] == before


@pytest.mark.asyncio
async def test_balances_and_settlement_are_server_derived_stable_and_expose_policy(
    expense_app,
):
    app, group, participants, _expenses = expense_app
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://testserver"
    ) as client:
        _set_cookies(client, _cookies())
        balances = await client.get(f"/api/v1/groups/{GROUP_ID}/balances")
        _set_cookies(client, _cookies())
        settlement = await client.get(f"/api/v1/groups/{GROUP_ID}/settlement")
        client.cookies.clear()
        no_session = await client.get(f"/api/v1/groups/{GROUP_ID}/settlement")

    assert balances.status_code == 200
    assert [row["participant_id"] for row in balances.json()["participants"]] == [
        "ana",
        "beto",
        "carla",
        "diego",
    ]
    assert balances.json()["participants"][-1] == {
        "participant_id": "diego",
        "name": "Diego",
        "archived": True,
        "paid_cents": 0,
        "owed_cents": 0,
        "balance_cents": 0,
    }
    assert settlement.status_code == 200
    assert settlement.json()["settlementPolicy"] == group.settlement_policy
    assert settlement.json()["settled"] is False
    assert settlement.json()["transfers"] == [
        {
            "from_participant_id": "beto",
            "to_participant_id": "ana",
            "from_name": "Beto",
            "to_name": "Ana",
            "amount_cents": 5_000,
        }
    ]
    assert no_session.status_code == 401
    assert no_session.json()["error_code"] == "unauthorized"
    assert len(participants.rows) == 4
