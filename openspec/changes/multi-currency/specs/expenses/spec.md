# Delta for Expenses

## MODIFIED Requirements

### Requirement: Expense creation validation

The system MUST create an expense only when the description is non-empty; the amount is positive and valid to two source-currency decimal places; the currency is exactly `USD`, `BOB`, or `EUR`; there is at least one contributor and beneficiary; every reference belongs to the group; and contributor integer cents sum exactly to the expense total in the selected source currency. For USD, the identity rate is used. For BOB and EUR, a valid frozen source-to-USD rate MUST be acquired or selected according to the rate policy before commit. Any violation, unavailable rate without fallback, or conversion failure MUST reject atomically with a structured error and MUST persist no partial data.

(Previously: Expense validation assumed one currency and did not require rate acquisition or conversion.)

#### Scenario: CB-01 — no participants

- GIVEN a group with zero participants
- WHEN an expense creation is attempted
- THEN the request is rejected with error `no_participants`
- AND no source expense or derived result is persisted

#### Scenario: CB-06 — no beneficiaries

- GIVEN an expense form with a valid source amount and contributor but zero selected beneficiaries
- WHEN creation is attempted
- THEN the request is rejected with error `no_beneficiaries`

#### Scenario: CB-07 — invalid reference

- GIVEN an expense form referencing a participant id that does not exist in the group
- WHEN creation is attempted
- THEN the request is rejected with error `invalid_participant_reference`

#### Scenario: AO-03 — contribution mismatch

- GIVEN an expense of `10000` source cents with contributions Ana `6000` and Beto `3000`
- WHEN creation is attempted
- THEN the request is rejected with error `contribution_mismatch`
- AND no expense or contribution row is persisted

#### Scenario: Mixed-currency expense succeeds

- GIVEN a group with Ana, Beto, Carla, and a valid Frankfurter EUR-to-USD quote
- WHEN a EUR expense with total `10000` EUR cents, Ana contributing `6000`, and Beto `4000` is created
- THEN the source expense and contributions are stored in EUR cents
- AND its frozen rate metadata is stored
- AND its derived USD total is available for balances and settlement

#### Scenario: Unsupported currency is rejected atomically

- GIVEN an expense request with currency `JPY`
- WHEN creation is attempted
- THEN it is rejected with structured error `unsupported_currency`
- AND no expense, contribution, rate, or derived result is persisted

#### Scenario: No rate and no fallback is rejected atomically

- GIVEN a BOB expense and no Frankfurter quote or stored valid BOB rate
- WHEN creation is attempted
- THEN it is rejected with structured error `rate_unavailable`
- AND no expense or child row is persisted

### Requirement: Multiple contributors

The system MUST support one or more contributors per expense, each with a positive integer-cent amount in the expense's original currency, and MUST require their sum to equal the original source expense total exactly. Contributor values MUST NOT be converted independently to determine the expense USD total.

