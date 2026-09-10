"""Persistence coverage for the additive multi-currency schema slice."""

from datetime import UTC, datetime
from decimal import Decimal
from importlib import import_module
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from backend.app.adapters.db.tables import Base, ExchangeRateCache, Expense
from sqlalchemy import create_engine, event, inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

MIGRATIONS = [
    import_module(f"backend.migrations.versions.000{i}_{name}")
    for i, name in (
        (1, "auth"),
        (2, "source"),
        (3, "workspace"),
        (4, "outing"),
        (5, "expense_outing"),
        (6, "join_codes"),
        (7, "multi_currency"),
    )
]
MIGRATION_0007 = MIGRATIONS[-1]


def _engine():
    engine = create_engine("sqlite://")

    @event.listens_for(engine, "connect")
    def _foreign_keys(connection, _record):
        cursor = connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    return engine


def _apply(connection, migration, direction="upgrade"):
    context = MigrationContext.configure(connection)
    setattr(migration, "op", Operations(context))
    getattr(migration, direction)()


def _apply_prior_migrations(connection):
    for migration in MIGRATIONS[:-1]:
        _apply(connection, migration)


def _legacy_fixture(connection):
    owner_id, group_id, participant_id, outing_id, expense_id = (
        str(uuid4()) for _ in range(5)
    )
    connection.execute(
        text(
            "INSERT INTO accounts (id, login_name, password_hash) "
            "VALUES (:id, :login_name, :password_hash)"
        ),
        {"id": owner_id, "login_name": "legacy-owner", "password_hash": "hash"},
    )
    connection.execute(
        text(
            "INSERT INTO groups (id, name, owner_account_id) "
            "VALUES (:id, :name, :owner_account_id)"
        ),
        {"id": group_id, "name": "Legacy group", "owner_account_id": owner_id},
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
            "INSERT INTO outings (id, group_id, name) "
            "VALUES (:id, :group_id, :name)"
        ),
        {"id": outing_id, "group_id": group_id, "name": "Legacy outing"},
    )
    created_at = "2026-01-02 03:04:05.000000"
    updated_at = "2026-01-03 04:05:06.000000"
    connection.execute(
        text(
            "INSERT INTO expenses "
            "(id, group_id, outing_id, description, amount_cents, "
            "created_at, updated_at) "
            "VALUES (:id, :group_id, :outing_id, :description, :amount_cents, "
            ":created_at, :updated_at)"
        ),
        {
            "id": expense_id,
            "group_id": group_id,
            "outing_id": outing_id,
            "description": "Legacy dinner",
            "amount_cents": 80000,
            "created_at": created_at,
            "updated_at": updated_at,
        },
    )
    connection.execute(
        text(
            "INSERT INTO expense_contributions "
            "(expense_id, participant_id, amount_cents) "
            "VALUES (:expense_id, :participant_id, :amount_cents)"
        ),
        {
            "expense_id": expense_id,
            "participant_id": participant_id,
            "amount_cents": 80000,
        },
    )
    connection.execute(
        text(
            "INSERT INTO expense_beneficiaries (expense_id, participant_id) "
            "VALUES (:expense_id, :participant_id)"
        ),
        {"expense_id": expense_id, "participant_id": participant_id},
    )
    return {
        "owner_id": owner_id,
        "group_id": group_id,
        "participant_id": participant_id,
        "outing_id": outing_id,
        "expense_id": expense_id,
        "created_at": created_at,
        "updated_at": updated_at,
    }


def test_revision_is_based_on_the_current_source_head():
    assert MIGRATION_0007.revision == "0007_multi_currency"
    assert MIGRATION_0007.down_revision == "0006_join_codes"


def test_migration_backfills_legacy_rows_without_changing_source_relationships():
    engine = _engine()
    with engine.connect() as connection:
        _apply_prior_migrations(connection)
        fixture = _legacy_fixture(connection)
        connection.commit()

        _apply(connection, MIGRATION_0007)
        row = connection.execute(
            text(
                "SELECT group_id, outing_id, description, amount_cents, created_at, "
                "updated_at, source_currency, usd_rate, rate_provider, "
                "rate_provenance, rate_observed_at, rate_frozen_at "
                "FROM expenses WHERE id = :id"
            ),
            {"id": fixture["expense_id"]},
        ).one()
        assert row[:6] == (
            fixture["group_id"],
            fixture["outing_id"],
            "Legacy dinner",
            80000,
            fixture["created_at"],
            fixture["updated_at"],
        )
        assert row[6:10] == (
            "USD",
            Decimal("1.000000000000000000"),
            "legacy",
            "legacy_migration",
        )
        assert row[10] == row[11]
        assert connection.execute(
            text(
                "SELECT participant_id, amount_cents FROM expense_contributions "
                "WHERE expense_id = :id"
            ),
            {"id": fixture["expense_id"]},
        ).one() == (fixture["participant_id"], 80000)
        assert connection.execute(
            text(
                "SELECT participant_id FROM expense_beneficiaries "
                "WHERE expense_id = :id"
            ),
            {"id": fixture["expense_id"]},
        ).one() == (fixture["participant_id"],)
        assert (
            connection.execute(
                text("SELECT COUNT(*) FROM exchange_rate_cache")
            ).scalar_one()
            == 0
        )

        before = connection.execute(
            text(
                "SELECT source_currency, usd_rate, rate_provider, rate_provenance, "
                "rate_observed_at, rate_frozen_at FROM expenses WHERE id = :id"
            ),
            {"id": fixture["expense_id"]},
        ).one()
        MIGRATION_0007.backfill_legacy_expenses(connection)
        after = connection.execute(
            text(
                "SELECT source_currency, usd_rate, rate_provider, rate_provenance, "
                "rate_observed_at, rate_frozen_at FROM expenses WHERE id = :id"
            ),
            {"id": fixture["expense_id"]},
        ).one()
        assert after == before
        assert (
            connection.execute(
                text("SELECT COUNT(*) FROM exchange_rate_cache")
            ).scalar_one()
            == 0
        )
    engine.dispose()


