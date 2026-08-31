"""Fake-based unit tests for the application authentication service."""

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from hashlib import sha256
from types import SimpleNamespace

import pytest
from backend.app.application.auth_service import (
    AuthService,
    InvalidCredentialsError,
    SessionExpiredError,
    UnauthorizedError,
)


@dataclass
class FakeClock:
    current: datetime

    def now(self) -> datetime:
        return self.current


class FakePasswordHasher:
    dummy_hash = "safe-dummy-hash"

    def __init__(self, valid_passwords: dict[str, str]):
        self.valid_passwords = valid_passwords
        self.calls: list[tuple[str, str]] = []

    def verify(self, password: str, encoded_hash: str) -> bool:
        self.calls.append((password, encoded_hash))
        return self.valid_passwords.get(encoded_hash) == password


class FakeSessionTokenSource:
    def __init__(self, *tokens: str):
        self.tokens = list(tokens)
        self.hash_calls: list[str] = []

    def generate(self) -> str:
        return self.tokens.pop(0)

    def hash(self, token: str) -> bytes:
        self.hash_calls.append(token)
        return sha256(token.encode("utf-8")).digest()


class FakeAccountRepository:
    def __init__(self, accounts):
        self.accounts = {account.login_name: account for account in accounts}
        self.by_id = {account.id: account for account in accounts}

    def find_by_login_name(self, login_name: str):
        return self.accounts.get(login_name)

    def find_by_id(self, account_id: str):
        return self.by_id.get(account_id)


class FakeMembershipRepository:
    def __init__(self, memberships):
        self.memberships = memberships

    def find_for_account(self, account_id: str):
        return self.memberships.get(account_id)


class FakeSessionRepository:
    def __init__(self):
        self.sessions = {}
        self.created = []
        self.revocations = []

    def create(self, session):
        self.created.append(session)
        self.sessions[session.token_hash] = session
        return session

    def find_by_token_hash(self, token_hash: bytes):
        return self.sessions.get(token_hash)

    def revoke_by_token_hash(self, token_hash: bytes, revoked_at: datetime):
        session = self.sessions.get(token_hash)
        if session is not None:
            session.revoked_at = revoked_at
        self.revocations.append((token_hash, revoked_at))


@pytest.fixture
def fixtures():
    owner = SimpleNamespace(
        id="account-owner",
        login_name="demo.owner",
        password_hash="owner-hash",
        is_active=True,
        role="member",  # A persisted/client claim must not affect authority.
    )
    member = SimpleNamespace(
        id="account-member",
        login_name="demo.member",
        password_hash="member-hash",
        is_active=True,
    )
    inactive = SimpleNamespace(
        id="account-inactive",
        login_name="demo.inactive",
        password_hash="inactive-hash",
        is_active=False,
    )
    memberships = {
        owner.id: SimpleNamespace(
            account_id=owner.id,
            group_id="group-demo",
            owner_account_id=owner.id,
        ),
        member.id: SimpleNamespace(
            account_id=member.id,
            group_id="group-demo",
            owner_account_id=owner.id,
        ),
        inactive.id: SimpleNamespace(
            account_id=inactive.id,
            group_id="group-demo",
            owner_account_id=owner.id,
        ),
    }
    clock = FakeClock(datetime(2026, 1, 1, 12, tzinfo=UTC))
    hasher = FakePasswordHasher(
        {
            "owner-hash": "owner-password",
            "member-hash": "member-password",
        }
    )
    tokens = FakeSessionTokenSource("owner-token", "member-token")
    accounts = FakeAccountRepository((owner, member, inactive))
    sessions = FakeSessionRepository()
    membership_repository = FakeMembershipRepository(memberships)
    service = AuthService(
        account_repository=accounts,
        session_repository=sessions,
        membership_repository=membership_repository,
        password_hasher=hasher,
        token_source=tokens,
        clock=clock,
        session_ttl=timedelta(hours=1),
    )
    return SimpleNamespace(
        service=service,
        clock=clock,
        memberships=membership_repository,
        hasher=hasher,
        tokens=tokens,
        accounts=accounts,
        sessions=sessions,
    )


