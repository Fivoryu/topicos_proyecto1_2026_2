"""Authentication request and server-derived session response schemas."""

from __future__ import annotations

from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

Role = Literal["owner", "member"] | None


class LoginRequest(BaseModel):
    """Credentials accepted by the seeded-account login operation."""

    model_config = ConfigDict(extra="forbid")

    login_name: str
    password: str


class AccountIdentityResponse(BaseModel):
    """Public account identity; password and session token never appear here."""

    model_config = ConfigDict(extra="forbid")

    id: Any
    login_name: str


class SessionIdentityResponse(BaseModel):
    """Safe identity response with a role derived by the server."""

    model_config = ConfigDict(extra="forbid")

    account: AccountIdentityResponse
    active_group_id: str | None
    role: Role = Field(json_schema_extra={"enum": ["owner", "member"]})
    expires_at: datetime

    @classmethod
    def from_identity(cls, identity: Any) -> SessionIdentityResponse:
        """Build the wire response without copying the raw session token."""

        account = getattr(identity, "account", None)
        if account is None:
            account = {
                "id": getattr(identity, "account_id"),
                "login_name": getattr(identity, "login_name"),
            }
        active_group_id = getattr(
            identity,
            "active_group_id",
            getattr(identity, "group_id", None),
        )
        if isinstance(active_group_id, UUID):
            active_group_id = str(active_group_id)
        return cls(
            account=AccountIdentityResponse.model_validate(account),
            active_group_id=active_group_id,
            role=getattr(identity, "role"),
            expires_at=getattr(identity, "expires_at"),
        )


__all__ = [
    "AccountIdentityResponse",
    "LoginRequest",
    "Role",
    "SessionIdentityResponse",
]
