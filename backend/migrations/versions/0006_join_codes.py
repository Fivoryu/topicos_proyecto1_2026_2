from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0006_join_codes"
down_revision = "0005_expense_outing"
branch_labels = None
depends_on = None

_UUID = sa.Uuid(as_uuid=True)
_DT = sa.DateTime(timezone=True)
_NOW = sa.text("CURRENT_TIMESTAMP")
_PARTICIPANT_KEY = "uq_participants_id_group_id"


def upgrade() -> None:
    op.create_index(_PARTICIPANT_KEY, "participants", ["id", "group_id"], unique=True)
    op.create_table(
        "group_join_codes",
        sa.Column("group_id", _UUID, nullable=False),
        sa.Column("token_hash", sa.LargeBinary(length=32), nullable=False),
        sa.Column("generation", sa.Integer(), server_default="1", nullable=False),
        sa.Column("created_at", _DT, server_default=_NOW, nullable=False),
        sa.Column("updated_at", _DT, server_default=_NOW, nullable=False),
        sa.Column("revoked_at", _DT, nullable=True),
        sa.CheckConstraint(
            "length(token_hash) = 32", name="ck_group_join_codes_token_hash_sha256"
        ),
        sa.ForeignKeyConstraint(
            ["group_id"], ["groups.id"],
            name="fk_group_join_codes_group", ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("group_id", name="pk_group_join_codes"),
    )
    op.create_table(
        "account_participant_links",
        sa.Column("group_id", _UUID, nullable=False),
        sa.Column("account_id", _UUID, nullable=False),
        sa.Column("participant_id", _UUID, nullable=False),
        sa.Column("created_at", _DT, server_default=_NOW, nullable=False),
        sa.Column("updated_at", _DT, server_default=_NOW, nullable=False),
        sa.Column("ended_at", _DT, nullable=True),
        sa.ForeignKeyConstraint(
            ["group_id", "account_id"],
            ["group_memberships.group_id", "group_memberships.account_id"],
            name="fk_account_participant_links_membership", ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["participant_id", "group_id"],
            ["participants.id", "participants.group_id"],
            name="fk_account_participant_links_participant", ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint(
            "group_id", "account_id", name="pk_account_participant_links"
        ),
    )


def downgrade() -> None:
    op.drop_table("account_participant_links")
    op.drop_table("group_join_codes")
    op.drop_index(_PARTICIPANT_KEY, table_name="participants")
