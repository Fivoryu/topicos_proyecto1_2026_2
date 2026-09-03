# pyright: reportMissingImports=false
"""Environment configuration tests for the backend bootstrap."""


def test_settings_read_typed_environment_values(monkeypatch):
    from backend.app.adapters.config import Settings

    monkeypatch.setenv(
        "DATABASE_URL",
        "postgresql+asyncpg://postgres:secret@localhost:5432/cuentas_claras",
    )
    monkeypatch.setenv("CORS_ORIGINS", "http://localhost:5173, https://demo.example")
    monkeypatch.setenv("SESSION_TTL", "3600")
    monkeypatch.setenv("DEMO_OWNER_PASSWORD", "owner-password")
    monkeypatch.setenv("DEMO_MEMBER_PASSWORD", "member-password")

    settings = Settings(_env_file=None)

    assert settings.database_url == (
        "postgresql+asyncpg://postgres:secret@localhost:5432/cuentas_claras"
    )
    assert settings.cors_origins == [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "https://demo.example",
    ]
    assert settings.session_ttl == 3600
    assert settings.demo_owner_password == "owner-password"
    assert settings.demo_member_password == "member-password"


def test_settings_use_safe_development_defaults(monkeypatch):
    from backend.app.adapters.config import Settings

    for name in (
        "DATABASE_URL",
        "CORS_ORIGINS",
        "SESSION_TTL",
        "DEMO_OWNER_PASSWORD",
        "DEMO_MEMBER_PASSWORD",
    ):
        monkeypatch.delenv(name, raising=False)

    settings = Settings(_env_file=None)

    assert settings.database_url.startswith("postgresql+asyncpg://")
    assert settings.cors_origins == [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ]
    assert settings.session_ttl == 28_800
    assert settings.demo_owner_password == "change-me-owner"
    assert settings.demo_member_password == "change-me-member"
