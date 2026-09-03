"""Integration coverage for the deterministic, idempotent demo seed."""

from typing import cast

import pytest
from backend.app.adapters.db.repositories import (
    ExpenseRepositoryAdapter,
    ParticipantRepositoryAdapter,
)
from backend.app.adapters.db.tables import (
    Account,
    AuthSession,
    Base,
    Expense,
    ExpenseBeneficiary,
    ExpenseContribution,
    Group,
    GroupMembership,
    Participant,
)
from backend.app.application.derived_service import DerivedService
from backend.app.domain.balance_service import PersistenceCorruptedError
from backend.app.domain.settlement_service import build_settlement
from backend.scripts.seed_demo import (
    DEMO_EXPENSE_IDS,
    DEMO_GROUP_ID,
    DEMO_PARTICIPANT_IDS,
    seed_demo,
)
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session


@pytest.fixture
def db_session():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    engine.dispose()


def test_seed_is_idempotent_and_matches_ao_01_state(db_session):
    seed_demo(
        db_session, owner_password="owner-secret", member_password="member-secret"
    )
    hashes_before = {
        row.login_name: row.password_hash for row in db_session.query(Account)
    }
    counts_before = {
        "participants": db_session.query(Participant).count(),
        "expenses": db_session.query(Expense).count(),
    }

    second = seed_demo(
        db_session, owner_password="different-secret", member_password="other"
    )

    assert second.accounts_created == 0
    assert second.participants_created == 0
    assert second.expenses_created == 0
    assert counts_before == {
        "participants": 4,
        "expenses": 4,
    }
    assert db_session.query(Account).count() == 2
    assert db_session.query(AuthSession).count() == 0
    assert db_session.query(GroupMembership).count() == 2
    group = db_session.get(Group, DEMO_GROUP_ID)
    assert group is not None
    assert group.settlement_policy == "owner_only"
    assert {
        "participants": db_session.query(Participant).count(),
        "expenses": db_session.query(Expense).count(),
    } == counts_before
    participants = db_session.scalars(
        select(Participant)
        .where(Participant.group_id == cast(str, DEMO_GROUP_ID))
        .order_by(Participant.created_at)
    )
    assert [row.name for row in participants] == ["Ana", "Beto", "Carla", "Diego"]
    assert set(DEMO_PARTICIPANT_IDS) == {
        row.id for row in db_session.scalars(select(Participant))
    }
    assert set(DEMO_EXPENSE_IDS) == {
        row.id for row in db_session.scalars(select(Expense))
    }
    expenses = list(
        db_session.scalars(select(Expense).order_by(Expense.created_at, Expense.id))
    )
    assert [(row.description, row.amount_cents) for row in expenses] == [
        ("Cabaña", 80_000),
        ("Entradas a El Fuerte", 16_000),
        ("Cena", 40_000),
        ("Gasolina", 24_000),
    ]
    expected_payers = [
        DEMO_PARTICIPANT_IDS[0],
        DEMO_PARTICIPANT_IDS[0],
        DEMO_PARTICIPANT_IDS[1],
        DEMO_PARTICIPANT_IDS[2],
    ]
    for expense, payer_id in zip(expenses, expected_payers, strict=True):
        contributions = list(
            db_session.scalars(
                select(ExpenseContribution).where(
                    ExpenseContribution.expense_id == expense.id
                )
            )
        )
        assert [(row.participant_id, row.amount_cents) for row in contributions] == [
            (payer_id, expense.amount_cents)
        ]
        beneficiary_ids = set(
            db_session.scalars(
                select(ExpenseBeneficiary.participant_id).where(
                    ExpenseBeneficiary.expense_id == expense.id
                )
            )
        )
        assert beneficiary_ids == set(DEMO_PARTICIPANT_IDS)
    assert hashes_before == {
        row.login_name: row.password_hash for row in db_session.query(Account)
    }
    derived = DerivedService(
        ParticipantRepositoryAdapter(db_session), ExpenseRepositoryAdapter(db_session)
    )
    balances = derived.get_balances(cast(str, DEMO_GROUP_ID))
    assert [
        balances[participant_id].balance_cents
        for participant_id in DEMO_PARTICIPANT_IDS
    ] == [
        56_000,
        0,
        -16_000,
        -40_000,
    ]
    assert sum(row.balance_cents for row in balances.values()) == 0
    settlement = build_settlement(balances)
    assert [
        (row["from_participant_id"], row["to_participant_id"], row["amount_cents"])
        for row in settlement["transfers"]
    ] == [
        (DEMO_PARTICIPANT_IDS[3], DEMO_PARTICIPANT_IDS[0], 40_000),
        (DEMO_PARTICIPANT_IDS[2], DEMO_PARTICIPANT_IDS[0], 16_000),
    ]


def test_seed_fails_closed_when_existing_source_is_corrupted(db_session):
    seed_demo(
        db_session, owner_password="owner-secret", member_password="member-secret"
    )
    expense = db_session.get(Expense, DEMO_EXPENSE_IDS[0])
    assert expense is not None
    expense.amount_cents = 1
    db_session.commit()

    with pytest.raises(PersistenceCorruptedError) as failure:
        seed_demo(
            db_session,
            owner_password="owner-secret",
            member_password="member-secret",
        )
    assert failure.value.code == "persistence_corrupted"
