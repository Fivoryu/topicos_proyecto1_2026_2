"""Integration coverage for source persistence and migration 0002."""

from datetime import datetime
from importlib import import_module
from pathlib import Path
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from backend.app.adapters.db.repositories import (
    ExpenseRepositoryAdapter,
    ParticipantRepositoryAdapter,
)
from backend.app.adapters.db.tables import (
    Account,
    Base,
    Expense,
    ExpenseBeneficiary,
    ExpenseContribution,
    Group,
    Participant,
)
from backend.app.adapters.db.uow import SqlAlchemyUnitOfWork
from backend.app.application.participant_service import ParticipantService
from backend.app.application.ports import ParticipantRecord
from sqlalchemy import create_engine, event, inspect
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

MIGRATION_0001 = import_module("backend.migrations.versions.0001_auth")
MIGRATION_0002 = import_module("backend.migrations.versions.0002_source")


def _engine(url="sqlite://"):
    engine = create_engine(url)

    @event.listens_for(engine, "connect")
    def _foreign_keys(dbapi_connection, _connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    return engine


def _auth_fixture(session):
    owner = Account(id=uuid4(), login_name="owner", password_hash="hash")
    group = Group(id=uuid4(), name="group", owner_account_id=owner.id)
    session.add_all([owner, group])
    session.commit()
    return group


def _participant(group_id, name, *, archived_at=None, created_at=None):
    return Participant(
        id=uuid4(),
        group_id=group_id,
        name=name,
        normalized_name=name.casefold(),
        archived_at=archived_at,
        created_at=created_at or datetime(2026, 1, 1),
    )


def test_source_tables_are_source_only_and_have_required_columns():
    engine = _engine()
    Base.metadata.create_all(engine)
    names = set(inspect(engine).get_table_names())

    assert {
        "groups",
        "participants",
        "expenses",
        "expense_contributions",
        "expense_beneficiaries",
    }.issubset(names)
    assert not {"balances", "transfers", "splits"}.intersection(names)
    assert {
        "amount_cents",
        "created_at",
        "updated_at",
    }.issubset({c["name"] for c in inspect(engine).get_columns("expenses")})
    engine.dispose()


def test_source_constraints_cover_names_positive_cents_and_cascade_restrict():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        group = _auth_fixture(session)
        first = _participant(group.id, "Ana")
        session.add(first)
        session.commit()
        archived_same_name = _participant(
            group.id, "Ana", archived_at=datetime(2026, 1, 2)
        )
        session.add(archived_same_name)
        with pytest.raises(IntegrityError):
            session.commit()
        session.rollback()

        expense = Expense(
            id=uuid4(),
            group_id=group.id,
            description="Lunch",
            amount_cents=1000,
        )
        session.add(expense)
        session.flush()
        session.add(
            ExpenseContribution(
                expense_id=expense.id,
                participant_id=first.id,
                amount_cents=1000,
            )
        )
        session.add(ExpenseBeneficiary(expense_id=expense.id, participant_id=first.id))
        session.commit()

        session.add(
            Expense(
                id=uuid4(),
                group_id=group.id,
                description="Invalid",
                amount_cents=0,
            )
        )
        with pytest.raises(IntegrityError):
            session.commit()
        session.rollback()
        session.add(
            ExpenseContribution(
                expense_id=expense.id,
                participant_id=first.id,
                amount_cents=0,
            )
        )
        with pytest.raises(IntegrityError):
            session.commit()
        session.rollback()

        session.delete(first)
        with pytest.raises(IntegrityError):
            session.commit()
        session.rollback()
        session.delete(expense)
        session.commit()
        assert session.get(ExpenseContribution, (expense.id, first.id)) is None
        assert session.get(ExpenseBeneficiary, (expense.id, first.id)) is None
    engine.dispose()


def test_domain_repositories_require_group_scope_and_reject_cross_group_children():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        first_group = _auth_fixture(session)
        second_owner = Account(id=uuid4(), login_name="other", password_hash="hash")
        second_group = Group(
            id=uuid4(), name="other group", owner_account_id=second_owner.id
        )
        second_participant = _participant(second_group.id, "Beto")
        session.add_all([second_owner, second_group, second_participant])
        session.commit()

        participants = ParticipantRepositoryAdapter(session)
        assert participants.find_by_id(first_group.id, second_participant.id) is None

        expenses = ExpenseRepositoryAdapter(session)
        with pytest.raises(ValueError, match="group"):
            expenses.create(
                first_group.id,
                Expense(
                    id=uuid4(),
                    group_id=first_group.id,
                    description="Cross-group",
                    amount_cents=100,
                ),
                [(second_participant.id, 100)],
                [second_participant.id],
            )
    engine.dispose()


def test_source_rows_survive_restart_and_name_updates_preserve_foreign_keys(
    tmp_path: Path,
):
    database = tmp_path / "restart.sqlite"
    engine = _engine(f"sqlite:///{database}")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        group = _auth_fixture(session)
        participant = _participant(group.id, "Ana")
        session.add(participant)
        expense = Expense(
            id=uuid4(), group_id=group.id, description="Lunch", amount_cents=1000
        )
        session.add(expense)
        session.flush()
        session.add_all(
            [
                ExpenseContribution(
                    expense_id=expense.id,
                    participant_id=participant.id,
                    amount_cents=1000,
                ),
                ExpenseBeneficiary(
                    expense_id=expense.id, participant_id=participant.id
                ),
            ]
        )
        session.commit()
        participant_id = participant.id
        expense_id = expense.id
    engine.dispose()

    restarted = _engine(f"sqlite:///{database}")
    with Session(restarted) as session:
        restored = session.get(Participant, participant_id)
        assert restored is not None
        restored.name = "Ana L."
        restored.normalized_name = "ana l."
        session.commit()
        assert session.get(ExpenseContribution, (expense_id, participant_id))
        assert session.get(ExpenseBeneficiary, (expense_id, participant_id))
    restarted.dispose()


def test_participant_service_and_uow_persist_only_group_scoped_changes():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        group = _auth_fixture(session)
        repository = ParticipantRepositoryAdapter(session)
        service = ParticipantService(repository, SqlAlchemyUnitOfWork(session=session))
        created = service.add(group.id, "  Ana  ")
        assert created.name == "Ana"
        assert repository.list_by_group(group.id)[0].id == created.id
        assert repository.find_by_id(uuid4(), created.id) is None

        record = ParticipantRecord(
            id=uuid4(),
            group_id=group.id,
            name="Beto",
            normalized_name="beto",
        )
        repository.create(group.id, record)
        session.commit()
        assert {row.name for row in repository.list_by_group(group.id)} == {
            "Ana",
            "Beto",
        }
    engine.dispose()


def test_migration_0002_round_trip_leaves_auth_then_base_is_empty():
    engine = _engine()
    with engine.connect() as connection:
        context = MigrationContext.configure(connection)
        setattr(MIGRATION_0001, "op", Operations(context))
        MIGRATION_0001.upgrade()
        context = MigrationContext.configure(connection)
        setattr(MIGRATION_0002, "op", Operations(context))
        MIGRATION_0002.upgrade()
        assert "participants" in inspect(connection).get_table_names()
        assert "balances" not in inspect(connection).get_table_names()

        context = MigrationContext.configure(connection)
        setattr(MIGRATION_0002, "op", Operations(context))
        MIGRATION_0002.downgrade()
        assert "participants" not in inspect(connection).get_table_names()
        assert "groups" in inspect(connection).get_table_names()

        context = MigrationContext.configure(connection)
        setattr(MIGRATION_0001, "op", Operations(context))
        MIGRATION_0001.downgrade()
        assert inspect(connection).get_table_names() == []
    engine.dispose()
