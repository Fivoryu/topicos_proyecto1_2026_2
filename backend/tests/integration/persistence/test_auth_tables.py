"""Persistence constraints and reversible migration coverage for auth tables."""

from datetime import datetime
from hashlib import sha256
from importlib import import_module
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from backend.app.adapters.db.repositories import (
    AccountParticipantLinkRepositoryAdapter,
    GroupRepositoryAdapter,
    MembershipRepositoryAdapter,
)
from backend.app.adapters.db.tables import (
    Account,
    AccountParticipantLink,
    AuthSession,
    Base,
    Group,
    GroupMembership,
    Participant,
)
from backend.app.adapters.db.uow import SqlAlchemyUnitOfWork
from backend.app.application.workspace_service import WorkspaceGroupRecord
from sqlalchemy import create_engine, event, inspect
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
    assert all(
        (fk.get("options") or {}).get("ondelete") == "CASCADE" for fk in membership_fks
    )

    session_columns = {column["name"] for column in inspector.get_columns("sessions")}
    assert {
        "token_hash",
        "account_id",
        "expires_at",
        "revoked_at",
    }.issubset(session_columns)
    session_fks = inspector.get_foreign_keys("sessions")
    assert (session_fks[0].get("options") or {}).get("ondelete") == "CASCADE"
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
        setattr(MIGRATION, "op", Operations(migration_context))
        MIGRATION.upgrade()
        assert set(inspect(connection).get_table_names()) == {
            "accounts",
            "groups",
            "group_memberships",
            "sessions",
        }

        migration_context = MigrationContext.configure(connection)
        setattr(MIGRATION, "op", Operations(migration_context))
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


def test_group_membership_exposes_active_history_column_and_index():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    inspector = inspect(engine)

    membership_columns = {
        column["name"]: column for column in inspector.get_columns("group_memberships")
    }
    assert membership_columns["ended_at"]["nullable"] is True
    active_index = next(
        index
        for index in inspector.get_indexes("group_memberships")
        if index["name"] == "ix_group_memberships_account_active"
    )
    assert active_index["column_names"] == ["account_id", "ended_at", "group_id"]

    engine.dispose()


def test_migration_0003_upgrade_and_downgrade_preserve_source_shape():
    migration_0002 = import_module("backend.migrations.versions.0002_source")
    migration_0003 = import_module("backend.migrations.versions.0003_workspace")
    engine = create_engine("sqlite://")
    with engine.connect() as connection:
        migration_context = MigrationContext.configure(connection)
        setattr(MIGRATION, "op", Operations(migration_context))
        MIGRATION.upgrade()

        migration_context = MigrationContext.configure(connection)
        setattr(migration_0002, "op", Operations(migration_context))
        migration_0002.upgrade()

        migration_context = MigrationContext.configure(connection)
        setattr(migration_0003, "op", Operations(migration_context))
        migration_0003.upgrade()
        inspector = inspect(connection)
        membership_columns = {
            column["name"] for column in inspector.get_columns("group_memberships")
        }
        assert "ended_at" in membership_columns
        assert {
            index["name"] for index in inspector.get_indexes("group_memberships")
        } >= {"ix_group_memberships_account_active"}

        migration_context = MigrationContext.configure(connection)
        setattr(migration_0003, "op", Operations(migration_context))
        migration_0003.downgrade()
        inspector = inspect(connection)
        membership_columns = {
            column["name"] for column in inspector.get_columns("group_memberships")
        }
        assert "ended_at" not in membership_columns
        assert "ix_group_memberships_account_active" not in {
            index["name"] for index in inspector.get_indexes("group_memberships")
        }
        assert "ix_group_memberships_account_id" in {
            index["name"] for index in inspector.get_indexes("group_memberships")
        }
    engine.dispose()


def test_group_repository_creates_workspace_record_without_committing():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        session.add(owner)
        session.commit()
        group_id = uuid4()
        repository = GroupRepositoryAdapter(session)
        commits = []

        def record_commit(_session):
            commits.append(True)

        event.listen(session, "after_commit", record_commit)
        created = repository.create(
            WorkspaceGroupRecord(
                id=group_id,
                name="Weekend away",
                owner_account_id=owner.id,
                role="owner",
            )
        )

        assert isinstance(created, Group)
        assert created.id == group_id
        assert created.name == "Weekend away"
        assert created.owner_account_id == owner.id
        assert session.get(Group, group_id) is created
        assert commits == []

        session.rollback()
        event.remove(session, "after_commit", record_commit)

    with Session(engine) as session:
        assert session.get(Group, group_id) is None
    engine.dispose()


def test_group_repository_accepts_orm_group_without_committing():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        session.add(owner)
        session.commit()
        group = Group(id=uuid4(), name="ORM trip", owner_account_id=owner.id)
        repository = GroupRepositoryAdapter(session)

        created = repository.create(group)

        assert created is group
        assert session.get(Group, group.id) is group
        session.rollback()

    with Session(engine) as session:
        assert session.get(Group, group.id) is None
    engine.dispose()


