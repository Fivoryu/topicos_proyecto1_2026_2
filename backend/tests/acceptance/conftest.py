"""Hermetic seeded API harness for the DA acceptance scenarios."""

from __future__ import annotations

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from typing import Any, cast

import pytest
from backend.app.adapters.db.repositories import (
    AccountRepositoryAdapter,
    ExpenseRepositoryAdapter,
    GroupRepositoryAdapter,
    MembershipRepositoryAdapter,
    ParticipantRepositoryAdapter,
    SessionRepositoryAdapter,
)
from backend.app.adapters.db.tables import (
    Base,
    Expense,
    ExpenseBeneficiary,
    ExpenseContribution,
)
from backend.app.adapters.db.uow import SqlAlchemyUnitOfWork
from backend.app.adapters.security.passwords import Argon2idPasswordHasher
from backend.app.adapters.security.sessions import (
    CSRF_COOKIE_NAME,
    CSRF_HEADER_NAME,
    SESSION_COOKIE_NAME,
    OpaqueSessionTokenSource,
)
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes.auth import router as auth_router
from backend.app.api.routes.balances import router as balances_router
from backend.app.api.routes.expenses import router as expenses_router
from backend.app.api.routes.groups import router as groups_router
from backend.app.api.routes.participants import router as participants_router
from backend.app.api.routes.settlement import router as settlement_router
from backend.app.application.auth_service import AuthService
from backend.app.application.authorization import AuthorizationService
from backend.app.application.derived_service import DerivedService
from backend.app.application.expense_service import ExpenseService
from backend.app.application.group_service import GroupService
from backend.app.application.participant_service import ParticipantService
from backend.scripts.seed_demo import (
    DEMO_EXPENSE_IDS,
    DEMO_GROUP_ID,
    DEMO_MEMBER_ID,
    DEMO_OWNER_ID,
    DEMO_PARTICIPANT_IDS,
    seed_demo,
)
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import create_engine, event, select
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

OWNER_LOGIN = "demo.owner"
OWNER_PASSWORD = "acceptance-owner-password"
MEMBER_LOGIN = "demo.member"
MEMBER_PASSWORD = "acceptance-member-password"
GROUP_PATH = f"/api/v1/groups/{DEMO_GROUP_ID}"
ORIGIN = "http://localhost:5173"


class AcceptanceClock:
    """Use naive UTC values because SQLite drops timezone metadata on reload."""

    def now(self) -> datetime:
        return datetime.now(UTC).replace(tzinfo=None)


class AcceptanceAPI:
    """Application plus one durable SQLite database for one acceptance test."""

    def __init__(self, engine, session: Session):
        self.engine = engine
        self.session = session
        self.app = FastAPI()
        self.app.state.settings = SimpleNamespace(cors_origins=[ORIGIN])
        register_error_handlers(self.app)
        self.app.include_router(auth_router)
        self.app.include_router(groups_router)
        self.app.include_router(participants_router)
        self.app.include_router(expenses_router)
        self.app.include_router(balances_router)
        self.app.include_router(settlement_router)
        self._wire_services()

    def _wire_services(self) -> None:
        account_repository = AccountRepositoryAdapter(self.session)
        session_repository = SessionRepositoryAdapter(self.session)
        membership_repository = MembershipRepositoryAdapter(self.session)
        group_repository = GroupRepositoryAdapter(self.session)
        participant_repository = ParticipantRepositoryAdapter(self.session)
        expense_repository = ExpenseRepositoryAdapter(self.session)
        hasher = Argon2idPasswordHasher(
            time_cost=1,
            memory_cost=8_192,
            parallelism=1,
            hash_len=32,
            salt_len=16,
        )
        auth_service = AuthService(
            account_repository,
            session_repository,
            membership_repository,
            hasher,
            OpaqueSessionTokenSource(),
            AcceptanceClock(),
            session_ttl=timedelta(hours=8),
        )
        participant_service = ParticipantService(
            participant_repository,
            cast(Any, SqlAlchemyUnitOfWork(session=self.session)),
        )
        derived_service = DerivedService(participant_repository, expense_repository)
        expense_service = ExpenseService(
            expense_repository,
            participant_repository,
            cast(Any, SqlAlchemyUnitOfWork(session=self.session)),
            derived_service,
        )
        authorization = AuthorizationService(membership_repository, group_repository)
        group_service = GroupService(
            group_repository,
            cast(Any, SqlAlchemyUnitOfWork(session=self.session)),
            authorization,
        )
        self.app.state.auth_service = auth_service
        self.app.state.membership_repository = membership_repository
        self.app.state.group_repository = group_repository
        self.app.state.participant_repository = participant_repository
        self.app.state.expense_repository = expense_repository
        self.app.state.participant_service = participant_service
        self.app.state.expense_service = expense_service
        self.app.state.derived_service = derived_service
        self.app.state.group_service = group_service

    def restart(self) -> None:
        """Recreate request services while retaining the same database contents."""

        self.session.close()
        self.session = Session(self.engine)
        self._wire_services()

    @asynccontextmanager
    async def client(
        self, cookies: dict[str, str] | None = None
    ) -> AsyncIterator[AsyncClient]:
        async with AsyncClient(
            transport=ASGITransport(app=self.app),
            base_url="http://testserver",
            cookies=cookies,
        ) as client:
            yield client

    async def login(self, client: AsyncClient, login_name: str, password: str):
        client.cookies.set(CSRF_COOKIE_NAME, "acceptance-csrf")
        return await client.post(
            "/api/v1/auth/login",
            headers=security_headers(),
            json={"login_name": login_name, "password": password},
        )


