# Proposal: Multi-currency expenses

- **Change:** `multi-currency`
- **Status:** Proposed
- **Independence:** New change; does not amend or modify another active change.

## Intent

Allow a group to record expenses in USD, BOB (bolivianos), and EUR while keeping balances and settlement understandable in one reporting currency: USD. The backend remains the sole authority for exchange-rate capture, conversion, splitting, balances, and settlement.

This addresses the current single-currency boundary without making clients responsible for monetary calculations or presenting an apparently precise rate as real-time trading data.

## Confirmed product decisions

1. The first-version currency set is exactly `USD`, `BOB`, and `EUR`.
2. A group may contain expenses in any mixture of those currencies.
3. Balances and settlement are reported in USD.
4. Every expense preserves its original amount and currency, plus a frozen source-currency-to-USD rate and timestamp.
5. For non-USD expenses, rates are fetched from Frankfurter, without an API key, using `https://api.frankfurter.dev/v2/rate/{source}/USD`.
6. If Frankfurter is unavailable or has no quote, the latest stored valid rate for that source currency is used. If no valid stored rate exists, the write fails clearly rather than guessing.
7. Currency and rate are editable with the expense; each saved expense uses the rate associated with that saved version.
8. Legacy expense rows migrate as USD.
9. The expense total is converted to USD cents first; only then is CC-01 splitting applied in USD.
10. The backend uses `Decimal` and integer cents for monetary logic. It must not use binary floating point (`float`/`double`) for amounts, rates, conversion, or rounding.

Frankfurter is daily/reference-rate data, not trading-grade real-time market data. The UI and API must communicate that the stored rate is a frozen reference used for group accounting.

## Scope

### Backend and domain

- Add source currency and frozen rate metadata to the expense domain and persistence model.
- Keep expense totals and contributor amounts in the original currency; validate that contributor amounts equal the original expense total in that currency.
- Normalize rates in the source-currency-to-USD direction and convert the complete expense total to USD cents before applying CC-01.
- Define deterministic Decimal-based conversion and USD-cent rounding, including negative derived balances and CC-01 residual allocation.
- Continue deriving balances and settlement on the server, with the exact-zero invariant preserved.
- Record rate provenance sufficient to distinguish a Frankfurter quote, a stored fallback, a manual rate edit, and a legacy USD migration.

### API and clients

- Extend handwritten request/response schemas for supported currency, original amount, frozen rate, timestamp, and provenance.
- Make balance and settlement semantics explicitly USD, using unambiguous field names where existing `amount_cents` names could be misread.
- Preserve structured validation errors for unsupported currencies, invalid rates, unavailable rates with no fallback, and conversion failures.
- Export the changed OpenAPI contract and regenerate downstream clients through the repository workflow; generated files are not hand-edited.
- Update web and, under its independent ownership, mobile presentation to show original expense money and USD-derived balances without client-side conversion.
- Keep WebSocket behavior unchanged: mutations publish only the existing invalidation event, and clients refetch authoritative REST data.

### Persistence and migration

- Add the required currency/rate/timestamp/provenance storage through an Alembic migration.
- Migrate every existing expense row as USD without fabricating a historical market quote. A legacy row may use the exact USD identity rate and migration timestamp with explicit legacy provenance.
- Keep source contributor rows and expense history consistent during create, edit, delete, archival, and outing-scoped operations.
- Keep the migration compatible with the fail-closed, idempotent demo seed.

## Non-goals

- No currencies beyond USD, BOB, and EUR in this change.
- No live trading, real-time pricing, rate forecasting, hedging, payment execution, or financial advice.
- No client-side authority for conversion, splitting, balances, or settlement.
- No custom split rules beyond existing CC-01 behavior.
- No changes to authentication, permissions, participant lifecycle, or WebSocket payload semantics.
- No modification of `group-outing-workspaces`, `web-professional-redesign`, `final-delivery-alignment`, mobile-owned implementation files, generated output by hand, or official fixture files as part of this proposal.

## User impact

- Users can select USD, BOB, or EUR for each expense in a mixed-currency group.
- Expense history shows what was originally entered and the frozen USD conversion context, including whether a stored fallback was used.
- Balances and suggested transfers are consistently shown in USD, regardless of expense currency.
- Editing an expense can change its currency and/or rate and therefore can change USD balances; the saved record must make the resulting rate auditable.
- Users may see a clear unavailable-rate error when a non-USD expense has neither a provider quote nor a prior valid stored rate.
- Existing expenses continue to be readable and are displayed as USD after migration.

