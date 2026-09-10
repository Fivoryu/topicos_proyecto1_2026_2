"""Exact monetary parsing and validated money value objects."""

import re
from dataclasses import dataclass
from decimal import Decimal
from enum import StrEnum

from .errors import InvalidAmountError, InvalidRateError, UnsupportedCurrencyError

Cents = int


class CurrencyCode(StrEnum):
    USD = "USD"
    BOB = "BOB"
    EUR = "EUR"

    @classmethod
    def _missing_(cls, value):
        raise UnsupportedCurrencyError()

    @classmethod
    def parse(cls, value: object) -> "CurrencyCode":
        if not isinstance(value, str):
            raise UnsupportedCurrencyError()
        return cls(value)

    @property
    def is_reporting_currency(self) -> bool:
        return self is CurrencyCode.USD


@dataclass(frozen=True)
class SourceMoney:
    cents: int
    currency: CurrencyCode

    def __post_init__(self) -> None:
        if not isinstance(self.cents, int) or isinstance(self.cents, bool):
            raise TypeError("source money cents must be an integer")
        if self.cents <= 0:
            raise ValueError("source money cents must be positive")
        object.__setattr__(self, "currency", CurrencyCode.parse(self.currency))


@dataclass(frozen=True, init=False)
class ExchangeRate:
    source: CurrencyCode
    quote: CurrencyCode
    value: Decimal

    def __init__(self, source, value=None, quote=CurrencyCode.USD):
        if isinstance(value, CurrencyCode):
            value, quote = quote, value
        source_code = CurrencyCode.parse(source)
        quote_code = CurrencyCode.parse(quote)
        if quote_code is not CurrencyCode.USD:
            raise InvalidRateError("Exchange rates must quote USD.")
        if not isinstance(value, Decimal):
            raise InvalidRateError("Exchange rate must be supplied as Decimal.")
        if not value.is_finite() or value <= 0:
            raise InvalidRateError()
        if value.as_tuple().exponent > 0:
            raise InvalidRateError("Exponent-form exchange rates are not accepted.")
        normalized = value.normalize()
        if max(0, -normalized.as_tuple().exponent) > 18:
            raise InvalidRateError("Exchange rate may have at most 18 decimals.")
        if source_code is CurrencyCode.USD:
            if normalized != Decimal("1"):
                raise InvalidRateError("USD exchange rate must be exactly 1.")
            normalized = Decimal("1")
        object.__setattr__(self, "source", source_code)
        object.__setattr__(self, "quote", quote_code)
        object.__setattr__(self, "value", normalized)

    @classmethod
    def from_text(cls, source: object, value: object, quote=CurrencyCode.USD):
        if not isinstance(value, str) or re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", value) is None:  # noqa: E501
            raise InvalidRateError("Exchange rate must be a decimal string without an exponent.")  # noqa: E501
        try:
            return cls(source, value=Decimal(value), quote=quote)
        except (TypeError, ValueError):
            raise InvalidRateError() from None


_AMOUNT_TEXT = re.compile(r"[0-9]+(?:\.[0-9]{1,2})?")


def _parse_ascii_digits(value: str) -> int:
    result = 0
    for character in value:
        result = result * 10 + ord(character) - 48
    return result


def parse_currency_code(value: object) -> CurrencyCode:
    """Parse an explicitly supplied ISO code without locale inference."""
    return CurrencyCode.parse(value)


def parse_amount_text(value: str) -> Cents:
    """Parse a positive ASCII decimal amount into exact integer cents."""
    if not isinstance(value, str) or _AMOUNT_TEXT.fullmatch(value) is None:
        raise InvalidAmountError()
    whole_text, separator, fraction_text = value.partition(".")
    if not separator:
        fraction_text = "00"
    elif len(fraction_text) == 1:
        fraction_text += "0"
    cents = _parse_ascii_digits(whole_text) * 100 + _parse_ascii_digits(fraction_text)
    if cents <= 0:
        raise InvalidAmountError()
    return cents
