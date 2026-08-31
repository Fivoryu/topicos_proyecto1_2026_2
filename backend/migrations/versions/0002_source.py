"""Create the source tables for participants and expenses.

Revision ID: 0002_source
Revises: 0001_auth

Balances, splits, and transfers are deliberately derived and have no tables.
The downgrade removes only source tables, leaving the auth foundation intact.
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0002_source"
down_revision = "0001_auth"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create group-scoped participants and expense source rows."""

    op.create_table(
        "participants",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("group_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("normalized_name", sa.String(length=255), nullable=False),
        sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "length(trim(name)) > 0", name="ck_participants_name_nonempty"
        ),
        sa.ForeignKeyConstraint(
            ["group_id"],
            ["groups.id"],
            name="fk_participants_group",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_participants"),
        sa.UniqueConstraint(
            "group_id", "normalized_name", name="uq_participants_group_name"
        ),
    )
    op.create_index("ix_participants_group_id", "participants", ["group_id"])
    op.create_index(
        "ix_participants_group_created",
        "participants",
        ["group_id", "created_at", "id"],
    )

    op.create_table(
        "expenses",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("group_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("description", sa.String(length=500), nullable=False),
        sa.Column("amount_cents", sa.Integer(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.CheckConstraint("amount_cents > 0", name="ck_expenses_amount_positive"),
        sa.ForeignKeyConstraint(
            ["group_id"], ["groups.id"], name="fk_expenses_group", ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id", name="pk_expenses"),
    )
    op.create_index(
        "ix_expenses_group_created", "expenses", ["group_id", "created_at", "id"]
    )

    op.create_table(
        "expense_contributions",
        sa.Column("expense_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("participant_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("amount_cents", sa.Integer(), nullable=False),
        sa.CheckConstraint("amount_cents > 0", name="ck_contributions_amount_positive"),
        sa.ForeignKeyConstraint(
            ["expense_id"],
            ["expenses.id"],
            name="fk_contributions_expense",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["participant_id"],
            ["participants.id"],
            name="fk_contributions_participant",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint(
            "expense_id", "participant_id", name="pk_expense_contributions"
        ),
    )
    op.create_index(
        "ix_expense_contributions_participant",
        "expense_contributions",
        ["participant_id"],
    )

    op.create_table(
        "expense_beneficiaries",
        sa.Column("expense_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("participant_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["expense_id"],
            ["expenses.id"],
            name="fk_beneficiaries_expense",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["participant_id"],
            ["participants.id"],
            name="fk_beneficiaries_participant",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint(
            "expense_id", "participant_id", name="pk_expense_beneficiaries"
        ),
    )
    op.create_index(
        "ix_expense_beneficiaries_participant",
        "expense_beneficiaries",
        ["participant_id"],
    )


def downgrade() -> None:
    """Drop source tables in dependency order; auth data remains."""

    op.drop_index(
        "ix_expense_beneficiaries_participant", table_name="expense_beneficiaries"
    )
    op.drop_table("expense_beneficiaries")
    op.drop_index(
        "ix_expense_contributions_participant", table_name="expense_contributions"
    )
    op.drop_table("expense_contributions")
    op.drop_index("ix_expenses_group_created", table_name="expenses")
    op.drop_table("expenses")
    op.drop_index("ix_participants_group_created", table_name="participants")
    op.drop_index("ix_participants_group_id", table_name="participants")
    op.drop_table("participants")
