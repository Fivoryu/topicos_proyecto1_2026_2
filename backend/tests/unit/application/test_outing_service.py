from dataclasses import dataclass
from datetime import UTC, datetime

import pytest
from backend.app.application.authorization import ForbiddenError
from backend.app.application.outing_service import (
    ArchivedOutingReadOnlyError,
    InvalidOutingNameError,
    OutingNotEmptyError,
    OutingNotFoundError,
    OutingService,
)

NOW = datetime(2026, 1, 1, tzinfo=UTC)


@dataclass
class Outing:
    id: str
    group_id: str
    name: str
    archived_at: datetime | None = None
    created_at: datetime = NOW
    updated_at: datetime = NOW


class Repository:
    def __init__(self):
        self.rows = [Outing("o1", "g1", "Old name")]
        self.expenses: set[str] = set()

    def list_by_group(self, group_id):
        return [row for row in self.rows if row.group_id == group_id]

    def find_by_id(self, group_id, outing_id):
        return next(
            (
                row
                for row in self.rows
                if row.group_id == group_id and row.id == outing_id
            ),
            None,
        )

    def create(self, group_id, outing):
        self.rows.append(outing)
        return outing

    def update_active(self, group_id, outing_id, name, updated_at):
        row = self.find_by_id(group_id, outing_id)
        if row is not None:
            row.name, row.updated_at = name, updated_at
        return row

    def archive(self, group_id, outing_id, archived_at):
        row = self.find_by_id(group_id, outing_id)
        if row is not None:
            row.archived_at, row.updated_at = archived_at, archived_at
        return row

    def unarchive(self, group_id, outing_id, updated_at):
        row = self.find_by_id(group_id, outing_id)
        if row is not None:
            row.archived_at, row.updated_at = None, updated_at
        return row

    def has_expenses(self, group_id, outing_id):
        return outing_id in self.expenses

    def delete_if_empty(self, group_id, outing_id):
        row = self.find_by_id(group_id, outing_id)
        if row is None or self.has_expenses(group_id, outing_id):
            return False
        self.rows.remove(row)
        return True


class UnitOfWork:
    def __init__(self, repository):
        self.outings = repository
        self.commits = 0
        self.rollbacks = 0
        self.fail_commit = False
        self._snapshot = None

    def __enter__(self):
        self._snapshot = list(self.outings.rows)
        return self

    def __exit__(self, exc_type, _value, _traceback):
        if exc_type is not None or self.fail_commit:
            self.outings.rows[:] = self._snapshot
            self.rollbacks += 1
            if self.fail_commit and exc_type is None:
                raise RuntimeError("commit failed")
        else:
            self.commits += 1
        return False

    def flush(self):
        return None


class Publisher:
    def __init__(self):
        self.groups = []

    def publish(self, group_id):
        self.groups.append(group_id)


@dataclass
class Actor:
    account_id: str
    role: str
    group_id: str | None = "g1"


@dataclass(frozen=True)
class AuthorizationContext:
    group_id: str
    role: str


class Authorization:
    def __init__(self, roles):
        self.roles = roles
        self.calls = []

    def authorize(self, actor, group_id, operation):
        self.calls.append((actor.account_id, group_id, operation))
        return AuthorizationContext(group_id, self.roles[actor.account_id])


@pytest.fixture
def fixture():
    repository = Repository()
    uow = UnitOfWork(repository)
    publisher = Publisher()
    service = OutingService(repository, uow, invalidation_publisher=publisher)
    return service, repository, uow, publisher


def test_member_creates_and_edits_trimmed_active_outing(fixture):
    service, repository, uow, publisher = fixture
    member = Actor("member", "member")

    created = service.create("g1", "  Weekend  ", actor=member)
    assert created.name == "Weekend"
    assert created.group_id == "g1"

    edited = service.edit("g1", created.id, "  Weekend final ", actor=member)

    assert edited.name == "Weekend final"
    assert edited.archived_at is None
    assert uow.commits == 2
    assert publisher.groups == ["g1", "g1"]
    assert [row.name for row in repository.list_by_group("g2")] == []


