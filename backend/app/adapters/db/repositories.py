"""Synchronous SQLAlchemy adapters for the application authentication ports.

The application ports expose small synchronous methods. These adapters map ORM
rows to the application dataclasses, so SQLAlchemy models and role derivation do
not leak into the application service or become a second authorization source.
A request-scoped transaction/session is supplied by the caller.
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy import func, select, update
from sqlalchemy.orm import Session as OrmSession

from backend.app.application.ports import (
    AccountRecord,
    ExpenseRecord,
    MembershipRecord,
    OutingRecord,
    ParticipantRecord,
    SessionRecord,
)

from .tables import (
    Account,
    AuthSession,
    Expense,
    ExpenseBeneficiary,
    ExpenseContribution,
    Group,
    GroupMembership,
    Outing,
    Participant,
)


def _coerce_uuid(value: object) -> object:
    """Normalize a parseable identifier to a UUID for Uuid-bound columns."""

    if isinstance(value, str):
        try:
            return UUID(value)
        except ValueError:
            return value
    return value


def _account_record(account: Account) -> AccountRecord:
    return AccountRecord(
        id=account.id,
        login_name=account.login_name,
        password_hash=account.password_hash,
        is_active=account.is_active,
    )


def _session_record(session: AuthSession) -> SessionRecord:
    return SessionRecord(
        id=session.id,
        token_hash=bytes(session.token_hash),
        account_id=session.account_id,
        created_at=session.created_at,
        expires_at=session.expires_at,
        revoked_at=session.revoked_at,
    )


class AccountRepositoryAdapter:
    """Implement account lookup and creation without exposing ORM rows."""

    def __init__(self, session: OrmSession):
        self.session = session

    def find_by_login_name(self, login_name: str) -> AccountRecord | None:
        account = self.session.scalar(
            select(Account).where(Account.login_name == login_name)
        )
        return _account_record(account) if account is not None else None

    def find_by_id(self, account_id: object) -> AccountRecord | None:
        account = self.session.get(Account, account_id)
        return _account_record(account) if account is not None else None

    def create(self, account: AccountRecord | Account) -> AccountRecord:
        """Persist one account, leaving password hashing to the caller."""

        if isinstance(account, Account):
            model = account
        else:
            model = Account(
                id=account.id,
                login_name=account.login_name,
                password_hash=account.password_hash,
                is_active=account.is_active,
            )
        self.session.add(model)
        self.session.commit()
        return _account_record(model)

    add = create


class SessionRepositoryAdapter:
    """Persist sessions and retrieve them by digest, never by raw token."""

    def __init__(self, session: OrmSession):
        self.session = session

    def create(self, session: SessionRecord | AuthSession) -> SessionRecord:
        if isinstance(session, AuthSession):
            model = session
        else:
            model = AuthSession(
                id=session.id,
                token_hash=bytes(session.token_hash),
                account_id=session.account_id,
                created_at=session.created_at,
                expires_at=session.expires_at,
                revoked_at=session.revoked_at,
            )
        self.session.add(model)
        self.session.commit()
        return _session_record(model)

    def find_by_token_hash(self, token_hash: bytes) -> SessionRecord | None:
        if not isinstance(token_hash, (bytes, bytearray, memoryview)):
            return None
        session = self.session.scalar(
            select(AuthSession).where(AuthSession.token_hash == bytes(token_hash))
        )
        return _session_record(session) if session is not None else None

    def revoke_by_token_hash(self, token_hash: bytes, revoked_at: datetime) -> None:
        if not isinstance(token_hash, (bytes, bytearray, memoryview)):
            return
        self.session.execute(
            update(AuthSession)
            .where(AuthSession.token_hash == bytes(token_hash))
            .values(revoked_at=revoked_at)
        )
        self.session.commit()


class MembershipRepositoryAdapter:
    """Resolve active memberships and server-owned group owner identity."""

    def __init__(self, session: OrmSession):
        self.session = session

    @staticmethod
    def _membership_record(
        membership: GroupMembership, group: Group
    ) -> MembershipRecord:
        return MembershipRecord(
            account_id=membership.account_id,
            group_id=membership.group_id,
            owner_account_id=group.owner_account_id,
            ended_at=membership.ended_at,
        )

    def list_for_account(
        self, account_id: object, *, active_only: bool = True
    ) -> list[MembershipRecord]:
        """Return memberships for an active account in stable creation order."""

        statement = (
            select(GroupMembership, Group)
            .join(Group, Group.id == GroupMembership.group_id)
            .join(Account, Account.id == GroupMembership.account_id)
            .where(
                GroupMembership.account_id == _coerce_uuid(account_id),
                Account.is_active.is_(True),
            )
            .order_by(GroupMembership.created_at, GroupMembership.group_id)
        )
        if active_only:
            statement = statement.where(GroupMembership.ended_at.is_(None))
        return [
            self._membership_record(membership, group)
            for membership, group in self.session.execute(statement).all()
        ]

    def find_for_account(self, account_id: object) -> MembershipRecord | None:
        """Return the account's first active membership, if one exists."""

        memberships = self.list_for_account(account_id)
        return memberships[0] if memberships else None

    def find_for_account_in_group(
        self, account_id: object, group_id: object
    ) -> MembershipRecord | None:
        """Return an active membership only within the requested group."""

        row = self.session.execute(
            select(GroupMembership, Group)
            .join(Group, Group.id == GroupMembership.group_id)
            .join(Account, Account.id == GroupMembership.account_id)
            .where(
                GroupMembership.account_id == _coerce_uuid(account_id),
                GroupMembership.group_id == _coerce_uuid(group_id),
                GroupMembership.ended_at.is_(None),
                Account.is_active.is_(True),
            )
        ).first()
        if row is None:
            return None
        membership, group = row
        return self._membership_record(membership, group)

    def find_active_by_group_account(
        self, group_id: object, account_id: object
    ) -> MembershipRecord | None:
        """Return an active membership using group-first lookup semantics."""

        return self.find_for_account_in_group(account_id, group_id)

    # This name mirrors the authorization port's alternative lookup spelling.
    find_for_account_and_group = find_for_account_in_group

    def owner_has_membership(self, group_id: object) -> bool:
        """Check the required invariant that the group owner is an active member."""

        return self.count_active_owners(group_id) > 0

    def count_active_owners(self, group_id: object) -> int:
        """Count active memberships belonging to the server-owned group owner."""

        count = self.session.scalar(
            select(func.count())
            .select_from(GroupMembership)
            .join(Group, Group.id == GroupMembership.group_id)
            .join(Account, Account.id == GroupMembership.account_id)
            .where(
                GroupMembership.group_id == _coerce_uuid(group_id),
                GroupMembership.account_id == Group.owner_account_id,
                GroupMembership.ended_at.is_(None),
                Account.is_active.is_(True),
            )
        )
        return count if isinstance(count, int) else 0

    def create_or_reactivate(
        self, group_id: object, account_id: object
    ) -> MembershipRecord:
        """Create a membership or reactivate its ended history row.

        The operation only flushes. The surrounding unit of work owns the commit so
        membership creation can remain atomic with other source changes.
        """

        bound_group_id = _coerce_uuid(group_id)
        bound_account_id = _coerce_uuid(account_id)
        group = self.session.get(Group, bound_group_id)
        if group is None:
            raise ValueError("group does not exist")
        if self.session.get(Account, bound_account_id) is None:
            raise ValueError("account does not exist")

        membership = self.session.get(
            GroupMembership, (bound_group_id, bound_account_id)
        )
        if membership is None:
            membership = GroupMembership(
                group_id=bound_group_id,
                account_id=bound_account_id,
            )
            self.session.add(membership)
        elif membership.ended_at is None:
            raise ValueError("membership is already active")
        else:
            membership.ended_at = None

        self.session.flush()
        return self._membership_record(membership, group)

    def end(
        self, group_id: object, account_id: object, ended_at: datetime | None = None
    ) -> bool:
        """End an active membership without deleting its history row."""

        membership = self.session.get(
            GroupMembership,
            (_coerce_uuid(group_id), _coerce_uuid(account_id)),
        )
        if membership is None or membership.ended_at is not None:
            return False
        membership.ended_at = ended_at or datetime.now(UTC)
        self.session.flush()
        return True

    def create(self, membership: GroupMembership) -> GroupMembership:
        self.session.add(membership)
        self.session.commit()
        return membership

    add = create


