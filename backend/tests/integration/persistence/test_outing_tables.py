from datetime import UTC, datetime
from importlib import import_module
from uuid import UUID, uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from backend.app.adapters.db.repositories import OutingRepositoryAdapter
from backend.app.adapters.db.tables import Account, Base, Expense, Group, Outing
from backend.app.adapters.db.uow import SqlAlchemyUnitOfWork
from backend.app.application.ports import OutingRecord
from sqlalchemy import create_engine, event, inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

MIGRATIONS = [
    import_module("backend.migrations.versions.0001_auth"),
    import_module("backend.migrations.versions.0002_source"),
    import_module("backend.migrations.versions.0003_workspace"),
    import_module("backend.migrations.versions.0004_outing"),
    import_module("backend.migrations.versions.0005_expense_outing"),
]


def _engine():
    engine = create_engine("sqlite://")

    @event.listens_for(engine, "connect")
    def _foreign_keys(connection, _record):
        cursor = connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    return engine


def test_outing_table_has_group_lifecycle_shape_and_group_index():
    engine = _engine()
    Base.metadata.create_all(engine)
    table = inspect(engine)
    columns = {column["name"] for column in table.get_columns("outings")}
    indexes = {index["name"] for index in table.get_indexes("outings")}

    assert columns == {
        "id",
        "group_id",
        "name",
        "archived_at",
        "created_at",
        "updated_at",
    }
    assert "ix_outings_group_created" in indexes
    assert "uq_outings_id_group_id" in {
        item["name"] for item in table.get_unique_constraints("outings")
    }
    assert Outing.__table__.c.group_id.foreign_keys
    assert Outing.__table__.c.archived_at.nullable
    assert getattr(Outing.__table__.c.created_at.type, "timezone", False) is True
    assert getattr(Outing.__table__.c.updated_at.type, "timezone", False) is True
    engine.dispose()


def test_outing_repository_preserves_group_scope_and_rejects_blank_names():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        group = Group(id=uuid4(), name="Trip", owner_account_id=owner.id)
        other = Group(id=uuid4(), name="Other", owner_account_id=owner.id)
        session.add_all([owner, group, other])
        session.commit()
        repository = OutingRepositoryAdapter(session)
        outing = repository.create(
            group.id,
            OutingRecord(id=uuid4(), group_id=str(group.id), name="Weekend"),
        )
        assert outing.created_at.tzinfo is UTC
        assert outing.updated_at.tzinfo is UTC
        session.commit()

        assert [row.name for row in repository.list_by_group(str(group.id))] == [
            "Weekend"
        ]
        assert repository.list_by_group(other.id) == []
        assert repository.find_by_id(other.id, outing.id) is None
        session.add(Outing(id=uuid4(), group_id=group.id, name="   "))
        with pytest.raises(IntegrityError):
            session.commit()
    engine.dispose()


def test_outing_repository_orders_by_created_at_and_id():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        group = Group(id=uuid4(), name="Trip", owner_account_id=owner.id)
        session.add_all([owner, group])
        session.commit()
        repository = OutingRepositoryAdapter(session)
        created_at = datetime(2026, 1, 1, tzinfo=UTC)
        second = repository.create(
            group.id,
            OutingRecord(
                id=UUID("00000000-0000-0000-0000-000000000002"),
                group_id=str(group.id),
                name="Second",
                created_at=created_at,
                updated_at=created_at,
            ),
        )
        first = repository.create(
            group.id,
            OutingRecord(
                id=UUID("00000000-0000-0000-0000-000000000001"),
                group_id=str(group.id),
                name="First",
                created_at=created_at,
                updated_at=created_at,
            ),
        )
        session.commit()

        assert [row.id for row in repository.list_by_group(group.id)] == [
            first.id,
            second.id,
        ]
    engine.dispose()


def test_outing_repository_deletes_empty_rows_but_preserves_linked_history():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
        group = Group(id=uuid4(), name="Trip", owner_account_id=owner.id)
        session.add_all([owner, group])
        session.commit()
        repository = OutingRepositoryAdapter(session)
        empty = repository.create(
            group.id, OutingRecord(id=uuid4(), group_id=group.id, name="Empty")
        )
        linked = repository.create(
            group.id, OutingRecord(id=uuid4(), group_id=group.id, name="Linked")
        )
        session.add(
            Expense(
                id=uuid4(),
                group_id=group.id,
                outing_id=linked.id,
                description="Dinner",
                amount_cents=100,
            )
        )
        session.flush()

        assert repository.has_expenses(group.id, linked.id) is True
        assert repository.delete_if_empty(group.id, linked.id) is False
        assert repository.find_by_id(group.id, linked.id) is not None
        assert repository.has_expenses(group.id, empty.id) is False
        assert repository.delete_if_empty(group.id, empty.id) is True
        session.commit()
        assert repository.find_by_id(group.id, empty.id) is None
        assert repository.find_by_id(group.id, linked.id) is not None
    engine.dispose()


