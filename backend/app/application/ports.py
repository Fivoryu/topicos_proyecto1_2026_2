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
OutingId = UUID | str


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
    ended_at: datetime | None = None


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
class OutingRecord:
    """Source outing data with group-owned lifecycle state."""

    id: OutingId
    group_id: GroupId
    name: str
    archived_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


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
    outing_id: OutingId | None = None


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

    def list_by_group(
        self,
        group_id: GroupId,
        *,
        outing_filter: OutingId | None = None,
        general_only: bool = False,
    ) -> list[ExpenseRecord]:
        """Return source expenses in stable creation order and optional scope."""
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


class OutingRepository(Protocol):
    """Group-scoped outing source operations."""

    def list_by_group(self, group_id: GroupId) -> list[OutingRecord]:
        """Return active and archived outings in stable creation order."""
        ...

    def find_by_id(self, group_id: GroupId, outing_id: OutingId) -> OutingRecord | None:
        """Return an outing only when it belongs to the requested group."""
        ...

    def create(self, group_id: GroupId, outing: OutingRecord) -> OutingRecord:
        """Add an outing to the current transaction."""
        ...

    def update_active(
        self, group_id: GroupId, outing_id: OutingId, name: str, updated_at: datetime
    ) -> OutingRecord | None:
        """Update the name of an active outing."""
        ...

    def archive(
        self, group_id: GroupId, outing_id: OutingId, archived_at: datetime
    ) -> OutingRecord | None:
        """Mark an active outing archived."""
        ...

    def unarchive(
        self, group_id: GroupId, outing_id: OutingId, updated_at: datetime
    ) -> OutingRecord | None:
        """Restore an archived outing to active state."""
        ...

    def has_expenses(self, group_id: GroupId, outing_id: OutingId) -> bool:
        """Report whether an outing has linked source expenses."""
        ...

    def delete_if_empty(self, group_id: GroupId, outing_id: OutingId) -> bool:
        """Delete an outing only when no linked expenses exist."""
        ...


class GroupRepository(Protocol):
    """Persist and load server-owned group settings."""

    def find_by_id(self, group_id: GroupId) -> object | None:
        """Return a group by its stable identifier."""
        ...

    def create(self, group: object) -> object:
        """Add a group to the current transaction without committing it."""
        ...


class UnitOfWork(Protocol):
    """Transaction boundary exposing repositories to application services."""

    participants: ParticipantRepository
    expenses: ExpenseRepository
    outings: OutingRepository
    groups: GroupRepository
    memberships: MembershipRepository

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
    """Persist and resolve account memberships with server-owned group roles."""

    def list_for_account(
        self, account_id: AccountId, *, active_only: bool = True
    ) -> list[MembershipRecord]:
        """Return an account's memberships in stable creation order."""
        ...

    def find_for_account(self, account_id: AccountId) -> MembershipRecord | None:
        """Return the account's first active membership, if one exists."""
        ...

    def find_for_account_in_group(
        self, account_id: AccountId, group_id: GroupId
    ) -> MembershipRecord | None:
        """Return an active membership only within the requested group."""
        ...

    def find_active_by_group_account(
        self, group_id: GroupId, account_id: AccountId
    ) -> MembershipRecord | None:
        """Return an active membership using group-first lookup semantics."""
        ...

    def create_or_reactivate(
        self, group_id: GroupId, account_id: AccountId
    ) -> MembershipRecord:
        """Create a membership or reactivate its ended history row."""
        ...

    def end(
        self, group_id: GroupId, account_id: AccountId, ended_at: datetime | None = None
    ) -> bool:
        """End an active membership without deleting its history row."""
        ...

    def count_active_owners(self, group_id: GroupId) -> int:
        """Count active memberships belonging to the server-owned group owner."""
        ...


class InvalidationPublisher(Protocol):
    """Publish a group-scoped invalidation after a successful commit."""

    def publish(self, group_id: GroupId) -> None:
        """Ask clients to refetch authoritative group data."""
        ...
