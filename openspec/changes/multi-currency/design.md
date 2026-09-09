# Design: multi-currency expenses

## 1. Design authority and boundaries

This design implements the validated `multi-currency` proposal and its deltas for money, expenses, API, and clients. It is a plan only; this phase changes no product code, tests, generated client, fixture, or other OpenSpec change.

The existing authority boundaries remain:

- FastAPI/application services own parsing, authorization, rate selection, conversion, splitting, balances, settlement, and structured errors.
- PostgreSQL/Alembic own durable source money, rate audit data, cache history, and referential integrity.
- React/Vite/TanStack Query displays server results and sends lexical input; it never converts or allocates money.
- Flutter remains independently governed by `mobile-domain-features`. This design defines the shared contract and coordination handoff only.
- WebSocket behavior is unchanged: one post-commit group-scoped `{"type":"data_changed"}` invalidation and no monetary payload.

The implementation must not directly edit:

- `group-outing-workspaces` artifacts or protected implementation files;
- `web-professional-redesign` files;
- `final-delivery-alignment` artifacts, official fixture data, or walkthrough content;
- `web/src/generated/api/`, `mobile/lib/generated/api/`, or `contracts/openapi.json` by hand;
- mobile-owned implementation files.

Generated outputs are downstream results of the normal contract workflow, not implementation surfaces for this change.

## 2. Target architecture and owned seams

The implementation follows the current synchronous application/service shape behind FastAPI:

```text
FastAPI route/schema
  -> lexical source-money and rate parsing
  -> ExpenseService + RateSelectionService
       -> ExchangeRateProvider (Frankfurter adapter)
       -> UnitOfWork
            -> ExpenseRepository / RateCacheRepository
            -> PostgreSQL source rows
  -> DerivedService
       -> total-first conversion
       -> USD paid allocation + CC-01 USD split
       -> BalanceService -> SettlementService
  -> commit
  -> InvalidationPublisher(data_changed)
```

Proposed owned modules and changes are additive at these seams:

- `backend/app/domain/money.py`: currency value object, source money, rate validation, Decimal conversion, and integer-cent formatting helpers used by the server.
- `backend/app/domain/conversion_service.py`: total-first conversion and deterministic contributor paid allocation.
- `backend/app/domain/errors.py`: stable rate/currency/conversion error codes.
- `backend/app/application/ports.py`: currency/rate fields on `ExpenseRecord`, rate-cache and provider protocols, and any optional outing filter already defined by the workspace contract.
- `backend/app/application/rate_service.py`: provider-first/fallback/manual/identity policy and provenance selection.
- `backend/app/application/expense_service.py`: complete candidate validation before mutation, rate resolution outside the transaction, group lock, source persistence, derived invariant check, and post-commit publication.
- `backend/app/application/derived_service.py` and domain balance/split services: source-money-aware USD derivation.
- `backend/app/adapters/rates/frankfurter.py`: timeout-bounded public HTTP adapter with Decimal JSON parsing.
- `backend/app/adapters/db/tables.py`, `repositories.py`, and `uow.py`: additive expense metadata, rate-cache persistence, and transaction access.
- `backend/app/api/schemas/{expenses,balances,settlement}.py` and routes: handwritten authoritative contract.
- `backend/migrations/versions/`: one additive migration based on the actual Alembic head at implementation time.
- Existing non-protected web feature/formatter modules: source-currency input/history and explicit USD display.

The exact filenames may be adjusted to match the repository's current dependency graph, but the provider must not be imported by domain code and clients must not receive provider credentials or perform rate lookup.

## 3. Domain value objects and invariants

### 3.1 Currency

Define a closed `CurrencyCode` enum/value object with exactly:

- `USD`
- `BOB`
- `EUR`

Parsing is case-sensitive at the API boundary. Symbols, locale names, and inferred currencies are rejected. The value object exposes whether the currency is reporting currency (`USD`) but does not perform formatting or conversion.

### 3.2 Source money

Use a `SourceMoney` value object:

```text
SourceMoney {
  cents: int          # positive for persisted expense/contribution input
  currency: CurrencyCode
}
```

