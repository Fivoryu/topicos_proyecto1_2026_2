"""Focused tests for total-first USD conversion and paid allocation."""

from decimal import Decimal

import pytest
from backend.app.domain import balance_service, settlement_service, split_service
from backend.app.domain.conversion_service import (
    allocate_paid_usd_cents,
    convert_to_usd_cents,
)
from backend.app.domain.errors import ConversionFailedError, ErrorCode
from backend.app.domain.money import CurrencyCode, ExchangeRate, SourceMoney


def rate(source, value):
    return ExchangeRate(source, value=Decimal(value))


def test_usd_identity_and_total_first_rounding():
    assert convert_to_usd_cents(1250, rate(CurrencyCode.USD, "1")) == 1250
    assert convert_to_usd_cents(
        SourceMoney(1250, CurrencyCode.USD), rate(CurrencyCode.USD, "1")
    ) == 1250
    assert convert_to_usd_cents(100, rate(CurrencyCode.BOB, "0.072")) == 7
    assert convert_to_usd_cents(10_000, rate(CurrencyCode.EUR, "1.08765")) == 10_877
    assert convert_to_usd_cents(-100, rate(CurrencyCode.BOB, "0.072")) == -7


def test_conversion_rejects_mismatched_currency_and_non_integer_input():
    with pytest.raises(ConversionFailedError) as error:
        convert_to_usd_cents(
            SourceMoney(100, CurrencyCode.BOB), rate(CurrencyCode.EUR, "1")
        )
    assert error.value.code == ErrorCode.CONVERSION_FAILED.value
    for cents in (True, 1.5, "100"):
        with pytest.raises(ConversionFailedError):
            convert_to_usd_cents(cents, rate(CurrencyCode.BOB, "0.072"))


def test_paid_allocation_uses_one_total_and_conserves_largest_remainder():
    assert allocate_paid_usd_cents(10_877, {"ana": 6_000, "beto": 4_000}, 10_000) == {
        "ana": 6_526,
        "beto": 4_351,
    }
    tied = allocate_paid_usd_cents(
        10, {"later": 1, "first": 1, "last": 1}, 3, ("first", "later", "last")
    )
    assert tied == {"first": 4, "later": 3, "last": 3}
    assert sum(tied.values()) == 10


def test_paid_allocation_covers_one_contributor_and_zero_residual():
    assert allocate_paid_usd_cents(720, {"ana": 100}, 100) == {"ana": 720}
    assert allocate_paid_usd_cents(9, {"ana": 1, "beto": 2}, 3) == {"ana": 3, "beto": 6}


def test_paid_allocation_rejects_non_conserving_or_non_positive_source_rows():
    for arguments in ((10, {"ana": 6, "beto": 3}, 10), (10, {"ana": 0}, 0)):
        with pytest.raises(ConversionFailedError):
            allocate_paid_usd_cents(*arguments)


def test_converted_inputs_keep_existing_derived_service_contracts():
    total = convert_to_usd_cents(100, rate(CurrencyCode.BOB, "0.072"))
    shares = split_service.equal_split(total, ("ana", "beto"), {"beto": total}, ("ana", "beto"))  # noqa: E501
    expense = {"amount_cents": total, "contributors": {"beto": total}, "beneficiaries": ("ana", "beto")}  # noqa: E501
    balances = balance_service.compute_balances(({"id": "ana"}, {"id": "beto"}), (expense,))  # noqa: E501
    transfer = settlement_service.build_settlement(balances)["transfers"][0]
    assert shares == {"ana": 3, "beto": 4} and transfer["amount_cents"] == 3
    assert sum(row["balance_cents"] for row in balances.values()) == 0