class GroupRepositoryAdapter:
    """Persist and load server-owned groups by their identifier."""

    def __init__(self, session: OrmSession):
        self.session = session

    def find_by_id(self, group_id: object) -> Group | None:
        return self.session.get(Group, group_id)

    def create(self, group: object) -> Group:
        """Add a group record to the current transaction without committing."""

        if isinstance(group, Group):
            model = group
        else:
            group_id = getattr(group, "id", None)
            name = getattr(group, "name", None)
            owner_account_id = getattr(group, "owner_account_id", None)
            if group_id is None or name is None or owner_account_id is None:
                raise TypeError("group must expose the persisted group fields")
            model = Group(
                id=_coerce_uuid(group_id),
                name=name,
                owner_account_id=_coerce_uuid(owner_account_id),
                settlement_policy=getattr(group, "settlement_policy", "owner_only"),
            )
        self.session.add(model)
        self.session.flush()
        return model


class OutingRepositoryAdapter:
    """Persist group-owned outing source rows without crossing group boundaries."""

    def __init__(self, session: OrmSession):
        self.session = session

    def list_by_group(self, group_id: object) -> list[Outing]:
        bound_group_id = _coerce_uuid(group_id)
        return list(
            self.session.scalars(
                select(Outing)
                .where(Outing.group_id == bound_group_id)
                .order_by(Outing.created_at, Outing.id)
            )
        )

    def find_by_id(
        self, group_id: object, outing_id: object, *, for_update: bool = False
    ) -> Outing | None:
        statement = select(Outing).where(
            Outing.group_id == _coerce_uuid(group_id),
            Outing.id == _coerce_uuid(outing_id),
        )
        if for_update:
            statement = statement.with_for_update()
        return self.session.scalar(statement)

    def create(self, group_id: object, outing: OutingRecord | Outing) -> Outing:
        if _coerce_uuid(outing.group_id) != _coerce_uuid(group_id):
            raise ValueError("outing does not belong to the requested group")
        if isinstance(outing, Outing):
            model = outing
        else:
            model = Outing(
                id=_coerce_uuid(outing.id),
                group_id=_coerce_uuid(outing.group_id),
                name=outing.name,
                archived_at=outing.archived_at,
                created_at=outing.created_at,
                updated_at=outing.updated_at,
            )
        self.session.add(model)
        self.session.flush()
        return model

    def update_active(
        self,
        group_id: object,
        outing_id: object,
        name: str,
        updated_at: datetime,
    ) -> Outing | None:
        outing = self.find_by_id(group_id, outing_id, for_update=True)
        if outing is None:
            return None
        outing.name = name
        outing.updated_at = updated_at
        self.session.flush()
        return outing

    def archive(
        self, group_id: object, outing_id: object, archived_at: datetime
    ) -> Outing | None:
        outing = self.find_by_id(group_id, outing_id, for_update=True)
        if outing is None:
            return None
        outing.archived_at = archived_at
        outing.updated_at = archived_at
        self.session.flush()
        return outing

    def unarchive(
        self, group_id: object, outing_id: object, updated_at: datetime
    ) -> Outing | None:
        outing = self.find_by_id(group_id, outing_id, for_update=True)
        if outing is None:
            return None
        outing.archived_at = None
        outing.updated_at = updated_at
        self.session.flush()
        return outing

    def has_expenses(self, group_id: object, outing_id: object) -> bool:
        expense_id = self.session.scalar(
            select(Expense.id)
            .where(
                Expense.group_id == _coerce_uuid(group_id),
                Expense.outing_id == _coerce_uuid(outing_id),
            )
            .limit(1)
        )
        return expense_id is not None

    def delete_if_empty(self, group_id: object, outing_id: object) -> bool:
        outing = self.find_by_id(group_id, outing_id, for_update=True)
        if outing is None or self.has_expenses(group_id, outing_id):
            return False
        self.session.delete(outing)
        self.session.flush()
        return True


