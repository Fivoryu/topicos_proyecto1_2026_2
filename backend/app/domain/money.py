"""Exact monetary parsing for the domain boundary."""

import re

from .errors import InvalidAmountError

Cents = int

_AMOUNT_TEXT = re.compile(r"[0-9]+(?:\.[0-9]{1,2})?")


def _parse_ascii_digits(value: str) -> int:
    result = 0
    for character in value:
        result = result * 10 + ord(character) - 48
    return result


def parse_amount_text(value: str) -> Cents:
    """Parse a positive decimal amount into exact integer cents.

    The accepted lexical form is an ASCII digit sequence, optionally followed
    by a decimal point and one or two fractional digits. Whitespace, signs,
    grouping separators, exponents, and implicit rounding are rejected.
    """

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
