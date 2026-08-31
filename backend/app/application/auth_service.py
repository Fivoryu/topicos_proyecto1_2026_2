"""Application service for opaque, server-authorized authentication sessions."""

from __future__ import annotations

import hmac
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Literal, cast
from uuid import uuid4

from .ports import (
    AccountId,
    AccountRepository,
    Clock,
    MembershipRepository,
    PasswordHasher,
    SessionRecord,
    SessionRepository,
    SessionTokenSource,
)

Role = Literal["owner", "member"]


class AuthenticationError(Exception):
    """Base error for expected authentication and session failures."""

    def __init__(self, code: str, message: str):
        self.code = code
        self.message = message
        super().__init__(message)

    @property
    def error_code(self) -> str:
        """Expose the API-facing machine-readable error code."""

        return self.code


class InvalidCredentialsError(AuthenticationError):
    """Raised for every login failure, without revealing account state."""

    def __init__(self):
        super().__init__("invalid_credentials", "Invalid login credentials.")


class UnauthorizedError(AuthenticationError):
    """Raised when a session is missing, unknown, revoked, or unusable."""

    def __init__(self):
        super().__init__("unauthorized", "A valid authenticated session is required.")


class SessionExpiredError(AuthenticationError):
    """Raised when the session reaches its configured expiry boundary."""

    def __init__(self):
        super().__init__("session_expired", "The authenticated session has expired.")


@dataclass(frozen=True, slots=True)
class SessionIdentity:
    """Server-derived identity returned by login and session validation.

    ``token`` is available to the transport adapter so it can set a cookie. It is
    deliberately omitted from :meth:`as_dict`, which is the safe response shape.
    The persistence record contains only ``token_hash``.
    """

    account_id: Any
    login_name: str
    active_group_id: Any
    role: Role
    expires_at: datetime
    token: str | None = None

    @property
    def group_id(self) -> Any:
        """Compatibility alias for the active group identifier."""

        return self.active_group_id

    @property
    def account(self) -> dict[str, Any]:
        """Return the nested account shape used by the API response."""

        return {"id": self.account_id, "login_name": self.login_name}

    @property
    def identity(self) -> SessionIdentity:
        """Allow login callers to treat the result as an identity envelope."""

        return self

    def as_dict(self) -> dict[str, Any]:
        """Return the safe server-derived identity payload without the token."""

        return {
            "account": self.account,
            "active_group_id": self.active_group_id,
            "role": self.role,
            "expires_at": self.expires_at,
        }

    def __getitem__(self, key: str) -> Any:
        """Support mapping-style access at the application boundary."""

        if key == "token":
            return self.token
        return self.as_dict()[key]


# A descriptive alias keeps the public result vocabulary flexible for adapters.
AuthenticatedSession = SessionIdentity
LoginResult = SessionIdentity

_MISSING = object()
_FIELD_MISSING = object()
_DEFAULT_SESSION_TTL = timedelta(hours=8)
# Adapters should expose a valid encoded dummy hash. This fallback still forces a
# hasher call for fakes or adapters that configure their dummy hash separately.
_DEFAULT_DUMMY_HASH = "safe-dummy-password-hash"


def _value(record: object, *names: str, default: object = _MISSING) -> object:
    """Read a record field from either a mapping or an adapter model."""

    if isinstance(record, Mapping):
        for name in names:
            if name in record:
                return record[name]
    else:
        for name in names:
            value = getattr(record, name, _MISSING)
            if value is not _MISSING:
                return value
    if default is not _MISSING:
        return default
    raise ValueError(f"Record is missing one of: {', '.join(names)}")


def _session_ttl(value: int | timedelta) -> timedelta:
    """Normalize the configured session lifetime without accepting booleans."""

    if isinstance(value, timedelta):
        lifetime = value
    elif isinstance(value, int) and not isinstance(value, bool):
        lifetime = timedelta(seconds=value)
    else:
        raise TypeError("session_ttl must be a positive integer or timedelta")
    if lifetime <= timedelta(0):
        raise ValueError("session_ttl must be greater than zero")
    return lifetime


def _token_hash(source: SessionTokenSource, token: str) -> bytes:
    """Hash a token and reject adapter results that could persist raw material."""

    digest = source.hash(token)
    if not isinstance(digest, (bytes, bytearray, memoryview)):
        raise TypeError("SessionTokenSource.hash must return bytes")
    result = bytes(digest)
    if not result:
        raise ValueError("SessionTokenSource.hash must return a non-empty digest")
    return result


