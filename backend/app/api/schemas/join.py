"""Join-code request and response schemas."""

from __future__ import annotations

from pydantic import BaseModel, ConfigDict, model_validator


class _JoinModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class JoinCodeStatus(_JoinModel):
    group_id: str
    generation: int | None
    active: bool


class JoinCodeResponse(_JoinModel):
    group_id: str
    code: str
    generation: int


class JoinCodeConsumeRequest(_JoinModel):
    code: str
    participant_id: str | None = None
    new_participant_name: str | None = None

    @model_validator(mode="after")
    def require_one_choice(self) -> JoinCodeConsumeRequest:
        if (self.participant_id is None) == (self.new_participant_name is None):
            raise ValueError("Exactly one participant choice is required.")
        return self


class JoinResponse(_JoinModel):
    group_id: str
    account_id: str
    participant_id: str
