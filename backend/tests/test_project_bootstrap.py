# pyright: reportMissingImports=false
"""Project metadata and local infrastructure tests for T-01."""

import tomllib
from pathlib import Path

PROJECT_ROOT = Path(__file__).parents[2]
BACKEND_ROOT = PROJECT_ROOT / "backend"


def test_backend_project_declares_runtime_and_test_dependencies():
    project = tomllib.loads((BACKEND_ROOT / "pyproject.toml").read_text())["project"]
    dependencies = "\n".join(project["dependencies"])
    test_dependencies = "\n".join(project["optional-dependencies"]["test"])

    for package in ("fastapi", "sqlalchemy", "alembic", "asyncpg", "argon2-cffi"):
        assert package in dependencies.lower()
    for package in ("pytest", "httpx"):
        assert package in test_dependencies.lower()


def test_postgres_compose_declares_volume_and_healthcheck():
    compose = (PROJECT_ROOT / "infra" / "docker-compose.yml").read_text()

    assert "services:" in compose
    assert "db:" in compose
    assert "image: postgres:" in compose
    assert "pg_isready" in compose
    assert "healthcheck:" in compose
    assert "volumes:" in compose
    assert "postgres_data:" in compose


def test_environment_example_documents_t01_variables():
    env_example = (BACKEND_ROOT / ".env.example").read_text()

    for variable in (
        "DATABASE_URL",
        "CORS_ORIGINS",
        "SESSION_TTL",
        "DEMO_OWNER_PASSWORD",
        "DEMO_MEMBER_PASSWORD",
    ):
        assert f"{variable}=" in env_example


def test_default_cors_origins_include_both_localhost_variants():
    from backend.app.adapters.config import Settings

    settings = Settings(_env_file=None)

    assert settings.cors_origins == [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ]


def test_cors_origins_environment_override_remains_explicit(monkeypatch):
    from backend.app.adapters.config import Settings

    monkeypatch.setenv(
        "CORS_ORIGINS", "https://frontend.example, https://admin.example"
    )

    settings = Settings(_env_file=None)

    assert settings.cors_origins == [
        "https://frontend.example",
        "https://admin.example",
    ]


def test_local_cors_override_keeps_both_loopback_hosts(monkeypatch):
    from backend.app.adapters.config import Settings

    monkeypatch.setenv("CORS_ORIGINS", "http://localhost:5173")
    settings = Settings(_env_file=None)

    assert settings.cors_origins == [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ]
