"""FastAPI application entrypoint for Cuentas Claras."""

from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta
from enum import StrEnum
from typing import Any, cast

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from backend.app.adapters.config import get_settings
from backend.app.adapters.db.repositories import (
    AccountRepositoryAdapter,
    ExpenseRepositoryAdapter,
    GroupRepositoryAdapter,
    MembershipRepositoryAdapter,
    ParticipantRepositoryAdapter,
    SessionRepositoryAdapter,
)
from backend.app.adapters.db.session import (
    check_database_connection,
    dispose_engine,
)
from backend.app.adapters.db.uow import SqlAlchemyUnitOfWork
from backend.app.adapters.events.broadcaster import GroupEventBroadcaster
from backend.app.adapters.security.passwords import Argon2idPasswordHasher
from backend.app.adapters.security.sessions import OpaqueSessionTokenSource
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes.auth import router as auth_router
from backend.app.api.routes.balances import router as balances_router
from backend.app.api.routes.events import router as events_router
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


class HealthStatus(StrEnum):
    OK = "ok"
    ERROR = "error"


class DatabaseStatus(StrEnum):
    OK = "ok"
    UNAVAILABLE = "unavailable"


class HealthResponse(BaseModel):
    status: HealthStatus
    database: DatabaseStatus


class UvClock:
    """Production clock: timezone-aware UTC sessions."""

    def now(self) -> datetime:
        return datetime.now(UTC)


def _sync_database_url(database_url: str) -> str:
    """Map the asyncpg URL to the psycopg2 dialect used by the sync adapters."""

    return database_url.replace("postgresql+asyncpg://", "postgresql://")


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    sync_engine = create_engine(
        _sync_database_url(settings.database_url), pool_pre_ping=True
    )
    session_factory = sessionmaker(
        bind=sync_engine, expire_on_commit=False, class_=Session
    )
    session = session_factory()
    _wire_request_services(app, session)
    try:
        yield
    finally:
        session.close()
        sync_engine.dispose()
        await dispose_engine()


def _wire_request_services(app: FastAPI, session: Session) -> None:
    """Attach the repository-backed services the request dependencies read."""

    account_repository = AccountRepositoryAdapter(session)
    session_repository = SessionRepositoryAdapter(session)
    membership_repository = MembershipRepositoryAdapter(session)
    group_repository = GroupRepositoryAdapter(session)
    participant_repository = ParticipantRepositoryAdapter(session)
    expense_repository = ExpenseRepositoryAdapter(session)
    settings = get_settings()
    hasher = Argon2idPasswordHasher()
    auth_service = AuthService(
        account_repository,
        session_repository,
        membership_repository,
        hasher,
        OpaqueSessionTokenSource(),
        UvClock(),
        session_ttl=timedelta(seconds=settings.session_ttl),
    )
    unit_of_work = cast(Any, SqlAlchemyUnitOfWork(session=session))
    invalidation_publisher = getattr(app.state, "broadcaster", None)
    participant_service = ParticipantService(
        participant_repository,
        unit_of_work,
        invalidation_publisher=invalidation_publisher,
    )
    derived_service = DerivedService(participant_repository, expense_repository)
    expense_service = ExpenseService(
        expense_repository,
        participant_repository,
        unit_of_work,
        derived_service,
        invalidation_publisher=invalidation_publisher,
    )
    authorization = AuthorizationService(membership_repository, group_repository)
    group_service = GroupService(
        group_repository,
        unit_of_work,
        authorization,
        invalidation_publisher=invalidation_publisher,
    )
    app.state.auth_service = auth_service
    app.state.membership_repository = membership_repository
    app.state.group_repository = group_repository
    app.state.participant_repository = participant_repository
    app.state.expense_repository = expense_repository
    app.state.participant_service = participant_service
    app.state.expense_service = expense_service
    app.state.derived_service = derived_service
    app.state.group_service = group_service


settings = get_settings()
app = FastAPI(
    title="Cuentas Claras API",
    version="0.1.0",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,  # pyright: ignore[reportArgumentType]
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.state.settings = settings
app.state.broadcaster = GroupEventBroadcaster()
register_error_handlers(app)
app.include_router(auth_router)
app.include_router(groups_router)
app.include_router(participants_router)
app.include_router(expenses_router)
app.include_router(events_router)
app.include_router(balances_router)
app.include_router(settlement_router)


@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health() -> HealthResponse | JSONResponse:
    """Report application availability and PostgreSQL connectivity."""

    if await check_database_connection():
        return HealthResponse(
            status=HealthStatus.OK,
            database=DatabaseStatus.OK,
        )
    return JSONResponse(
        status_code=503,
        content={"status": "error", "database": "unavailable"},
    )