class AuthService:
    """Coordinate login, logout, and server-side session identity resolution."""

    def __init__(
        self,
        account_repository: AccountRepository,
        session_repository: SessionRepository,
        membership_repository: MembershipRepository,
        password_hasher: PasswordHasher,
        token_source: SessionTokenSource,
        clock: Clock,
        session_ttl: int | timedelta = _DEFAULT_SESSION_TTL,
        *,
        dummy_password_hash: str | None = None,
    ):
        self._accounts = account_repository
        self._sessions = session_repository
        self._memberships = membership_repository
        self._hasher = password_hasher
        self._tokens = token_source
        self._clock = clock
        self._session_ttl = _session_ttl(session_ttl)
        self._dummy_password_hash = dummy_password_hash

    def login(self, login_name: str, password: str) -> SessionIdentity:
        """Authenticate an account and create a hash-only persisted session.

        Unknown and inactive accounts deliberately verify against the same safe
        dummy hash used for all non-existent identities. They therefore share the
        same public error code and message as wrong passwords and never create a
        session.
        """

        account = self._accounts.find_by_login_name(login_name)
        is_active = (
            bool(_value(account, "is_active", default=False)) if account else False
        )
        encoded_hash = self._password_hash_for(account, is_active)
        try:
            verified = self._hasher.verify(password, encoded_hash)
        except Exception:
            # A malformed stored hash is an authentication failure, not a reason
            # to expose account state or accidentally authenticate the caller.
            verified = False

        if not account or not is_active or not verified:
            raise InvalidCredentialsError()

        try:
            account_id = cast(AccountId, _value(account, "id"))
            membership = self._memberships.find_for_account(account_id)
        except (AttributeError, KeyError, TypeError, ValueError) as error:
            raise InvalidCredentialsError() from error
        if not self._is_usable_membership(membership, account_id):
            # Account-without-group is intentionally indistinguishable from a
            # failed login: the minimum product only authenticates group actors.
            raise InvalidCredentialsError()

        token = self._tokens.generate()
        if not isinstance(token, str) or not token:
            raise RuntimeError(
                "SessionTokenSource.generate must return a non-empty token"
            )
        created_at = self._clock.now()
        expires_at = created_at + self._session_ttl
        token_hash = _token_hash(self._tokens, token)
        session = SessionRecord(
            id=uuid4(),
            token_hash=token_hash,
            account_id=account_id,
            created_at=created_at,
            expires_at=expires_at,
        )

        identity = self._identity(account, membership, expires_at, token)
        self._sessions.create(session)
        return identity

    def logout(self, token: str | None) -> None:
        """Revoke a currently valid session at the injected clock instant."""

        _, token_hash = self._validated_session(token)
        revoked_at = self._clock.now()
        self._sessions.revoke_by_token_hash(token_hash, revoked_at)

    def session_identity(self, token: str | None) -> SessionIdentity:
        """Validate token hash, revocation, expiry, account, and membership."""

        session, _ = self._validated_session(token)
        try:
            account = self._accounts.find_by_id(
                cast(AccountId, _value(session, "account_id"))
            )
            if not account or not bool(_value(account, "is_active", default=False)):
                raise UnauthorizedError()
            account_id = cast(AccountId, _value(account, "id"))
            membership = self._memberships.find_for_account(account_id)
            if not self._is_usable_membership(membership, account_id):
                raise UnauthorizedError()
            expires_at = cast(datetime, _value(session, "expires_at"))
            return self._identity(account, membership, expires_at, token)
        except UnauthorizedError:
            raise
        except (AttributeError, KeyError, TypeError, ValueError) as error:
            raise UnauthorizedError() from error

    def _validated_session(self, token: str | None) -> tuple[object, bytes]:
        if not isinstance(token, str) or not token:
            raise UnauthorizedError()
        try:
            token_hash = _token_hash(self._tokens, token)
            session = self._sessions.find_by_token_hash(token_hash)
        except Exception as error:
            raise UnauthorizedError() from error
        if not session:
            raise UnauthorizedError()

        stored_hash = cast(bytes, _value(session, "token_hash", default=None))
        try:
            hash_matches = hmac.compare_digest(bytes(stored_hash), token_hash)
        except (TypeError, ValueError):
            hash_matches = False
        if not hash_matches:
            raise UnauthorizedError()
        if _value(session, "revoked_at", default=None) is not None:
            raise UnauthorizedError()

        expires_at = _value(session, "expires_at", default=None)
        if not isinstance(expires_at, datetime):
            raise UnauthorizedError()
        try:
            expired = self._clock.now() >= expires_at
        except TypeError as error:
            raise UnauthorizedError() from error
        if expired:
            raise SessionExpiredError()
        return session, token_hash

    def _password_hash_for(self, account: object, is_active: bool) -> str:
        if account and is_active:
            value = _value(account, "password_hash", default=None)
            if isinstance(value, str) and value:
                return value
        configured = self._dummy_password_hash
        if configured:
            return configured
        candidate = getattr(self._hasher, "dummy_hash", None)
        if callable(candidate):
            candidate = cast(Callable[[], object], candidate)()
        if isinstance(candidate, str) and candidate:
            return candidate
        return _DEFAULT_DUMMY_HASH

    @staticmethod
    def _is_usable_membership(membership: object, account_id: object) -> bool:
        if membership is None:
            return False
        membership_account_id = _value(membership, "account_id", default=_FIELD_MISSING)
        group_id = _value(membership, "group_id", default=_FIELD_MISSING)
        owner_account_id = _value(
            membership, "owner_account_id", default=_FIELD_MISSING
        )
        return (
            membership_account_id == account_id
            and account_id is not None
            and group_id is not _FIELD_MISSING
            and group_id is not None
            and owner_account_id is not _FIELD_MISSING
            and owner_account_id is not None
        )

    @staticmethod
    def _identity(
        account: object,
        membership: object,
        expires_at: datetime,
        token: str | None,
    ) -> SessionIdentity:
        account_id = cast(AccountId, _value(account, "id"))
        owner_account_id = _value(membership, "owner_account_id")
        role: Role = "owner" if account_id == owner_account_id else "member"
        return SessionIdentity(
            account_id=account_id,
            login_name=cast(str, _value(account, "login_name")),
            active_group_id=_value(membership, "group_id"),
            role=role,
            expires_at=expires_at,
            token=token,
        )