class ParticipantRepositoryAdapter:
    """Persist participants while keeping every operation group-scoped."""

    def __init__(self, session: OrmSession):
        self.session = session

    def list_by_group(self, group_id: object) -> list[Participant]:
        return list(
            self.session.scalars(
                select(Participant)
                .where(Participant.group_id == group_id)
                .order_by(Participant.created_at, Participant.id)
            )
        )

    def find_by_id(
        self, group_id: object, participant_id: object, *, for_update: bool = False
    ) -> Participant | None:
        statement = select(Participant).where(
            Participant.group_id == group_id, Participant.id == participant_id
        )
        if for_update:
            statement = statement.with_for_update()
        return self.session.scalar(statement)

    def find_by_normalized_name(
        self, group_id: object, normalized_name: str, exclude_id: object | None = None
    ) -> Participant | None:
        statement = select(Participant).where(
            Participant.group_id == group_id,
            Participant.normalized_name == normalized_name,
        )
        if exclude_id is not None:
            statement = statement.where(Participant.id != exclude_id)
        return self.session.scalar(statement)

    def create(
        self, group_id: object, participant: Participant | ParticipantRecord
    ) -> Participant:
        if participant.group_id != group_id:
            raise ValueError("participant does not belong to the requested group")
        if not isinstance(participant, Participant):
            participant = Participant(
                id=participant.id,
                group_id=participant.group_id,
                name=participant.name,
                normalized_name=participant.normalized_name,
                archived_at=participant.archived_at,
                created_at=participant.created_at,
            )
        self.session.add(participant)
        return participant

    add = create

    def update_name(
        self,
        group_id: object,
        participant_id: object,
        name: str,
        normalized_name: str,
    ) -> Participant | None:
        participant = self.find_by_id(group_id, participant_id, for_update=True)
        if participant is None:
            return None
        participant.name = name
        participant.normalized_name = normalized_name
        return participant

    def set_archived(
        self, group_id: object, participant_id: object, archived_at: datetime | None
    ) -> Participant | None:
        participant = self.find_by_id(group_id, participant_id, for_update=True)
        if participant is None:
            return None
        participant.archived_at = archived_at
        return participant

    def has_references(self, group_id: object, participant_id: object) -> bool:
        contribution = self.session.scalar(
            select(ExpenseContribution.expense_id)
            .join(Expense, Expense.id == ExpenseContribution.expense_id)
            .where(
                Expense.group_id == group_id,
                ExpenseContribution.participant_id == participant_id,
            )
            .limit(1)
        )
        if contribution is not None:
            return True
        beneficiary = self.session.scalar(
            select(ExpenseBeneficiary.expense_id)
            .join(Expense, Expense.id == ExpenseBeneficiary.expense_id)
            .where(
                Expense.group_id == group_id,
                ExpenseBeneficiary.participant_id == participant_id,
            )
            .limit(1)
        )
        return beneficiary is not None

    is_referenced = has_references

    def delete(self, group_id: object, participant_id: object) -> bool:
        participant = self.find_by_id(group_id, participant_id, for_update=True)
        if participant is None:
            return False
        self.session.delete(participant)
        return True


