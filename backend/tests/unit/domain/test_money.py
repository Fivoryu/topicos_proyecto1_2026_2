"""Unit tests for the exact decimal-to-cents boundary."""

from decimal import Decimal

import pytest
from backend.app.domain.errors import (
    DomainError,
    ErrorCode,
    InvalidRateError,
    UnsupportedCurrencyError,
)
from backend.app.domain.money import (
    Cents,
    CurrencyCode,
    ExchangeRate,
    SourceMoney,
    parse_amount_text,
    parse_currency_code,
)


@pytest.mark.parametrize(
    ("text", "expected_cents"),
    [
        ("0.01", 1),
        ("1.2", 120),
        ("10.5", 1_050),
        ("100", 10_000),
        ("100.00", 10_000),
        ("1000.9", 100_090),
        ("1000.99", 100_099),
        ("0001.05", 105),
    ],
)
def test_parse_amount_text_returns_exact_integer_cents(
    text: str, expected_cents: int
) -> None:
    result = parse_amount_text(text)

    assert result == expected_cents
    assert isinstance(result, int)


@pytest.mark.parametrize(
    "value",
    [
        "",
        "   ",
        "\t",
        "100.",
        ".50",
        "1.2.3",
        "1,600",
        "1,600.00",
        " 1.00",
        "1.00 ",
        "1_600.00",
        "1e2",
        "+50.00",
        "-50.00",
        "100.001",
        "0",
        "0.00",
        None,
    ],
)
def test_parse_amount_text_rejects_invalid_amounts_with_stable_code(value: str) -> None:
    with pytest.raises(DomainError) as error:
        parse_amount_text(value)

    assert error.value.code == ErrorCode.INVALID_AMOUNT.value


def test_invalid_amount_message_explains_decimal_precision_limit():
    with pytest.raises(DomainError) as error:
        parse_amount_text("100.001")

    assert "at most two decimal places" in error.value.message


def test_cents_is_an_integer_type_alias():
    assert Cents is int


def test_domain_error_codes_are_stable_for_subsequent_domain_rules():
    assert {code.value for code in ErrorCode} == {
        "invalid_amount",
        "no_beneficiaries",
        "no_participants",
        "invalid_participant_reference",
        "contribution_mismatch",
        "invalid_participant_name",
        "duplicate_participant_name",
        "participant_in_use",
        "unsupported_currency",
        "invalid_rate",
        "conversion_failed",
    }


@pytest.mark.parametrize("value", ["USD", "BOB", "EUR"])
def test_currency_code_accepts_closed_set(value: str):
    assert parse_currency_code(value) is CurrencyCode(value)


@pytest.mark.parametrize("value", ["usd", "Bs", "$", "JPY", "euro", ""])
def test_currency_code_rejects_unsupported_values(value: str):
    with pytest.raises(UnsupportedCurrencyError) as error:
        parse_currency_code(value)
    assert error.value.code == ErrorCode.UNSUPPORTED_CURRENCY.value


def test_source_money_requires_positive_integer_cents_and_currency():
    assert SourceMoney(1250, CurrencyCode.USD).cents == 1250
    for cents in (0, -1, True, 1.5, "1250"):
        with pytest.raises((DomainError, TypeError, ValueError)):
            SourceMoney(cents, CurrencyCode.USD)
    with pytest.raises(UnsupportedCurrencyError):
        SourceMoney(1250, "usd")


@pytest.mark.parametrize(
    "value",
    [
        Decimal("0"),
        Decimal("-0.1"),
        Decimal("NaN"),
        Decimal("Infinity"),
        Decimal("0.1234567890123456789"),
        0.072,
        "0.072",
    ],
)
def test_exchange_rate_rejects_invalid_values(value):
    with pytest.raises(InvalidRateError):
        ExchangeRate(CurrencyCode.BOB, value=value)


def test_exchange_rate_validates_decimal_direction_and_identity():
    rate = ExchangeRate(CurrencyCode.BOB, value=Decimal("0.072000"))
    assert (rate.value, rate.quote) == (Decimal("0.072"), CurrencyCode.USD)
    assert ExchangeRate(CurrencyCode.USD, value=Decimal("1")).value == Decimal("1")
    for kwargs in (
        {"value": Decimal("1.01")},
        {"quote": CurrencyCode.EUR, "value": Decimal("0.072")},
    ):
        with pytest.raises(InvalidRateError):
            source = CurrencyCode.USD if "quote" not in kwargs else CurrencyCode.BOB
            ExchangeRate(source, **kwargs)


def test_exchange_rate_text_parser_rejects_exponent_form():
    with pytest.raises(InvalidRateError):
        ExchangeRate.from_text(CurrencyCode.BOB, "1e-2")
