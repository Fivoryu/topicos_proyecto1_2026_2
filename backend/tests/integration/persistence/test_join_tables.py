# ruff: noqa: E501, I001
from backend.app.adapters.db.tables import Base
from sqlalchemy import create_engine, inspect
def test_join_tables_persist_only_hashes_and_bind_participants_to_same_group():
    engine = create_engine("sqlite://")
    Base.metadata.create_all(engine)
    inspector = inspect(engine)
    code_columns = {column["name"] for column in inspector.get_columns("group_join_codes")}
    assert "token_hash" in code_columns and "code" not in code_columns
    assert inspector.get_pk_constraint("group_join_codes")["constrained_columns"] == ["group_id"]
    foreign_keys = inspector.get_foreign_keys("account_participant_links")
    assert any(
        fk["referred_table"] == "participants"
        and fk["constrained_columns"] == ["participant_id", "group_id"]
        and fk["referred_columns"] == ["id", "group_id"]
        for fk in foreign_keys
    )
    engine.dispose()
