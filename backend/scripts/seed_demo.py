"""Idempotently load the protected Samaipata demonstration dataset.

The seed owns only development data. Passwords are read from the two demo
settings/environment variables and are never written to source or logs.
"""

from __future__ import annotations

import asyncio
import logging
import os
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any, NoReturn
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncEngine
from sqlalchemy.orm import Session

from backend.app.adapters.config import get_settings
from backend.app.adapters.db.session import create_engine
from backend.app.adapters.db.tables import (
    Account,
    Expense,
    ExpenseBeneficiary,
    ExpenseContribution,
    Group,
    GroupMembership,
    Participant,
)
from backend.app.adapters.security.passwords import Argon2idPasswordHasher
from backend.app.domain.balance_service import (
    PersistenceCorruptedError,
    compute_balances,
)
from backend.app.domain.settlement_service import build_settlement

logger = logging.getLogger(__name__)

DEMO_GROUP_ID = UUID("00000000-0000-4000-8000-000000000001")
DEMO_OWNER_ID = UUID("00000000-0000-4000-8000-000000000002")
DEMO_MEMBER_ID = UUID("00000000-0000-4000-8000-000000000003")
DEMO_PARTICIPANT_IDS = (
    UUID("00000000-0000-4000-8000-000000000011"),
    UUID("00000000-0000-4000-8000-000000000012"),
    UUID("00000000-0000-4000-8000-000000000013"),
    UUID("00000000-0000-4000-8000-000000000014"),
)
DEMO_EXPENSE_IDS = (
    UUID("00000000-0000-4000-8000-000000000021"),
    UUID("00000000-0000-4000-8000-000000000022"),
    UUID("00000000-0000-4000-8000-000000000023"),
    UUID("00000000-0000-4000-8000-000000000024"),
)

_PARTICIPANTS = ("Ana", "Beto", "Carla", "Diego")
# Official Samaipata fixture: description, amount in cents, payer index.
_EXPENSES = (
    ("Cabaña", 80_000, 0),
    ("Entradas a El Fuerte", 16_000, 0),
    ("Cena", 40_000, 1),
    ("Gasolina", 24_000, 2),
)


@dataclass(frozen=True, slots=True)
class SeedSummary:
    """Safe, non-secret seed operation counters."""

    group_id: UUID
    accounts_created: int
    participants_created: int
    expenses_created: int


def _corrupted(message: str, error: BaseException | None = None) -> NoReturn:
    if error is None:
        raise PersistenceCorruptedError(message)
    raise PersistenceCorruptedError(message) from error


def _password(explicit: str | None, env_name: str, configured: str) -> str:
    value = explicit if explicit is not None else os.getenv(env_name, configured)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{env_name} must contain a non-empty demo password")
    return value


def _hash_password(hasher: Any, password: str) -> str:
    method = getattr(hasher, "hash", None) or getattr(hasher, "hash_password", None)
    if method is None:
        raise TypeError("password hasher cannot create a password hash")
    result = method(password)
    if not isinstance(result, str) or not result:
        raise TypeError("password hasher returned an invalid password hash")
    return result


def _ensure_account(
    session: Session,
    login_name: str,
    stable_id: UUID,
    password: str,
    hasher: Any | None,
) -> tuple[Account, bool]:
    account = session.scalar(select(Account).where(Account.login_name == login_name))
    if account is not None:
        if not account.is_active:
            account.is_active = True
        return account, False

    occupied = session.get(Account, stable_id)
    if occupied is not None:
        _corrupted("A stable demo account id belongs to another login name.")
    if hasher is None:
        hasher = Argon2idPasswordHasher()
    account = Account(
        id=stable_id,
        login_name=login_name,
        password_hash=_hash_password(hasher, password),
        is_active=True,
    )
    session.add(account)
    session.flush()
    return account, True


def _ensure_membership(session: Session, group_id: UUID, account_id: UUID) -> bool:
    membership = session.get(GroupMembership, (group_id, account_id))
    if membership is not None:
        return False
    session.add(GroupMembership(group_id=group_id, account_id=account_id))
    session.flush()
    return True


def _ensure_group(session: Session, owner_id: UUID) -> Group:
    group = session.get(Group, DEMO_GROUP_ID)
    if group is None:
        group = Group(
            id=DEMO_GROUP_ID,
            name="Samaipata",
            owner_account_id=owner_id,
            settlement_policy="owner_only",
        )
        session.add(group)
        session.flush()
        return group
    if group.owner_account_id != owner_id:
        _corrupted("The stable demo group has a different owner account.")
    if group.settlement_policy != "owner_only":
        group.settlement_policy = "owner_only"
    return group


