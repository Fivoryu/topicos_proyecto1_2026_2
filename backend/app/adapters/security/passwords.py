"""Argon2id password hashing adapter for the application hasher port."""

from __future__ import annotations

try:  # Keep module importable so missing optional runtime dependencies fail clearly.
    from argon2 import PasswordHasher as _Argon2PasswordHasher
    from argon2.exceptions import VerificationError as _VerificationError
    from argon2.low_level import Type as _Argon2Type
except ImportError:  # pragma: no cover - exercised by the unavailable check.
    _Argon2PasswordHasher = None
    _Argon2Type = None
    _VerificationError = Exception


_DUMMY_PASSWORD = "cuentas-claras-invalid-login-dummy"


class Argon2idPasswordHasher:
    """Implement the application password port with Argon2id only.

    There is intentionally no insecure fallback. Deployments and tests that need
    this adapter must install the declared ``argon2-cffi`` dependency.
    """

    dummy_hash: str

    def __init__(
        self,
        *,
        time_cost: int = 3,
        memory_cost: int = 65_536,
        parallelism: int = 4,
        hash_len: int = 32,
        salt_len: int = 16,
    ) -> None:
        if _Argon2PasswordHasher is None or _Argon2Type is None:
            raise RuntimeError(
                "argon2-cffi is unavailable; Argon2id password hashing cannot be used"
            )
        self._hasher = _Argon2PasswordHasher(
            time_cost=time_cost,
            memory_cost=memory_cost,
            parallelism=parallelism,
            hash_len=hash_len,
            salt_len=salt_len,
            type=_Argon2Type.ID,
        )
        # AuthService verifies this valid hash for unknown/inactive accounts so the
        # public failure shape does not reveal whether a login name exists.
        self.dummy_hash = self._hasher.hash(_DUMMY_PASSWORD)

    def hash(self, password: str) -> str:
        """Return an encoded Argon2id hash for a new password."""

        if not isinstance(password, str):
            raise TypeError("password must be a string")
        return self._hasher.hash(password)

    hash_password = hash

    def verify(self, password: str, encoded_hash: str) -> bool:
        """Return false for wrong, malformed, or non-string credentials."""

        if not isinstance(password, str) or not isinstance(encoded_hash, str):
            return False
        try:
            return bool(self._hasher.verify(encoded_hash, password))
        except (_VerificationError, TypeError, ValueError):
            return False

    def needs_rehash(self, encoded_hash: str) -> bool:
        """Expose Argon2's parameter-upgrade check without changing the port."""

        return self._hasher.check_needs_rehash(encoded_hash)


PasswordHasherAdapter = Argon2idPasswordHasher

__all__ = ["Argon2idPasswordHasher", "PasswordHasherAdapter"]