def test_membership_repository_lists_only_active_memberships_and_derives_owner():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        member = Account(id=uuid4(), login_name="member", password_hash="hash")
        first_group = Group(id=uuid4(), name="first", owner_account_id=owner.id)
        second_group = Group(id=uuid4(), name="second", owner_account_id=owner.id)
        session.add_all(
            [
                owner,
                member,
                first_group,
                second_group,
                GroupMembership(group_id=first_group.id, account_id=member.id),
                GroupMembership(
                    group_id=second_group.id,
                    account_id=member.id,
                    ended_at=datetime(2026, 1, 2),
                ),
            ]
        )
        session.commit()

        repository = MembershipRepositoryAdapter(session)
        memberships = repository.list_for_account(member.id)

        assert [membership.group_id for membership in memberships] == [first_group.id]
        assert memberships[0].account_id == member.id
        assert memberships[0].owner_account_id == owner.id
        history = repository.list_for_account(member.id, active_only=False)
        assert [membership.group_id for membership in history] == [
            first_group.id,
            second_group.id,
        ]
        assert history[1].ended_at == datetime(2026, 1, 2)
        assert repository.find_for_account_in_group(member.id, second_group.id) is None
        assert (
            repository.find_active_by_group_account(second_group.id, member.id) is None
        )
    engine.dispose()


def test_membership_repository_creates_ends_and_reactivates_memberships():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        member = Account(id=uuid4(), login_name="member", password_hash="hash")
        group = Group(id=uuid4(), name="group", owner_account_id=owner.id)
        session.add_all([owner, member, group])
        session.commit()
        repository = MembershipRepositoryAdapter(session)

        created = repository.create_or_reactivate(group.id, member.id)
        session.commit()
        assert created.group_id == group.id
        assert created.account_id == member.id
        assert created.ended_at is None
        assert repository.count_active_owners(group.id) == 0

        ended_at = datetime(2026, 1, 3)
        assert repository.end(group.id, member.id, ended_at) is True
        session.commit()
        assert repository.find_active_by_group_account(group.id, member.id) is None

        reactivated = repository.create_or_reactivate(group.id, member.id)
        session.commit()
        assert reactivated.group_id == group.id
        assert reactivated.account_id == member.id
        assert reactivated.ended_at is None
        with pytest.raises(ValueError, match="already active"):
            repository.create_or_reactivate(group.id, member.id)
        persisted = session.get(GroupMembership, (group.id, member.id))
        assert persisted is not None
        assert persisted.ended_at is None
    engine.dispose()


def test_unit_of_work_exposes_memberships_in_the_transaction():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        group = Group(id=uuid4(), name="group", owner_account_id=owner.id)
        session.add_all([owner, group])
        session.commit()
        group_id = group.id
        owner_id = owner.id

    def session_factory():
        return Session(engine)

    with SqlAlchemyUnitOfWork(session_factory=session_factory) as unit_of_work:
        assert unit_of_work.memberships is not None
        created = unit_of_work.memberships.create_or_reactivate(group_id, owner_id)
        found = unit_of_work.memberships.find_active_by_group_account(
            group_id, owner_id
        )
        assert found is not None
        assert found.group_id == created.group_id

    with Session(engine) as session:
        assert session.get(GroupMembership, (group_id, owner_id)) is not None
    engine.dispose()


def test_active_member_listing_and_link_end_preserve_history():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        member = Account(id=uuid4(), login_name="member", password_hash="hash")
        group = Group(id=uuid4(), name="group", owner_account_id=owner.id)
        participant = Participant(
            id=uuid4(), group_id=group.id, name="Member", normalized_name="member"
        )
        link = AccountParticipantLink(
            group_id=group.id, account_id=member.id, participant_id=participant.id
        )
        session.add_all([
            owner,
            member,
            group,
            participant,
            GroupMembership(group_id=group.id, account_id=owner.id),
            GroupMembership(group_id=group.id, account_id=member.id),
            link,
        ])
        session.commit()
        memberships = MembershipRepositoryAdapter(session)
        links = AccountParticipantLinkRepositoryAdapter(session)
        listed = memberships.list_active_by_group(group.id)
        assert {row.account_id for row in listed} == {owner.id, member.id}
        assert next(row for row in listed if row.account_id == member.id).participant_id == participant.id  # noqa: E501
        ended_at = datetime(2026, 1, 4)
        assert memberships.end(group.id, member.id, ended_at)
        assert links.end(group.id, member.id, ended_at)
        session.commit()
        assert [row.account_id for row in memberships.list_active_by_group(group.id)] == [owner.id]  # noqa: E501
        assert (
            session.get(GroupMembership, (group.id, member.id)).ended_at
            == session.get(AccountParticipantLink, (group.id, member.id)).ended_at
            == ended_at
        )
        assert session.get(Participant, participant.id) is not None
