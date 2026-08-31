"""Unit tests for deterministic equal beneficiary splitting."""

import pytest
from backend.app.domain.errors import ErrorCode, NoBeneficiariesError
from backend.app.domain.split_service import equal_split

STABLE_ORDER = ("ana", "beto", "carla", "diego")


def test_da02_assigns_complete_residual_to_first_stable_contributor_beneficiary():
    shares = equal_split(
        amount_cents=10_000,
        beneficiaries={"carla", "ana", "beto"},
        contributors={"ana": 10_000},
        stable_order=STABLE_ORDER,
    )

    assert shares == {"ana": 3_334, "beto": 3_333, "carla": 3_333, "diego": 0}
    assert sum(shares.values(), 0) == 10_000
    assert list(shares) == list(STABLE_ORDER)


def test_da03_excluded_participant_has_zero_share():
    shares = equal_split(
        amount_cents=30_000,
        beneficiaries={"ana", "beto", "carla"},
        contributors={"ana": 30_000},
        stable_order=STABLE_ORDER,
    )

    assert shares == {"ana": 10_000, "beto": 10_000, "carla": 10_000, "diego": 0}
    assert sum(shares.values(), 0) == 30_000


def test_cc01_uses_stable_order_not_contributor_entry_order():
    shares = equal_split(
        amount_cents=10_000,
        beneficiaries=("carla", "beto", "ana"),
        contributors={"beto": 4_000, "ana": 6_000},
        stable_order=STABLE_ORDER,
    )

    assert shares == {"ana": 3_334, "beto": 3_333, "carla": 3_333, "diego": 0}
    assert sum(shares.values(), 0) == 10_000


def test_cc01_falls_back_to_first_selected_beneficiary_when_intersection_is_empty():
    shares = equal_split(
        amount_cents=10_001,
        beneficiaries=("diego", "carla"),
        contributors={"ana": 6_001, "beto": 4_000},
        stable_order=STABLE_ORDER,
    )

    assert shares == {"ana": 0, "beto": 0, "carla": 5_001, "diego": 5_000}
    assert sum(shares.values(), 0) == 10_001
    assert list(shares) == list(STABLE_ORDER)


def test_empty_beneficiaries_use_the_existing_domain_error_contract():
    with pytest.raises(NoBeneficiariesError) as error:
        equal_split(
            amount_cents=10_000,
            beneficiaries=(),
            contributors={"ana": 10_000},
            stable_order=STABLE_ORDER,
        )

    assert error.value.code == ErrorCode.NO_BENEFICIARIES.value


def test_boolean_amount_is_rejected_before_money_arithmetic():
    with pytest.raises(TypeError, match="amount_cents must be an integer"):
        equal_split(
            amount_cents=True,
            beneficiaries=("ana",),
            contributors={"ana": 10_000},
            stable_order=STABLE_ORDER,
        )


def test_beneficiaries_missing_from_stable_order_fail_closed():
    with pytest.raises(ValueError, match="stable_order"):
        equal_split(
            amount_cents=10_000,
            beneficiaries=("ana", "unknown"),
            contributors={"ana": 10_000},
            stable_order=STABLE_ORDER,
        )
