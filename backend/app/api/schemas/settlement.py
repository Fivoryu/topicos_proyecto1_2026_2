"""Server-derived settlement response schemas."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class SettlementTransferResponse(BaseModel):
    """One ordered positive-cent transfer."""

    model_config = ConfigDict(extra="forbid")

    from_participant_id: str
    to_participant_id: str
    from_name: str
    to_name: str
    amount_cents: int


class SettlementResponse(BaseModel):
    """Current policy and deterministic transfers."""

    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    group_id: str
    settlement_policy: Literal["owner_only", "any_member"] = Field(
        alias="settlementPolicy"
    )
    settled: bool
    transfers: list[SettlementTransferResponse]


__all__ = ["SettlementResponse", "SettlementTransferResponse"]
