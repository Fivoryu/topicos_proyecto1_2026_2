"""Deterministic total-first conversion and USD paid allocation."""

from collections.abc import Iterable, Mapping
from decimal import ROUND_FLOOR, ROUND_HALF_UP, Decimal, DecimalException, localcontext

from .errors import ConversionFailedError
from .money import ExchangeRate, SourceMoney

_ONE = Decimal("1")
_PRECISION = 60


def _fail(message: str) -> None:
    raise ConversionFailedError(message)


def _integer(value: object, name: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        _fail(f"{name} must be an integer number of cents.")
    return value


def convert_to_usd_cents(source_cents: int | SourceMoney, rate: ExchangeRate) -> int:
    """Convert one complete source total, rounding once to USD cents."""
    if not isinstance(rate, ExchangeRate):
        _fail("Conversion requires a validated exchange rate.")
    currency = None
    if isinstance(source_cents, SourceMoney):
        currency, cents = source_cents.currency, source_cents.cents
    else:
        cents = _integer(source_cents, "source cents")
    if currency is not None and currency is not rate.source:
        _fail("Source money and exchange rate currencies do not match.")
    try:
        with localcontext() as context:
            context.prec = _PRECISION
            converted = (Decimal(cents) * rate.value).quantize(
                _ONE, rounding=ROUND_HALF_UP
            )
        if not converted.is_finite():
            _fail("Conversion produced a non-finite USD amount.")
        return int(converted)
    except ConversionFailedError:
        raise
    except (DecimalException, OverflowError, ValueError) as error:
        raise ConversionFailedError("Validated money could not be converted.") from error  # noqa: E501


def _items(contributors: object) -> tuple[tuple[object, int], ...]:
    if isinstance(contributors, Mapping):
        raw = tuple(contributors.items())
    else:
        try:
            raw = tuple(contributors)  # type: ignore[arg-type]
        except TypeError as error:
            raise ConversionFailedError("Contributors must be ordered pairs.") from error  # noqa: E501
    result, seen = [], set()
    for item in raw:
        if not isinstance(item, (tuple, list)) or len(item) != 2:
            _fail("Each contributor must contain an id and source cents.")
        participant_id, cents = item
        try:
            if participant_id in seen:
                _fail("Contributors must not contain duplicate ids.")
            seen.add(participant_id)
        except TypeError as error:
            raise ConversionFailedError("Contributor ids must be hashable.") from error
        cents = _integer(cents, "contributor source cents")
        if cents <= 0:
            _fail("Contributor source cents must be positive.")
        result.append((participant_id, cents))
    if not result:
        _fail("At least one contributor is required.")
    return tuple(result)


def allocate_paid_usd_cents(
    usd_total_cents: int,
    contributors: Mapping[object, int] | Iterable[tuple[object, int]],
    source_total_cents: int | None = None,
    stable_order: Iterable[object] | None = None,
) -> dict[object, int]:
    """Allocate one converted total by largest remainder in stable order."""
    total = _integer(usd_total_cents, "USD total cents")
    if total < 0:
        _fail("Paid USD allocation requires a non-negative total.")
    items = _items(contributors)
    source_total = (
        sum(cents for _, cents in items)
        if source_total_cents is None
        else _integer(source_total_cents, "source total cents")
    )
    if source_total <= 0 or sum(cents for _, cents in items) != source_total:
        _fail("Contributor source cents must conserve the source total.")
    by_id = dict(items)
    if stable_order is None:
        ordered = tuple(participant_id for participant_id, _ in items)
    else:
        supplied = tuple(stable_order)
        try:
            if len(set(supplied)) != len(supplied):
                _fail("Stable contributor order must not contain duplicates.")
            ordered = tuple(id_ for id_ in supplied if id_ in by_id)
        except TypeError as error:
            raise ConversionFailedError("Stable contributor ids must be hashable.") from error  # noqa: E501
        if len(ordered) != len(items):
            _fail("Stable contributor order must include every contributor.")

    floors, remainders = {}, []
    try:
        with localcontext() as context:
            context.prec = _PRECISION
            for order, participant_id in enumerate(ordered):
                quota = Decimal(total) * Decimal(by_id[participant_id]) / Decimal(source_total)  # noqa: E501
                floor = quota.to_integral_value(rounding=ROUND_FLOOR)
                floors[participant_id] = int(floor)
                remainders.append((quota - floor, order, participant_id))
    except (DecimalException, OverflowError, ValueError, KeyError) as error:
        raise ConversionFailedError("Contributor allocation could not be completed.") from error  # noqa: E501

    residual = total - sum(floors.values())
    if residual < 0 or residual > len(ordered):
        _fail("Paid USD allocation did not conserve the converted total.")
    for _, _, participant_id in sorted(remainders, key=lambda row: (-row[0], row[1]))[:residual]:  # noqa: E501
        floors[participant_id] += 1
    if sum(floors.values()) != total:
        _fail("Paid USD allocation did not conserve the converted total.")
    return floors


convert_source_to_usd_cents = convert_to_usd_cents
convert_total_to_usd_cents = convert_to_usd_cents
allocate_contributor_usd_cents = allocate_paid_usd_cents
