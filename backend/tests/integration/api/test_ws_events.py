"""Integration tests for the authenticated, invalidation-only event channel."""

from datetime import UTC, datetime
from types import SimpleNamespace

import pytest
from backend.app.adapters.events.broadcaster import GroupEventBroadcaster
from backend.app.api.deps import (
    get_auth_service,
    get_group_repository,
    get_membership_repository,
)
from backend.app.api.errors import register_error_handlers
from backend.app.api.routes.events import router as events_router
from fastapi import FastAPI
from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

GROUP_ID = "group-demo"
ACCOUNT_ID = "account-owner"


class Auth:
    def session_identity(self, token: str | None):
        if token == "valid-session":
            return SimpleNamespace(
                account_id=ACCOUNT_ID,
                login_name="demo.owner",
                active_group_id=GROUP_ID,
                role="owner",
                expires_at=datetime(2027, 1, 1, tzinfo=UTC),
            )
        from backend.app.application.auth_service import UnauthorizedError

        raise UnauthorizedError()


class Memberships:
    def find_for_account_in_group(self, account_id: object, group_id: object):
        if account_id != ACCOUNT_ID or str(group_id) != GROUP_ID:
            return None
        return SimpleNamespace(
            account_id=ACCOUNT_ID,
            group_id=GROUP_ID,
            owner_account_id=ACCOUNT_ID,
        )


class Groups:
    def find_by_id(self, group_id: object):
        if str(group_id) != GROUP_ID:
            return None
        return SimpleNamespace(id=GROUP_ID, owner_account_id=ACCOUNT_ID)


@pytest.fixture
def event_app():
    app = FastAPI()
    register_error_handlers(app)
    broadcaster = GroupEventBroadcaster()
    app.state.broadcaster = broadcaster
    app.state.settings = SimpleNamespace(cors_origins=["http://localhost:5173"])
    app.include_router(events_router)
    app.dependency_overrides.update(
        {
            get_auth_service: lambda: Auth(),
            get_membership_repository: lambda: Memberships(),
            get_group_repository: lambda: Groups(),
        }
    )
    return app, broadcaster


def _client(app: FastAPI) -> TestClient:
    client = TestClient(app)
    client.cookies.set("cc_session", "valid-session", path="/api")
    return client


def test_event_frame_is_only_a_type_bearing_invalidation(event_app):
    app, broadcaster = event_app
    with _client(app) as client:
        with client.websocket_connect(
            f"/api/v1/groups/{GROUP_ID}/events",
            headers={"Origin": "http://localhost:5173"},
        ) as websocket:
            broadcaster.publish(GROUP_ID)
            frame = websocket.receive_json()

    assert frame == {"type": "data_changed"}
    assert set(frame) == {"type"}
    assert not any(
        key in frame
        for key in (
            "amount",
            "amount_cents",
            "balance",
            "balance_cents",
            "transfer",
            "role",
            "participant",
        )
    )


@pytest.mark.parametrize(
    ("token", "origin"),
    [("missing-session", "http://localhost:5173"), ("valid-session", "https://evil.example")],
)
def test_unauthorized_handshake_is_rejected(event_app, token, origin):
    app, _broadcaster = event_app
    with TestClient(app) as client:
        client.cookies.set("cc_session", token, path="/api")
        with pytest.raises(WebSocketDisconnect) as error:
            with client.websocket_connect(
                f"/api/v1/groups/{GROUP_ID}/events",
                headers={"Origin": origin},
            ):
                pass

    assert error.value.code == 1008


def test_broadcaster_failure_does_not_break_committed_rest_work(event_app):
    app, broadcaster = event_app
    committed = {"value": 0}

    class FailingQueue:
        def put_nowait(self, _frame):
            raise RuntimeError("closed websocket")

    broadcaster._subscribers.setdefault(GROUP_ID, set()).add(FailingQueue())

    @app.post("/commit")
    def commit():
        committed["value"] += 1
        broadcaster.publish(GROUP_ID)
        return {"committed": committed["value"]}

    with TestClient(app) as client:
        response = client.post("/commit")

    assert response.status_code == 200
    assert response.json() == {"committed": 1}
