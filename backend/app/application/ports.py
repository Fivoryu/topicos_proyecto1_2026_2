"""Application boundaries for authentication and protected sessions.

The application layer depends on these small protocols rather than on SQLAlchemy,
Argon2, or a particular token transport. Adapters can therefore provide the
persistent records and security implementations without moving authorization
logic into the application service or transport layer.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from types import TracebackType
from typing import Protocol, Self
from uuid import UUID

AccountId = UUID | str
GroupId = UUID | str
ParticipantId = UUID | str


class Clock(Protocol):
    """Provide the current time to make session expiry deterministic in tests."""

    def now(self) -> datetime:
        """Return the current instant used by the application."""
        ...


class PasswordHasher(Protocol):
    """Verify passwords against encoded hashes supplied by an adapter."""

    dummy_hash: str

    def verify(self, password: str, encoded_hash: str) -> bool:
        """Return whether ``password`` matches ``encoded_hash``."""
        ...


class SessionTokenSource(Protocol):
    """Generate an opaque transport token and its persistence-safe digest."""

    def generate(self) -> str:
        """Return a new opaque token for transport to the authenticated client."""
        ...

    def hash(self, token: str) -> bytes:
        """Return the token digest that is safe to persist and query."""
        ...


@dataclass(slots=True)
class AccountRecord:
    """Minimum account data needed by the authentication use case."""

    id: AccountId
    login_name: str
    password_hash: str
    is_active: bool = True


@dataclass(slots=True)
class MembershipRecord:
    """Membership data used to derive the active group and role."""

    account_id: AccountId
    group_id: GroupId
    owner_account_id: AccountId


@dataclass(slots=True)
class SessionRecord:
    """Persisted session data; the raw token is intentionally not a field."""

    id: AccountId
    token_hash: bytes
    account_id: AccountId
    created_at: datetime
    expires_at: datetime
    revoked_at: datetime | None = None


@dataclass(slots=True)
class ParticipantRecord:
    """Source participant data shared by use cases and adapters."""

    id: ParticipantId
    group_id: GroupId
    name: str
    normalized_name: str
    archived_at: datetime | None = None
    created_at: datetime | None = None


@dataclass(slots=True)
class ExpenseRecord:
    """Source expense data with its child references for application use cases."""

    id: str
    group_id: GroupId
    description: str
    amount_cents: int
    contributors: dict[str, int]
    beneficiaries: tuple[str, ...]
    created_at: datetime
    updated_at: datetime


class AccountRepository(Protocol):
    """Read accounts without exposing persistence details to the service."""

    def find_by_login_name(self, login_name: str) -> AccountRecord | None:
        """Find an account by its stable login name."""
        ...

    def find_by_id(self, account_id: AccountId) -> AccountRecord | None:
        """Load an account referenced by a persisted session."""
        ...


class SessionRepository(Protocol):
    """Persist and retrieve sessions by their one-way token digest."""

    def create(self, session: SessionRecord) -> SessionRecord | None:
        """Persist a new session record."""
        ...

    def find_by_token_hash(self, token_hash: bytes) -> SessionRecord | None:
        """Find a session using only the supplied token digest."""
        ...

    def revoke_by_token_hash(self, token_hash: bytes, revoked_at: datetime) -> None:
        """Mark the matching session as revoked."""
        ...


class ParticipantRepository(Protocol):
    """Group-scoped participant source operations."""

    def list_by_group(self, group_id: GroupId) -> list[ParticipantRecord]:
        """Return active and archived rows in creation order."""
        ...

    def find_by_id(
        self, group_id: GroupId, participant_id: str, *, for_update: bool = False
    ) -> ParticipantRecord | None:
        """Return a participant only when it belongs to the requested group."""
        ...

    def find_by_normalized_name(
        self,
        group_id: GroupId,
        normalized_name: str,
        exclude_id: str | None = None,
    ) -> ParticipantRecord | None:
        """Find active or archived normalized-name conflicts."""
        ...

    def update_name(
        self,
        group_id: GroupId,
        participant_id: str,
        name: str,
        normalized_name: str,
    ) -> ParticipantRecord | None:
        """Change only the display and normalized names."""
        ...

    def has_references(self, group_id: GroupId, participant_id: str) -> bool:
        """Report whether any expense child row references the participant."""
        ...

    def delete(self, group_id: GroupId, participant_id: str) -> bool:
        """Delete a never-referenced participant."""
        ...


class ExpenseRepository(Protocol):
    """Group-scoped source expense operations."""

    def list_by_group(self, group_id: GroupId) -> list[ExpenseRecord]:
        """Return source expenses in stable creation order."""
        ...

    def find_by_id(self, group_id: GroupId, expense_id: str) -> ExpenseRecord | None:
        """Return an expense only when it belongs to the requested group."""
        ...

    def create(
        self,
        group_id: GroupId,
        expense: ExpenseRecord,
        contributions: tuple[tuple[str, int], ...] = (),
        beneficiaries: tuple[str, ...] = (),
    ) -> ExpenseRecord | None:
        """Persist one expense and all validated child rows."""
        ...

    def update(
        self,
        group_id: GroupId,
        expense_id: str,
        expense: ExpenseRecord,
        contributions: tuple[tuple[str, int], ...] = (),
        beneficiaries: tuple[str, ...] = (),
    ) -> ExpenseRecord | None:
        """Replace an expense and its validated child rows."""
        ...

    def delete(self, group_id: GroupId, expense_id: str) -> bool:
        """Delete an expense and its child rows."""
        ...


class GroupRepository(Protocol):
    """Load and update server-owned group settings."""

    def find_by_id(self, group_id: GroupId) -> object | None:
        """Return a group by its stable identifier."""
        ...


class UnitOfWork(Protocol):
    """Transaction boundary exposing repositories to application services."""

    participants: ParticipantRepository
    expenses: ExpenseRepository
    groups: GroupRepository

    def __enter__(self) -> Self:
        """Begin and return this transaction."""
        ...

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool:
        """Commit on success or roll back when the body raises."""
        ...

    def flush(self) -> None:
        """Make pending source changes visible to invariant checks."""
        ...


class MembershipRepository(Protocol):
    """Resolve the active group membership used for server-side role derivation."""

    def find_for_account(self, account_id: AccountId) -> MembershipRecord | None:
        """Return the account's active-group membership, if one exists."""
        ...


class InvalidationPublisher(Protocol):
    """Publish a group-scoped invalidation after a successful commit."""

    def publish(self, group_id: GroupId) -> None:
        """Ask clients to refetch authoritative group data."""
        ...
