"""Outing lifecycle request and response schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class OutingWriteRequest(BaseModel):
    """The only editable outing field in this bounded lifecycle slice."""

    model_config = ConfigDict(extra="forbid")

    name: str


class OutingResponse(BaseModel):
    """Server-owned active/archived outing history shape."""

    model_config = ConfigDict(extra="forbid", from_attributes=True)

    id: str
    group_id: str
    name: str
    archived: bool
    archived_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None


__all__ = ["OutingResponse", "OutingWriteRequest"]