`cents` must be an integer, never `bool`, and must be positive for expense totals and contributor rows. Existing `parse_amount_text` remains the lexical boundary: ASCII decimal text, zero to two fractional digits, no sign, grouping, exponent, implicit rounding, or binary conversion.

The existing database `expenses.amount_cents` and `expense_contributions.amount_cents` columns remain source-currency cents. The application record may expose a clearer `source_money`/`source_amount_cents` view, but the adapter maps the existing column without changing historical integers. Contributors have the same currency as their parent expense; no currency column is duplicated on each child row.

### 3.3 USD money

Use an integer `UsdCents` boundary for every derived amount:

```text
UsdCents = int
```

This includes converted expense totals, paid allocations, owed shares, `paid_usd_cents`, `owed_usd_cents`, `balance_usd_cents`, and settlement transfer amounts. A derived value may be negative only as a balance/effect after subtraction; persisted expense and contribution source values remain positive.

### 3.4 Exchange rate

Use an `ExchangeRate` value object backed by Python `Decimal` only:

```text
ExchangeRate {
  source: CurrencyCode       # BOB or EUR for provider/manual rates
  quote: USD
  value: Decimal              # USD per one source-currency unit
}
```

Rules:

- `USD -> USD` is exactly `Decimal("1")`; any other USD rate is invalid.
- BOB/EUR rates must be finite, strictly positive, and have no more than 18 fractional digits after normalization.
- Accepted manual wire rates are decimal strings, not JSON numbers; no exponent, NaN, infinity, or locale separator is accepted.
- Provider JSON is parsed with `json.loads(..., parse_float=Decimal, parse_int=Decimal)`, never through a Python `float`.
- Use a local Decimal context with sufficient precision (at least 50 digits) for multiplication, ratio allocation, and quantization. Database `NUMERIC(30,18)` stores the normalized value exactly within the accepted scale.
- Serialize the rate as a string in REST/OpenAPI so generated clients cannot silently deserialize it as a binary floating-point number.

## 4. Deterministic conversion and residual rules

### 4.1 Total-first conversion

For a complete source total `S` in source cents and rate `R` in USD per source unit:

```text
raw_usd_cents = Decimal(S) * R
usd_total_cents = raw_usd_cents.quantize(Decimal("1"), rounding=ROUND_HALF_UP)
```

The factor of 100 cancels because `S` is already cents and `R` is quoted per whole source unit. For USD, the identity rate returns exactly `S`. Conversion is performed once for the complete expense total before any beneficiary split. The helper accepts signed intermediate values as well, uses the same `ROUND_HALF_UP` rule, and never uses `round()`, float arithmetic, or locale-dependent behavior.

Examples:

- `1250 USD cents * 1 = 1250 USD cents`.
- `100 BOB cents * 0.072 = 7.2`, therefore `7 USD cents`.
- `10000 EUR cents * 1.08765 = 10876.5`, therefore `10877 USD cents`.
- `-100 BOB cents * 0.072 = -7.2`, therefore `-7 USD cents`; negative balance subtraction is still integer-only.

A non-finite, non-quantizable, overflowed, or scale-invalid conversion raises `conversion_failed` before persistence.

### 4.2 Contributor paid allocation

Source contributor amounts remain the audit record and must sum exactly to the source total. They must not be independently converted to decide the expense USD total. To derive payer effects while preserving the exact converted total, allocate the already-converted `usd_total_cents` proportionally with a largest-remainder integer algorithm:

1. For each contributor in stable group creation order, compute the exact Decimal quota `usd_total_cents * contributor_source_cents / source_total_cents`.
2. Assign the floor of each non-negative quota.
3. Compute the integer residual `usd_total_cents - sum(floors)`.
4. Give each residual cent to contributors in descending fractional-remainder order, breaking ties by stable group order.

This allocates the one converted total, rather than converting contributor totals independently. It guarantees that paid allocations sum exactly to the converted expense total. The algorithm is covered for one contributor, multiple contributors, a zero residual, and ties. It does not change the source contributor rows.

### 4.3 CC-01 after conversion

After `usd_total_cents` is known, call the existing deterministic equal-split rule with USD cents:

- base share is integer division by beneficiary count;
- the complete residual is assigned to the first stable participant in `contributors ∩ beneficiaries`;
- if that intersection is empty, it goes to the first selected beneficiary in stable group order;
- non-beneficiaries receive zero;
- all USD owed shares sum exactly to `usd_total_cents`.

