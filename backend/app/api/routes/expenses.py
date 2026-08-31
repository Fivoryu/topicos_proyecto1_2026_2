"""Protected source-expense routes and the decimal-to-cents boundary."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from fastapi import APIRouter, Depends, Response, status

from backend.app.api.deps import AuthenticatedActor, require_csrf
from backend.app.api.routes._common import (
    MISSING,
    Identifier,
    archived,
    call_with_actor,
    coerce_identifier,
    find_group_record,
    get_expense_repository,
    get_expense_service,
    get_participant_service,
    identifier,
    list_group,
    lookup_by_id,
    require_group_scoped_access,
    value,
)
from backend.app.api.schemas.expenses import (
    ExpenseBeneficiaryResponse,
    ExpenseContributorResponse,
    ExpenseResponse,
    ExpenseWriteRequest,
)
from backend.app.application.expense_service import ExpenseNotFoundError
from backend.app.domain.balance_service import PersistenceCorruptedError
from backend.app.domain.money import parse_amount_text

router = APIRouter(prefix="/api/v1/groups/{group_id}/expenses", tags=["expenses"])


def _parse_command(
    payload: ExpenseWriteRequest,
) -> tuple[int, list[dict[str, Any]], list[str]]:
    """Parse each lexical amount exactly once before entering the use case."""

    amount_cents = parse_amount_text(payload.amount)
    contributors = [
        {
            "participant_id": item.participant_id,
            "amount_cents": parse_amount_text(item.amount),
        }
        for item in payload.contributors
    ]
    beneficiaries = list(payload.beneficiary_ids)
    return amount_cents, contributors, beneficiaries


def _children(expense: object, repository: Any, group_id: Identifier):
    expense_id = identifier(expense, "id", "expense_id")
    contributors = value(expense, "contributors", "contributions", default=MISSING)
    if contributors is MISSING:
        method = getattr(repository, "list_contributions", None)
        contributors = method(group_id, expense_id) if method else ()
    beneficiaries = value(expense, "beneficiaries", "beneficiary_ids", default=MISSING)
    if beneficiaries is MISSING:
        method = getattr(repository, "list_beneficiaries", None)
        beneficiaries = method(group_id, expense_id) if method else ()
    return contributors, beneficiaries


def _contributor_items(value_to_normalize: object) -> list[tuple[str, int]]:
    if isinstance(value_to_normalize, Mapping):
        if "participant_id" in value_to_normalize or "id" in value_to_normalize:
            participant_id = identifier(value_to_normalize, "participant_id", "id")
            amount = value(value_to_normalize, "amount_cents", "amount")
            return [(participant_id, amount)]  # type: ignore[list-item]
        return [
            (participant_id, amount)  # type: ignore[misc]
            for participant_id, amount in value_to_normalize.items()
        ]
    result: list[tuple[str, int]] = []
    for row in value_to_normalize:  # type: ignore[union-attr]
        if isinstance(row, (tuple, list)) and len(row) == 2:
            participant_id, amount = row
        else:
            participant_id = identifier(row, "participant_id", "id")
            amount = value(row, "amount_cents", "amount")
        if not isinstance(amount, int) or isinstance(amount, bool):
            raise PersistenceCorruptedError(
                "Expense contribution source must contain integer cents."
            )
        result.append((participant_id, amount))
    return result


def _beneficiary_items(value_to_normalize: object) -> list[str]:
    if isinstance(value_to_normalize, Mapping):
        if "participant_id" in value_to_normalize or "id" in value_to_normalize:
            return [identifier(value_to_normalize, "participant_id", "id")]
        return list(value_to_normalize)
    result = []
    for row in value_to_normalize:  # type: ignore[union-attr]
        if isinstance(row, (tuple, list)):
            result.append(row[0])
        else:
            result.append(identifier(row, "participant_id", "id")) if not isinstance(
                row, (str, bytes)
            ) else result.append(row)
    return result


def _participant_info(participant_id: str, rows: list[Any]) -> tuple[str, bool]:
    participant = lookup_by_id(rows, participant_id)
    if participant is None:
        raise PersistenceCorruptedError(
            "Expense references a participant absent from its group."
        )
    name = value(participant, "name")
    if not isinstance(name, str):
        raise PersistenceCorruptedError("Participant source is missing a name.")
    return name, archived(participant)


def _response(
    expense: object,
    group_id: Identifier,
    participant_rows: list[Any],
    repository: Any,
) -> ExpenseResponse:
    contributor_source, beneficiary_source = _children(expense, repository, group_id)
    contributors = []
    for participant_id, amount_cents in _contributor_items(contributor_source):
        name, is_archived = _participant_info(participant_id, participant_rows)
        contributors.append(
            ExpenseContributorResponse(
                participant_id=participant_id,
                name=name,
                archived=is_archived,
                amount_cents=amount_cents,
            )
        )
    beneficiaries = []
    for participant_id in _beneficiary_items(beneficiary_source):
        name, is_archived = _participant_info(participant_id, participant_rows)
        beneficiaries.append(
            ExpenseBeneficiaryResponse(
                participant_id=participant_id,
                name=name,
                archived=is_archived,
            )
        )
    amount_cents = value(expense, "amount_cents", "amount")
    if not isinstance(amount_cents, int) or isinstance(amount_cents, bool):
        raise PersistenceCorruptedError("Expense source must contain integer cents.")
    return ExpenseResponse(
        id=identifier(expense, "id", "expense_id"),
        group_id=identifier(expense, "group_id"),
        description=value(expense, "description"),  # type: ignore[arg-type]
        amount_cents=amount_cents,
        contributors=contributors,
        beneficiaries=beneficiaries,
        created_at=value(expense, "created_at", default=None),  # type: ignore[arg-type]
        updated_at=value(expense, "updated_at", default=None),  # type: ignore[arg-type]
    )


def _list_expenses(service: Any, repository: Any, group_id: Identifier, actor: Any):
    method = getattr(service, "list", None) or getattr(service, "list_expenses", None)
    if method is not None:
        return call_with_actor(method, group_id, actor=actor)
    return list_group(repository, group_id)


def _find_expense(
    service: Any,
    repository: Any,
    group_id: Identifier,
    expense_id: Identifier,
):
    method = getattr(service, "get", None) or getattr(service, "read", None)
    if method is not None:
        result = call_with_actor(method, group_id, expense_id, actor=object())
    else:
        result = find_group_record(repository, group_id, expense_id)
    if result is None:
        raise ExpenseNotFoundError()
    return result


def _participant_rows(service: Any, group_id: Identifier, actor: Any) -> list[Any]:
    return list(call_with_actor(getattr(service, "list"), group_id, actor=actor))


@router.get("", response_model=list[ExpenseResponse])
def list_expenses(
    group_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_expense_service),
    participant_service: Any = Depends(get_participant_service),
    repository: Any = Depends(get_expense_repository),
) -> list[ExpenseResponse]:
    """List source expenses in stable creation order with current names."""

    stored_group_id = coerce_identifier(group_id)
    rows = _list_expenses(service, repository, stored_group_id, actor)
    participants = _participant_rows(participant_service, stored_group_id, actor)
    return [_response(row, stored_group_id, participants, repository) for row in rows]


@router.post(
    "",
    response_model=ExpenseResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_expense(
    group_id: str,
    payload: ExpenseWriteRequest,
    _csrf: None = Depends(require_csrf),
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_expense_service),
    participant_service: Any = Depends(get_participant_service),
    repository: Any = Depends(get_expense_repository),
) -> ExpenseResponse:
    """Parse lexical money and create one complete source expense."""

    amount_cents, contributors, beneficiaries = _parse_command(payload)
    stored_group_id = coerce_identifier(group_id)
    row = call_with_actor(
        getattr(service, "create"),
        stored_group_id,
        payload.description,
        amount_cents,
        contributors,
        beneficiaries,
        actor=actor,
    )
    participants = _participant_rows(participant_service, stored_group_id, actor)
    return _response(row, stored_group_id, participants, repository)


@router.get("/{expense_id}", response_model=ExpenseResponse)
def get_expense(
    group_id: str,
    expense_id: str,
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_expense_service),
    participant_service: Any = Depends(get_participant_service),
    repository: Any = Depends(get_expense_repository),
) -> ExpenseResponse:
    """Read one group-owned source expense."""

    stored_group_id = coerce_identifier(group_id)
    row = _find_expense(
        service, repository, stored_group_id, coerce_identifier(expense_id)
    )
    participants = _participant_rows(participant_service, stored_group_id, actor)
    return _response(row, stored_group_id, participants, repository)


@router.patch("/{expense_id}", response_model=ExpenseResponse)
def edit_expense(
    group_id: str,
    expense_id: str,
    payload: ExpenseWriteRequest,
    _csrf: None = Depends(require_csrf),
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_expense_service),
    participant_service: Any = Depends(get_participant_service),
    repository: Any = Depends(get_expense_repository),
) -> ExpenseResponse:
    """Validate a full replacement before changing the source expense."""

    amount_cents, contributors, beneficiaries = _parse_command(payload)
    stored_group_id = coerce_identifier(group_id)
    row = call_with_actor(
        getattr(service, "edit"),
        stored_group_id,
        coerce_identifier(expense_id),
        payload.description,
        amount_cents,
        contributors,
        beneficiaries,
        actor=actor,
    )
    participants = _participant_rows(participant_service, stored_group_id, actor)
    return _response(row, stored_group_id, participants, repository)


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_expense(
    group_id: str,
    expense_id: str,
    _csrf: None = Depends(require_csrf),
    actor: AuthenticatedActor = Depends(require_group_scoped_access),
    service: Any = Depends(get_expense_service),
) -> Response:
    """Delete a source expense and all of its derived effect."""

    call_with_actor(
        getattr(service, "delete"),
        coerce_identifier(group_id),
        coerce_identifier(expense_id),
        actor=actor,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


__all__ = ["router"]
