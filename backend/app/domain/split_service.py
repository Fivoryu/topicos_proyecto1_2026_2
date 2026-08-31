"""Exact, deterministic equal splitting for expense beneficiaries."""

from .errors import NoBeneficiariesError


def equal_split(
    amount_cents: int,
    beneficiaries,
    contributors,
    stable_order,
) -> dict:
    """Return each stable participant's exact equal beneficiary share.

    ``stable_order`` is the caller-provided group creation order. The returned
    mapping preserves that order and includes zero shares for non-beneficiaries.
    Contributor amounts are validated by the expense rules; this service only
    needs their participant IDs to choose the residual recipient.
    """

    if not isinstance(amount_cents, int) or isinstance(amount_cents, bool):
        raise TypeError("amount_cents must be an integer")

    stable_participants = tuple(stable_order)
    if len(set(stable_participants)) != len(stable_participants):
        raise ValueError("stable_order must not contain duplicate participants")

    beneficiary_values = tuple(beneficiaries)
    if not beneficiary_values:
        raise NoBeneficiariesError()
    beneficiary_ids = set(beneficiary_values)
    if len(beneficiary_ids) != len(beneficiary_values):
        raise ValueError("beneficiaries must not contain duplicate participants")

    stable_ids = set(stable_participants)
    if not beneficiary_ids.issubset(stable_ids):
        raise ValueError("beneficiaries must be present in stable_order")

    selected = [
        participant_id
        for participant_id in stable_participants
        if participant_id in beneficiary_ids
    ]
    shares: dict = {participant_id: 0 for participant_id in stable_participants}

    base = amount_cents // len(selected)
    residual = amount_cents % len(selected)
    for participant_id in selected:
        shares[participant_id] = base

    if residual:
        contributor_ids = set(contributors)
        residual_recipient = None
        for participant_id in selected:
            residual_recipient = participant_id
            break
        for participant_id in stable_participants:
            if participant_id in contributor_ids and participant_id in beneficiary_ids:
                residual_recipient = participant_id
                break
        if residual_recipient is None:
            raise AssertionError("equal split has no residual recipient")
        shares[residual_recipient] += residual

    total = 0
    for share in shares.values():
        total += share
    if total != amount_cents:
        raise AssertionError(
            f"equal split invariant violated: expected {amount_cents}, got {total}"
        )

    return shares