def test_owner_lifecycle_and_empty_delete_are_group_scoped(fixture):
    service, repository, _uow, publisher = fixture
    owner = Actor("owner", "owner")

    archived = service.archive("g1", "o1", actor=owner)
    assert archived.archived_at is not None

    restored = service.unarchive("g1", "o1", actor=owner)
    assert restored.archived_at is None

    service.delete("g1", "o1", actor=owner)
    assert service.list("g2", actor=Actor("owner", "owner", "g2")) == []
    assert repository.find_by_id("g1", "o1") is None
    assert publisher.groups == ["g1", "g1", "g1"]


def test_member_cannot_archive_and_archived_outing_is_read_only(fixture):
    service, _repository, uow, publisher = fixture
    member = Actor("member", "member")
    owner = Actor("owner", "owner")
    service.archive("g1", "o1", actor=owner)

    with pytest.raises(ForbiddenError):
        service.archive("g1", "o1", actor=member)
    with pytest.raises(ArchivedOutingReadOnlyError):
        service.edit("g1", "o1", "new", actor=owner)
    with pytest.raises(ArchivedOutingReadOnlyError):
        service.delete("g1", "o1", actor=owner)

    # Authorization is checked before opening a transaction; only the two
    # archived mutations enter the UoW and roll back.
    assert uow.rollbacks == 2
    assert uow.commits == 1
    assert publisher.groups == ["g1"]


def test_actor_cannot_mutate_a_different_group(fixture):
    service, repository, uow, publisher = fixture
    member = Actor("member", "member", group_id="g1")

    with pytest.raises(ForbiddenError):
        service.create("g2", "Foreign group", actor=member)

    assert repository.list_by_group("g2") == []
    assert uow.commits == uow.rollbacks == 0
    assert publisher.groups == []


def test_non_empty_delete_preserves_history_and_failed_commit_publishes_nothing(
    fixture,
):
    service, repository, uow, publisher = fixture
    owner = Actor("owner", "owner")
    repository.expenses.add("o1")

    with pytest.raises(OutingNotEmptyError):
        service.delete("g1", "o1", actor=owner)
    with pytest.raises(OutingNotFoundError):
        service.edit("g1", "missing", "name", actor=owner)

    repository.expenses.clear()
    uow.fail_commit = True
    with pytest.raises(RuntimeError, match="commit failed"):
        service.create("g1", "rolled back", actor=owner)

    assert repository.find_by_id("g1", "o1").name == "Old name"
    assert not any(row.name == "rolled back" for row in repository.rows)
    assert publisher.groups == []


def test_authorization_collaborator_derives_owner_role_for_lifecycle(fixture):
    _service, repository, uow, publisher = fixture
    authorization = Authorization({"member": "member", "owner": "owner"})
    service = OutingService(
        repository,
        uow,
        authorization_service=authorization,
        invalidation_publisher=publisher,
    )

    with pytest.raises(ForbiddenError):
        service.archive("g1", "o1", actor=Actor("member", "owner"))

    archived = service.archive("g1", "o1", actor=Actor("owner", "member"))

    assert archived.archived_at is not None
    assert authorization.calls == [
        ("member", "g1", "read_group"),
        ("owner", "g1", "read_group"),
    ]


def test_authorization_collaborator_covers_member_reads_and_mutations(fixture):
    _service, repository, uow, publisher = fixture
    authorization = Authorization({"member": "member"})
    service = OutingService(
        repository,
        uow,
        authorization_service=authorization,
        invalidation_publisher=publisher,
    )
    member = Actor("member", "owner")

    assert [row.id for row in service.list("g1", actor=member)] == ["o1"]
    created = service.create("g1", "  Member outing  ", actor=member)

    assert created.name == "Member outing"
    assert authorization.calls == [
        ("member", "g1", "read_group"),
        ("member", "g1", "read_group"),
    ]


def test_actor_fallback_rejects_incomplete_context(fixture):
    service, _repository, _uow, _publisher = fixture

    with pytest.raises(ForbiddenError):
        service.list("g1")
    with pytest.raises(ForbiddenError):
        service.list("g1", actor={"role": "owner"})


def test_blank_names_are_rejected_before_mutation(fixture):
    service, repository, uow, publisher = fixture

    with pytest.raises(InvalidOutingNameError):
        service.create("g1", " \t ")
    with pytest.raises(InvalidOutingNameError):
        service.create("g1", "x" * 256)

    assert len(repository.rows) == 1
    assert uow.commits == uow.rollbacks == 0
    assert publisher.groups == []
