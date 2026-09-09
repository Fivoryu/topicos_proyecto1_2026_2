"""Add membership lifecycle state and active-account lookup support.

Revision ID: 0003_workspace
Revises: 0002_source

Existing memberships remain active because ``ended_at`` is nullable and defaults
implicitly to NULL. The new index supports account-scoped active-membership
lookups without changing the composite membership identity.
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0003_workspace"
down_revision = "0002_source"
branch_labels = None
depends_on = None


_ACTIVE_MEMBERSHIP_INDEX = "ix_group_memberships_account_active"


def upgrade() -> None:
    """Add nullable membership end state and its account lookup index."""

    op.add_column(
        "group_memberships",
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        _ACTIVE_MEMBERSHIP_INDEX,
        "group_memberships",
        ["account_id", "ended_at", "group_id"],
        unique=False,
    )


def downgrade() -> None:
    """Remove workspace membership lifecycle additions only."""

    op.drop_index(_ACTIVE_MEMBERSHIP_INDEX, table_name="group_memberships")
    op.drop_column("group_memberships", "ended_at")
