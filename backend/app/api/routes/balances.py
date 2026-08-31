"""Protected server-derived balance route."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from fastapi import APIRouter, Depends

from backend.app.api.deps import AuthenticatedActor
from backend.app.api.routes._common import (
    archived,
    balance_value,
    call_with_actor,
    coerce_identifier,
    get_derived_service,
    get_participant_service,
    identifier,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.balances import (
    BalanceParticipantResponse,
    BalancesResponse,
)
from backend.app.domain.balance_service import PersistenceCorruptedError

router = APIRouter(prefix="/api/v1/groups/{group_id}/balances", tags=["balances"])


def _row_for(balances: object, participant_id: str) -> object | None:
    if isinstance(balances, Mapping):
        lookup = coerce_identifier(participant_id)
        if lookup in balances:
            return balances[lookup]
        return balances.get(str(participant_id))
    for row in balances:  # type: ignore[union-attr]
        row_id = value(row, "participant_id", "id", default=None)
        if row_id == participant_id or str(row_id) == str(participant_id):
            return row
    return None


def _response(
    group_id: str, participants: list[Any], balances: object
) -> BalancesResponse:
    result = []
    for participant in participants:
        participant_id = identifier(participant, "id", "participant_id")
        balance = _row_for(balances, participant_id)
        if balance is None:
            raise PersistenceCorruptedError(
                "Balance source is missing a group participant."
            )
        try:
            result.append(
                BalanceParticipantResponse(
                    participant_id=participant_id,
                    name=value(participant, "name"),  # type: ignore[arg-type]
                    archived=archived(participant),
                    paid_cents=balance_value(balance, "paid_cents"),
                    owed_cents=balance_value(balance, "owed_cents"),
                    balance_cents=balance_value(balance, "balance_cents"),
                )
            )
        except (TypeError, ValueError) as error:
            raise PersistenceCorruptedError(
                "Balance source contains an invalid participant row."
            ) from error
    return BalancesResponse(group_id=group_id, participants=result)


@router.get("", response_model=BalancesResponse)
def get_balances(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    derived_service: Any = Depends(get_derived_service),
    participant_service: Any = Depends(get_participant_service),
) -> BalancesResponse:
    """Compute balances from source expenses in stable participant order."""

    stored_group_id = coerce_identifier(group_id)
    method = getattr(derived_service, "get_balances", None) or getattr(
        derived_service, "balances"
    )
    balances = method(stored_group_id)
    participants = call_with_actor(
        getattr(participant_service, "list"), stored_group_id, actor=actor
    )
    return _response(str(stored_group_id), list(participants), balances)


__all__ = ["router"]