def test_uow_exposes_group_scoped_outing_repository():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        with SqlAlchemyUnitOfWork(session=session) as unit_of_work:
            assert isinstance(unit_of_work.outings, OutingRepositoryAdapter)
    engine.dispose()


def test_0005_migration_round_trip_preserves_existing_expense_rows():
    engine = _engine()
    with engine.connect() as connection:
        for migration in MIGRATIONS:
            context = MigrationContext.configure(connection)
            setattr(migration, "op", Operations(context))
            migration.upgrade()
        columns = {
            column["name"] for column in inspect(connection).get_columns("expenses")
        }
        assert "outing_id" in columns
        indexes = {
            index["name"] for index in inspect(connection).get_indexes("expenses")
        }
        assert "ix_expenses_group_outing" in indexes

        context = MigrationContext.configure(connection)
        migration = MIGRATIONS[-1]
        setattr(migration, "op", Operations(context))
        migration.downgrade()
        assert "outing_id" not in {
            column["name"] for column in inspect(connection).get_columns("expenses")
        }
        assert "expenses" in inspect(connection).get_table_names()
    engine.dispose()


def test_0004_migration_round_trip_preserves_prior_tables():
    engine = _engine()
    with engine.connect() as connection:
        for migration in MIGRATIONS[:-1]:
            context = MigrationContext.configure(connection)
            setattr(migration, "op", Operations(context))
            migration.upgrade()
        assert "outings" in inspect(connection).get_table_names()
        assert "groups" in inspect(connection).get_table_names()

        context = MigrationContext.configure(connection)
        migration = MIGRATIONS[-2]
        setattr(migration, "op", Operations(context))
        migration.downgrade()
        assert "outings" not in inspect(connection).get_table_names()
        assert "groups" in inspect(connection).get_table_names()
    engine.dispose()


def test_0005_upgrade_survives_existing_general_expense_rows():
    engine = _engine()
    owner_id = str(uuid4())
    group_id = str(uuid4())
    participant_id = str(uuid4())
    expense_id = str(uuid4())
    with engine.connect() as connection:
        for migration in MIGRATIONS[:2]:
            context = MigrationContext.configure(connection)
            setattr(migration, "op", Operations(context))
            migration.upgrade()

        connection.execute(
            text(
                "INSERT INTO accounts (id, login_name, password_hash) "
                "VALUES (:id, :login_name, :password_hash)"
            ),
            {"id": owner_id, "login_name": "migration-owner", "password_hash": "hash"},
        )
        connection.execute(
            text(
                "INSERT INTO groups (id, name, owner_account_id) "
                "VALUES (:id, :name, :owner_account_id)"
            ),
            {"id": group_id, "name": "Migration group", "owner_account_id": owner_id},
        )
        connection.execute(
            text(
                "INSERT INTO group_memberships (group_id, account_id) "
                "VALUES (:group_id, :account_id)"
            ),
            {"group_id": group_id, "account_id": owner_id},
        )
        connection.execute(
            text(
                "INSERT INTO participants "
                "(id, group_id, name, normalized_name) "
                "VALUES (:id, :group_id, :name, :normalized_name)"
            ),
            {
                "id": participant_id,
                "group_id": group_id,
                "name": "Ana",
                "normalized_name": "ana",
            },
        )
        connection.execute(
            text(
                "INSERT INTO expenses "
                "(id, group_id, description, amount_cents) "
                "VALUES (:id, :group_id, :description, :amount_cents)"
            ),
            {
                "id": expense_id,
                "group_id": group_id,
                "description": "Existing general",
                "amount_cents": 100,
            },
        )
        connection.commit()

        for migration in MIGRATIONS[2:]:
            context = MigrationContext.configure(connection)
            setattr(migration, "op", Operations(context))
            migration.upgrade()
        row = connection.execute(
            text(
                "SELECT description, amount_cents, outing_id "
                "FROM expenses WHERE id = :id"
            ),
            {"id": expense_id},
        ).one()
        assert tuple(row) == ("Existing general", 100, None)

        migration = MIGRATIONS[-1]
        context = MigrationContext.configure(connection)
        setattr(migration, "op", Operations(context))
        migration.downgrade()
        row = connection.execute(
            text("SELECT description, amount_cents FROM expenses WHERE id = :id"),
            {"id": expense_id},
        ).one()
        assert tuple(row) == ("Existing general", 100)
    engine.dispose()
