"""Add nullable, same-group expense outing associations.

Revision ID: 0005_expense_outing
Revises: 0004_outing
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0005_expense_outing"
down_revision = "0004_outing"
branch_labels = None
depends_on = None

_COLUMN = "outing_id"
_FOREIGN_KEY = "fk_expenses_outing_group"
_INDEX = "ix_expenses_group_outing"


def upgrade() -> None:
    """Add the nullable association without rewriting existing expenses."""

    bind = op.get_bind()
    if bind.dialect.name == "sqlite":
        with op.batch_alter_table("expenses", recreate="always") as batch:
            batch.add_column(sa.Column(_COLUMN, sa.Uuid(as_uuid=True), nullable=True))
            batch.create_foreign_key(
                _FOREIGN_KEY,
                "outings",
                ["outing_id", "group_id"],
                ["id", "group_id"],
                ondelete="RESTRICT",
            )
            batch.create_index(_INDEX, ["group_id", _COLUMN], unique=False)
        return

    op.add_column("expenses", sa.Column(_COLUMN, sa.Uuid(as_uuid=True), nullable=True))
    op.create_foreign_key(
        _FOREIGN_KEY,
        "expenses",
        "outings",
        ["outing_id", "group_id"],
        ["id", "group_id"],
        ondelete="RESTRICT",
    )
    op.create_index(_INDEX, "expenses", ["group_id", _COLUMN], unique=False)


def downgrade() -> None:
    """Remove only the association column and its supporting objects."""

    bind = op.get_bind()
    if bind.dialect.name == "sqlite":
        with op.batch_alter_table("expenses", recreate="always") as batch:
            batch.drop_index(_INDEX)
            batch.drop_constraint(_FOREIGN_KEY, type_="foreignkey")
            batch.drop_column(_COLUMN)
        return

    op.drop_index(_INDEX, table_name="expenses")
    op.drop_constraint(_FOREIGN_KEY, "expenses", type_="foreignkey")
    op.drop_column("expenses", _COLUMN)
