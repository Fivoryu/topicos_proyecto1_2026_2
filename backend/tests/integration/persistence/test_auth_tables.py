"""Persistence constraints and reversible migration coverage for auth tables."""

from datetime import datetime
from hashlib import sha256
from importlib import import_module
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from backend.app.adapters.db.tables import (
    Account,
    AuthSession,
    Base,
    Group,
    GroupMembership,
)
from sqlalchemy import create_engine, inspect
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

MIGRATION = import_module("backend.migrations.versions.0001_auth")


def test_auth_tables_expose_required_constraints_and_covering_indexes():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    inspector = inspect(engine)

    assert {"accounts", "groups", "group_memberships", "sessions"}.issubset(
        inspector.get_table_names()
    )
    account_columns = {column["name"] for column in inspector.get_columns("accounts")}
    assert {"login_name", "password_hash", "is_active"}.issubset(account_columns)

    membership_pk = inspector.get_pk_constraint("group_memberships")[
        "constrained_columns"
    ]
    assert membership_pk == ["group_id", "account_id"]
    membership_fks = inspector.get_foreign_keys("group_memberships")
    assert {fk["referred_table"] for fk in membership_fks} == {"accounts", "groups"}
    assert all(fk["options"].get("ondelete") == "CASCADE" for fk in membership_fks)

    session_columns = {column["name"] for column in inspector.get_columns("sessions")}
    assert {
        "token_hash",
        "account_id",
        "expires_at",
        "revoked_at",
    }.issubset(session_columns)
    session_fks = inspector.get_foreign_keys("sessions")
    assert session_fks[0]["options"].get("ondelete") == "CASCADE"
    indexes = {index["name"] for index in inspector.get_indexes("sessions")}
    assert {
        "ix_sessions_token_hash",
        "ix_sessions_account_id",
        "ix_sessions_expires_at",
        "ix_sessions_revoked_at",
    }.issubset(indexes)

    engine.dispose()


def test_unique_login_and_token_hash_constraints_are_enforced():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    token_hash = sha256(b"token-hash").digest()
    with Session(engine) as session:
        account = Account(id=uuid4(), login_name="duplicate", password_hash="hash")
        session.add(account)
        session.commit()
        session.add(Account(id=uuid4(), login_name="duplicate", password_hash="hash"))
        try:
            session.commit()
        except IntegrityError:
            session.rollback()
        else:
            raise AssertionError("login_name must be unique")

        session.add(
            AuthSession(
                id=uuid4(),
                token_hash=token_hash,
                account_id=account.id,
                expires_at=datetime(2026, 1, 1),
            )
        )
        session.commit()
        session.add(
            AuthSession(
                id=uuid4(),
                token_hash=token_hash,
                account_id=account.id,
                expires_at=datetime(2026, 1, 1),
            )
        )
        try:
            session.commit()
        except IntegrityError:
            session.rollback()
        else:
            raise AssertionError("token_hash must be unique")
    engine.dispose()


def test_migration_0001_upgrade_and_downgrade_round_trip():
    engine = create_engine("sqlite://")
    with engine.connect() as connection:
        migration_context = MigrationContext.configure(connection)
        MIGRATION.op = Operations(migration_context)
        MIGRATION.upgrade()
        assert set(inspect(connection).get_table_names()) == {
            "accounts",
            "groups",
            "group_memberships",
            "sessions",
        }

        migration_context = MigrationContext.configure(connection)
        MIGRATION.op = Operations(migration_context)
        MIGRATION.downgrade()
        assert inspect(connection).get_table_names() == []
    engine.dispose()


def test_owner_membership_invariant_is_visible_in_persisted_rows():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        group = Group(id=uuid4(), name="group", owner_account_id=owner.id)
        session.add_all([owner, group])
        session.commit()

        assert (
            session.query(GroupMembership)
            .filter_by(group_id=group.id, account_id=owner.id)
            .one_or_none()
            is None
        )
        session.add(GroupMembership(group_id=group.id, account_id=owner.id))
        session.commit()
        assert (
            session.query(GroupMembership)
            .filter_by(group_id=group.id, account_id=owner.id)
            .one_or_none()
            is not None
        )
    engine.dispose()


def test_session_token_hash_must_be_a_sha256_digest():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        account = Account(id=uuid4(), login_name="hash-length", password_hash="hash")
        session.add(account)
        session.commit()
        session.add(
            AuthSession(
                id=uuid4(),
                token_hash=b"too-short",
                account_id=account.id,
                expires_at=datetime(2026, 1, 1),
            )
        )
        with pytest.raises(IntegrityError):
            session.commit()
    engine.dispose()
