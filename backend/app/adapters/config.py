"""Typed configuration loaded from environment variables."""

from functools import lru_cache
from pathlib import Path
from typing import Any

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_ROOT = Path(__file__).resolve().parents[2]  # pyright: ignore[reportCallIssue]


class Settings(BaseSettings):
    """Runtime settings for the API and its development/demo environment."""

    database_url: str = (
        "postgresql+asyncpg://postgres:postgres@localhost:5432/cuentas_claras"
    )
    cors_origins: list[str] = Field(default_factory=lambda: ["http://localhost:5173"])  # pyright: ignore[reportAssignmentType]
    session_ttl: int = 28_800
    demo_owner_password: str = Field(default_factory=lambda: "change-me-owner")  # pyright: ignore[reportAssignmentType]
    demo_member_password: str = Field(default_factory=lambda: "change-me-member")  # pyright: ignore[reportAssignmentType]

    model_config = SettingsConfigDict(
        env_file=(str(_BACKEND_ROOT / ".env"), ".env"),
        env_ignore_empty=True,
        enable_decoding=False,
        extra="ignore",
        case_sensitive=False,
    )

    @field_validator("database_url")
    @classmethod
    def strip_database_url(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("DATABASE_URL must not be empty")
        return value

    @field_validator("session_ttl")
    @classmethod
    def validate_session_ttl(cls, value: int) -> int:
        if value <= 0:
            raise ValueError("SESSION_TTL must be greater than zero")
        return value

    @field_validator("demo_owner_password", "demo_member_password")
    @classmethod
    def validate_demo_password(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("demo passwords must not be empty")
        return value

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: Any) -> list[str]:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        if isinstance(value, (list, tuple)):
            return [str(origin).strip() for origin in value if str(origin).strip()]
        raise TypeError("CORS_ORIGINS must be a comma-separated string or list")


@lru_cache
def get_settings() -> Settings:
    """Return the process-wide immutable-by-convention settings instance."""

    return Settings()
