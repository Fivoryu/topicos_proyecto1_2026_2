# ruff: noqa: E501, E702, I001
from contextlib import contextmanager
from types import SimpleNamespace
import pytest
from backend.app.application.authorization import ForbiddenError
from backend.app.application.join_service import DuplicateMembershipError, InvalidJoinCodeError, InvalidParticipantLinkChoiceError, JoinService

G, OWNER, MEMBER = "group-one", "owner", "member"
@pytest.fixture
def fixture():
    parts, memberships, links = [], set(), {}
    codes, tokens, events = SimpleNamespace(current=None), iter(("first", "second")), []
    counts = SimpleNamespace(commits=0, rollbacks=0)

    def current(group):
        return codes.current if codes.current and codes.current.group_id == group else None
    codes.get_current_for_update = current
    codes.find_by_hash_for_update = lambda digest: codes.current if codes.current and codes.current.token_hash == digest else None
    def create_code(row):
        row.generation, row.revoked_at, codes.current = 1, None, row
        return row
    codes.create = create_code
    def replace(group, digest):
        codes.current.token_hash, codes.current.generation, codes.current.revoked_at = digest, codes.current.generation + 1, None
        return codes.current
    codes.replace_hash, codes.revoke = replace, lambda group: (setattr(codes.current, "revoked_at", True) or codes.current)

    participants = SimpleNamespace(
        find_by_normalized_name=lambda group, name: next((p for p in parts if p.group_id == group and p.normalized_name == name), None),
        find_by_id=lambda group, pid, for_update=False: next((p for p in parts if p.group_id == group and p.id == pid), None),
    )
    fail = SimpleNamespace(value=False)
    def create(group, row):
        parts.append(row)
        if fail.value:
            raise RuntimeError("participant write failed")
        return row
    participants.create, memberships_repo = create, SimpleNamespace()
    memberships_repo.find_active_by_group_account = lambda group, account: SimpleNamespace() if (group, account) in memberships else None
    memberships_repo.create_or_reactivate = lambda group, account: memberships.add((group, account))
    links_repo = SimpleNamespace(
        find_active=lambda group, account: SimpleNamespace() if (group, account) in links else None,
        upsert_active=lambda group, account, participant: links.__setitem__((group, account), participant),
    )
    repos = SimpleNamespace(participants=participants, memberships=memberships_repo, account_participant_links=links_repo, join_codes=codes)

    @contextmanager
    def transaction():
        snapshot = (len(parts), memberships.copy(), links.copy())
        try:
            yield repos
        except Exception:
            del parts[snapshot[0]:]
            memberships.clear(); memberships.update(snapshot[1])
            links.clear(); links.update(snapshot[2]); counts.rollbacks += 1
            raise
        else:
            counts.commits += 1

    auth = SimpleNamespace(authorize=lambda actor, group, operation: SimpleNamespace(role="owner" if actor.account_id == OWNER else "member"))
    token_source = SimpleNamespace(generate=lambda: next(tokens), hash=lambda token: f"digest:{token}".encode())
    service = JoinService(lambda: transaction(), auth, token_source, invalidation_publisher=SimpleNamespace(publish=events.append))
    return SimpleNamespace(service=service, parts=parts, memberships=memberships, links=links, codes=codes, counts=counts, events=events, fail=fail)

def actor(account_id):
    return SimpleNamespace(account_id=account_id)

def test_owner_lifecycle_is_protected_and_regeneration_invalidates_hash(fixture):
    first = fixture.service.generate(G, actor(OWNER))
    fixture.service.regenerate(G, actor(OWNER))
    assert fixture.codes.current.token_hash == b"digest:second"
    assert fixture.service.status(G, actor(OWNER)).generation == 2
    with pytest.raises(InvalidJoinCodeError):
        fixture.service.consume(first.code, actor(MEMBER), new_participant_name="Ana")
    with pytest.raises(ForbiddenError):
        fixture.service.status(G, actor(MEMBER))
    with pytest.raises(ForbiddenError):
        fixture.service.revoke(G, actor(MEMBER))
    assert fixture.service.revoke(G, actor(OWNER)).active is False

def test_reusable_consume_links_same_group_and_rejects_foreign_or_duplicate(fixture):
    token = fixture.service.generate(G, actor(OWNER)).code
    joined = fixture.service.consume(token, actor("a"), new_participant_name="Ana")
    linked = fixture.service.consume(token, actor("b"), participant_id=joined.participant_id)
    assert linked.group_id == G and fixture.links[G, "b"] == joined.participant_id
    fixture.parts.append(SimpleNamespace(id="foreign", group_id="other", normalized_name="x"))
    with pytest.raises(InvalidParticipantLinkChoiceError):
        fixture.service.consume(token, actor("c"), participant_id="foreign")
    with pytest.raises(DuplicateMembershipError):
        fixture.service.consume(token, actor("a"), new_participant_name="Beto")

def test_one_choice_failure_rolls_back_and_does_not_publish(fixture):
    token = fixture.service.generate(G, actor(OWNER)).code
    for choice in ({}, {"participant_id": "p", "new_participant_name": "Ana"}):
        with pytest.raises(InvalidParticipantLinkChoiceError):
            fixture.service.consume(token, actor(MEMBER), **choice)
    fixture.fail.value = True
    with pytest.raises(RuntimeError, match="participant write failed"):
        fixture.service.consume(token, actor(MEMBER), new_participant_name="Ana")
    assert fixture.parts == [] and not fixture.memberships and not fixture.links
    assert fixture.events == [G] and (fixture.counts.commits, fixture.counts.rollbacks) == (1, 1)
