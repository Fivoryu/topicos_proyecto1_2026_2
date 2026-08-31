"""Server-derived balance response schemas."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class BalanceParticipantResponse(BaseModel):
    """One stable-order participant balance row."""

    model_config = ConfigDict(extra="forbid")

    participant_id: str
    name: str
    archived: bool
    paid_cents: int
    owed_cents: int
    balance_cents: int


class BalancesResponse(BaseModel):
    """All participant balances derived from current source expenses."""

    model_config = ConfigDict(extra="forbid")

    group_id: str
    participants: list[BalanceParticipantResponse]


__all__ = ["BalanceParticipantResponse", "BalancesResponse"]
