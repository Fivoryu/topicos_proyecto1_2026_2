"""Fail-closed seed corruption and documented local recovery."""

from pathlib import Path

import pytest
from backend.app.adapters.db.tables import Base, Expense
from backend.app.domain.balance_service import PersistenceCorruptedError
from backend.scripts.seed_demo import DEMO_EXPENSE_IDS, seed_demo
from sqlalchemy import create_engine
from sqlalchemy.orm import Session


@pytest.fixture
def db_session():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    engine.dispose()


def test_corrupted_seed_requires_reset_and_reseed(db_session):
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

    engine = db_session.get_bind()
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    seed_demo(
        db_session, owner_password="owner-secret", member_password="member-secret"
    )
    assert db_session.query(Expense).count() == 3


def test_recovery_document_contains_reset_and_reseed_sequence():
    document = Path("docs/demo-recovery.md").read_text(encoding="utf-8")
    assert "docker compose -f infra/docker-compose.yml down -v" in document
    assert "python -m alembic -c backend/alembic.ini upgrade head" in document
    assert "python -m backend.scripts.seed_demo" in document
