"""Alembic harness tests for the backend bootstrap."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).parents[2]
BACKEND_ROOT = PROJECT_ROOT / "backend"


def test_alembic_harness_includes_source_revision():
    alembic_ini = BACKEND_ROOT / "alembic.ini"
    migration_env = BACKEND_ROOT / "migrations" / "env.py"
    migration_template = BACKEND_ROOT / "migrations" / "script.py.mako"
    revisions = list((BACKEND_ROOT / "migrations" / "versions").glob("*.py"))

    assert "script_location = backend/migrations" in alembic_ini.read_text()
    assert migration_env.is_file()
    assert migration_template.is_file()
    assert revisions == [
        BACKEND_ROOT / "migrations" / "versions" / "0001_auth.py",
        BACKEND_ROOT / "migrations" / "versions" / "0002_source.py",
    ]