Example: `100 BOB cents`, rate `0.072`, three beneficiaries gives `7 USD cents`; shares are `3, 2, 2` when the first stable contributor who is also a beneficiary is the first beneficiary. The residual is allocated in USD, not BOB.

For `10000 EUR cents`, contributors `6000` and `4000`, and rate `1.08765`, the source total converts once to `10877 USD cents`. Paid allocation is `6526/4351` by largest remainder. With three beneficiaries, CC-01 produces `3627/3625/3625` when the first selected participant is the residual recipient.

### 4.4 Balance and settlement invariant

For every group or outing scope:

```text
paid_usd_cents[p] = sum(contributor paid allocations for p)
owed_usd_cents[p] = sum(CC-01 USD shares for p)
balance_usd_cents[p] = paid_usd_cents[p] - owed_usd_cents[p]
```

The derived service must assert that the sum of balances is exactly zero. Settlement consumes only these integer USD balances and retains the existing deterministic greedy ordering. It must assert that transfers reconcile all residuals exactly. A failure is `persistence_corrupted`/`conversion_failed` as appropriate and never produces a partial mutation.

## 5. Rate acquisition, fallback, provenance, and timestamps

### 5.1 Provider port and Frankfurter adapter

Define an `ExchangeRateProvider` port returning a validated provider quote or a typed unavailable result. The Frankfurter adapter is the only implementation in this change:

```text
GET https://api.frankfurter.dev/v2/rate/{SOURCE}/USD
```

