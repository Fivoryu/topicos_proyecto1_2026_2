"""Expense write and source-history response schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ExpenseContributorRequest(BaseModel):
    """One contributor and its decimal lexical input."""

    model_config = ConfigDict(extra="forbid")

    participant_id: str
    amount: str


class ExpenseWriteRequest(BaseModel):
    """Complete replacement command for an expense."""

    model_config = ConfigDict(extra="forbid")

    description: str
    amount: str
    contributors: list[ExpenseContributorRequest]
    beneficiary_ids: list[str]


class ExpenseContributorResponse(BaseModel):
    """Contributor history resolved to current participant metadata."""

    model_config = ConfigDict(extra="forbid")

    participant_id: str
    name: str
    archived: bool
    amount_cents: int


class ExpenseBeneficiaryResponse(BaseModel):
    """Beneficiary history resolved to current participant metadata."""

    model_config = ConfigDict(extra="forbid")

    participant_id: str
    name: str
    archived: bool


class ExpenseResponse(BaseModel):
    """Persisted source expense; monetary values are integer cents only."""

    model_config = ConfigDict(extra="forbid", from_attributes=True)

    id: str
    group_id: str
    description: str
    amount_cents: int
    contributors: list[ExpenseContributorResponse]
    beneficiaries: list[ExpenseBeneficiaryResponse]
    created_at: datetime | None = None
    updated_at: datetime | None = None


__all__ = [
    "ExpenseBeneficiaryResponse",
    "ExpenseContributorRequest",
    "ExpenseContributorResponse",
    "ExpenseResponse",
    "ExpenseWriteRequest",
]
