"""Unit tests for the exact decimal-to-cents boundary."""

import pytest
from backend.app.domain.errors import DomainError, ErrorCode
from backend.app.domain.money import Cents, parse_amount_text


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
    }