The URL is constructed only from the closed currency enum; no user-provided URL or API key is accepted. Use a bounded synchronous standard-library HTTP client (or the repository's approved HTTP dependency) with a configurable default timeout of 3 seconds. The adapter must:

- accept only HTTP success responses;
- treat timeout, DNS/connection failure, 404, 429, and 5xx as unavailable and eligible for fallback;
- parse JSON with Decimal hooks;
- require an object with a `rate`, and validate `base/source == SOURCE` and `quote == USD` when those fields are present;
- reject missing, zero, negative, non-finite, non-Decimal, excessive-scale, or directionally incorrect rates;
- validate the provider date when present and normalize it to UTC;
- discard the body after parsing and never log it as a request payload;
- return provider name `frankfurter`, observed date/timestamp, fetch timestamp, and the normalized Decimal rate.

Malformed successful responses are not silently treated as a valid quote. They produce `conversion_failed` (or an internal provider-validation event mapped to that stable error), while transport/no-quote cases produce `rate_unavailable` if no fallback exists.

### 5.2 Selection policy

`RateSelectionService` is called before a source mutation is committed:

1. `USD`: choose identity rate `1`, provenance `usd_identity`, provider `system`.
2. Explicit non-USD `usd_rate`: validate and choose it with provenance `manual`; never insert it into provider cache.
3. Omitted non-USD rate: call Frankfurter outside the database transaction.
4. Valid current quote: use it with provenance `frankfurter_current` and persist it in the cache in the same transaction as the expense.
5. Provider unavailable or no quote: in the transaction, select the latest valid stored quote for that source currency, ordered by provider observation timestamp then cache insertion timestamp. Use provenance `stored_fallback` and retain the original observed timestamp.
6. No valid cached quote: raise `rate_unavailable`; the transaction has no expense or child mutation to roll back.

A stored fallback is allowed regardless of age because the confirmed policy is latest-valid fallback. Its age is returned and observed in operations. Staleness is an alerting/UX concern, not a hidden alternate conversion rule.

### 5.3 Persisted provenance

Every expense version stores the context actually used:

- `source_currency`;
- source `amount_cents` (existing column) and source contributor cents;
- normalized `usd_rate`;
- `rate_provider` (`system`, `frankfurter`, `manual`, or `legacy`);
- `rate_provenance` (`usd_identity`, `frankfurter_current`, `stored_fallback`, `manual`, or `legacy_migration`);
- `rate_observed_at` — provider reference date/time, cached quote observation time, or explicit saved timestamp for identity/manual/migration;
- `rate_frozen_at` — the UTC instant this expense version committed with that rate;
- optional `rate_cache_id` for provider/fallback traceability, never a client authority.

A fallback therefore exposes both the age of the selected source quote (`rate_observed_at`) and the time this expense froze it (`rate_frozen_at`). Editing an expense replaces these fields atomically for the new saved version; the current row always reproduces its current USD result. Historical version storage is not added in this change, but the current saved version is auditable.

The cache is an append-only `exchange_rate_cache` source table for valid provider observations:

```text
id UUID primary key
source_currency CHAR(3)            # BOB or EUR
quote_currency CHAR(3)             # USD
rate NUMERIC(30,18)
provider VARCHAR(32)                # frankfurter
observed_at TIMESTAMPTZ
fetched_at TIMESTAMPTZ
valid BOOLEAN NOT NULL
```

Add an index on `(source_currency, quote_currency, valid, observed_at DESC, fetched_at DESC)`. Manual and legacy identity values are not cache rows. Invalid provider responses are observable events, not durable fallback candidates.

## 6. Persistence and legacy migration

### 6.1 Additive schema

Use one new Alembic revision at the then-current repository head. It must not assume or rewrite a revision owned by `group-outing-workspaces`. Add to `expenses`:

- `source_currency CHAR(3)`;
- `usd_rate NUMERIC(30,18)`;
- `rate_provider VARCHAR(32)`;
- `rate_provenance VARCHAR(32)`;
- `rate_observed_at TIMESTAMPTZ`;
- `rate_frozen_at TIMESTAMPTZ`;
- optional `rate_cache_id UUID` if the final foreign-key ordering permits it.

Add checks for supported currencies, positive rate, quote direction represented by the column contract, and the allowed provenance/provider combinations. Keep `amount_cents` and child `amount_cents` as source cents. Do not persist `usd_amount_cents` as a second source of truth; it is derived from the frozen metadata.

Add the `exchange_rate_cache` table described above with source/quote checks and indexes. A cache row is valid only when its rate is positive and provider is Frankfurter.

### 6.2 Safe legacy backfill

The migration is expand/backfill/contract within one Alembic transaction where the PostgreSQL deployment permits it:

1. Add new columns nullable or with temporary defaults.
2. Capture one UTC migration timestamp for the revision execution.
3. For every legacy expense lacking metadata, set:
   - `source_currency = 'USD'`;
   - `usd_rate = 1`;
   - `rate_provider = 'legacy'`;
   - `rate_provenance = 'legacy_migration'`;
   - `rate_observed_at = migration_timestamp`;
   - `rate_frozen_at = migration_timestamp`.
4. Leave `amount_cents`, all contribution rows, beneficiaries, `group_id`, nullable `outing_id`, participant IDs, and timestamps unchanged.
5. Add non-null constraints after the backfill and remove only temporary defaults if they would hide future write bugs.

The update predicate is `source_currency IS NULL` (and equivalent metadata-null guards), so the revision is safe against a pre-existing partial backfill and does not alter already populated rows. The official Samaipata rows remain the same source integer values and remain general USD expenses. No historical Frankfurter quote is fabricated.

The migration test must upgrade a legacy fixture, verify every child and nullable outing relation byte-for-byte at the domain level, run the verification/backfill path again, and prove no duplicate cache or metadata change. Production rollback is forward-compatible; a destructive downgrade is permitted only on disposable databases before non-USD data exists.

## 7. Expense/contributor application flow and transaction boundaries

### 7.1 Create/edit flow

1. FastAPI validates the request envelope and parses source amount/contributor lexical strings once into integer source cents.
2. The route validates the closed currency code and optional lexical `usd_rate`.
3. `ExpenseService` validates description, participant membership, archived-participant rules, contributor positivity/sum, beneficiary presence, and nullable outing scope before mutation.
4. For non-USD with an omitted rate, `RateSelectionService` calls Frankfurter before opening/holding the source mutation transaction. No external request occurs while a PostgreSQL transaction or group lock is held.
5. Enter the UnitOfWork. Lock the group row for the mutation to serialize group source changes and prevent concurrent edit/lost-update races around the derived invariant. On edit, lock the current expense as well.
6. Revalidate the outing through the existing nullable outing contract: `NULL` is a general expense; a non-null ID must belong to the same group and be writable under the owning outing rules. Do not redefine outing authorization here.
7. For a provider quote, insert the cache observation. For fallback, select the latest valid cache row under the transaction. For manual/identity, no provider cache write occurs.
8. Persist the complete expense replacement and source child rows atomically. The replacement carries the selected rate and all provenance timestamps.
9. Flush, derive all affected group/outing balances from source rows, convert totals, allocate paid effects, apply USD CC-01, and assert exact zero. Any failure raises before commit.
10. UnitOfWork commits once. Only after successful commit does the existing publisher emit exactly one group invalidation. The returned REST object is the committed source record plus derived USD total.

Delete follows the same group lock, source-child cascade, flush, derived invariant check, commit, and one post-commit invalidation. A failed rate lookup, validation, derived check, or database operation emits no invalidation.

### 7.2 Repository and port changes

Extend `ExpenseRecord` with currency/rate audit fields while retaining compatibility accessors for `amount_cents` and source contributor cents. Add a `RateCacheRepository` with:

- `insert_provider_observation(...)`;
- `latest_valid(source_currency, quote_currency, *, for_update=False)`;
- `find_by_id(...)`.

Expose it through `UnitOfWork`. The SQLAlchemy adapter maps Decimal values directly to PostgreSQL `NUMERIC`; it must not convert through `float`. The existing composite `(outing_id, group_id)` integrity and optional `outing_filter` from the workspace contract remain unchanged.

## 8. API contract, compatibility, and errors

### 8.1 Canonical expense fields

The handwritten Pydantic schemas are authoritative and use `extra="forbid"` for commands. Canonical new names are explicit:

**Write request**

```text
currency: "USD" | "BOB" | "EUR" | omitted only for legacy compatibility
amount: decimal lexical string
contributors[].participant_id: string
contributors[].amount: decimal lexical source-currency string
usd_rate: decimal lexical string | null   # explicit manual rate, optional
beneficiary_ids: string[]
outing_id: string | null                  # existing nullable workspace field
```

`currency` omitted on create means USD identity for an old client. On edit, omission preserves the current source currency so an old USD-only client cannot reinterpret a non-USD source integer as USD. New clients always send `currency`. A new client omitting `usd_rate` requests the provider-first/fallback policy for non-USD; an explicit rate is manual. USD accepts only identity behavior.

**Expense response**

```text
source_currency: "USD" | "BOB" | "EUR"
source_amount_cents: int
usd_amount_cents: int
usd_rate: string
rate_provider: string
rate_provenance: string
rate_observed_at: ISO-8601 UTC timestamp
rate_frozen_at: ISO-8601 UTC timestamp
rate_cache_id: string | null
contributors[].source_amount_cents: int
outing_id: string | null
```

Contributor response fields use `source_amount_cents`; they are never USD amounts. The response may also expose `amount_cents` as a deprecated source alias during the compatibility window. New clients must not consume the alias.

**Balances and settlement**

Canonical fields are `paid_usd_cents`, `owed_usd_cents`, `balance_usd_cents`, and `amount_usd_cents`. Existing `paid_cents`, `owed_cents`, `balance_cents`, and transfer `amount_cents` may remain as deprecated exact aliases during the transition because all of these results are now USD. Their schema descriptions explicitly say USD cents. No response field named simply `amount_cents` is used as the canonical mixed-currency expense amount.

The compatibility aliases are a migration aid, not permission for old clients to write or display mixed-currency data. The rollout enables non-USD writes only after the updated web contract consumer is deployed. A later cleanup may remove aliases through a separately specified breaking contract change.

### 8.2 Error mapping

Extend the existing `ErrorCode`/exception handler with:

| Code | HTTP | Meaning |
| --- | ---: | --- |
| `unsupported_currency` | 422 | Code is not USD, BOB, or EUR. |
| `invalid_rate` | 422 | Malformed, non-positive, non-finite, wrong-direction, or excessive-scale explicit rate. |
| `rate_unavailable` | 422 | Provider has no usable quote and no valid stored fallback exists. |
| `conversion_failed` | 422 | Validated inputs could not be converted deterministically. |

The existing `ErrorResponse` envelope remains `{error_code, message, field_errors?}`. Currency/rate errors identify `currency` or `usd_rate` in `field_errors` where applicable. Transport details, URLs, response bodies, credentials, cookies, and database internals are not returned. Every error path leaves an edit's prior source/rate state and derived results unchanged.

### 8.3 OpenAPI and generation sequence

For an implementation slice:

1. Change handwritten schemas/routes/domain ports first.
2. Export `contracts/openapi.json` through `backend/scripts/export_openapi.py`.
3. Regenerate TypeScript and Dart clients with `backend/scripts/check_contract_drift.py`'s pinned workflow.
4. Run the drift check and client type/build checks.
5. Review the generated diff as output only; never patch generated files to make drift pass.

The OpenAPI descriptions must document the source-to-USD direction, string rate representation, frozen daily/reference semantics, all provenance values, USD-only balance/settlement, nullable `outing_id`, and structured errors.

## 9. Outing integration without ownership transfer

`group-outing-workspaces` owns group, membership, outing lifecycle, nullable `outing_id`, outing authorization, and scoped derivation semantics. Multi-currency consumes that contract; it does not amend its artifacts or protected files.

Integration rules:

- `outing_id = null` remains a general group expense.
- A non-null outing must be validated by the owning group/outing service and database composite foreign key; currency logic must not duplicate or weaken that check.
- Group derivation includes every general and outing-associated expense exactly once.
- Outing derivation includes only rows with the requested outing ID. General expenses are never allocated into an outing by currency code or client behavior.
- Currency conversion is orthogonal to scope: the same frozen source rate and total-first USD algorithm is used for group and outing results.
- Archived outing write rejection, participant lifecycle, roles, and outing deletion rules remain owned by `group-outing-workspaces`.
- Multi-currency tests include a USD/BOB/EUR general/outing matrix, proving no double counting and no cross-group outing reference.

Because both changes may touch `tables.py`, `repositories.py`, `ports.py`, expense schemas/routes, and Alembic heads, implementation sequencing is explicit:

1. Coordinate the actual `group-outing-workspaces` revision/head and nullable-outing contract before creating the multi-currency migration.
2. Base the currency migration on the merged/current head; never create a competing revision that re-adds `outing_id` or edits the other change's migration.
3. Treat `outing_id` as an additive field passed through the currency-aware expense record rather than changing its meaning.
4. If both branches modify a shared handwritten seam, merge by preserving the outing behavior first and adding currency/rate fields around it; do not rewrite or “clean up” protected workspace files.
5. Run both changes' focused outing and currency tests after integration. A conflict in a protected file is a sequencing/delivery blocker, not permission to edit the protected owner artifact.

## 10. Web presentation and synchronization

The existing web expense feature remains the implementation owner for behavior; `web-professional-redesign` remains untouched.

### Input and history

- Add a supported-currency selector with USD as the default.
- Keep amount and contributor inputs as lexical decimal strings with two-decimal validation; no JavaScript numeric conversion is used for monetary logic.
- Add an optional explicit USD-rate input for BOB/EUR and explain that omission uses Frankfurter then the latest valid stored rate.
- Show validation for unsupported currency, invalid rate, no available rate, and conversion failure without optimistically inserting the row.
- Render history as `source amount + ISO code`, then show `usd_amount_cents` and the frozen rate context (`source -> USD`, rate string, observed/frozen timestamp, provider/provenance). Label Frankfurter values as daily/reference accounting data, not live trading prices.
- Preserve outing selection and nullable general-expense behavior from the workspace contract.

### Balances, settlement, and formatters

Replace the fixed `Bs.` formatter usage with a currency-aware integer-cent formatter that accepts an ISO code and produces explicit USD/BOB/EUR output. It may use strings or BigInt/integer division and modulo, but no floating-point arithmetic. Balances and transfers always call the USD formatter and label the reporting currency. Expense history calls the source-currency formatter using the server-provided code. The UI never calculates `usd_amount_cents`, paid allocation, shares, balances, or transfers.

TanStack Query key factories remain group/outing scoped. On the unchanged WebSocket invalidation, invalidate/refetch expenses, balances, settlement, and the relevant outing scope. A failed mutation leaves cached authoritative data untouched; a successful mutation waits for refetch as it does today.

## 11. Mobile coordination without taking ownership

This change owns the shared REST semantics and OpenAPI requirements only. `mobile-domain-features` owns:

- Dart model adaptation and generated-client consumption;
- read-model, repository, Cubit, formatter, form, and screen changes;
- mobile write parity and its acceptance evidence.

The handoff contract is:

1. Regenerate Dart from the same OpenAPI snapshot through the repository workflow; do not hand-edit `mobile/lib/generated/api`.
2. Treat source amounts/contributions as integer cents in the returned source currency and rates as strings/Decimal-like lexical values.
3. Render server-provided USD balances and settlement without local conversion or split logic.
4. Keep WebSocket handling invalidation-only and refetch REST data.
5. Coordinate a compatibility test for old mobile payloads: omitted currency is USD on create and preserves existing currency on edit, while new mobile writes send explicit currency once the independent change adopts the contract.
6. Do not add Flutter implementation tasks, edit mobile-owned files, or make mobile parity a prerequisite for the web demo beyond the agreed contract sequencing gate.

## 12. Tests and verification gates

### Backend/domain

- Currency enum accepts exactly USD/BOB/EUR and rejects symbols, lowercase, JPY, and inferred locale.
- Amount parsing rejects zero, negative, signs, exponents, and more than two decimals.
- Decimal conversion covers identity, terminating/non-terminating rates, exact half-cent `ROUND_HALF_UP`, negative signed intermediates, excessive rate scale, and no float calls.
- Total-first tests prove beneficiary shares are based on converted total, not independently converted shares.
- Contributor paid-allocation tests prove allocated USD cents sum to the one converted total, including largest-remainder ties.
- CC-01 tests cover contributor/beneficiary intersection, fallback residual target, stable order, and exact sum.
- Balance/settlement tests cover mixed currencies, positive and negative balances, outing filtering, and exact zero.

### Provider and rate persistence

- Frankfurter adapter tests cover URL/source/quote, no API key, timeout, connection failure, non-2xx, 404/no quote, malformed JSON, wrong direction, non-finite/negative/zero rate, valid date, and Decimal parsing.
- Rate policy tests cover current quote, latest-valid fallback, no fallback atomic failure, explicit manual rate, USD identity, and manual exclusion from cache.
- Cache tests cover append-only observations, source ordering, invalid rows excluded, observed versus frozen timestamps, and concurrent latest selection.
- Expense service tests prove a provider request is outside the database transaction, source/cache/children commit together, rollback leaves prior edit intact, and only successful commit publishes invalidation.

### Persistence/API

- Alembic upgrade/backfill/idempotency tests preserve source integers, children, participant IDs, group IDs, timestamps, and nullable outings.
- API tests verify canonical names, deprecated alias semantics, string rates, provenance, USD balance/settlement fields, outing filters, structured error codes/statuses, and no partial rows.
- WebSocket integration proves one post-commit `data_changed` for a successful mixed-currency mutation and none for rate failure.
- OpenAPI export and generated-client drift gate must pass after each handwritten contract change.

### Web and coordinated mobile

- Web unit/component tests cover integer-only formatters for USD/BOB/EUR, negatives, zero, separators, currency selection, rate input, provenance display, and structured error states.
- Web tests assert no conversion/split code is executed client-side and that invalidation refetches authoritative REST resources.
- Mobile tests remain in `mobile-domain-features`; this change records the shared contract and requires its owner to run its own Flutter gate after regeneration.

Required repository gates for an implementation delivery are:

```text
python -m pytest backend/tests -q
python -m ruff check backend
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
python -m backend.scripts.check_contract_drift --cwd .
openspec validate multi-currency --strict
```

The existing WebSocket integration gate and any group-outing focused tests must also remain green. No task is considered complete from artifact presence alone.

## 13. Observability and operational safety

Emit structured metrics/log fields without secrets or full request bodies:

- provider request count by currency/status (`success`, `timeout`, `unavailable`, `malformed`);
- provider latency and timeout count;
- fallback selection count by currency and cache age bucket;
- no-fallback rejections;
- manual-rate and USD-identity usage;
- conversion/rounding failures;
- mutation rollback count;
- exact-zero invariant and persistence-corruption failures;
- cache latest-observation age and missing-currency gauges.

Logs contain request ID, group ID where authorized, expense ID after persistence, source currency, provenance, provider status, and durations. They must not contain passwords, hashes, cookies, session tokens, raw join codes, or provider response bodies. Rate values may be present only where needed for an authorized audit log; default operational logs should identify the rate/cache record rather than duplicate financial payloads.

Alert on sustained provider failure, rising no-fallback failures, unexpectedly old cache observations, conversion failures, and any non-zero balance invariant. The provider adapter has no retry loop in the request path by default; a bounded single request plus deterministic fallback avoids making a mutation transaction wait on repeated external calls.

## 14. Rollout and rollback

### Rollout

1. Land and validate this design/spec artifact before code.
2. Add the additive schema/cache migration and legacy USD backfill; verify existing fixture and child relations.
3. Deploy read compatibility: understand new metadata and continue serving all legacy rows as USD identity.
4. Deploy provider adapter, cache policy, domain conversion, and API fields with non-USD writes disabled by configuration.
5. Export OpenAPI and regenerate TypeScript/Dart through the pinned workflow; update the owned web consumer and coordinate the mobile handoff.
6. Run mixed-currency, fallback, outing-scope, websocket, drift, and full regression gates.
7. Enable non-USD writes for the web after the updated web contract consumer is live. Keep USD writes network-independent and available if Frankfurter is down.
8. Monitor provider/fallback/cache/invariant metrics and review audit presentation before broadening use.

### Rollback

Rollback is expand/contract and data-preserving:

- First disable non-USD writes and manual non-USD edits through server configuration, while continuing to read already persisted source/rate records.
- Keep the new metadata and cache tables. Never reinterpret BOB/EUR source cents as USD and never delete audit columns or cache history.
- Restore a prior compatible application only if it can safely ignore additive fields; otherwise deploy a compatibility reader that exposes frozen USD-derived results until a forward migration is prepared.
- Do not use a production Alembic downgrade after non-USD rows exist. A corrective forward migration must preserve source currency, rate, provenance, timestamps, contributors, and outing scope.
- Roll back web behavior only in non-protected multi-currency-owned files; do not revert or reformat `web-professional-redesign`, generated outputs by hand, final-delivery artifacts, or mobile-owned implementation.
- If the concurrent workspace change must be rolled back, preserve nullable outing data and do not convert outing-linked expenses to general expenses. Coordinate a release-level rollback with that change's owner.

## 15. Implementation order and review slices

Keep implementation reviewable in these slices:

1. Domain value objects, Decimal conversion, errors, and focused unit tests.
2. Alembic additive migration, legacy backfill, cache table, ORM/repository/port mapping, and persistence tests.
3. Frankfurter adapter and rate-selection/fallback service with provider/cache tests.
4. Expense service and derived USD pipeline, including transaction locking, edit/delete, outing filter compatibility, and backend integration tests.
5. Handwritten API schemas/routes/errors, OpenAPI export/regeneration, drift tests, and websocket regression.
6. Existing web expense/history/balance/settlement behavior and integer formatters, without touching the redesign.
7. Mobile contract handoff and independently owned mobile implementation/acceptance under `mobile-domain-features`.

Before each slice, audit the changed paths and the current Alembic/OpenAPI heads. If a shared path is currently protected by `group-outing-workspaces`, stop and coordinate sequencing rather than editing its protected file.

## Key Learnings

- The existing `amount_cents` column is the safest legacy persistence seam: retain it as source-currency cents, add explicit API names, and never silently reinterpret it as USD.
- Exact-zero accounting requires a deterministic USD allocation for multiple source contributors in addition to total-first beneficiary splitting; independently rounding contributor conversions would create unreconcilable paid effects.
- Frankfurter must be parsed with Decimal-aware JSON hooks because even a temporary provider `float` would violate the monetary invariant.
- Rate provenance needs both the source observation time and the expense freeze time; a fallback is auditable only if its age and the saved version are distinguishable.
- The concurrent workspace change already owns nullable `outing_id`, same-group integrity, archived-outing writes, and scoped derivations. Currency must consume those rules orthogonally and must not create a second outing implementation.
- Generated OpenAPI clients, Flutter implementation files, redesign files, final-delivery artifacts, and official fixture data are downstream/protected ownership surfaces, not places to make this design appear complete.