class ExpenseRepositoryAdapter:
    """Persist expenses and verify all child participant references in-group."""

    def __init__(self, session: OrmSession):
        self.session = session

    def list_by_group(self, group_id: object) -> list[Expense]:
        bound_group_id = _coerce_uuid(group_id)
        return list(
            self.session.scalars(
                select(Expense)
                .where(Expense.group_id == bound_group_id)
                .order_by(Expense.created_at, Expense.id)
            )
        )

    def find_by_id(self, group_id: object, expense_id: object) -> Expense | None:
        return self.session.scalar(
            select(Expense).where(
                Expense.group_id == _coerce_uuid(group_id),
                Expense.id == _coerce_uuid(expense_id),
            )
        )

    @staticmethod
    def _participant_ids(contributions, beneficiaries) -> set[object]:
        ids = set()
        for contribution in contributions:
            if isinstance(contribution, (tuple, list)):
                ids.add(contribution[0])
            elif isinstance(contribution, dict):
                ids.add(contribution.get("participant_id", contribution.get("id")))
            else:
                ids.add(contribution.participant_id)
        for beneficiary in beneficiaries:
            if isinstance(beneficiary, dict):
                ids.add(beneficiary.get("participant_id", beneficiary.get("id")))
            else:
                ids.add(
                    beneficiary.participant_id
                    if hasattr(beneficiary, "participant_id")
                    else beneficiary
                )
        return {_coerce_uuid(value) for value in ids}

    def _verify_participants(
        self, group_id: object, participant_ids: set[object]
    ) -> None:
        if None in participant_ids:
            raise ValueError("participant reference is not in the requested group")
        found = set(
            self.session.scalars(
                select(Participant.id).where(
                    Participant.group_id == group_id,
                    Participant.id.in_(participant_ids),
                )
            )
        )
        if found != participant_ids:
            raise ValueError("participant reference is not in the requested group")

    def create(
        self,
        group_id: object,
        expense: ExpenseRecord | Expense,
        contributions=(),
        beneficiaries=(),
    ) -> Expense:
        if expense.group_id != group_id:
            raise ValueError("expense does not belong to the requested group")
        if not isinstance(expense, Expense):
            expense = Expense(
                id=_coerce_uuid(expense.id),
                group_id=_coerce_uuid(expense.group_id),
                outing_id=(
                    _coerce_uuid(expense.outing_id)
                    if expense.outing_id is not None
                    else None
                ),
                description=expense.description,
                amount_cents=expense.amount_cents,
                created_at=expense.created_at,
                updated_at=expense.updated_at,
            )
        contributions = tuple(contributions)
        beneficiaries = tuple(beneficiaries)
        self._verify_participants(
            group_id, self._participant_ids(contributions, beneficiaries)
        )
        self.session.add(expense)
        for contribution in contributions:
            if isinstance(contribution, ExpenseContribution):
                row = contribution
            elif isinstance(contribution, dict):
                row = ExpenseContribution(
                    expense_id=expense.id,
                    participant_id=contribution.get(
                        "participant_id", contribution.get("id")
                    ),
                    amount_cents=contribution.get(
                        "amount_cents", contribution.get("amount")
                    ),
                )
            else:
                participant_id, amount_cents = contribution
                row = ExpenseContribution(
                    expense_id=expense.id,
                    participant_id=_coerce_uuid(participant_id),
                    amount_cents=amount_cents,
                )
            self.session.add(row)
        for beneficiary in beneficiaries:
            if isinstance(beneficiary, ExpenseBeneficiary):
                row = beneficiary
            elif isinstance(beneficiary, dict):
                row = ExpenseBeneficiary(
                    expense_id=expense.id,
                    participant_id=_coerce_uuid(
                        beneficiary.get("participant_id", beneficiary.get("id"))
                    ),
                )
            else:
                row = ExpenseBeneficiary(
                    expense_id=expense.id, participant_id=_coerce_uuid(beneficiary)
                )
            self.session.add(row)
        return expense

    add = create

    def update(
        self,
        group_id: object,
        expense_id: object,
        replacement: ExpenseRecord | Expense,
        contributions=(),
        beneficiaries=(),
    ) -> Expense | None:
        expense = self.find_by_id(group_id, expense_id)
        if expense is None:
            return None
        if replacement.group_id != group_id:
            raise ValueError("expense does not belong to the requested group")
        contributions = tuple(contributions)
        beneficiaries = tuple(beneficiaries)
        self._verify_participants(
            group_id, self._participant_ids(contributions, beneficiaries)
        )
        expense.outing_id = (
            _coerce_uuid(replacement.outing_id)
            if replacement.outing_id is not None
            else None
        )
        expense.description = replacement.description
        expense.amount_cents = replacement.amount_cents
        expense.updated_at = replacement.updated_at
        for row in self.list_contributions(group_id, expense_id):
            self.session.delete(row)
        for row in self.list_beneficiaries(group_id, expense_id):
            self.session.delete(row)
        self.session.flush()
        for participant_id, amount_cents in contributions:
            self.session.add(
                ExpenseContribution(
                    expense_id=expense.id,
                    participant_id=_coerce_uuid(participant_id),
                    amount_cents=amount_cents,
                )
            )
        for participant_id in beneficiaries:
            self.session.add(
                ExpenseBeneficiary(
                    expense_id=expense.id,
                    participant_id=_coerce_uuid(participant_id),
                )
            )
        return expense

    def list_contributions(
        self, group_id: object, expense_id: object
    ) -> list[ExpenseContribution]:
        return list(
            self.session.scalars(
                select(ExpenseContribution)
                .join(Expense, Expense.id == ExpenseContribution.expense_id)
                .where(
                    Expense.group_id == _coerce_uuid(group_id),
                    ExpenseContribution.expense_id == _coerce_uuid(expense_id),
                )
            )
        )

    def list_beneficiaries(
        self, group_id: object, expense_id: object
    ) -> list[ExpenseBeneficiary]:
        return list(
            self.session.scalars(
                select(ExpenseBeneficiary)
                .join(Expense, Expense.id == ExpenseBeneficiary.expense_id)
                .where(
                    Expense.group_id == _coerce_uuid(group_id),
                    ExpenseBeneficiary.expense_id == _coerce_uuid(expense_id),
                )
            )
        )

    def delete(self, group_id: object, expense_id: object) -> bool:
        expense = self.find_by_id(_coerce_uuid(group_id), _coerce_uuid(expense_id))
        if expense is None:
            return False
        self.session.delete(expense)
        return True


