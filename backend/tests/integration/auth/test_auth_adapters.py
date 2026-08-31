"""Integration coverage for the authentication persistence and security adapters."""

from datetime import datetime, timedelta
from hashlib import sha256
from uuid import uuid4

import pytest
from backend.app.adapters.db.repositories import (
    AccountRepositoryAdapter,
    MembershipRepositoryAdapter,
    SessionRepositoryAdapter,
)
from backend.app.adapters.db.tables import (
    Account,
    AuthSession,
    Base,
    Group,
    GroupMembership,
)
from backend.app.adapters.security.passwords import Argon2idPasswordHasher
from backend.app.adapters.security.sessions import OpaqueSessionTokenSource
from backend.app.application.auth_service import (
    AuthService,
    InvalidCredentialsError,
    SessionExpiredError,
    UnauthorizedError,
)
from backend.app.application.ports import SessionRecord
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session as OrmSession


def _sqlite_engine():
    engine = create_engine("sqlite://")

    @event.listens_for(engine, "connect")
    def _enable_foreign_keys(dbapi_connection, _connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    return engine


@pytest.fixture
def db_session():
    engine = _sqlite_engine()
    Base.metadata.create_all(engine)
    with OrmSession(engine) as session:
        yield session
    engine.dispose()


def _auth_fixture(session: OrmSession):
    owner = Account(
        id=uuid4(),
        login_name="demo.owner",
        password_hash="owner-hash",
        is_active=True,
    )
    member = Account(
        id=uuid4(),
        login_name="demo.member",
        password_hash="member-hash",
        is_active=True,
    )
    group = Group(
        id=uuid4(),
        name="Demo group",
        owner_account_id=owner.id,
    )
    session.add_all(
        [
            owner,
            member,
            group,
            GroupMembership(group_id=group.id, account_id=owner.id),
            GroupMembership(group_id=group.id, account_id=member.id),
        ]
    )
    session.commit()
    return owner, member, group


def test_owner_membership_is_persisted_and_active_memberships_are_server_records(
    db_session,
):
    owner, member, group = _auth_fixture(db_session)
    account_repository = AccountRepositoryAdapter(db_session)
    membership_repository = MembershipRepositoryAdapter(db_session)

    owner_membership = membership_repository.find_for_account(owner.id)
    member_membership = membership_repository.find_for_account_in_group(
        member.id, group.id
    )

    assert owner_membership is not None
    assert owner_membership.account_id == owner.id
    assert owner_membership.group_id == group.id
    assert owner_membership.owner_account_id == owner.id
    assert member_membership is not None
    assert member_membership.owner_account_id == owner.id
    assert membership_repository.owner_has_membership(group.id) is True
    assert account_repository.find_by_login_name("demo.member").id == member.id

    db_session.execute(
        Account.__table__.update()
        .where(Account.id == member.id)
        .values(is_active=False)
    )
    db_session.commit()
    assert membership_repository.find_for_account(member.id) is None


def test_session_repository_looks_up_only_the_sha256_token_hash_and_revokes(
    db_session,
):
    owner, _, _ = _auth_fixture(db_session)
    repository = SessionRepositoryAdapter(db_session)
    raw_token = "opaque-token-that-is-never-persisted"
    token_hash = sha256(raw_token.encode("utf-8")).digest()
    record = SessionRecord(
        id=uuid4(),
        token_hash=token_hash,
        account_id=owner.id,
        created_at=datetime(2026, 1, 1, 12),
        expires_at=datetime(2026, 1, 1, 13),
    )

    repository.create(record)
    persisted = repository.find_by_token_hash(token_hash)

    assert persisted is not None
    assert persisted.token_hash == token_hash
    assert raw_token not in repr(persisted)
    assert repository.find_by_token_hash(raw_token.encode("utf-8")) is None

    revoked_at = datetime(2026, 1, 1, 12, 30)
    repository.revoke_by_token_hash(token_hash, revoked_at)
    revoked = repository.find_by_token_hash(token_hash)
    assert revoked is not None
    assert revoked.revoked_at == revoked_at


def test_auth_service_rejects_expired_and_revoked_persisted_sessions(db_session):
    owner, _, group = _auth_fixture(db_session)
    account_repository = AccountRepositoryAdapter(db_session)
    session_repository = SessionRepositoryAdapter(db_session)
    membership_repository = MembershipRepositoryAdapter(db_session)
    token_source = OpaqueSessionTokenSource()
    current = datetime(2026, 1, 1, 12)

    class Clock:
        def now(self):
            return current

    class Hasher:
        dummy_hash = "dummy-hash"

        def verify(self, password, encoded_hash):
            return password == "correct" and encoded_hash == "owner-hash"

    service = AuthService(
        account_repository=account_repository,
        session_repository=session_repository,
        membership_repository=membership_repository,
        password_hasher=Hasher(),
        token_source=token_source,
        clock=Clock(),
        session_ttl=timedelta(hours=1),
    )

    login = service.login("demo.owner", "correct")
    assert login.active_group_id == group.id
    assert service.session_identity(login.token).role == "owner"

    current = login.expires_at
    with pytest.raises(SessionExpiredError):
        service.session_identity(login.token)

    current = datetime(2026, 1, 1, 12)
    login = service.login("demo.owner", "correct")
    service.logout(login.token)
    with pytest.raises(UnauthorizedError):
        service.session_identity(login.token)

    with pytest.raises(InvalidCredentialsError):
        service.login("demo.owner", "wrong")


def test_opaque_session_tokens_are_random_and_only_sha256_is_exposed_for_storage():
    source = OpaqueSessionTokenSource()
    first = source.generate()
    second = source.generate()

    assert first != second
    assert len(first) >= 40
    assert source.hash(first) == sha256(first.encode("utf-8")).digest()
    assert first.encode("utf-8") != source.hash(first)


def test_argon2id_verifies_correct_and_rejects_wrong_password():
    hasher = Argon2idPasswordHasher()
    encoded = hasher.hash("correct horse battery staple")

    assert encoded.startswith("$argon2id$")
    assert hasher.verify("correct horse battery staple", encoded) is True
    assert hasher.verify("wrong password", encoded) is False
    assert hasher.verify("wrong password", hasher.dummy_hash) is False


def test_argon2id_adapter_reports_unavailable_dependency_without_fallback(monkeypatch):
    import backend.app.adapters.security.passwords as password_module

    monkeypatch.setattr(password_module, "_Argon2PasswordHasher", None)
    monkeypatch.setattr(password_module, "_Argon2Type", None)

    with pytest.raises(RuntimeError, match="argon2-cffi"):
        Argon2idPasswordHasher()


def test_auth_tables_cascade_account_owned_sessions_and_memberships(db_session):
    owner, member, group = _auth_fixture(db_session)
    repository = SessionRepositoryAdapter(db_session)
    repository.create(
        SessionRecord(
            id=uuid4(),
            token_hash=sha256(b"cascade-token").digest(),
            account_id=member.id,
            created_at=datetime(2026, 1, 1),
            expires_at=datetime(2026, 1, 2),
        )
    )

    db_session.delete(member)
    db_session.commit()

    assert (
        db_session.query(GroupMembership)
        .filter_by(account_id=member.id, group_id=group.id)
        .one_or_none()
        is None
    )
    assert (
        db_session.query(AuthSession).filter_by(account_id=member.id).one_or_none()
        is None
    )
    assert db_session.get(Account, owner.id) is not None


def test_group_deletion_cascades_memberships(db_session):
    _, member, group = _auth_fixture(db_session)

    db_session.delete(group)
    db_session.commit()

    assert (
        db_session.query(GroupMembership)
        .filter_by(account_id=member.id, group_id=group.id)
        .one_or_none()
        is None
    )
