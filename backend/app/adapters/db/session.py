"""SQLAlchemy async engine and session factory."""

from typing import cast

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from backend.app.adapters.config import Settings, get_settings

_ENGINE_KWARGS = {"pool_pre_ping": True}
_engine: AsyncEngine | None = None


def create_engine(settings: Settings = cast(Settings, None)) -> AsyncEngine:
    """Create an async SQLAlchemy engine without opening a connection."""

    runtime_settings = settings or get_settings()
    return create_async_engine(runtime_settings.database_url, **_ENGINE_KWARGS)


def get_engine() -> AsyncEngine:
    """Return the lazily-created process engine."""

    global _engine
    if _engine is None:
        _engine = create_engine()
    return _engine


def get_session_factory(
    settings: Settings = cast(Settings, None),
) -> async_sessionmaker:
    """Build a session factory with non-expiring ORM objects after commits."""

    return async_sessionmaker(
        create_engine(settings),
        expire_on_commit=False,
        class_=AsyncSession,
    )


async def check_database_connection(
    engine: AsyncEngine = cast(AsyncEngine, None),
) -> bool:
    """Return whether the configured database can execute a trivial query."""

    try:
        connection_engine = engine or get_engine()
        async with connection_engine.connect() as connection:
            await connection.execute(select(1))
    except (SQLAlchemyError, ImportError, OSError, ValueError):
        return False
    return True


async def dispose_engine() -> None:
    """Dispose the process engine during application shutdown."""

    global _engine
    if _engine is not None:
        await _engine.dispose()
        _engine = None


async def session_scope(
    settings: Settings = cast(Settings, None),
):
    """Yield one async session for future request dependencies."""

    session_factory = get_session_factory(settings)
    async with session_factory() as session:
        yield session