# Explicit aliases make the adapter names discoverable while retaining a stable
# ``*Adapter`` spelling for dependency injection and tests.
SqlAlchemyAccountRepository = AccountRepositoryAdapter
SqlAlchemySessionRepository = SessionRepositoryAdapter
SqlAlchemyMembershipRepository = MembershipRepositoryAdapter
AccountRepository = AccountRepositoryAdapter
SessionRepository = SessionRepositoryAdapter
MembershipRepository = MembershipRepositoryAdapter
OutingRepository = OutingRepositoryAdapter
GroupRepository = GroupRepositoryAdapter
ParticipantRepository = ParticipantRepositoryAdapter
ExpenseRepository = ExpenseRepositoryAdapter

__all__ = [
    "AccountRepository",
    "AccountRepositoryAdapter",
    "ExpenseRepository",
    "ExpenseRepositoryAdapter",
    "GroupRepository",
    "GroupRepositoryAdapter",
    "MembershipRepository",
    "MembershipRepositoryAdapter",
    "OutingRepository",
    "OutingRepositoryAdapter",
    "ParticipantRepository",
    "ParticipantRepositoryAdapter",
    "SessionRepository",
    "SessionRepositoryAdapter",
    "SqlAlchemyAccountRepository",
    "SqlAlchemyMembershipRepository",
    "SqlAlchemySessionRepository",
]
