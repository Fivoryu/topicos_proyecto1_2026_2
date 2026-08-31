"""Async engine factory tests for the backend bootstrap."""

import pytest


def test_create_engine_uses_configured_database_url(monkeypatch):
    from backend.app.adapters.config import Settings
    from backend.app.adapters.db import session as db_session

    captured = {}

    def fake_create_async_engine(url, **kwargs):
        captured["url"] = url
        captured["kwargs"] = kwargs
        return object()

    monkeypatch.setattr(db_session, "create_async_engine", fake_create_async_engine)

    result = db_session.create_engine(
        Settings(
            database_url="postgresql+asyncpg://postgres:secret@localhost:5432/test",
            _env_file=None,
        )
    )

    assert result is not None
    assert captured["url"] == (
        "postgresql+asyncpg://postgres:secret@localhost:5432/test"
    )
    assert captured["kwargs"]["pool_pre_ping"] is True


@pytest.mark.asyncio
async def test_database_check_fails_closed_for_an_invalid_database_url(monkeypatch):
    from backend.app.adapters.config import Settings
    from backend.app.adapters.db import session as db_session

    monkeypatch.setattr(
        db_session,
        "get_settings",
        lambda: Settings(database_url="not-a-database-url", _env_file=None),
    )

    assert await db_session.check_database_connection() is False
