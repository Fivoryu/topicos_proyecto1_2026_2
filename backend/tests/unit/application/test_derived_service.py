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