def test_owner_and_member_login_return_server_derived_identity_and_role(fixtures):
    owner = fixtures.service.login("demo.owner", "owner-password")
    member = fixtures.service.login("demo.member", "member-password")

    assert owner.account_id == "account-owner"
    assert owner.login_name == "demo.owner"
    assert owner.active_group_id == "group-demo"
    assert owner.role == "owner"
    assert owner.token == "owner-token"
    assert owner.expires_at == fixtures.clock.current + timedelta(hours=1)

    assert member.account_id == "account-member"
    assert member.active_group_id == "group-demo"
    assert member.role == "member"
    assert member.token == "member-token"

    assert len(fixtures.sessions.created) == 2
    assert all(
        session.token_hash not in {b"owner-token", b"member-token"}
        for session in fixtures.sessions.created
    )
    assert all(
        raw_token not in repr(session)
        for session, raw_token in zip(
            fixtures.sessions.created, ("owner-token", "member-token")
        )
    )


def test_wrong_unknown_and_inactive_credentials_have_one_public_failure_shape(fixtures):
    with pytest.raises(InvalidCredentialsError) as wrong:
        fixtures.service.login("demo.owner", "wrong-password")
    wrong_call = fixtures.hasher.calls[-1]

    with pytest.raises(InvalidCredentialsError) as unknown:
        fixtures.service.login("does-not-exist", "wrong-password")
    unknown_call = fixtures.hasher.calls[-1]

    with pytest.raises(InvalidCredentialsError) as inactive:
        fixtures.service.login("demo.inactive", "inactive-password")
    inactive_call = fixtures.hasher.calls[-1]

    assert (wrong.value.code, str(wrong.value)) == (
        unknown.value.code,
        str(unknown.value),
    )
    assert (unknown.value.code, str(unknown.value)) == (
        inactive.value.code,
        str(inactive.value),
    )
    assert wrong_call == ("wrong-password", "owner-hash")
    assert unknown_call == ("wrong-password", FakePasswordHasher.dummy_hash)
    assert inactive_call == ("inactive-password", FakePasswordHasher.dummy_hash)
    assert fixtures.sessions.created == []


def test_malformed_credentials_still_take_the_hasher_boundary(fixtures):
    with pytest.raises(InvalidCredentialsError):
        fixtures.service.login(None, None)

    assert fixtures.hasher.calls[-1] == (None, FakePasswordHasher.dummy_hash)
    assert fixtures.sessions.created == []


def test_session_identity_rejects_a_missing_account(fixtures):
    login = fixtures.service.login("demo.owner", "owner-password")
    fixtures.accounts.by_id.pop("account-owner")

    with pytest.raises(UnauthorizedError) as error:
        fixtures.service.session_identity(login.token)

    assert error.value.code == "unauthorized"


def test_session_identity_rejects_a_tampered_persisted_token_hash(fixtures):
    login = fixtures.service.login("demo.owner", "owner-password")
    fixtures.sessions.created[0].token_hash = b"tampered"

    with pytest.raises(UnauthorizedError) as error:
        fixtures.service.session_identity(login.token)

    assert error.value.code == "unauthorized"


def test_session_identity_uses_the_current_server_identity_and_safe_payload(fixtures):
    login = fixtures.service.login("demo.owner", "owner-password")
    identity = fixtures.service.session_identity(login.token)

    assert identity.role == "owner"
    assert identity.active_group_id == "group-demo"
    assert identity.as_dict()["role"] == "owner"
    assert "token" not in identity.as_dict()
    assert identity["token"] == login.token


def test_session_expires_at_the_injected_clock_boundary(fixtures):
    login = fixtures.service.login("demo.owner", "owner-password")
    fixtures.clock.current = login.expires_at

    with pytest.raises(SessionExpiredError) as error:
        fixtures.service.session_identity(login.token)

    assert error.value.code == "session_expired"


def test_logout_revokes_the_current_session_and_validation_rejects_it(fixtures):
    login = fixtures.service.login("demo.owner", "owner-password")

    fixtures.clock.current += timedelta(minutes=5)
    fixtures.service.logout(login.token)

    assert fixtures.sessions.created[0].revoked_at == fixtures.clock.current
    with pytest.raises(UnauthorizedError) as error:
        fixtures.service.session_identity(login.token)
    assert error.value.code == "unauthorized"


def test_missing_and_malformed_tokens_are_unauthorized_without_account_lookup(
    fixtures,
):
    with pytest.raises(UnauthorizedError) as missing:
        fixtures.service.session_identity(None)
    with pytest.raises(UnauthorizedError) as malformed:
        fixtures.service.session_identity("")

    assert missing.value.code == malformed.value.code == "unauthorized"
    assert fixtures.accounts.by_id  # The fixture remains available for the boundary.
    assert fixtures.sessions.created == []
