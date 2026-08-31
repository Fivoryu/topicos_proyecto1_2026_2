"""Unit tests for source-expense validation rules."""

import pytest
from backend.app.domain.errors import (
    ContributionMismatchError,
    DomainError,
    ErrorCode,
    InvalidAmountError,
    InvalidParticipantReferenceError,
    NoBeneficiariesError,
    NoParticipantsError,
)
from backend.app.domain.expense_rules import validate_expense

PARTICIPANTS = ("ana", "beto", "carla", "diego")


def test_valid_multi_contributor_expense_is_accepted():
    assert (
        validate_expense(
            amount_cents=10_000,
            contributors={"ana": 6_000, "beto": 4_000},
            beneficiaries=("ana", "beto", "carla"),
            participants=PARTICIPANTS,
        )
        is None
    )


def test_expense_requires_at_least_one_contributor():
    with pytest.raises(NoParticipantsError) as error:
        validate_expense(
            amount_cents=10_000,
            contributors={},
            beneficiaries=("ana",),
            participants=PARTICIPANTS,
        )

    assert error.value.code == ErrorCode.NO_PARTICIPANTS.value


def test_expense_requires_at_least_one_beneficiary():
    with pytest.raises(NoBeneficiariesError) as error:
        validate_expense(
            amount_cents=10_000,
            contributors={"ana": 10_000},
            beneficiaries=(),
            participants=PARTICIPANTS,
        )

    assert error.value.code == ErrorCode.NO_BENEFICIARIES.value


def test_empty_group_is_reported_before_reference_validation():
    with pytest.raises(NoParticipantsError) as error:
        validate_expense(
            amount_cents=10_000,
            contributors={"ana": 10_000},
            beneficiaries=("ana",),
            participants=(),
        )

    assert error.value.code == ErrorCode.NO_PARTICIPANTS.value


def test_contributor_and_beneficiary_references_must_belong_to_group():
    with pytest.raises(InvalidParticipantReferenceError) as error:
        validate_expense(
            amount_cents=10_000,
            contributors={"outsider": 10_000},
            beneficiaries=("ana",),
            participants=PARTICIPANTS,
        )

    assert error.value.code == ErrorCode.INVALID_PARTICIPANT_REFERENCE.value

    with pytest.raises(InvalidParticipantReferenceError):
        validate_expense(
            amount_cents=10_000,
            contributors={"ana": 10_000},
            beneficiaries=("outsider",),
            participants=PARTICIPANTS,
        )


def test_amount_and_contribution_values_must_be_positive_integer_cents():
    with pytest.raises(InvalidAmountError):
        validate_expense(
            amount_cents=0,
            contributors={"ana": 0},
            beneficiaries=("ana",),
            participants=PARTICIPANTS,
        )

    with pytest.raises(InvalidAmountError):
        validate_expense(
            amount_cents=10_000,
            contributors={"ana": 0},
            beneficiaries=("ana",),
            participants=PARTICIPANTS,
        )

    with pytest.raises(InvalidAmountError):
        validate_expense(
            amount_cents=10_000,
            contributors={"ana": 10_000.0},
            beneficiaries=("ana",),
            participants=PARTICIPANTS,
        )


def test_contributions_must_sum_to_the_expense_amount():
    with pytest.raises(ContributionMismatchError) as error:
        validate_expense(
            amount_cents=10_000,
            contributors={"ana": 6_000, "beto": 3_000},
            beneficiaries=("ana", "beto"),
            participants=PARTICIPANTS,
        )

    assert error.value.code == ErrorCode.CONTRIBUTION_MISMATCH.value


def test_record_shaped_contributors_and_participants_are_supported():
    participants = (
        {"id": "ana", "archived": False},
        {"id": "beto", "archived": True},
    )

    assert (
        validate_expense(
            amount_cents=1_000,
            contributors=({"participant_id": "ana", "amount_cents": 1_000},),
            beneficiaries=({"participant_id": "beto"},),
            participants=participants,
        )
        is None
    )


def test_boolean_amounts_are_not_accepted_as_integer_cents():
    with pytest.raises(InvalidAmountError):
        validate_expense(
            amount_cents=True,
            contributors={"ana": 1},
            beneficiaries=("ana",),
            participants=PARTICIPANTS,
        )


def test_duplicate_contributor_or_beneficiary_references_fail_closed():
    with pytest.raises(InvalidParticipantReferenceError):
        validate_expense(
            amount_cents=2_000,
            contributors=(("ana", 1_000), ("ana", 1_000)),
            beneficiaries=("ana",),
            participants=PARTICIPANTS,
        )

    with pytest.raises(InvalidParticipantReferenceError):
        validate_expense(
            amount_cents=1_000,
            contributors={"ana": 1_000},
            beneficiaries=("ana", "ana"),
            participants=PARTICIPANTS,
        )


def test_domain_errors_keep_the_stable_error_contract():
    assert issubclass(InvalidParticipantReferenceError, DomainError)
    assert issubclass(ContributionMismatchError, DomainError)
