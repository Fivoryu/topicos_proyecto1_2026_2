"""Fake-repository tests for participant lifecycle and CC-04 rename."""

from dataclasses import dataclass, field
from datetime import UTC, datetime
from types import SimpleNamespace
from uuid import UUID, uuid4

import pytest
from backend.app.application.participant_service import ParticipantService
from backend.app.domain.errors import (
    DomainError,
    DuplicateParticipantNameError,
    InvalidParticipantNameError,
    ParticipantInUseError,
)


@dataclass
class FakeParticipant:
    id: UUID | str
    group_id: str
    name: str
    normalized_name: str
    archived_at: datetime | None = None
    created_at: datetime = field(
        default_factory=lambda: datetime(2026, 1, 1, tzinfo=UTC)
    )
    references: bool = False


class FakeParticipantRepository:
    def __init__(self, participants=()):
        self.rows = {row.id: row for row in participants}
        self.updated_fields = []

    def list_by_group(self, group_id):
        return sorted(
            (row for row in self.rows.values() if row.group_id == group_id),
            key=lambda row: (row.created_at, str(row.id)),
        )

    def find_by_id(self, group_id, participant_id):
        row = self.rows.get(participant_id)
        return row if row is not None and row.group_id == group_id else None

    def find_by_normalized_name(self, group_id, normalized_name, exclude_id=None):
        return next(
            (
                row
                for row in self.list_by_group(group_id)
                if row.normalized_name == normalized_name and row.id != exclude_id
            ),
            None,
        )

    def add(self, group_id, row):
        assert row.group_id == group_id
        self.rows[row.id] = row
        return row

    def update_name(self, group_id, participant_id, name, normalized_name):
        row = self.find_by_id(group_id, participant_id)
        if row is None:
            return None
        self.updated_fields.append((participant_id, name, normalized_name))
        row.name = name
        row.normalized_name = normalized_name
        return row

    def set_archived(self, group_id, participant_id, archived_at):
        row = self.find_by_id(group_id, participant_id)
        if row is None:
            return None
        row.archived_at = archived_at
        return row

    def has_references(self, group_id, participant_id):
        row = self.find_by_id(group_id, participant_id)
        return row is not None and getattr(row, "references", False)

    def delete(self, group_id, participant_id):
        row = self.find_by_id(group_id, participant_id)
        if row is not None:
            del self.rows[participant_id]


class FakeUnitOfWork:
    def __init__(self):
        self.commits = 0
        self.rollbacks = 0

    def __enter__(self):
        return self

    def __exit__(self, exc_type, _exc, _tb):
        if exc_type:
            self.rollbacks += 1
        else:
            self.commits += 1
        return False


def _row(group_id, name, *, archived=False, references=False):
    return FakeParticipant(
        id=uuid4(),
        group_id=group_id,
        name=name,
        normalized_name=name.casefold(),
        archived_at=datetime(2026, 1, 2, tzinfo=UTC) if archived else None,
        references=references,
    )


@pytest.fixture
def fixture():
    group_id = str(uuid4())
    ana = _row(group_id, "Ana", references=True)
    archived = _row(group_id, "Carla", archived=True, references=True)
    archived.created_at = datetime(2026, 1, 2, tzinfo=UTC)
    repository = FakeParticipantRepository((ana, archived))
    uow = FakeUnitOfWork()
    return SimpleNamespace(
        group_id=group_id,
        ana=ana,
        archived=archived,
        repository=repository,
        uow=uow,
        service=ParticipantService(repository, uow),
    )


def test_add_and_list_trims_names_and_keeps_archived_rows_in_creation_order(fixture):
    added = fixture.service.add(fixture.group_id, "  Beto  ")

    assert added.name == "Beto"
    assert added.normalized_name == "beto"
    assert [row.name for row in fixture.service.list(fixture.group_id)] == [
        "Ana",
        "Carla",
        "Beto",
    ]


def test_add_rejects_blank_and_normalized_conflicts_including_archived(fixture):
    with pytest.raises(InvalidParticipantNameError) as blank:
        fixture.service.add(fixture.group_id, "  \t")
    with pytest.raises(DuplicateParticipantNameError) as active_conflict:
        fixture.service.add(fixture.group_id, "  ANA ")
    with pytest.raises(DuplicateParticipantNameError) as archived_conflict:
        fixture.service.add(fixture.group_id, " carla ")

    assert blank.value.code == "invalid_participant_name"
    assert active_conflict.value.code == "duplicate_participant_name"
    assert archived_conflict.value.code == "duplicate_participant_name"
    assert len(fixture.repository.rows) == 2


def test_archive_reactivate_and_protected_delete_preserve_references(fixture):
    fixture.service.archive(fixture.group_id, fixture.ana.id)
    assert fixture.ana.archived_at is not None
    fixture.service.reactivate(fixture.group_id, fixture.ana.id)
    assert fixture.ana.archived_at is None

    with pytest.raises(ParticipantInUseError) as error:
        fixture.service.delete(fixture.group_id, fixture.ana.id)
    assert error.value.code == "participant_in_use"
    assert (
        fixture.repository.find_by_id(fixture.group_id, fixture.ana.id) is fixture.ana
    )

    unused = fixture.service.add(fixture.group_id, "Diego")
    fixture.service.delete(fixture.group_id, unused.id)
    assert fixture.repository.find_by_id(fixture.group_id, unused.id) is None


def test_rename_preserves_id_archived_status_references_and_balance(fixture):
    fixture.archived.balance_cents = 56000
    participant_id = fixture.archived.id
    archived_at = fixture.archived.archived_at

    renamed = fixture.service.rename(fixture.group_id, participant_id, "  Carla L. ")

    assert renamed.id == participant_id
    assert renamed.name == "Carla L."
    assert renamed.normalized_name == "carla l."
    assert renamed.archived_at == archived_at
    assert renamed.references is True
    assert renamed.balance_cents == 56000
    assert fixture.repository.updated_fields == [
        (participant_id, "Carla L.", "carla l.")
    ]


def test_rename_uses_unicode_casefold_conflict_and_invalid_input_is_noop(fixture):
    original = fixture.ana.name
    with pytest.raises(DuplicateParticipantNameError):
        fixture.service.rename(fixture.group_id, fixture.ana.id, "  CARLA ")
    with pytest.raises(InvalidParticipantNameError):
        fixture.service.rename(fixture.group_id, fixture.ana.id, " \n ")

    assert fixture.ana.name == original
    assert fixture.repository.updated_fields == []
    assert fixture.uow.commits == 0
    assert fixture.uow.rollbacks == 0

    renamed = fixture.service.rename(fixture.group_id, fixture.ana.id, " ÁNA ")
    assert renamed.name == "ÁNA"
    assert renamed.normalized_name == "ána"


def test_invalid_service_input_does_not_change_repository_state(fixture):
    before = [
        (row.id, row.name, row.normalized_name)
        for row in fixture.repository.rows.values()
    ]

    with pytest.raises(DomainError):
        fixture.service.rename(fixture.group_id, uuid4(), "New name")

    after = [
        (row.id, row.name, row.normalized_name)
        for row in fixture.repository.rows.values()
    ]
    assert after == before
