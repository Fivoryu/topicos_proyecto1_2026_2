# Delta for Money

## MODIFIED Requirements

### Requirement: Integer-cents representation

The system MUST represent source monetary amounts and all derived USD monetary amounts as integer cents at their respective boundaries. Source expense and contribution amounts MUST remain integer cents in the selected source currency; balances, settlement transfers, and converted totals MUST be integer USD cents. API monetary fields MUST be integers and MUST NOT be floating-point numbers. Rates and conversion intermediates MUST use exact Decimal arithmetic; no component MAY use binary floating-point arithmetic for amounts, rates, conversion, or rounding.

(Previously: Every monetary value was a single-currency integer-cent value, with no conversion or rate representation.)

#### Scenario: Wire values are integers

- GIVEN an expense of Bs. 100.00 created through the API
- WHEN the client reads the expense payload
- THEN the payload contains the source amount as integer `10000` cents
- AND no monetary field is transmitted as a floating-point number

#### Scenario: Source and reporting units are explicit

- GIVEN a BOB expense of `10000` source cents converted to `720` USD cents
- WHEN the expense and balances are read
- THEN the expense preserves `10000` in BOB
- AND the derived balance/settlement value is integer `720` USD cents
- AND neither API value is a floating-point number

#### Scenario: Decimal conversion does not introduce binary drift

- GIVEN a non-terminating or high-precision source-to-USD Decimal rate
- WHEN the server converts the complete source amount
- THEN conversion and rounding use Decimal arithmetic and the documented deterministic cent rule
- AND no binary floating-point intermediate is used

### Requirement: Boundary parsing and validation

FastAPI MUST parse and validate source monetary inputs at the API boundary, converting accepted lexical amounts to integer source cents. Expense amounts and contributions MUST accept at most two decimal places, reject zero and negative values, and reject excess precision with an explicit error rather than silently rounding. Conversion MUST produce integer USD cents only after the source amount has passed source-currency validation.

(Previously: Boundary parsing converted all monetary input directly into the sole integer-cent unit.)

#### Scenario: Two-decimal input is accepted

- GIVEN an expense form submitting `100.00` in a selected source currency
- WHEN the request reaches FastAPI
- THEN it is accepted as integer source cents `10000`
- AND the server derives USD cents separately

#### Scenario: Source amount precision is preserved

- GIVEN a EUR expense submitting `100.00`
- WHEN the request reaches FastAPI
- THEN it is accepted as `10000` EUR cents
- AND the server derives USD cents separately

#### Scenario: More than two decimal places is rejected

- GIVEN an expense form for a selected source currency submitting `100.001`
- WHEN the request reaches FastAPI
- THEN the request is rejected with error `invalid_amount` and an explicit message requesting a maximum of two decimal places
- AND no source, rate, conversion, or derived rows are persisted

#### Scenario: Zero and negative amounts are rejected

- GIVEN an expense form submitting `0` or `-50.00`
- WHEN the request reaches FastAPI
- THEN the request is rejected with `invalid_amount`
- AND no source expense or derived result is persisted

## ADDED Requirements

### Requirement: Deterministic source-to-USD conversion

The server MUST normalize every non-USD rate as a positive source-currency-to-USD Decimal and MUST convert the complete source expense total to integer USD cents by multiplying source cents by the rate and quantizing to one USD cent with Decimal `ROUND_HALF_UP`. The policy MUST apply equally to positive and negative derived values and MUST preserve the group exact-zero invariant.

#### Scenario: USD identity conversion

- GIVEN a USD expense of `1250` USD cents
- WHEN it is converted for reporting
- THEN its USD total is exactly `1250` cents using identity rate `1`

#### Scenario: Half-cent conversion is deterministic

- GIVEN a source total whose Decimal conversion lies exactly on the chosen half-cent boundary
- WHEN the server converts it
- THEN the documented rounding policy selects the same integer USD cent on every execution
- AND the result is not dependent on machine locale or floating-point behavior

#### Scenario: Negative derived balances close exactly

- GIVEN converted payer and beneficiary effects that produce both positive and negative balances
- WHEN group balances and settlement are derived
- THEN all values are integer USD cents
- AND the sum of all balances is exactly zero
- AND settlement transfers reconcile to zero exactly

### Requirement: Total-first conversion and CC-01 residuals

The server MUST convert the complete expense total to USD cents before applying CC-01 equal splitting. It MUST NOT independently convert beneficiary shares and then infer or repair the expense total. CC-01 residual cents MUST be allocated by the existing deterministic residual rule in USD cents.

#### Scenario: Residual is selected after conversion

- GIVEN a `100` BOB-cent expense with three beneficiaries and a rate producing `7` USD cents after total conversion
- WHEN the server applies CC-01
- THEN the three USD shares sum to exactly `7` cents
- AND the one-cent residual is assigned by the existing CC-01 deterministic rule
- AND source contributor amounts remain in BOB

#### Scenario: Contributor source total remains exact

- GIVEN a EUR expense with contributors of `6000` and `4000` EUR cents
- WHEN the expense is converted and split
- THEN contributor amounts still sum to `10000` EUR cents
- AND the converted expense total is calculated once from `10000`, not from separately converted contributor shares

### Requirement: Currency-aware display formatting

Clients MUST render source expense amounts with their ISO currency and MUST render balances and settlement transfers as USD. Formatters MUST operate from integer cents without floating-point arithmetic and MUST make the reporting currency unambiguous. The stored rate MUST be presented as a frozen daily/reference accounting value, not as live trading data.

#### Scenario: Formatting values

- GIVEN a server-derived value of `160000` USD cents
- WHEN the client formatter renders it
- THEN the output is `$1,600.00` or an equivalent explicit USD rendering

- GIVEN a balance of `-16000` USD cents
- WHEN the balances view renders it
- THEN the output is an explicitly negative USD amount

- GIVEN a balance of `0` USD cents
- WHEN the balances view renders it
- THEN the output is an unsigned USD zero amount

#### Scenario: Formatter avoids floating point

- GIVEN the web and mobile cents formatters
- WHEN they are unit-tested with values including `0`, `5`, `99`, `1000`, `1234567`, and negatives
- THEN every output has exactly two decimals and correct separators
- AND the formatter source performs integer division/modulo only

#### Scenario: Mixed-currency display

- GIVEN history containing USD, BOB, and EUR expenses
- WHEN the client renders history, balances, and settlement
- THEN each expense shows its original amount and ISO currency
- AND every balance and transfer is labeled/rendered as USD
- AND the rate timestamp and provenance are available for audit context

#### Scenario: Frozen reference disclaimer

- GIVEN a Frankfurter-derived rate stored on an expense
- WHEN the expense details are shown
- THEN the UI/API identifies it as a frozen daily/reference rate
- AND it does not present it as live trading pricing
