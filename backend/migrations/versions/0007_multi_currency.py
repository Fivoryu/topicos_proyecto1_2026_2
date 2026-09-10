"""Add expense currency metadata, a rate cache, and legacy USD backfill.

Revision ID: 0007_multi_currency
Revises: 0006_join_codes
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal

import sqlalchemy as sa
from alembic import op

revision = "0007_multi_currency"
down_revision = "0006_join_codes"
branch_labels = None
depends_on = None

_RATE = sa.Numeric(30, 18, asdecimal=True)
_DT = sa.DateTime(timezone=True)
_EXPENSE_COLUMNS = (
    sa.Column("source_currency", sa.CHAR(3)),
    sa.Column("usd_rate", _RATE),
    sa.Column("rate_provider", sa.String(32)),
    sa.Column("rate_provenance", sa.String(32)),
    sa.Column("rate_observed_at", _DT),
    sa.Column("rate_frozen_at", _DT),
)
_EXPENSE_CHECKS = (
    (
        "ck_expenses_source_currency_supported",
        "source_currency IN ('USD', 'BOB', 'EUR')",
    ),
    ("ck_expenses_usd_rate_positive", "usd_rate > 0"),
    (
        "ck_expenses_rate_provider_supported",
        "rate_provider IN ('system', 'frankfurter', 'manual', 'legacy')",
    ),
    (
        "ck_expenses_rate_provenance_supported",
        "rate_provenance IN ('usd_identity', 'frankfurter_current', "
        "'stored_fallback', 'manual', 'legacy_migration')",
    ),
    (
        "ck_expenses_rate_provider_provenance",
        "(rate_provider = 'system' AND rate_provenance = 'usd_identity') OR "
        "(rate_provider = 'frankfurter' AND rate_provenance IN "
        "('frankfurter_current', 'stored_fallback')) OR "
        "(rate_provider = 'manual' AND rate_provenance = 'manual') OR "
        "(rate_provider = 'legacy' AND rate_provenance = 'legacy_migration')",
    ),
)
_CACHE_CHECKS = (
    (
        "ck_exchange_rate_cache_source_currency_supported",
        "source_currency IN ('BOB', 'EUR')",
    ),
    ("ck_exchange_rate_cache_quote_currency_usd", "quote_currency = 'USD'"),
    ("ck_exchange_rate_cache_rate_positive", "rate > 0"),
    ("ck_exchange_rate_cache_provider_frankfurter", "provider = 'frankfurter'"),
)
_CACHE_INDEX = "ix_exchange_rate_cache_latest_valid"


def _sqlite_expense_recreate(callback) -> None:
    """Keep child rows when SQLite drops the parent during batch recreation."""

    bind = op.get_bind()
    contributions = list(
        bind.execute(
            sa.text(
                "SELECT expense_id, participant_id, amount_cents "
                "FROM expense_contributions"
            )
        ).mappings()
    )
    beneficiaries = list(
        bind.execute(
            sa.text("SELECT expense_id, participant_id FROM expense_beneficiaries")
        ).mappings()
    )
    callback()
    if contributions:
        bind.execute(
            sa.text(
                "INSERT INTO expense_contributions "
                "(expense_id, participant_id, amount_cents) "
                "VALUES (:expense_id, :participant_id, :amount_cents)"
            ),
            contributions,
        )
    if beneficiaries:
        bind.execute(
            sa.text(
                "INSERT INTO expense_beneficiaries (expense_id, participant_id) "
                "VALUES (:expense_id, :participant_id)"
            ),
            beneficiaries,
        )


def backfill_legacy_expenses(bind, migration_timestamp: datetime | None = None) -> None:
    """Fill only completely empty metadata with one UTC timestamp."""

    timestamp = migration_timestamp or datetime.now(UTC)
    statement = sa.text(
        "UPDATE expenses SET source_currency = 'USD', usd_rate = :rate, "
        "rate_provider = 'legacy', rate_provenance = 'legacy_migration', "
        "rate_observed_at = :timestamp, rate_frozen_at = :timestamp "
        "WHERE source_currency IS NULL AND usd_rate IS NULL "
        "AND rate_provider IS NULL AND rate_provenance IS NULL "
        "AND rate_observed_at IS NULL AND rate_frozen_at IS NULL"
    ).bindparams(
        sa.bindparam("rate", type_=_RATE),
        sa.bindparam("timestamp", type_=_DT),
    )
    bind.execute(statement, {"rate": Decimal("1"), "timestamp": timestamp})


def _add_expense_metadata() -> None:
    bind = op.get_bind()

    def change():
        with op.batch_alter_table("expenses", recreate="always") as batch:
            for column in _EXPENSE_COLUMNS:
                batch.add_column(column.copy(nullable=True))
            for name, condition in _EXPENSE_CHECKS:
                batch.create_check_constraint(name, condition)

    if bind.dialect.name == "sqlite":
        _sqlite_expense_recreate(change)
    else:
        for column in _EXPENSE_COLUMNS:
            op.add_column("expenses", column.copy(nullable=True))
        for name, condition in _EXPENSE_CHECKS:
            op.create_check_constraint(name, "expenses", condition)


def _require_expense_metadata() -> None:
    bind = op.get_bind()
    names = (column.name for column in _EXPENSE_COLUMNS)

    def change():
        with op.batch_alter_table("expenses", recreate="always") as batch:
            for name in names:
                batch.alter_column(name, nullable=False)

    if bind.dialect.name == "sqlite":
        _sqlite_expense_recreate(change)
    else:
        for name in names:
            op.alter_column("expenses", name, nullable=False)


def _drop_expense_metadata() -> None:
    bind = op.get_bind()
    names = tuple(column.name for column in _EXPENSE_COLUMNS)

    def change():
        with op.batch_alter_table("expenses", recreate="always") as batch:
            for name, _ in _EXPENSE_CHECKS:
                batch.drop_constraint(name, type_="check")
            for name in reversed(names):
                batch.drop_column(name)

    if bind.dialect.name == "sqlite":
        _sqlite_expense_recreate(change)
    else:
        for name, _ in _EXPENSE_CHECKS:
            op.drop_constraint(name, "expenses", type_="check")
        for name in reversed(names):
            op.drop_column("expenses", name)


def upgrade() -> None:
    _add_expense_metadata()
    backfill_legacy_expenses(op.get_bind())
    _require_expense_metadata()
    op.create_table(
        "exchange_rate_cache",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("source_currency", sa.CHAR(3), nullable=False),
        sa.Column("quote_currency", sa.CHAR(3), nullable=False),
        sa.Column("rate", _RATE, nullable=False),
        sa.Column("provider", sa.String(32), nullable=False),
        sa.Column("observed_at", _DT, nullable=False),
        sa.Column("fetched_at", _DT, nullable=False),
        sa.Column(
            "valid", sa.Boolean(), server_default=sa.text("true"), nullable=False
        ),
        *(
            sa.CheckConstraint(condition, name=name)
            for name, condition in _CACHE_CHECKS
        ),
        sa.PrimaryKeyConstraint("id", name="pk_exchange_rate_cache"),
    )
    op.create_index(
        _CACHE_INDEX,
        "exchange_rate_cache",
        [
            "source_currency",
            "quote_currency",
            "valid",
            sa.text("observed_at DESC"),
            sa.text("fetched_at DESC"),
        ],
    )


def downgrade() -> None:
    op.drop_index(_CACHE_INDEX, table_name="exchange_rate_cache")
    op.drop_table("exchange_rate_cache")
    _drop_expense_metadata()
