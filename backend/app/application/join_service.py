"""Application service for owner-controlled reusable group joins."""
from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

from backend.app.adapters.db.tables import GroupJoinCode
from backend.app.adapters.security.join_codes import JoinCodeTokenSource
from backend.app.application.auth_service import UnauthorizedError
from backend.app.application.authorization import ForbiddenError
from backend.app.application.participant_service import normalize_participant_name
from backend.app.application.ports import GroupId, ParticipantRecord
from backend.app.domain.errors import DomainError, DuplicateParticipantNameError


@dataclass(frozen=True, slots=True)
class JoinCodeStatus:
    group_id: GroupId
    generation: int | None
    active: bool
@dataclass(frozen=True, slots=True)
class JoinCodeResult:
    group_id: GroupId
    code: str
    generation: int
@dataclass(frozen=True, slots=True)
class JoinResult:
    group_id: GroupId
    account_id: object
    participant_id: object
class _JoinError(DomainError):
    def __init__(self):
        super().__init__(self.code, "Join operation failed.")
class InvalidJoinCodeError(_JoinError):
    code = "invalid_join_code"
class RevokedJoinCodeError(_JoinError):
    code = "revoked_join_code"
class DuplicateMembershipError(_JoinError):
    code = "duplicate_membership"
class InvalidParticipantLinkChoiceError(_JoinError):
    code = "invalid_participant_link_choice"
class DuplicateParticipantLinkError(_JoinError):
    code = "duplicate_participant_link"
def _value(record: object, name: str, default: object = None) -> object:
    return getattr(record, name, default)
def _account_id(actor: object | None) -> object:
    account = getattr(actor, "account", None) if actor is not None else None
    account_id = getattr(actor, "account_id", None) or getattr(account, "id", None)
    if account_id is None:
        raise UnauthorizedError()
    return account_id
class JoinService:
    def __init__(self, unit_of_work: Any, authorization_service: Any,
                 token_source: Any | None = None,
                 *, invalidation_publisher: Any = None):
        self._unit_of_work, self._authorization = unit_of_work, authorization_service
        self._tokens = token_source or JoinCodeTokenSource()
        self._publisher = invalidation_publisher
    def status(self, group_id: GroupId, actor: object | None = None) -> JoinCodeStatus:
        with self._transaction() as tx:
            self._authorize_owner(actor, group_id)
            code = tx.join_codes.get_current_for_update(group_id)
            return self._status(group_id, code)
    def generate(self, group_id: GroupId, actor: object | None = None) -> JoinCodeResult:  # noqa: E501
        return self._issue(group_id, actor)
    regenerate = generate
    def revoke(self, group_id: GroupId, actor: object | None = None) -> JoinCodeStatus:
        with self._transaction() as tx:
            self._authorize_owner(actor, group_id)
            code = tx.join_codes.revoke(group_id)
        if code is not None and self._publisher is not None:
            self._publisher.publish(group_id)
        return self._status(group_id, code)
    def consume(self, code: str, actor: object | None = None, *,
                participant_id: object | None = None,
                new_participant_name: object | None = None) -> JoinResult:
        account_id = _account_id(actor)
        existing = participant_id is not None
        creating = new_participant_name is not None
        if existing == creating:
            raise InvalidParticipantLinkChoiceError()
        if creating:
            try:
                display_name, normalized_name = normalize_participant_name(
                    new_participant_name)
            except DomainError as error:
                raise InvalidParticipantLinkChoiceError() from error
        if not isinstance(code, str) or not code:
            raise InvalidJoinCodeError()
        with self._transaction() as tx:
            joined = tx.join_codes.find_by_hash_for_update(self._tokens.hash(code))
            if joined is None:
                raise InvalidJoinCodeError()
            if _value(joined, "revoked_at") is not None:
                raise RevokedJoinCodeError()
            group_id = _value(joined, "group_id")
            if tx.memberships.find_active_by_group_account(
                group_id, account_id) is not None:
                raise DuplicateMembershipError()
            if tx.account_participant_links.find_active(
                group_id, account_id) is not None:
                raise DuplicateParticipantLinkError()
            if existing:
                participant = tx.participants.find_by_id(
                    group_id, participant_id, for_update=True)
                if participant is None or _value(participant, "archived_at") is not None:  # noqa: E501
                    raise InvalidParticipantLinkChoiceError()
            else:
                if tx.participants.find_by_normalized_name(
                    group_id, normalized_name) is not None:
                    raise DuplicateParticipantNameError()
                participant = tx.participants.create(
                    group_id, ParticipantRecord(
                        uuid4(), group_id, display_name, normalized_name,
                        created_at=datetime.now(UTC)))
            tx.memberships.create_or_reactivate(group_id, account_id)
            participant_id = _value(participant, "id")
            tx.account_participant_links.upsert_active(
                group_id, account_id, participant_id)
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return JoinResult(group_id, account_id, participant_id)
    def _issue(self, group_id: GroupId, actor: object | None) -> JoinCodeResult:
        with self._transaction() as tx:
            self._authorize_owner(actor, group_id)
            token = self._tokens.generate()
            digest = self._tokens.hash(token)
            current = tx.join_codes.get_current_for_update(group_id)
            if current is None:
                current = tx.join_codes.create(
                    GroupJoinCode(group_id=group_id, token_hash=digest))
            else:
                current = tx.join_codes.replace_hash(group_id, digest)
            generation = int(_value(current, "generation", 1))
        if self._publisher is not None:
            self._publisher.publish(group_id)
        return JoinCodeResult(group_id, token, generation)
    def _authorize_owner(self, actor: object | None, group_id: GroupId) -> None:
        if self._authorization is None:
            raise TypeError("authorization service is required")
        context = self._authorization.authorize(actor, group_id, "manage_join_code")
        if _value(context, "role") != "owner":
            raise ForbiddenError()
    @staticmethod
    def _status(group_id: GroupId, code: object | None) -> JoinCodeStatus:
        generation = _value(code, "generation") if code is not None else None
        return JoinCodeStatus(
            group_id, int(generation) if generation is not None else None,
            code is not None and _value(code, "revoked_at") is None)
    @contextmanager
    def _transaction(self):
        candidate = (self._unit_of_work() if callable(self._unit_of_work)
                     else self._unit_of_work)
        if candidate is None or not hasattr(candidate, "__enter__"):
            raise TypeError("a unit of work is required")
        with candidate as transaction:
            yield transaction