def test_partial_metadata_guard_does_not_rewrite_a_populated_expense():
    engine = _engine()
    with engine.connect() as connection:
        _apply_prior_migrations(connection)
        fixture = _legacy_fixture(connection)
        connection.commit()
        _apply(connection, MIGRATION_0007)
        connection.execute(
            text(
                "UPDATE expenses SET source_currency = 'EUR', "
                "usd_rate = CAST(:rate AS NUMERIC), "
                "rate_provider = 'manual', rate_provenance = 'manual' "
                "WHERE id = :id"
            ),
            {"rate": "1.234", "id": fixture["expense_id"]},
        )
        connection.commit()
        before = connection.execute(
            text(
                "SELECT source_currency, usd_rate, rate_provider, rate_provenance, "
                "rate_observed_at, rate_frozen_at FROM expenses WHERE id = :id"
            ),
            {"id": fixture["expense_id"]},
        ).one()
        MIGRATION_0007.backfill_legacy_expenses(
            connection, datetime(2030, 1, 1, tzinfo=UTC)
        )
        assert connection.execute(
            text(
                "SELECT source_currency, usd_rate, rate_provider, rate_provenance, "
                "rate_observed_at, rate_frozen_at FROM expenses WHERE id = :id"
            ),
            {"id": fixture["expense_id"]},
        ).one() == before
    engine.dispose()


def test_cache_and_expense_schema_have_explicit_rate_metadata_and_latest_index():
    engine = _engine()
    Base.metadata.create_all(engine)
    inspector = inspect(engine)
    expense_columns = {
        column["name"]: column for column in inspector.get_columns("expenses")
    }
    assert {
        "source_currency",
        "usd_rate",
        "rate_provider",
        "rate_provenance",
        "rate_observed_at",
        "rate_frozen_at",
    }.issubset(expense_columns)
    assert expense_columns["usd_rate"]["type"].precision == 30
    assert expense_columns["usd_rate"]["type"].scale == 18
    assert {
        "id",
        "source_currency",
        "quote_currency",
        "rate",
        "provider",
        "observed_at",
        "fetched_at",
        "valid",
    } == {column["name"] for column in inspector.get_columns("exchange_rate_cache")}
    assert "ix_exchange_rate_cache_latest_valid" in {
        index["name"] for index in inspector.get_indexes("exchange_rate_cache")
    }
    engine.dispose()


def test_orm_numeric_rates_round_trip_as_decimal_and_preserve_source_cents():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        cache = ExchangeRateCache(
            id=uuid4(),
            source_currency="BOB",
            quote_currency="USD",
            rate=Decimal("0.072000000000000001"),
            provider="frankfurter",
            observed_at=datetime(2026, 1, 1, tzinfo=UTC),
            fetched_at=datetime(2026, 1, 2, tzinfo=UTC),
            valid=True,
        )
        expense = Expense(
            id=uuid4(),
            group_id=uuid4(),
            description="Source money",
            amount_cents=10000,
            source_currency="BOB",
            usd_rate=Decimal("0.072000000000000001"),
            rate_provider="manual",
            rate_provenance="manual",
            rate_observed_at=datetime(2026, 1, 1, tzinfo=UTC),
            rate_frozen_at=datetime(2026, 1, 2, tzinfo=UTC),
        )
        session.add(cache)
        session.flush()
        assert session.get(ExchangeRateCache, cache.id).rate == Decimal(
            "0.072000000000000001"
        )
        assert expense.amount_cents == 10000
    engine.dispose()


def test_cache_checks_reject_unsupported_direction_provider_and_nonpositive_rate():
    engine = _engine()
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        for values in (
            {
                "source_currency": "USD",
                "quote_currency": "USD",
                "provider": "frankfurter",
                "rate": Decimal("1"),
            },
            {
                "source_currency": "BOB",
                "quote_currency": "EUR",
                "provider": "frankfurter",
                "rate": Decimal("1"),
            },
            {
                "source_currency": "BOB",
                "quote_currency": "USD",
                "provider": "other",
                "rate": Decimal("1"),
            },
            {
                "source_currency": "BOB",
                "quote_currency": "USD",
                "provider": "frankfurter",
                "rate": Decimal("0"),
            },
        ):
            session.add(
                ExchangeRateCache(
                    id=uuid4(),
                    observed_at=datetime(2026, 1, 1, tzinfo=UTC),
                    fetched_at=datetime(2026, 1, 1, tzinfo=UTC),
                    valid=True,
                    **values,
                )
            )
            with pytest.raises(IntegrityError):
                session.flush()
            session.rollback()
    engine.dispose()


def test_expense_keeps_nullable_same_group_outing_foreign_key_after_migration():
    engine = _engine()
    with engine.connect() as connection:
        _apply_prior_migrations(connection)
        _apply(connection, MIGRATION_0007)
        foreign_keys = inspect(connection).get_foreign_keys("expenses")
        outing_fk = next(
            item
            for item in foreign_keys
            if item["name"] == "fk_expenses_outing_group"
        )
        assert outing_fk["constrained_columns"] == ["outing_id", "group_id"]
        assert outing_fk["referred_columns"] == ["id", "group_id"]
        columns = {
            row[1]: row
            for row in connection.execute(text("PRAGMA table_info(expenses)"))
        }
        assert columns["outing_id"][3] == 0
    engine.dispose()
