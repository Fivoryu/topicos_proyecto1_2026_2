# Money Specification

## Purpose

Guarantee that all monetary values in Cuentas Claras MVP are handled as exact integer cents end to end: parsed exactly once at the FastAPI boundary, stored and transmitted as integers, and rendered to users with a single fixed display convention. Floating-point arithmetic on money is prohibited everywhere, including clients.

## Requirements

### Requirement: Integer-cents representation

The system MUST represent every monetary value as an integer number of cents in the domain, database, and API. The API wire format MUST use an integer `amount_cents` field; no monetary field MAY be transmitted as a floating-point number. No component MAY perform floating-point arithmetic on monetary values; all money math MUST use integer operations.

#### Scenario: Wire values are integers

- GIVEN an expense of Bs. 100.00 created through the API
- WHEN the client reads the expense payload
- THEN the payload contains `amount_cents: 10000` as an integer and no decimal money field

### Requirement: Boundary parsing and validation

FastAPI MUST parse and validate every monetary input at the API boundary, converting the accepted representation to integer cents. The parser MUST accept at most two decimal places, MUST reject zero (`CB-02`) and negative amounts (`CB-03`) for expenses, and MUST reject amounts with more than two decimal places (`CB-04`) with an explicit error rather than silent rounding or normalization.

#### Scenario: Two-decimal input is accepted

- GIVEN an expense form submitting `100.00` for the amount
- WHEN the request reaches FastAPI
- THEN it is accepted and persisted as `amount_cents: 10000`

#### Scenario: More than two decimal places is rejected

- GIVEN an expense form submitting `100.001`
- WHEN the request reaches FastAPI
- THEN the request is rejected with error `invalid_amount` and an explicit message requesting a maximum of two decimal places
- AND no expense is persisted

#### Scenario: Zero and negative amounts are rejected

- GIVEN an expense form submitting `0` or `-50.00`
- WHEN the request reaches FastAPI
- THEN the request is rejected with error `invalid_amount`
- AND no expense is persisted

### Requirement: Display formatting convention

Every client MUST render monetary values with the single fixed convention `Bs. X,XXX.XX` (comma thousands separator, exactly two decimal places) using a shared, unit-tested cents formatter that performs no floating-point operations (integer division/modulo only). The balances view MUST render the sign explicitly as `+Bs. X,XXX.XX` or `-Bs. X,XXX.XX`; the neutral zero balance MUST render as `Bs. 0.00`.

#### Scenario: Formatting values

- GIVEN a server-derived value of `160000` cents
- WHEN the client formatter renders it
- THEN the output is `Bs. 1,600.00`

- GIVEN a balance of `-16000` cents
- WHEN the balances view renders it
- THEN the output is `-Bs. 160.00`

- GIVEN a balance of `0` cents
- WHEN the balances view renders it
- THEN the output is `Bs. 0.00` with no sign

#### Scenario: Formatter avoids floating point

- GIVEN the web and mobile cents formatters
- WHEN they are unit-tested with values including `0`, `5`, `99`, `1000`, `1234567`, and negatives
- THEN every output has exactly two decimals and correct thousands separators
- AND the formatter source performs integer division/modulo only

## Non-goals

- No currency configuration, conversion, exchange rates, or configurable symbols; `Bs.` and the fixed convention are the only display mode.
- No floating-point money representation anywhere.
