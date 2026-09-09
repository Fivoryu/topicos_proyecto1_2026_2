# Delta for API

## MODIFIED Requirements

### Requirement: REST endpoint surface

The system MUST expose the existing protected group-scoped expense, balance, and settlement endpoints with currency-aware request and response contracts. Expense writes MUST accept and validate supported source currency, source amount, contributors, and optional explicit rate according to the expense specification. Expense reads MUST expose original-money and frozen-rate provenance. Balance and settlement endpoints MUST return server-derived integer USD cents with unambiguous USD semantics. All conversions, splits, balances, and settlement calculations MUST remain server-side.

(Previously: REST monetary fields represented a single currency and did not expose source currency or frozen-rate context.)

#### Scenario: Full protected CRUD surface responds

- GIVEN an authenticated owner or member session for the seeded group
- WHEN participant, rename, expense, balance, settlement, and group-setting endpoints are exercised
- THEN each responds with the documented currency-aware schema
- AND every monetary field is an integer with explicit source or USD semantics

#### Scenario: Rename is name-only

- GIVEN an authenticated session
- WHEN a participant rename request is sent
- THEN the request contains exactly the new name and no other participant field
- AND the response returns the renamed participant with the same ID

#### Scenario: Mixed-currency REST contract

- GIVEN an authenticated group containing USD, BOB, and EUR expenses
- WHEN expenses, balances, and settlement are read
- THEN expense responses preserve source amount/currency and frozen rate metadata
- AND every balance and transfer is an integer USD-cent value
- AND no client calculation is required to reconcile the responses

#### Scenario: Explicit rate is accepted only by the authoritative API

- GIVEN an authenticated edit request containing a valid explicit EUR-to-USD Decimal rate
- WHEN the expense endpoint processes it
- THEN FastAPI validates and freezes the rate and provenance
- AND the resulting REST response is authoritative for all derived USD values

### Requirement: Structured error contract

The system MUST reject invalid multi-currency cases with the existing structured error envelope containing stable `error_code` and human-readable message, with no partial mutation. The contract MUST include `unsupported_currency`, `invalid_rate`, `rate_unavailable`, and `conversion_failed` for unsupported codes, non-positive or malformed rates, unavailable provider/fallback rates, and conversion failures respectively. These validation failures MUST use HTTP 422 unless an existing resource/authorization status applies.

(Previously: The structured error list covered single-currency amount and participant failures only.)

#### Scenario: AO-06 — every invalid case is explicit

- GIVEN each baseline invalid case plus invalid currency, rate, unavailable-rate, invalid credentials, missing/expired session, role denial, and invalid rename input
- WHEN the corresponding request is sent
- THEN the response carries the matching `error_code` and an understandable message
- AND no state changed

#### Scenario: Auth failures use 401 and never leak group data

- GIVEN a request with invalid credentials or an absent/invalid session
- WHEN the request is sent
- THEN the response is HTTP 401 with the matching auth `error_code`
- AND the response body contains no group data

#### Scenario: Unsupported code has a stable error

- GIVEN an expense request with currency `GBP`
- WHEN the request is sent
- THEN it returns HTTP 422 with `unsupported_currency` and a clear supported-code message
- AND no state changes

#### Scenario: No fallback has a stable error

- GIVEN a non-USD expense with provider outage and no stored valid rate
- WHEN the request is sent
- THEN it returns HTTP 422 with `rate_unavailable`
- AND no expense or child rows are persisted

#### Scenario: Invalid rate has a stable error

- GIVEN an explicit zero, negative, malformed, or non-finite rate
- WHEN an expense write is sent
- THEN it returns HTTP 422 with `invalid_rate`
- AND the existing record remains unchanged on edit

## ADDED Requirements

### Requirement: OpenAPI authority and generated consumers

The handwritten FastAPI schemas and routes MUST define the currency, rate, provenance, USD balance, and structured-error contract. The OpenAPI export MUST describe supported codes, rate direction, frozen/reference semantics, fallback provenance, and USD reporting. TypeScript and Dart clients MUST be regenerated from that contract through the repository workflow; generated files MUST NOT be hand-edited. `mobile-domain-features` owns mobile implementation and acceptance, while this change owns only the shared contract requirements and coordination boundary.

#### Scenario: Contract drift is prevented

- GIVEN the handwritten multi-currency API contract
- WHEN OpenAPI is exported, both clients are regenerated, and drift checks run
- THEN generated consumers match the REST contract
- AND no generated file was manually edited

#### Scenario: Provider semantics are documented

- GIVEN the exported OpenAPI contract
- WHEN an expense operation is inspected
- THEN the contract identifies USD, BOB, and EUR as the complete supported set
- AND identifies rates as source-to-USD frozen reference values
- AND represents provider quote, stored fallback, manual, and legacy provenance distinctly

### Requirement: Server authority and invalidation-only WebSocket preservation

FastAPI and PostgreSQL MUST remain the authority for source money, Decimal conversion, USD-cent rounding, CC-01 splitting, balances, settlement, rate acquisition, and persistence. The WebSocket MUST remain unchanged as an invalidation-only channel: after a successful expense mutation it MUST publish exactly the existing group-scoped `{"type":"data_changed"}` signal after commit, and MUST NOT carry currency, rates, balances, transfers, or other monetary payloads. Clients MUST refetch REST data.

#### Scenario: Expense mutation invalidates without monetary payload

- GIVEN a valid session connected to a group's WebSocket
- WHEN a mixed-currency expense create or edit commits
- THEN exactly one post-commit `data_changed` invalidation is published for that group
- AND the frame contains no currency, rate, amount, balance, or settlement data
- AND clients refetch authoritative REST resources

#### Scenario: Failed rate acquisition publishes nothing

- GIVEN a connected client and an expense write that fails because no provider quote or fallback exists
- WHEN the transaction is rejected
- THEN no WebSocket invalidation is published
- AND the REST error and database rollback remain authoritative

### Requirement: Ownership boundaries for protected changes

This change MUST integrate with `group-outing-workspaces` through its existing group and nullable outing contract without modifying its protected artifacts. It MUST NOT modify `web-professional-redesign` files. Mobile presentation and mobile-owned implementation files remain under `mobile-domain-features`; shared API sequencing MAY be coordinated, but ownership MUST NOT be transferred by this change.

#### Scenario: Protected ownership is preserved

- GIVEN implementation work for a currency-aware expense with an outing scope and web/mobile consumers
- WHEN the change is delivered
- THEN only the multi-currency-owned contract and implementation surfaces are changed
- AND group/outing, redesign, and mobile-owned protected files remain untouched
