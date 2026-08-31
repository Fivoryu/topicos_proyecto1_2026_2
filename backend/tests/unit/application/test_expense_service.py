from copy import deepcopy
from dataclasses import dataclass
from datetime import UTC, datetime

import pytest
from backend.app.application.derived_service import DerivedService
from backend.app.application.expense_service import ExpenseService
from backend.app.application.ports import ParticipantRecord
from backend.app.domain.errors import (
    ContributionMismatchError,
    InvalidAmountError,
    InvalidParticipantReferenceError,
    NoBeneficiariesError,
    NoParticipantsError,
)


@dataclass
class FakeExpense:
    id: str
    group_id: str
    description: str
    amount_cents: int
    contributors: dict[str, int]
    beneficiaries: tuple[str, ...]
    created_at: datetime
    updated_at: datetime


class FakeParticipants:
    def __init__(self, rows):
        self.rows = rows

    def list_by_group(self, group_id: str):
        return [row for row in self.rows if row.group_id == group_id]


class FakeExpenses:
    def __init__(self, rows=()):
        self.rows = list(rows)

    def list_by_group(self, group_id: str):
        return [row for row in self.rows if row.group_id == group_id]

    def find_by_id(self, group_id: str, expense_id: str):
        return next(
            (
                row
                for row in self.rows
                if row.group_id == group_id and row.id == expense_id
            ),
            None,
        )

    def create(self, group_id: str, expense, contributions=(), beneficiaries=()):
        assert expense.group_id == group_id
        self.rows.append(expense)
        return expense

    def update(
        self,
        group_id: str,
        expense_id: str,
        replacement,
        contributions=(),
        beneficiaries=(),
    ):
        current = self.find_by_id(group_id, expense_id)
        if current is None:
            return None
        current.description = replacement.description
        current.amount_cents = replacement.amount_cents
        current.updated_at = replacement.updated_at
        current.contributors = dict(contributions)
        current.beneficiaries = tuple(beneficiaries)
        return current

    def delete(self, group_id: str, expense_id: str):
        current = self.find_by_id(group_id, expense_id)
        if current is None:
            return False
        self.rows.remove(current)
        return True


class FakeUnitOfWork:
    def __init__(self, participants, expenses):
        self.participants = participants
        self.expenses = expenses
        self.commits = 0
        self.rollbacks = 0
        self.flushes = 0
        self._snapshot = None

    def __enter__(self):
        self._snapshot = deepcopy(self.expenses.rows)
        return self

    def __exit__(self, exc_type, _value, _traceback):
        if exc_type is None:
            self.commits += 1
        else:
            self.rollbacks += 1
            self.expenses.rows[:] = self._snapshot
        return False

    def flush(self):
        self.flushes += 1


def participant(group_id: str, participant_id: str, day: int, *, archived=False):
    return ParticipantRecord(
        participant_id,
        group_id,
        participant_id.title(),
        participant_id,
        archived_at=(datetime(2026, 1, day, tzinfo=UTC) if archived else None),
        created_at=datetime(2026, 1, day, tzinfo=UTC),
    )


def fixture(*, archived=False, expenses=()):
    group_id = "group-one"
    participants = FakeParticipants(
        [
            participant(group_id, "ana", 1),
            participant(group_id, "beto", 2),
            participant(group_id, "carla", 3, archived=archived),
        ]
    )
    repository = FakeExpenses(expenses)
    uow = FakeUnitOfWork(participants, repository)
    return (
        group_id,
        participants,
        repository,
        uow,
        ExpenseService(repository, participants, uow),
    )


def test_create_persists_valid_multi_contributor_expense_atomically():
    group_id, _participants, expenses, uow, service = fixture()

    created = service.create(
        group_id,
        description="  Dinner  ",
        amount_cents=10_000,
        contributors={"ana": 6_000, "beto": 4_000},
        beneficiaries=["ana", "beto", "carla"],
    )

    assert created.description == "Dinner"
    assert created.amount_cents == 10_000
    assert created.contributors == {"ana": 6_000, "beto": 4_000}
    assert created.beneficiaries == ("ana", "beto", "carla")
    assert len(expenses.rows) == 1
    assert uow.commits == 1
    assert uow.rollbacks == 0
    assert uow.flushes == 1


def test_creation_rejects_empty_group_before_persistence():
    group_id, participants, expenses, uow, service = fixture()
    participants.rows.clear()

    with pytest.raises(NoParticipantsError) as error:
        service.create(group_id, "Dinner", 10_000, {"ana": 10_000}, ["ana"])

    assert error.value.code == "no_participants"
    assert expenses.rows == []
    assert uow.commits == 0
    assert uow.rollbacks == 1


