"""SQLAlchemy source tables for the account and protected-session boundary.

This module deliberately models identity and session state separately from the
participant domain. Roles are derived by joining memberships to the group's
server-owned ``owner_account_id``; no role claim is persisted.
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    LargeBinary,
    PrimaryKeyConstraint,
    String,
    Text,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


def _utc_now() -> datetime:
    """Return a timezone-aware UTC timestamp for new persisted records."""

    return datetime.now(UTC)


class Base(DeclarativeBase):
    """Declarative base shared by current and subsequent persistence slices."""


class Account(Base):
    """An authenticated account; participant identity is intentionally separate."""

    __tablename__ = "accounts"
    __table_args__ = (
        UniqueConstraint("login_name", name="uq_accounts_login_name"),
        Index("ix_accounts_login_name", "login_name", unique=True),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    login_name: Mapped[str] = mapped_column(String(255), nullable=False)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utc_now
    )


class Group(Base):
    """The minimum group anchor required to derive membership roles.

    Later persistence work adds participant and expense source tables; the group
    identity and owner relationship live here so membership rows are constrained
    and role derivation remains server-authoritative from the first migration.
    """

    __tablename__ = "groups"

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    owner_account_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("accounts.id", name="fk_groups_owner_account", ondelete="RESTRICT"),
        nullable=False,
    )
    settlement_policy: Mapped[str] = mapped_column(
        String(32), nullable=False, default="owner_only", server_default="owner_only"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utc_now
    )


class GroupMembership(Base):
    """A composite-key account/group membership with database cascades."""

    __tablename__ = "group_memberships"
    __table_args__ = (
        PrimaryKeyConstraint("group_id", "account_id", name="pk_group_memberships"),
        Index("ix_group_memberships_account_id", "account_id"),
    )

    group_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("groups.id", name="fk_memberships_group", ondelete="CASCADE"),
        nullable=False,
    )
    account_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("accounts.id", name="fk_memberships_account", ondelete="CASCADE"),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utc_now
    )


class Participant(Base):
    """A group-scoped participant whose identity is stable across renames."""

    __tablename__ = "participants"
    __table_args__ = (
        UniqueConstraint(
            "group_id", "normalized_name", name="uq_participants_group_name"
        ),
        Index("ix_participants_group_id", "group_id"),
        Index("ix_participants_group_created", "group_id", "created_at", "id"),
        CheckConstraint("length(trim(name)) > 0", name="ck_participants_name_nonempty"),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    group_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("groups.id", name="fk_participants_group", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    normalized_name: Mapped[str] = mapped_column(String(255), nullable=False)
    archived_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utc_now
    )


class Expense(Base):
    """An expense source row; balances and transfers are derived, not stored."""

    __tablename__ = "expenses"
    __table_args__ = (
        CheckConstraint("amount_cents > 0", name="ck_expenses_amount_positive"),
        Index("ix_expenses_group_created", "group_id", "created_at", "id"),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    group_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("groups.id", name="fk_expenses_group", ondelete="CASCADE"),
        nullable=False,
    )
    description: Mapped[str] = mapped_column(String(500), nullable=False)
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utc_now
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utc_now, onupdate=_utc_now
    )


class ExpenseContribution(Base):
    """A positive contribution linked to one expense and participant."""

    __tablename__ = "expense_contributions"
    __table_args__ = (
        PrimaryKeyConstraint(
            "expense_id", "participant_id", name="pk_expense_contributions"
        ),
        CheckConstraint("amount_cents > 0", name="ck_contributions_amount_positive"),
        Index("ix_expense_contributions_participant", "participant_id"),
    )

    expense_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("expenses.id", name="fk_contributions_expense", ondelete="CASCADE"),
        nullable=False,
    )
    participant_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "participants.id",
            name="fk_contributions_participant",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )
    amount_cents: Mapped[int] = mapped_column(Integer, nullable=False)


class ExpenseBeneficiary(Base):
    """A participant receiving an equal share of one expense."""

    __tablename__ = "expense_beneficiaries"
    __table_args__ = (
        PrimaryKeyConstraint(
            "expense_id", "participant_id", name="pk_expense_beneficiaries"
        ),
        Index("ix_expense_beneficiaries_participant", "participant_id"),
    )

    expense_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("expenses.id", name="fk_beneficiaries_expense", ondelete="CASCADE"),
        nullable=False,
    )
    participant_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey(
            "participants.id",
            name="fk_beneficiaries_participant",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )


class AuthSession(Base):
    """A database-backed session containing only the one-way token digest."""

    __tablename__ = "sessions"
    __table_args__ = (
        CheckConstraint(
            "length(token_hash) = 32", name="ck_sessions_token_hash_sha256"
        ),
        UniqueConstraint("token_hash", name="uq_sessions_token_hash"),
        Index("ix_sessions_token_hash", "token_hash", unique=True),
        Index("ix_sessions_account_id", "account_id"),
        Index("ix_sessions_expires_at", "expires_at"),
        Index("ix_sessions_revoked_at", "revoked_at"),
        Index(
            "ix_sessions_active_lookup",
            "account_id",
            "revoked_at",
            "expires_at",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid4
    )
    token_hash: Mapped[bytes] = mapped_column(LargeBinary(length=32), nullable=False)
    account_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("accounts.id", name="fk_sessions_account", ondelete="CASCADE"),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=_utc_now
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )


# ``Session`` is a convenient public model name, while ``AuthSession`` avoids
# colliding with SQLAlchemy's ORM Session in adapter implementation modules.
Session = AuthSession

__all__ = [
    "Account",
    "AuthSession",
    "Base",
    "Expense",
    "ExpenseBeneficiary",
    "ExpenseContribution",
    "Group",
    "GroupMembership",
    "Participant",
    "Session",
]
