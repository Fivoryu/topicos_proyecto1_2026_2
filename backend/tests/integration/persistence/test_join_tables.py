# ruff: noqa: E501, I001
from hashlib import sha256
from importlib import import_module
from uuid import uuid4

from alembic.migration import MigrationContext
from alembic.operations import Operations
from backend.app.adapters.db.tables import Base
from backend.app.adapters.security.join_codes import JoinCodeTokenSource
from sqlalchemy import create_engine, event, inspect, text


MIGRATIONS = [
    import_module(f"backend.migrations.versions.000{i}_{name}")
    for i, name in (
        (1, "auth"),
        (2, "source"),
        (3, "workspace"),
        (4, "outing"),
        (5, "expense_outing"),
        (6, "join_codes"),
    )
]


def _engine():
    engine = create_engine("sqlite://")

    @event.listens_for(engine, "connect")
    def _foreign_keys(connection, _record):
        cursor = connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    return engine


def _apply(connection, migration, direction):
    context = MigrationContext.configure(connection)
    setattr(migration, "op", Operations(context))
    getattr(migration, direction)()
def test_join_tables_persist_only_hashes_and_bind_participants_to_same_group():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    inspector = inspect(engine)
    code_columns = {column["name"] for column in inspector.get_columns("group_join_codes")}
    assert "token_hash" in code_columns and "code" not in code_columns
    assert "ck_group_join_codes_token_hash_sha256" in {
        check["name"] for check in inspector.get_check_constraints("group_join_codes")
    }
    assert inspector.get_pk_constraint("group_join_codes")["constrained_columns"] == ["group_id"]
    foreign_keys = inspector.get_foreign_keys("account_participant_links")
    assert any(
        fk["referred_table"] == "participants"
        and fk["constrained_columns"] == ["participant_id", "group_id"]
        and fk["referred_columns"] == ["id", "group_id"]
        for fk in foreign_keys
    )
    engine.dispose()


def test_join_code_token_source_returns_exact_sha256_digest():
    token = "known-join-token"
    digest = JoinCodeTokenSource().hash(token)

    assert digest == sha256(token.encode("utf-8")).digest()
    assert len(digest) == 32


def test_0006_migration_round_trip_preserves_existing_data():
    engine = _engine()
    owner_id, group_id, participant_id = (str(uuid4()) for _ in range(3))
    with engine.connect() as connection:
        for migration in MIGRATIONS[:5]:
            _apply(connection, migration, "upgrade")
        connection.execute(
            text(
                "INSERT INTO accounts (id, login_name, password_hash) "
                "VALUES (:id, :login_name, :password_hash)"
            ),
            {"id": owner_id, "login_name": "migration-owner", "password_hash": "hash"},
        )
        connection.execute(
            text(
                "INSERT INTO groups (id, name, owner_account_id) "
                "VALUES (:id, :name, :owner_account_id)"
            ),
            {"id": group_id, "name": "Migration group", "owner_account_id": owner_id},
        )
        connection.execute(
            text(
                "INSERT INTO group_memberships (group_id, account_id) "
                "VALUES (:group_id, :account_id)"
            ),
            {"group_id": group_id, "account_id": owner_id},
        )
        connection.execute(
            text(
                "INSERT INTO participants "
                "(id, group_id, name, normalized_name) "
                "VALUES (:id, :group_id, :name, :normalized_name)"
            ),
            {"id": participant_id, "group_id": group_id, "name": "Ana", "normalized_name": "ana"},
        )
        connection.commit()

        _apply(connection, MIGRATIONS[5], "upgrade")
        assert {"group_join_codes", "account_participant_links"}.issubset(
            inspect(connection).get_table_names()
        )
        connection.execute(
            text(
                "INSERT INTO group_join_codes (group_id, token_hash) "
                "VALUES (:group_id, :token_hash)"
            ),
            {"group_id": group_id, "token_hash": b"x" * 32},
        )
        connection.execute(
            text(
                "INSERT INTO account_participant_links "
                "(group_id, account_id, participant_id) "
                "VALUES (:group_id, :account_id, :participant_id)"
            ),
            {"group_id": group_id, "account_id": owner_id, "participant_id": participant_id},
        )
        connection.commit()

        _apply(connection, MIGRATIONS[5], "downgrade")
        tables = inspect(connection).get_table_names()
        assert "group_join_codes" not in tables and "account_participant_links" not in tables
        assert "accounts" in tables and "groups" in tables and "participants" in tables
        assert connection.execute(
            text("SELECT name, normalized_name FROM participants WHERE id = :id"),
            {"id": participant_id},
        ).one() == ("Ana", "ana")
        assert "uq_participants_id_group_id" not in {
            index["name"] for index in inspect(connection).get_indexes("participants")
        }
    engine.dispose()