## Requirements

### R1 — Supported currencies and validation

The server accepts exactly `USD`, `BOB`, and `EUR` for new or edited expenses, rejects other codes with a structured validation error, and does not infer currency from a symbol or locale.

### R2 — Rate acquisition and provenance

For BOB and EUR, the default rate acquisition uses the Frankfurter endpoint `https://api.frankfurter.dev/v2/rate/{source}/USD` without an API key. The implementation stores the normalized positive Decimal rate, its frozen timestamp, provider/provenance, and whether it was a current quote or stored fallback. USD uses the exact identity conversion of 1 USD to USD.

If Frankfurter is unavailable or lacks a quote, the latest stored valid rate for that source currency is selected. A write with no valid prior rate fails atomically and never stores an invented or partially converted expense.

### R3 — Original-money preservation

The expense amount and contributor amounts remain represented in the selected source currency. Their integer-cent total must equal the expense total before conversion. The record must retain the original currency and amount even when derived USD values are exposed.

### R4 — Total-first USD conversion

The server converts each complete expense total to USD cents with Decimal arithmetic and one documented deterministic rounding policy. It then applies CC-01 splitting in USD. It must not convert each beneficiary share independently before determining the USD total, and it must preserve exact-zero group balances.

### R5 — USD reporting

All balance values and settlement transfer amounts returned for a group are USD cents. Clients render those server-derived values and do not recalculate them from source amounts or rates.

### R6 — Editable currency and rate

Expense create/edit supports changing currency and rate. An explicit rate edit is retained as the rate used for that saved record and is labeled with appropriate provenance; omitted rates follow the current Frankfurter-then-stored-fallback policy. Edit operations remain atomic and recalculate all affected USD-derived results server-side.

### R7 — Legacy migration

Existing rows with no currency/rate metadata become USD records. The migration is repeatable/safe, preserves original integer amounts and relationships, and records explicit legacy provenance rather than implying a historical Frankfurter quote.

### R8 — Authority and contract safety

FastAPI/PostgreSQL remain the authority. REST contracts, generated-client regeneration, structured errors, outing scope, and invalidation-only WebSocket behavior remain coherent with the active changes and existing invariants.

## Affected areas and dependencies

- **Backend:** expense routes/schemas, expense service and ports, monetary/conversion/split/balance/settlement services, repositories/tables, Alembic migrations, and focused tests.
- **API contract:** handwritten FastAPI schemas first, then OpenAPI export and TypeScript/Dart regeneration.
- **Web:** expense form/history, currency-aware formatters, balances, settlement, and query/refetch behavior.
- **Mobile:** shared contract/read models and presentation under `mobile-domain-features`; this proposal does not take ownership of its implementation.
- **Data:** existing expense and contributor rows, demo seed behavior, and legacy USD migration.
- **External dependency:** Frankfurter availability, supported source-to-USD quotes, response semantics, daily refresh behavior, and operational rate limits. No API key is required.
- **Parallel changes:** `group-outing-workspaces` remains the owner of group/outing work; this change integrates with its nullable outing scope without editing its protected files. `web-professional-redesign` is protected and out of scope.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Frankfurter is unavailable, delayed, or lacks a quote | Use the latest stored valid rate; fail closed when none exists; expose provenance and stale/reference context. |
| Users mistake a daily/reference rate for a live market rate | Label Frankfurter data as daily/reference data, not trading-grade real-time data; freeze and display the rate timestamp. |
| Floating-point drift or inconsistent rounding breaks balances | Use Decimal for rates/conversion and integer cents for money; centralize one deterministic rounding policy; test exact-zero totals. |
| Converting shares instead of totals creates residual inconsistencies | Convert the complete expense total to USD cents first, then apply CC-01 in USD. |
| A manually edited rate becomes indistinguishable from a provider quote | Persist explicit provenance and timestamp for every saved rate. |
| Existing `amount_cents` consumers misread source cents as USD cents | Clarify or rename API fields, update generated clients, and add contract/drift coverage before enabling mixed-currency writes. |
| Legacy migration appears to claim a historical market rate | Use USD identity conversion plus explicit migration provenance; never fabricate a quote. |
| Concurrent workspace/redesign changes create integration conflicts | Respect ownership boundaries and coordinate contract sequencing; do not modify protected files. |