def security_headers() -> dict[str, str]:
    return {"Origin": ORIGIN, CSRF_HEADER_NAME: "acceptance-csrf"}


def cookies_for(token: str) -> dict[str, str]:
    return {
        SESSION_COOKIE_NAME: token,
        CSRF_COOKIE_NAME: "acceptance-csrf",
    }


async def delete_seed_expenses(client: AsyncClient) -> list[int]:
    statuses = []
    for expense_id in DEMO_EXPENSE_IDS:
        response = await client.delete(
            f"{GROUP_PATH}/expenses/{expense_id}", headers=security_headers()
        )
        statuses.append(response.status_code)
    return statuses


async def api_snapshot(client: AsyncClient) -> dict[str, Any]:
    responses = {
        "group": await client.get(GROUP_PATH),
        "participants": await client.get(f"{GROUP_PATH}/participants"),
        "expenses": await client.get(f"{GROUP_PATH}/expenses"),
        "balances": await client.get(f"{GROUP_PATH}/balances"),
        "settlement": await client.get(f"{GROUP_PATH}/settlement"),
    }
    for response in responses.values():
        assert response.status_code == 200, response.text
    return {name: response.json() for name, response in responses.items()}


def monetary_source_snapshot(api: AcceptanceAPI) -> dict[str, list[tuple[Any, ...]]]:
    expenses = [
        tuple(row)
        for row in api.session.execute(
            select(
                Expense.id,
                Expense.group_id,
                Expense.description,
                Expense.amount_cents,
                Expense.created_at,
                Expense.updated_at,
            ).order_by(Expense.created_at, Expense.id)
        ).all()
    ]
    contributions = [
        tuple(row)
        for row in api.session.execute(
            select(
                ExpenseContribution.expense_id,
                ExpenseContribution.participant_id,
                ExpenseContribution.amount_cents,
            ).order_by(
                ExpenseContribution.expense_id,
                ExpenseContribution.participant_id,
            )
        ).all()
    ]
    beneficiaries = [
        tuple(row)
        for row in api.session.execute(
            select(
                ExpenseBeneficiary.expense_id,
                ExpenseBeneficiary.participant_id,
            ).order_by(
                ExpenseBeneficiary.expense_id,
                ExpenseBeneficiary.participant_id,
            )
        ).all()
    ]
    return {
        "expenses": expenses,
        "contributions": contributions,
        "beneficiaries": beneficiaries,
    }


@pytest.fixture
def seeded_api() -> Any:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(engine, "connect")
    def enable_foreign_keys(connection, _record) -> None:
        cursor = connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    Base.metadata.create_all(engine)
    session = Session(engine)
    seed_hasher = Argon2idPasswordHasher(
        time_cost=1,
        memory_cost=8_192,
        parallelism=1,
        hash_len=32,
        salt_len=16,
    )
    seed_demo(
        session,
        owner_password=OWNER_PASSWORD,
        member_password=MEMBER_PASSWORD,
        hasher=seed_hasher,
    )
    api = AcceptanceAPI(engine, session)
    try:
        yield api
    finally:
        api.session.close()
        engine.dispose()


__all__ = [
    "AcceptanceAPI",
    "CSRF_COOKIE_NAME",
    "CSRF_HEADER_NAME",
    "DEMO_GROUP_ID",
    "DEMO_MEMBER_ID",
    "DEMO_OWNER_ID",
    "DEMO_PARTICIPANT_IDS",
    "GROUP_PATH",
    "MEMBER_LOGIN",
    "MEMBER_PASSWORD",
    "ORIGIN",
    "OWNER_LOGIN",
    "OWNER_PASSWORD",
    "SESSION_COOKIE_NAME",
    "api_snapshot",
    "cookies_for",
    "delete_seed_expenses",
    "monetary_source_snapshot",
    "security_headers",
]
