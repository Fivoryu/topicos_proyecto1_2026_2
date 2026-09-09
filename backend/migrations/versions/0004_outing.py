"""Add group-owned outing source records.

Revision ID: 0004_outing
Revises: 0003_workspace
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0004_outing"
down_revision = "0003_workspace"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create the active/archived outing source table."""

    op.create_table(
        "outings",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("group_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.CheckConstraint("length(trim(name)) > 0", name="ck_outings_name_nonempty"),
        sa.ForeignKeyConstraint(
            ["group_id"],
            ["groups.id"],
            name="fk_outings_group",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_outings"),
        sa.UniqueConstraint("id", "group_id", name="uq_outings_id_group_id"),
    )
    op.create_index("ix_outings_group_id", "outings", ["group_id"])
    op.create_index(
        "ix_outings_group_created", "outings", ["group_id", "created_at", "id"]
    )


def downgrade() -> None:
    """Drop only outing source data in disposable environments."""

    op.drop_index("ix_outings_group_created", table_name="outings")
    op.drop_index("ix_outings_group_id", table_name="outings")
    op.drop_table("outings")
