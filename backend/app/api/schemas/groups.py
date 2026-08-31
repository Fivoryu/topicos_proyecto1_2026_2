"""Group settings request and response schemas."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class GroupUpdateRequest(BaseModel):
    """The only mutable group setting exposed by the MVP."""

    model_config = ConfigDict(extra="forbid", populate_by_name=False)

    settlement_policy: Literal["owner_only", "any_member"] = Field(
        alias="settlementPolicy"
    )


class GroupResponse(BaseModel):
    """Server-owned group identity and settlement policy."""

    model_config = ConfigDict(
        extra="forbid", from_attributes=True, populate_by_name=True
    )

    id: str
    name: str
    owner_account_id: str
    settlement_policy: Literal["owner_only", "any_member"] = Field(
        alias="settlementPolicy"
    )


__all__ = ["GroupResponse", "GroupUpdateRequest"]