def _ensure_participant(
    session: Session,
    position: int,
    name: str,
) -> tuple[Participant, bool]:
    stable_id = DEMO_PARTICIPANT_IDS[position]
    participant = session.get(Participant, stable_id)
    if participant is not None:
        if participant.group_id != DEMO_GROUP_ID:
            _corrupted("A stable demo participant belongs to another group.")
        if participant.name != name or participant.normalized_name != name.casefold():
            _corrupted("A stable demo participant has an unexpected name.")
        return participant, False

    participant = session.scalar(
        select(Participant).where(
            Participant.group_id == DEMO_GROUP_ID,
            Participant.normalized_name == name.casefold(),
        )
    )
    if participant is not None:
        return participant, False

    participant = Participant(
        id=stable_id,
        group_id=DEMO_GROUP_ID,
        name=name,
        normalized_name=name.casefold(),
        created_at=datetime(2026, 1, 1, 12, position, tzinfo=UTC),
    )
    session.add(participant)
    session.flush()
    return participant, True


def _ensure_expense(
    session: Session,
    position: int,
    description: str,
    amount_cents: int,
    payer_index: int,
    participants: tuple[Participant, ...],
) -> bool:
    expense_id = DEMO_EXPENSE_IDS[position]
    expense = session.get(Expense, expense_id)
    if expense is not None:
        if expense.group_id != DEMO_GROUP_ID:
            _corrupted("A stable demo expense belongs to another group.")
        if expense.amount_cents != amount_cents:
            _corrupted("A seeded expense has an unexpected amount.")
        return False

    expense = Expense(
        id=expense_id,
        group_id=DEMO_GROUP_ID,
        description=description,
        amount_cents=amount_cents,
        created_at=datetime(2026, 1, 2, 12, position, tzinfo=UTC),
        updated_at=datetime(2026, 1, 2, 12, position, tzinfo=UTC),
    )
    session.add(expense)
    session.flush()
    session.add(
        ExpenseContribution(
            expense_id=expense.id,
            participant_id=participants[payer_index].id,
            amount_cents=amount_cents,
        )
    )
    session.add_all(
        [
            ExpenseBeneficiary(expense_id=expense.id, participant_id=participant.id)
            for participant in participants
        ]
    )
    session.flush()
    return True


def _source_expenses(session: Session) -> list[dict[str, Any]]:
    rows = session.scalars(
        select(Expense)
        .where(Expense.group_id == DEMO_GROUP_ID)
        .order_by(Expense.created_at, Expense.id)
    )
    result = []
    for expense in rows:
        contributions = session.scalars(
            select(ExpenseContribution).where(
                ExpenseContribution.expense_id == expense.id
            )
        )
        beneficiaries = session.scalars(
            select(ExpenseBeneficiary).where(
                ExpenseBeneficiary.expense_id == expense.id
            )
        )
        result.append(
            {
                "id": expense.id,
                "amount_cents": expense.amount_cents,
                "contributors": {
                    row.participant_id: row.amount_cents for row in contributions
                },
                "beneficiaries": tuple(row.participant_id for row in beneficiaries),
            }
        )
    return result


def _validate_seed(session: Session, owner_id: UUID, member_id: UUID) -> None:
    group = session.get(Group, DEMO_GROUP_ID)
    if group is None or group.owner_account_id != owner_id:
        _corrupted("The seeded group or owner invariant is missing.")
    if group.settlement_policy != "owner_only":
        _corrupted("The seeded group policy is invalid.")

    member_ids = set(
        session.scalars(
            select(GroupMembership.account_id).where(
                GroupMembership.group_id == DEMO_GROUP_ID
            )
        )
    )
    if owner_id not in member_ids or member_id not in member_ids:
        _corrupted("The seeded owner/member membership invariant is missing.")

    participants = list(
        session.scalars(
            select(Participant)
            .where(Participant.group_id == DEMO_GROUP_ID)
            .order_by(Participant.created_at, Participant.id)
        )
    )
    by_id = {participant.id: participant for participant in participants}
    if any(participant_id not in by_id for participant_id in DEMO_PARTICIPANT_IDS):
        _corrupted("The seeded participant set is incomplete.")

    source_expenses = _source_expenses(session)
    by_expense_id = {expense["id"]: expense for expense in source_expenses}
    expected_ids = set(DEMO_EXPENSE_IDS)
    if not expected_ids.issubset(by_expense_id):
        _corrupted("The seeded expense set is incomplete.")
    expected_contributors = tuple(
        {DEMO_PARTICIPANT_IDS[payer_index]: amount_cents}
        for _description, amount_cents, payer_index in _EXPENSES
    )
    for position, (description, amount_cents, _payer_index) in enumerate(_EXPENSES):
        expense = by_expense_id[DEMO_EXPENSE_IDS[position]]
        if (
            expense["amount_cents"] != amount_cents
            or expense["contributors"] != expected_contributors[position]
            or set(expense["beneficiaries"]) != set(DEMO_PARTICIPANT_IDS)
        ):
            _corrupted(
                f"Seeded expense {position + 1} does not match its source shape."
            )
        seeded_expense = session.get(Expense, DEMO_EXPENSE_IDS[position])
        if seeded_expense is None or seeded_expense.description != description:
            _corrupted(f"Seeded expense {position + 1} has an unexpected description.")

    balances = compute_balances(participants, source_expenses)
    expected_balances = (56_000, 0, -16_000, -40_000)
    for participant_id, expected in zip(DEMO_PARTICIPANT_IDS, expected_balances):
        row = balances.get(participant_id)
        if row is None or row.balance_cents != expected:
            _corrupted("Seeded balance results do not match AO-01.")

    settlement = build_settlement(balances)
    actual_transfers = [
        (
            transfer["from_participant_id"],
            transfer["to_participant_id"],
            transfer["amount_cents"],
        )
        for transfer in settlement["transfers"]
    ]
    expected_transfers = [
        (DEMO_PARTICIPANT_IDS[3], DEMO_PARTICIPANT_IDS[0], 40_000),
        (DEMO_PARTICIPANT_IDS[2], DEMO_PARTICIPANT_IDS[0], 16_000),
    ]
    if actual_transfers != expected_transfers:
        _corrupted("Seeded settlement results do not match AO-01.")


