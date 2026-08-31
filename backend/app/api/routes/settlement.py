"""Protected server-derived settlement route."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from fastapi import APIRouter, Depends

from backend.app.api.deps import AuthenticatedActor
from backend.app.api.routes._common import (
    call_with_actor,
    coerce_identifier,
    get_derived_service,
    get_group_service,
    get_participant_service,
    lookup_by_id,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.settlement import (
    SettlementResponse,
    SettlementTransferResponse,
)
from backend.app.domain.balance_service import PersistenceCorruptedError

router = APIRouter(prefix="/api/v1/groups/{group_id}/settlement", tags=["settlement"])


def _policy(group: object) -> str:
    policy = value(
        group,
        "settlement_policy",
        "settlementPolicy",
        default="owner_only",
    )
    if not isinstance(policy, str) or policy not in {"owner_only", "any_member"}:
        raise PersistenceCorruptedError("Group contains an invalid settlement policy.")
    return policy


def _transfer_values(transfer: object) -> tuple[str, str, int]:
    if isinstance(transfer, Mapping):
        source = transfer.get("from_participant_id")
        target = transfer.get("to_participant_id")
        amount = transfer.get("amount_cents")
    else:
        source = value(transfer, "from_participant_id")
        target = value(transfer, "to_participant_id")
        amount = value(transfer, "amount_cents")
    if not isinstance(source, str):
        if not hasattr(source, "hex"):
            raise PersistenceCorruptedError(
                "Settlement transfer has no source participant."
            )
        source = str(source)
    if not isinstance(target, str):
        if not hasattr(target, "hex"):
            raise PersistenceCorruptedError(
                "Settlement transfer has no target participant."
            )
        target = str(target)
    if not isinstance(amount, int) or isinstance(amount, bool) or amount <= 0:
        raise PersistenceCorruptedError("Settlement transfer amount is invalid.")
    return source, target, amount  # type: ignore[return-value]


@router.get("", response_model=SettlementResponse)
def get_settlement(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    derived_service: Any = Depends(get_derived_service),
    group_service: Any = Depends(get_group_service),
    participant_service: Any = Depends(get_participant_service),
) -> SettlementResponse:
    """Return policy and deterministic transfers derived from current balances."""

    stored_group_id = coerce_identifier(group_id)
    settlement_method = getattr(derived_service, "get_settlement", None) or getattr(
        derived_service, "settlement"
    )
    settlement = settlement_method(stored_group_id)
    group_method = getattr(group_service, "read", None) or getattr(group_service, "get")
    group = call_with_actor(group_method, stored_group_id, actor=actor)
    participants = list(
        call_with_actor(
            getattr(participant_service, "list"), stored_group_id, actor=actor
        )
    )
    transfers = []
    for transfer in settlement.get("transfers", ()):
        source, target, amount = _transfer_values(transfer)
        source_row = lookup_by_id(participants, source)
        target_row = lookup_by_id(participants, target)
        if source_row is None or target_row is None:
            raise PersistenceCorruptedError(
                "Settlement transfer references an unknown participant."
            )
        source_name = value(source_row, "name")
        target_name = value(target_row, "name")
        if not isinstance(source_name, str) or not isinstance(target_name, str):
            raise PersistenceCorruptedError("Settlement participant names are invalid.")
        transfers.append(
            SettlementTransferResponse(
                from_participant_id=source,
                to_participant_id=target,
                from_name=source_name,
                to_name=target_name,
                amount_cents=amount,
            )
        )
    return SettlementResponse(
        group_id=str(stored_group_id),
        settlement_policy=_policy(group),  # type: ignore[arg-type]
        settled=bool(settlement.get("settled", not transfers)),
        transfers=transfers,
    )


__all__ = ["router"]
