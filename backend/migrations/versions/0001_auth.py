"""Create the account, group-membership, and session auth schema.

Revision ID: 0001_auth
Revises:

The downgrade is intentionally destructive: it removes sessions first, then
memberships, groups, and accounts so every foreign-key dependency is removed in
reverse order. It is suitable for local reset/recovery and migration testing;
production operators must back up authentication data before downgrading.
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0001_auth"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create the minimum server-authoritative authentication schema."""

    op.create_table(
        "accounts",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("login_name", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column(
            "is_active",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id", name="pk_accounts"),
        sa.UniqueConstraint("login_name", name="uq_accounts_login_name"),
    )
    op.create_index("ix_accounts_login_name", "accounts", ["login_name"], unique=True)

    op.create_table(
        "groups",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("owner_account_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column(
            "settlement_policy",
            sa.String(length=32),
            server_default=sa.text("'owner_only'"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["owner_account_id"],
            ["accounts.id"],
            name="fk_groups_owner_account",
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_groups"),
    )

    op.create_table(
        "group_memberships",
        sa.Column("group_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("account_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["account_id"],
            ["accounts.id"],
            name="fk_memberships_account",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["group_id"],
            ["groups.id"],
            name="fk_memberships_group",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("group_id", "account_id", name="pk_group_memberships"),
    )
    op.create_index(
        "ix_group_memberships_account_id",
        "group_memberships",
        ["account_id"],
        unique=False,
    )

    op.create_table(
        "sessions",
        sa.Column("id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column("token_hash", sa.LargeBinary(length=32), nullable=False),
        sa.Column("account_id", sa.Uuid(as_uuid=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint(
            "length(token_hash) = 32", name="ck_sessions_token_hash_sha256"
        ),
        sa.ForeignKeyConstraint(
            ["account_id"],
            ["accounts.id"],
            name="fk_sessions_account",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_sessions"),
        sa.UniqueConstraint("token_hash", name="uq_sessions_token_hash"),
    )
    op.create_index("ix_sessions_token_hash", "sessions", ["token_hash"], unique=True)
    op.create_index("ix_sessions_account_id", "sessions", ["account_id"], unique=False)
    op.create_index("ix_sessions_expires_at", "sessions", ["expires_at"], unique=False)
    op.create_index("ix_sessions_revoked_at", "sessions", ["revoked_at"], unique=False)
    op.create_index(
        "ix_sessions_active_lookup",
        "sessions",
        ["account_id", "revoked_at", "expires_at"],
        unique=False,
    )


def downgrade() -> None:
    """Remove auth tables in dependency order; all auth data is destroyed."""

    op.drop_index("ix_sessions_active_lookup", table_name="sessions")
    op.drop_index("ix_sessions_revoked_at", table_name="sessions")
    op.drop_index("ix_sessions_expires_at", table_name="sessions")
    op.drop_index("ix_sessions_account_id", table_name="sessions")
    op.drop_index("ix_sessions_token_hash", table_name="sessions")
    op.drop_table("sessions")

    op.drop_index("ix_group_memberships_account_id", table_name="group_memberships")
    op.drop_table("group_memberships")
    op.drop_table("groups")

    op.drop_index("ix_accounts_login_name", table_name="accounts")
    op.drop_table("accounts")
