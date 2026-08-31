"""Participant lifecycle request and response schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ParticipantWriteRequest(BaseModel):
    """Request used to add a participant."""

    model_config = ConfigDict(extra="forbid")

    name: str


class RenameParticipantRequest(BaseModel):
    """Exactly the name-only participant rename contract."""

    model_config = ConfigDict(extra="forbid")

    name: str


class ParticipantResponse(BaseModel):
    """Current participant identity and archive state."""

    model_config = ConfigDict(extra="forbid", from_attributes=True)

    id: str
    group_id: str
    name: str
    archived: bool
    created_at: datetime | None = None


__all__ = [
    "ParticipantResponse",
    "ParticipantWriteRequest",
    "RenameParticipantRequest",
]
