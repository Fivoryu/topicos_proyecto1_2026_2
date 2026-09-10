from typing import Literal

from pydantic import BaseModel, ConfigDict


class MemberResponse(BaseModel):
    model_config = ConfigDict(extra="forbid", from_attributes=True)

    account_id: str
    login_name: str
    role: Literal["owner", "member"]
    active: bool
    participant_id: str | None = None
