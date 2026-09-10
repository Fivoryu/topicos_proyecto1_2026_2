"""Cryptographic source and digesting for reusable group join codes."""

from __future__ import annotations

from hashlib import sha256
from secrets import token_urlsafe


class JoinCodeTokenSource:
    """Generate URL-safe bearer tokens and persist only SHA-256 digests."""

    def generate(self) -> str:
        """Return a URL-safe token with 256 bits of cryptographic randomness."""

        return token_urlsafe(32)

    def hash(self, token: str) -> bytes:
        """Hash a token before it crosses into persistence."""

        if not isinstance(token, str) or not token:
            raise TypeError("join code must be a non-empty string")
        return sha256(token.encode("utf-8")).digest()


__all__ = ["JoinCodeTokenSource"]
