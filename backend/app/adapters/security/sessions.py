"""Opaque session-token generation and persistence-safe hashing."""

from __future__ import annotations

from hashlib import sha256
from secrets import compare_digest, token_urlsafe
from typing import Any

# Transport constants are centralized here so API adapters cannot accidentally
# create a second cookie name or broaden the cookie path.
SESSION_COOKIE_NAME = "cc_session"
SESSION_COOKIE_PATH = "/api"
SESSION_COOKIE_HTTP_ONLY = True
SESSION_COOKIE_SAMESITE = "lax"
CSRF_COOKIE_NAME = "cc_csrf"
# The readable CSRF cookie must match the SPA document path ("/") because
# document.cookie only exposes cookies whose path matches the document URL;
# the session cookie stays scoped to /api because it is sent automatically.
CSRF_COOKIE_PATH = "/"
CSRF_HEADER_NAME = "X-CSRF-Token"
CSRF_COOKIE_HTTP_ONLY = False
CSRF_COOKIE_SAMESITE = SESSION_COOKIE_SAMESITE

# Explicit cc_* aliases are useful at transport call sites while the descriptive
# names above remain the public adapter constants.
CC_SESSION_COOKIE_NAME = SESSION_COOKIE_NAME
CC_SESSION_COOKIE_PATH = SESSION_COOKIE_PATH
CC_SESSION_COOKIE_HTTP_ONLY = SESSION_COOKIE_HTTP_ONLY
CC_SESSION_COOKIE_SAMESITE = SESSION_COOKIE_SAMESITE
CC_CSRF_COOKIE_NAME = CSRF_COOKIE_NAME
CC_CSRF_COOKIE_PATH = CSRF_COOKIE_PATH
CC_CSRF_COOKIE_HTTP_ONLY = CSRF_COOKIE_HTTP_ONLY
CC_CSRF_COOKIE_SAMESITE = CSRF_COOKIE_SAMESITE


def generate_csrf_token() -> str:
    """Return the random token exposed to the browser for CSRF protection."""

    return token_urlsafe(32)


def set_csrf_cookie(
    response: Any, token: str | None = None, *, secure: bool = False
) -> str:
    """Set the readable CSRF companion cookie and return its value."""

    csrf_token = token or generate_csrf_token()
    response.set_cookie(
        key=CSRF_COOKIE_NAME,
        value=csrf_token,
        httponly=CSRF_COOKIE_HTTP_ONLY,
        samesite=CSRF_COOKIE_SAMESITE,
        secure=secure,
        path=CSRF_COOKIE_PATH,
    )
    return csrf_token


def set_session_cookies(
    response: Any,
    session_token: str,
    csrf_token: str | None = None,
    *,
    secure: bool = False,
) -> str:
    """Set the opaque session and readable CSRF cookies with fixed flags."""

    response.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=session_token,
        httponly=SESSION_COOKIE_HTTP_ONLY,
        samesite=SESSION_COOKIE_SAMESITE,
        secure=secure,
        path=SESSION_COOKIE_PATH,
    )
    return set_csrf_cookie(response, csrf_token, secure=secure)


def clear_session_cookies(response: Any) -> None:
    """Expire both authentication cookies without broadening their path."""

    response.delete_cookie(SESSION_COOKIE_NAME, path=SESSION_COOKIE_PATH)
    response.delete_cookie(CSRF_COOKIE_NAME, path=CSRF_COOKIE_PATH)


# Singular aliases keep call sites readable while preserving one cookie contract.
set_session_cookie = set_session_cookies
clear_session_cookie = clear_session_cookies


def csrf_tokens_match(cookie_token: str | None, header_token: str | None) -> bool:
    """Compare the double-submit values in constant time and reject empties."""

    if not isinstance(cookie_token, str) or not isinstance(header_token, str):
        return False
    if not cookie_token or not header_token:
        return False
    return compare_digest(cookie_token, header_token)


def origin_is_allowed(origin: str | None, allowed_origins: Any) -> bool:
    """Require an exact configured browser origin for unsafe requests."""

    if not isinstance(origin, str) or not origin:
        return False
    configured = {str(value).strip() for value in allowed_origins if str(value).strip()}
    return origin in configured


class OpaqueSessionTokenSource:
    """Generate random transport tokens and SHA-256 digests for the database."""

    def generate(self) -> str:
        """Return a URL-safe token with 256 bits of cryptographic randomness."""

        return token_urlsafe(32)

    def hash(self, token: str) -> bytes:
        """Hash a token before it crosses into persistence."""

        if not isinstance(token, str) or not token:
            raise TypeError("session token must be a non-empty string")
        return sha256(token.encode("utf-8")).digest()


# The adapter structurally implements the existing SessionTokenSource protocol.
SessionTokenSourceAdapter = OpaqueSessionTokenSource

__all__ = [
    "CC_CSRF_COOKIE_HTTP_ONLY",
    "CC_CSRF_COOKIE_NAME",
    "CC_CSRF_COOKIE_PATH",
    "CC_CSRF_COOKIE_SAMESITE",
    "CC_SESSION_COOKIE_HTTP_ONLY",
    "CC_SESSION_COOKIE_NAME",
    "CC_SESSION_COOKIE_PATH",
    "CC_SESSION_COOKIE_SAMESITE",
    "CSRF_COOKIE_HTTP_ONLY",
    "CSRF_COOKIE_NAME",
    "CSRF_COOKIE_PATH",
    "CSRF_COOKIE_SAMESITE",
    "CSRF_HEADER_NAME",
    "clear_session_cookie",
    "clear_session_cookies",
    "csrf_tokens_match",
    "generate_csrf_token",
    "origin_is_allowed",
    "set_csrf_cookie",
    "set_session_cookie",
    "set_session_cookies",
    "OpaqueSessionTokenSource",
    "SESSION_COOKIE_HTTP_ONLY",
    "SESSION_COOKIE_NAME",
    "SESSION_COOKIE_PATH",
    "SESSION_COOKIE_SAMESITE",
    "SessionTokenSourceAdapter",
]