## Rollout and migration

1. Finalize the spec/design with worked USD, BOB, and EUR examples, Decimal precision, rounding, provenance, and no-fallback behavior.
2. Add the persistence migration in an additive, reviewable form. Backfill legacy expenses as USD with explicit migration metadata and verify relationships and idempotency.
3. Implement the provider adapter and stored-rate fallback before exposing non-USD writes. Add timeouts and structured errors; do not block database transactions on an unbounded external request.
4. Update handwritten API/domain behavior, then export OpenAPI, regenerate clients, and run contract-drift checks.
5. Enable mixed-currency expense writes only after backend, web, and coordinated mobile contract consumers can display source money and USD results safely.
6. Monitor provider failures, fallback use, conversion errors, and balance/settlement invariant failures. Keep the existing USD path as the simplest operational fallback.

### Rollback

Rollback must be expand/contract, not a destructive down migration. Disable new non-USD writes first, preserve migrated metadata and stored rates, and deploy a compatible reader that continues to report already persisted results correctly. Do not reinterpret non-USD source cents as USD or drop audit columns. A full reversal requires a data-preserving compatibility migration and explicit verification of all derived USD values.

## Acceptance framing

Acceptance should demonstrate at least:

1. USD, BOB, and EUR are accepted; an unsupported code is rejected.
2. A group containing expenses in all three currencies receives one server-derived USD balance and USD settlement result.
3. A successful Frankfurter quote is frozen with source, normalized rate, timestamp, and provenance; the API endpoint uses no API key.
4. Provider outage and missing-quote cases use the latest valid stored rate; no-history cases fail atomically with a clear error.
5. An expense can edit its currency and rate, and the saved provenance reflects the rate actually used.
6. A multi-contributor expense preserves source-currency contributor totals, converts the total once to USD cents, and applies CC-01 residual selection in USD.
7. Positive/negative balances and settlement transfers sum exactly to zero cents under deterministic rounding.
8. Legacy rows migrate as USD without changing their original integer amounts or relationships and without fabricating a market quote.
9. REST responses, generated clients, web/mobile displays, outing scope, and invalidation-only WebSocket behavior remain contract-consistent.
10. Tests and static checks demonstrate that backend monetary logic uses Decimal/integer cents and no float/double arithmetic.

## Proposal question round

The confirmed decisions resolve the main product direction. These questions are intentionally limited to business rules and edge cases; they are meant to improve the proposal by exposing implications and tradeoffs before specification. The current proposal records the stated assumption so the user can answer, skip, correct it, or request a second round:

1. **No prior rate:** should create/edit always fail when Frankfurter has no quote and no stored valid rate? Current assumption: yes, fail closed rather than guess.
2. **Manual rate edits:** should an explicitly edited rate be labeled `manual` and excluded from the provider-rate cache? Current assumption: yes; it applies only to the saved expense unless a later product rule says otherwise.
3. **Legacy audit metadata:** is it acceptable for migrated USD rows to carry identity rate `1` and migration timestamp with `legacy_migration` provenance? Current assumption: yes, because no historical quote should be invented.
4. **Official fixture:** should existing fixture rows remain USD after migration, with any mixed-currency demonstration added separately later? Current assumption: yes; this proposal does not rewrite protected fixture data.

## Research references

- Exploration evidence: `openspec/changes/multi-currency/exploration.md` (architecture boundaries, CC-01 implications, migration risks, generated-client ownership, and protected-change constraints).
- Frankfurter official documentation: <https://frankfurter.dev/>.
- Frankfurter BOB currency reference: <https://frankfurter.dev/currencies/bob/>.
- Frankfurter source-to-USD endpoint used by this proposal: <https://api.frankfurter.dev/v2/rate/{source}/USD>.

The exploration artifact contains earlier Binance wording. The confirmed product decision supersedes that provider direction for this change; implementation and later specs must use Frankfurter and the fallback behavior above.

## Success criteria

- Users can record and edit supported mixed-currency expenses without client-side monetary authority.
- Every saved expense has auditable original-money and frozen-rate context.
- Balances and settlement are consistently server-derived USD cents with exact-zero invariants.
- Provider failure is safe, observable, and deterministic through stored-rate fallback or an explicit atomic error.
- Legacy data remains readable as USD, and the change integrates without modifying protected active changes or generated files by hand.