(Previously: Contributions were integer cents in the application's only currency.)

#### Scenario: Valid multi-contributor expense

- GIVEN an expense of `10000` source cents with Ana `6000` and Beto `4000` as contributors
- WHEN creation is attempted
- THEN it succeeds
- AND the expense is persisted with both contributions summing to `10000` source cents

#### Scenario: Source contribution invariant with USD derivation

- GIVEN a `10000` BOB-cent expense with Ana `6000` and Beto `4000`
- WHEN the expense is saved with a valid BOB-to-USD rate
- THEN the source contributions sum to `10000` BOB cents
- AND the complete `10000` BOB-cent total is converted once to USD cents

### Requirement: Edit expense with atomic recalculation

The system MUST allow editing an expense's description, source amount, contributors, beneficiaries, currency, and rate. A successful edit MUST save the rate and provenance associated with that version and recompute all affected USD-derived balances and settlement server-side. An explicit positive rate edit MUST be retained with manual provenance for that saved record; an omitted rate MUST follow Frankfurter-then-latest-valid-stored-fallback acquisition. An invalid currency, rate, conversion, or source contribution change MUST leave the prior expense, metadata, balances, and settlement unchanged.

(Previously: Edits could change source fields but had no currency or frozen-rate semantics.)

#### Scenario: CB-10 — changing the payer recalculates everything

- GIVEN an expense of `30000` source cents originally paid by Ana with Ana, Beto, and Carla as beneficiaries
- WHEN the edit changes the payer to Beto with the same beneficiaries
- THEN balances show Beto's positive effect and Ana neutral for this expense
- AND balances and settlement reflect the edit immediately in USD

#### Scenario: AO-05 — invalid edit leaves state unchanged

- GIVEN an existing valid expense
- WHEN an edit sets the source amount to `0`
- THEN the edit is rejected with error `invalid_amount`
- AND the expense, balances, and settlement are unchanged

#### Scenario: Edit currency and rate

- GIVEN an existing USD expense and a valid explicit EUR-to-USD rate
- WHEN the expense is edited to EUR with a new EUR amount and that rate
- THEN the saved expense preserves the EUR source amount
- AND its rate provenance is `manual`
- AND balances and settlement reflect the new server-derived USD result

#### Scenario: Provider outage uses latest valid stored rate

- GIVEN an edited BOB expense, an unavailable Frankfurter request, and a latest valid stored BOB rate
- WHEN the edit omits an explicit rate
- THEN the edit succeeds using that stored rate
- AND the saved record identifies fallback provenance and its frozen timestamp

#### Scenario: Invalid edit leaves state unchanged

- GIVEN an existing valid expense
- WHEN an edit supplies an unsupported code, non-positive rate, or no available rate
- THEN the edit returns the corresponding structured error
- AND the previous source values, rate metadata, balances, and settlement remain unchanged

### Requirement: Expense listing

The system MUST list each expense with its original integer amount, ISO currency, source-currency contributors, frozen source-to-USD rate, frozen timestamp, and explicit provenance, while exposing server-derived USD values where required by the REST contract. Listing MUST continue to include archived participant references and preserve outing scope.

(Previously: Listing exposed a single `amount_cents` unit without currency or rate audit metadata.)

#### Scenario: History includes archived references

- GIVEN an expense referencing an archived participant
- WHEN the expense list is read
- THEN the expense appears with the archived participant's name and archived status visible

#### Scenario: Renamed participant history

- GIVEN an expense whose contributor or beneficiary was renamed after it was recorded
- WHEN the expense list is read
- THEN the expense resolves the same participant ID and displays the current name with archived status
- AND the recorded source contribution amounts and USD-derived split shares are unchanged

#### Scenario: History preserves original money and rate context

- GIVEN a EUR expense recorded using a Frankfurter quote and a BOB expense using a stored fallback
- WHEN expense history is read
- THEN each row retains its original currency and amount
- AND each row exposes the rate timestamp and provenance used for that saved version

## ADDED Requirements

### Requirement: Frankfurter acquisition and fallback

For BOB and EUR, the server MUST use the official public Frankfurter endpoint `https://api.frankfurter.dev/v2/rate/{source}/USD` without an API key. A valid provider quote MUST be normalized to a positive Decimal source-to-USD rate and frozen with acquisition timestamp and provider provenance. If the provider is unavailable or has no quote, the server MUST select the latest stored valid rate for that source currency. If no valid stored rate exists, the operation MUST fail atomically and MUST NOT guess.

#### Scenario: Frankfurter quote is frozen

- GIVEN a BOB expense and a successful response from `/v2/rate/BOB/USD`
- WHEN the expense is created
- THEN the request uses the endpoint without an API key
- AND the saved record contains the normalized positive Decimal rate, timestamp, provider `frankfurter`, and current-quote provenance
- AND later provider changes do not alter that saved record

#### Scenario: Provider has no quote but fallback exists

- GIVEN a EUR expense, a missing Frankfurter quote, and a latest valid stored EUR rate
- WHEN creation is attempted
- THEN the latest valid stored rate is used
- AND the saved record identifies stored-fallback provenance

### Requirement: Editable frozen-rate audit

Every saved expense version MUST retain the source currency, source amount, rate, rate timestamp, and provenance actually used for that version. Manual rate edits MUST be scoped to the saved expense version and MUST NOT silently become provider-cache truth. USD records MUST use exact identity rate `1` with explicit USD provenance.

#### Scenario: Manual rate is auditable

- GIVEN a user edits a EUR expense with an explicit positive rate
- WHEN the edit commits
- THEN the response identifies the rate as manual with its saved timestamp
- AND the expense's source amount and resulting USD amount are reproducible from that frozen context

### Requirement: Legacy expense migration

A migration MUST convert every legacy expense row lacking currency/rate metadata into a USD record without changing its original integer amount, contributor rows, beneficiary rows, group, outing scope, or participant relationships. It MUST use exact identity rate `1`, a migration timestamp, and explicit `legacy_migration` provenance rather than fabricating a historical market quote. The migration MUST be safe to rerun and compatible with idempotent fail-closed demo seeding.

#### Scenario: Legacy row becomes USD without reinterpretation

- GIVEN a legacy expense with `amount_cents = 80000` and its existing child rows
- WHEN the migration runs
- THEN the row is represented as `80000` USD cents with identity rate `1`
- AND all relationships and original integer values are unchanged
- AND provenance states `legacy_migration`, not Frankfurter

#### Scenario: Migration is repeatable

- GIVEN a database already backfilled with legacy USD metadata
- WHEN the migration or verification is run again
- THEN no amount, timestamp provenance, or child relationship is duplicated or changed

### Requirement: Outing ownership boundary

Currency metadata, conversion, and source-money behavior MUST integrate with the nullable outing scope owned by `group-outing-workspaces`; this change MUST NOT modify that active change's protected files or redefine outing authorization, archival, or derivation rules. Group and outing derivations MUST include each expense exactly once according to the owning group/outing contract.

#### Scenario: Currency does not change outing scope

- GIVEN a valid EUR expense linked to an active outing
- WHEN group and outing balances are read
- THEN the expense is converted and included exactly once in each applicable server-derived USD result
- AND general/outing inclusion rules remain those of `group-outing-workspaces`