def test_creation_rejects_no_beneficiaries_invalid_reference_and_mismatch():
    group_id, _participants, expenses, uow, service = fixture()

    with pytest.raises(NoBeneficiariesError):
        service.create(group_id, "Dinner", 10_000, {"ana": 10_000}, [])
    with pytest.raises(InvalidParticipantReferenceError):
        service.create(group_id, "Dinner", 10_000, {"missing": 10_000}, ["missing"])
    with pytest.raises(ContributionMismatchError):
        service.create(
            group_id,
            "Dinner",
            10_000,
            {"ana": 6_000, "beto": 3_000},
            ["ana", "beto"],
        )

    assert expenses.rows == []
    assert uow.commits == 0
    assert uow.rollbacks == 3


def test_creation_rejects_non_positive_amount_and_archived_participant():
    group_id, _participants, expenses, uow, service = fixture(archived=True)

    with pytest.raises(InvalidAmountError):
        service.create(group_id, "Dinner", 0, {"ana": 1}, ["ana"])
    with pytest.raises(InvalidParticipantReferenceError):
        service.create(group_id, "Dinner", 10_000, {"ana": 10_000}, ["carla"])

    assert expenses.rows == []
    assert uow.commits == 0
    assert uow.rollbacks == 2


def test_edit_replaces_complete_source_and_payer_change_recalculates_derived_values():
    group_id = "group-one"
    original = FakeExpense(
        "expense-one",
        group_id,
        "Lunch",
        30_000,
        {"ana": 30_000},
        ("ana", "beto", "carla"),
        datetime(2026, 1, 4, tzinfo=UTC),
        datetime(2026, 1, 4, tzinfo=UTC),
    )
    group_id, participants, expenses, uow, service = fixture(expenses=(original,))

    updated = service.edit(
        group_id,
        original.id,
        "Lunch paid by Beto",
        30_000,
        {"beto": 30_000},
        ["ana", "beto", "carla"],
    )
    balances = DerivedService(participants, expenses).get_balances(group_id)

    assert updated.id == original.id
    assert updated.contributors == {"beto": 30_000}
    assert balances["beto"].balance_cents == 20_000
    assert balances["ana"].balance_cents == -10_000
    assert balances["carla"].balance_cents == -10_000
    assert uow.commits == 1


def test_edit_accepts_a_referenced_archived_participant():
    group_id = "group-one"
    original = FakeExpense(
        "expense-one",
        group_id,
        "Lunch",
        10_000,
        {"ana": 10_000},
        ("ana", "beto"),
        datetime(2026, 1, 4, tzinfo=UTC),
        datetime(2026, 1, 4, tzinfo=UTC),
    )
    group_id, _participants, expenses, uow, service = fixture(
        archived=True, expenses=(original,)
    )

    updated = service.edit(
        group_id,
        original.id,
        "Lunch retained archived Carla",
        10_000,
        {"ana": 10_000},
        ["ana", "carla"],
    )

    assert updated.beneficiaries == ("ana", "carla")
    assert expenses.rows[0].beneficiaries == ("ana", "carla")
    assert uow.commits == 1


def test_invalid_edit_is_noop_and_rolls_back_before_replacing_children():
    group_id = "group-one"
    original = FakeExpense(
        "expense-one",
        group_id,
        "Lunch",
        10_000,
        {"ana": 10_000},
        ("ana", "beto"),
        datetime(2026, 1, 4, tzinfo=UTC),
        datetime(2026, 1, 4, tzinfo=UTC),
    )
    group_id, participants, expenses, uow, service = fixture(expenses=(original,))
    before = deepcopy(original)

    with pytest.raises(InvalidAmountError):
        service.edit(
            group_id,
            original.id,
            "Invalid edit",
            0,
            {"beto": 0},
            ["ana", "beto"],
        )

    assert expenses.rows[0] == before
    assert DerivedService(participants, expenses).get_balances(group_id) == {
        "ana": {"paid_cents": 10_000, "owed_cents": 5_000, "balance_cents": 5_000},
        "beto": {"paid_cents": 0, "owed_cents": 5_000, "balance_cents": -5_000},
        "carla": {"paid_cents": 0, "owed_cents": 0, "balance_cents": 0},
    }
    assert uow.commits == 0
    assert uow.rollbacks == 1


def test_delete_withdraws_effect_and_unknown_delete_leaves_state_unchanged():
    group_id = "group-one"
    original = FakeExpense(
        "expense-one",
        group_id,
        "Lunch",
        10_000,
        {"ana": 10_000},
        ("ana", "beto"),
        datetime(2026, 1, 4, tzinfo=UTC),
        datetime(2026, 1, 4, tzinfo=UTC),
    )
    group_id, participants, expenses, uow, service = fixture(expenses=(original,))

    service.delete(group_id, original.id)
    derived = DerivedService(participants, expenses)
    assert derived.get_balances(group_id)["ana"].balance_cents == 0
    assert derived.get_settlement(group_id) == {"settled": True, "transfers": []}
    with pytest.raises(Exception):
        service.delete(group_id, original.id)
    assert expenses.rows == []
    assert uow.commits == 1
    assert uow.rollbacks == 1
