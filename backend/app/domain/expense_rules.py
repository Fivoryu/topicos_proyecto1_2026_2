"""Validation and normalization for source expense data."""

from collections.abc import Mapping

from .errors import (
    ContributionMismatchError,
    InvalidAmountError,
    InvalidParticipantReferenceError,
    NoBeneficiariesError,
    NoParticipantsError,
)


class NormalizedExpense:
    """The integer-cent source values needed by the domain services."""

    def __init__(self, amount_cents, contributors, beneficiaries):
        self.amount_cents = amount_cents
        self.contributors = contributors
        self.beneficiaries = beneficiaries


def _field(value, *names):
    if isinstance(value, Mapping):
        for name in names:
            if name in value:
                return value[name]
    else:
        for name in names:
            if hasattr(value, name):
                attribute = getattr(value, name, None)
                if attribute is not None:
                    return attribute
    raise ValueError(f"missing required field: {', '.join(names)}")


def _identifier(value):
    if isinstance(value, Mapping):
        for name in ("participant_id", "id"):
            if name in value:
                value = value[name]
                break
        else:
            raise InvalidParticipantReferenceError(
                "A participant reference must include an id."
            )
    else:
        for name in ("participant_id", "id"):
            if hasattr(value, name):
                attribute = getattr(value, name, None)
                if attribute is not None:
                    value = attribute
                    break
                break

    try:
        hash(value)
    except TypeError as error:
        raise InvalidParticipantReferenceError(
            "A participant reference must be hashable."
        ) from error
    return value


def _participant_ids(participants, *, allow_empty=False):
    if isinstance(participants, Mapping):
        if "id" in participants or "participant_id" in participants:
            values = (participants,)
        else:
            values = participants.keys()
    elif isinstance(participants, (str, bytes)):
        values = (participants,)
    else:
        values = participants

    try:
        result = tuple(_identifier(value) for value in values)
    except TypeError as error:
        raise NoParticipantsError(
            "An expense requires a participant collection."
        ) from error

    if not result and not allow_empty:
        raise NoParticipantsError()
    if len(set(result)) != len(result):
        raise InvalidParticipantReferenceError(
            "The participant collection contains duplicate ids."
        )
    return result


def _contribution_items(contributors):
    if isinstance(contributors, Mapping):
        if "participant_id" in contributors or "id" in contributors:
            participant_id = _identifier(contributors)
            amount = _field(
                contributors,
                "amount_cents",
                "contribution_cents",
                "amount",
                "contribution",
            )
            return ((participant_id, amount),)
        return tuple(contributors.items())

    if isinstance(contributors, (str, bytes)):
        raise InvalidParticipantReferenceError(
            "Contributors must include participant ids and amounts."
        )

    try:
        entries = tuple(contributors)
    except TypeError as error:
        raise InvalidParticipantReferenceError(
            "Contributors must include participant ids and amounts."
        ) from error

    result = []
    for entry in entries:
        if isinstance(entry, Mapping):
            participant_id = _identifier(entry)
            amount = _field(
                entry,
                "amount_cents",
                "contribution_cents",
                "amount",
                "contribution",
            )
        elif isinstance(entry, (tuple, list)) and len(entry) == 2:
            participant_id, amount = entry
            participant_id = _identifier(participant_id)
        else:
            participant_id = _identifier(entry)
            amount = _field(
                entry,
                "amount_cents",
                "contribution_cents",
                "amount",
                "contribution",
            )
        result.append((participant_id, amount))
    return tuple(result)


def _beneficiary_ids(beneficiaries):
    if isinstance(beneficiaries, Mapping):
        if "participant_id" in beneficiaries or "id" in beneficiaries:
            values = (beneficiaries,)
        else:
            values = beneficiaries.keys()
    elif isinstance(beneficiaries, (str, bytes)):
        values = (beneficiaries,)
    else:
        values = beneficiaries

    try:
        result = tuple(_identifier(value) for value in values)
    except TypeError as error:
        raise NoBeneficiariesError() from error

    if not result:
        raise NoBeneficiariesError()
    if len(set(result)) != len(result):
        raise InvalidParticipantReferenceError(
            "The beneficiary collection contains duplicate ids."
        )
    return result


def _normalise_expense(*, amount_cents, contributors, beneficiaries, participants):
    participant_ids = _participant_ids(participants)
    participant_set = set(participant_ids)

    if not isinstance(amount_cents, int) or isinstance(amount_cents, bool):
        raise InvalidAmountError()
    if amount_cents <= 0:
        raise InvalidAmountError()

    contribution_items = _contribution_items(contributors)
    if not contribution_items:
        raise NoParticipantsError()

    beneficiary_ids = _beneficiary_ids(beneficiaries)
    beneficiary_set = set(beneficiary_ids)

    normalized_contributors = {}
    for participant_id, contribution in contribution_items:
        if participant_id not in participant_set:
            raise InvalidParticipantReferenceError()
        if participant_id in normalized_contributors:
            raise InvalidParticipantReferenceError(
                "A participant may contribute only once per expense."
            )
        if not isinstance(contribution, int) or isinstance(contribution, bool):
            raise InvalidAmountError()
        if contribution <= 0:
            raise InvalidAmountError()
        normalized_contributors[participant_id] = contribution

    for participant_id in beneficiary_ids:
        if participant_id not in participant_set:
            raise InvalidParticipantReferenceError()

    contribution_total = sum(normalized_contributors.values(), 0)
    if contribution_total != amount_cents:
        raise ContributionMismatchError()

    # Return stable group order for set-like beneficiary inputs. The split
    # service deliberately uses this order when selecting its residual target.
    stable_beneficiaries = tuple(
        participant_id
        for participant_id in participant_ids
        if participant_id in beneficiary_set
    )
    return NormalizedExpense(
        amount_cents,
        normalized_contributors,
        stable_beneficiaries,
    )


def validate_expense(amount_cents, contributors, beneficiaries, participants):
    """Validate one complete expense without mutating any source state.

    ``participants`` is the complete in-group participant collection. It may
    be a stable sequence of ids or records exposing ``id``. Contributors may be
    a mapping of participant ids to integer cents or records containing
    ``participant_id`` and ``amount_cents``. Beneficiaries may be ids or
    records. All accepted values are exact integer cents; floats are rejected.
    """

    _normalise_expense(
        amount_cents=amount_cents,
        contributors=contributors,
        beneficiaries=beneficiaries,
        participants=participants,
    )


# Keep the domain vocabulary explicit for callers that name the module rule
# rather than the operation.
validate_expense_rules = validate_expense
