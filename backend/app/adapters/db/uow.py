"""Transaction boundary for source-data use cases."""

from __future__ import annotations

from collections.abc import Callable

from sqlalchemy.orm import Session as OrmSession

from .repositories import (
    ExpenseRepositoryAdapter,
    GroupRepositoryAdapter,
    ParticipantRepositoryAdapter,
)


class SqlAlchemyUnitOfWork:
    """Provide one session and source repositories for an atomic mutation."""

    def __init__(
        self,
        session: OrmSession | None = None,
        session_factory: Callable[[], OrmSession] | None = None,
    ):
        if session is None and session_factory is None:
            raise TypeError("session or session_factory is required")
        self._session = session
        self._session_factory = session_factory
        self._owns_session = session is None
        self.participants = None
        self.expenses = None
        self.groups = None

    def __enter__(self) -> SqlAlchemyUnitOfWork:
        if self._session is None:
            if self._session_factory is None:
                raise TypeError("session_factory required when no session is provided")
            self._session = self._session_factory()
        self.participants = ParticipantRepositoryAdapter(self._session)
        self.expenses = ExpenseRepositoryAdapter(self._session)
        self.groups = GroupRepositoryAdapter(self._session)
        return self

    def __exit__(self, exc_type, _exc, _traceback) -> bool:
        if exc_type is None:
            self.commit()
        else:
            self.rollback()
        if self._owns_session:
            assert self._session is not None, "session must exist when owned"
            self._session.close()
        return False

    def commit(self) -> None:
        if self._session is None:
            raise RuntimeError("unit of work is not active")
        self._session.commit()

    def rollback(self) -> None:
        if self._session is not None:
            self._session.rollback()


UnitOfWork = SqlAlchemyUnitOfWork

__all__ = ["SqlAlchemyUnitOfWork", "UnitOfWork"]