def seed_demo(
    session: Session,
    *,
    owner_password: str | None = None,
    member_password: str | None = None,
    hasher: Any | None = None,
) -> SeedSummary:
    """Create or validate demo source data in one fail-closed transaction."""

    settings = get_settings()
    owner_secret = _password(
        owner_password, "DEMO_OWNER_PASSWORD", settings.demo_owner_password
    )
    member_secret = _password(
        member_password, "DEMO_MEMBER_PASSWORD", settings.demo_member_password
    )
    accounts_created = participants_created = expenses_created = 0
    try:
        owner, owner_created = _ensure_account(
            session, "demo.owner", DEMO_OWNER_ID, owner_secret, hasher
        )
        if owner_created:
            accounts_created += 1
        member, member_created = _ensure_account(
            session, "demo.member", DEMO_MEMBER_ID, member_secret, hasher
        )
        if member_created:
            accounts_created += 1
        group = _ensure_group(session, owner.id)
        _ensure_membership(session, group.id, owner.id)
        _ensure_membership(session, group.id, member.id)

        participants = []
        for position, name in enumerate(_PARTICIPANTS):
            participant, created = _ensure_participant(session, position, name)
            participants.append(participant)
            if created:
                participants_created += 1
        participant_tuple = tuple(participants)

        for position, (description, amount_cents, payer_index) in enumerate(_EXPENSES):
            if _ensure_expense(
                session,
                position,
                description,
                amount_cents,
                payer_index,
                participant_tuple,
            ):
                expenses_created += 1

        session.flush()
        _validate_seed(session, owner.id, member.id)
        session.commit()
    except PersistenceCorruptedError as error:
        session.rollback()
        logger.error(
            "demo seed failed closed: error_code=%s evidence=%s",
            error.code,
            str(error),
        )
        raise
    except SQLAlchemyError as error:
        session.rollback()
        logger.error(
            "demo seed failed closed: error_code=persistence_corrupted evidence=%s",
            str(error),
        )
        raise PersistenceCorruptedError(
            "Demo seed stopped after a persistence integrity failure."
        ) from error
    except Exception:
        session.rollback()
        raise

    return SeedSummary(
        group_id=DEMO_GROUP_ID,
        accounts_created=accounts_created,
        participants_created=participants_created,
        expenses_created=expenses_created,
    )


def _seed_connection(
    connection: Any,
    owner_password: str | None,
    member_password: str | None,
) -> SeedSummary:
    with Session(bind=connection) as session:
        return seed_demo(
            session,
            owner_password=owner_password,
            member_password=member_password,
        )


async def _run() -> SeedSummary:
    settings = get_settings()
    engine: AsyncEngine = create_engine(settings)
    try:
        async with engine.begin() as connection:
            return await connection.run_sync(
                lambda sync_connection: _seed_connection(sync_connection, None, None)
            )
    finally:
        await engine.dispose()


def main() -> int:
    """Run the seed without printing credentials or hashes."""

    try:
        summary = asyncio.run(_run())
    except PersistenceCorruptedError as error:
        logger.error("demo seed aborted: error_code=%s", error.code)
        return 1
    print(
        "Seeded demo group "
        f"{summary.group_id}: {summary.accounts_created} accounts, "
        f"{summary.participants_created} participants, "
        f"{summary.expenses_created} expenses created."
    )
    return 0


if __name__ == "__main__":  # pragma: no cover - exercised by the runbook
    raise SystemExit(main())


__all__ = [
    "DEMO_EXPENSE_IDS",
    "DEMO_GROUP_ID",
    "DEMO_MEMBER_ID",
    "DEMO_OWNER_ID",
    "DEMO_PARTICIPANT_IDS",
    "SeedSummary",
    "main",
    "seed_demo",
]
