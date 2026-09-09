from datetime import UTC, datetime

from backend.app.application.derived_service import DerivedService
from backend.app.application.ports import ParticipantRecord


def test_read_derives_balances_and_settlement_from_source_expenses():
    group_id = "group-one"
    participants = [
        ParticipantRecord(
            "ana",
            group_id,
            "Ana",
            "ana",
            created_at=datetime(2026, 1, 1, tzinfo=UTC),
        ),
        ParticipantRecord(
            "beto",
            group_id,
            "Beto",
            "beto",
            created_at=datetime(2026, 1, 2, tzinfo=UTC),
        ),
    ]
    expense = {
        "id": "expense-one",
        "group_id": group_id,
        "amount_cents": 10_000,
        "contributors": {"ana": 10_000},
        "beneficiaries": ("ana", "beto"),
    }

    class Participants:
        def list_by_group(self, requested_group_id: str):
            assert requested_group_id == group_id
            return participants

    class Expenses:
        def list_by_group(self, requested_group_id: str):
            assert requested_group_id == group_id
            return [expense]

    result = DerivedService(Participants(), Expenses()).read(group_id)

    assert result["balances"]["ana"].balance_cents == 5_000
    assert result["balances"]["beto"].balance_cents == -5_000
    assert result["settlement"]["transfers"] == [
        {
            "from_participant_id": "beto",
            "to_participant_id": "ana",
            "amount_cents": 5_000,
        }
    ]


def test_scoped_read_filters_outing_expenses_and_keeps_group_participants():
    group_id = "group-one"
    participants = [
        ParticipantRecord("ana", group_id, "Ana", "ana"),
        ParticipantRecord("beto", group_id, "Beto", "beto"),
        ParticipantRecord("carla", group_id, "Carla", "carla"),
    ]
    expenses = [
        {
            "id": "general",
            "outing_id": None,
            "amount_cents": 12_000,
            "contributors": {"ana": 12_000},
            "beneficiaries": ("ana", "beto"),
        },
        {
            "id": "outing-one-expense",
            "outing_id": "outing-one",
            "amount_cents": 6_000,
            "contributors": {"carla": 6_000},
            "beneficiaries": ("ana", "beto"),
        },
        {
            "id": "outing-two-expense",
            "outing_id": "outing-two",
            "amount_cents": 9_000,
            "contributors": {"beto": 9_000},
            "beneficiaries": ("ana", "carla"),
        },
    ]

    class Participants:
        def list_by_group(self, requested_group_id: str):
            assert requested_group_id == group_id
            return participants

    class Expenses:
        def __init__(self):
            self.calls = []

        def list_by_group(self, requested_group_id: str, *, outing_filter=None):
            assert requested_group_id == group_id
            self.calls.append(outing_filter)
            if outing_filter is None:
                return expenses
            return [row for row in expenses if row["outing_id"] == outing_filter]

    source = Expenses()
    service = DerivedService(Participants(), source)

    group_result = service.read(group_id)
    outing_result = service.read(group_id, outing_id="outing-one")

    assert source.calls == [None, "outing-one"]
    assert list(group_result["balances"]) == ["ana", "beto", "carla"]
    assert sum(row.balance_cents for row in group_result["balances"].values()) == 0
    assert group_result["settlement"]["transfers"] == [
        {
            "from_participant_id": "ana",
            "to_participant_id": "carla",
            "amount_cents": 1_500,
        }
    ]
    assert outing_result["balances"] == {
        "ana": {"paid_cents": 0, "owed_cents": 3_000, "balance_cents": -3_000},
        "beto": {"paid_cents": 0, "owed_cents": 3_000, "balance_cents": -3_000},
        "carla": {"paid_cents": 6_000, "owed_cents": 0, "balance_cents": 6_000},
    }
    assert sum(row.balance_cents for row in outing_result["balances"].values()) == 0
    assert outing_result["settlement"]["transfers"] == [
        {
            "from_participant_id": "ana",
            "to_participant_id": "carla",
            "amount_cents": 3_000,
        },
        {
            "from_participant_id": "beto",
            "to_participant_id": "carla",
            "amount_cents": 3_000,
        },
    ]
    assert not hasattr(service, "_derived_repository")


def test_empty_outing_scope_keeps_every_authorized_participant_neutral():
    group_id = "group-one"
    participants = [
        ParticipantRecord("ana", group_id, "Ana", "ana"),
        ParticipantRecord("beto", group_id, "Beto", "beto"),
    ]

    class Repository:
        def list_by_group(self, requested_group_id: str, *, outing_filter=None):
            assert requested_group_id == group_id
            assert outing_filter == "empty-outing"
            return []

    balances = DerivedService(
        type("Participants", (), {"list_by_group": lambda self, _: participants})(),
        Repository(),
    ).get_balances(group_id, outing_id="empty-outing")

    assert list(balances) == ["ana", "beto"]
    assert all(row.balance_cents == 0 for row in balances.values())
