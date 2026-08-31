"""Health endpoint tests for the backend bootstrap."""

import pytest
from httpx import ASGITransport, AsyncClient


async def _get_health(app):
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
    ) as client:
        return await client.get("/health")


@pytest.mark.asyncio
async def test_health_reports_database_connectivity(monkeypatch):
    from backend.app import main

    async def database_is_available():
        return True

    monkeypatch.setattr(main, "check_database_connection", database_is_available)

    response = await _get_health(main.app)

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "ok"}


@pytest.mark.asyncio
async def test_health_fails_closed_when_database_is_unavailable(monkeypatch):
    from backend.app import main

    async def database_is_unavailable():
        return False

    monkeypatch.setattr(main, "check_database_connection", database_is_unavailable)

    response = await _get_health(main.app)

    assert response.status_code == 503
    assert response.json() == {"status": "error", "database": "unavailable"}
