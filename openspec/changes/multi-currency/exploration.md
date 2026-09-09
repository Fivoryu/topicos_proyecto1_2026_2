# Exploration: multi-currency

## Status and scope

This is exploration only. No proposal, specification, design, task list, product code, generated output, existing active change, or fixture is changed by this artifact.

Confirmed product decisions:

- First-version currencies are exactly `USD`, `BOB` (bolivianos), and `EUR`.
- A group may contain expenses in more than one of those currencies.
- Every group reports balances and settlement in USD.
- Each expense retains its original amount, ISO currency, and a frozen source-currency-to-USD exchange rate for auditability.
- The rate is fetched from the Binance API at expense create/edit time and frozen with its timestamp, provider, and normalized source-currency-to-USD value.
- If Binance is unavailable or lacks a quote, the latest stored valid rate is reused and the expense records that fallback provenance.
- Currency and rate are editable with the expense.
- Legacy expense rows migrate as USD.

This change reverses the current single-currency product boundary only for its own accepted scope. The existing `money` and `project-context` non-goals remain historical/current baseline constraints until this change's later specs explicitly supersede them.

## Current architecture and boundaries

### Backend and monetary domain

- `backend/app/api/routes/expenses.py` owns the group-scoped expense REST boundary and currently parses lexical decimal amounts once before calling the application service.
- `backend/app/api/schemas/expenses.py` currently accepts `amount` and contributor `amount` as decimal strings and returns only integer `amount_cents` plus participant metadata.
- `backend/app/application/expense_service.py` validates description, positive integer cents, participant references, contributor totals, outing scope, and atomic create/edit behavior.
- `backend/app/application/ports.py` exposes `ExpenseRecord` with `amount_cents`, contributor cents, beneficiaries, timestamps, group, and optional `outing_id`; this is a key domain-port seam for adding currency and USD-derived values without putting conversion in clients.
- `backend/app/domain/money.py`, `expense_rules.py`, `split_service.py`, and `balance_service.py` currently assume one integer-cent unit. `settlement_service.py` consumes derived integer-cent balances and emits integer-cent transfers.
- FastAPI is the authority for parsing, conversion, validation, balances, and settlement. WebSocket remains invalidation-only and must not carry rates, currencies, balances, or transfers.

### Database and persistence

- `backend/app/adapters/db/tables.py` persists source expenses in `expenses`; the current row has `amount_cents`, `group_id`, optional `outing_id`, description, and timestamps.
- `expense_contributions` stores contributor amounts as integer cents; `expense_beneficiaries` stores beneficiary membership. Derived balances and transfers are not persisted as ledgers.
- `backend/app/adapters/db/repositories.py` maps `ExpenseRecord` to source and child rows and replaces the complete expense atomically on edit.
- A schema change will require a new Alembic migration in the repository's migration tree, migration of existing rows as USD, and compatibility with the fail-closed/idempotent demo seed. Existing Samaipata rows therefore remain legacy USD rows under the confirmed migration policy; the presentation/fixture implications still need explicit validation.

### API and contract generation

- The handwritten FastAPI schemas/routes are authoritative. `contracts/openapi.json`, `web/src/generated/api/`, and `mobile/lib/generated/api/` are generated and must only change through the pinned export/regeneration workflow.
- Expense create/edit requests currently carry a decimal lexical amount and contributor lexical amounts. Responses expose source history and timestamps but no currency or exchange-rate audit fields.
- Balance and settlement response schemas currently expose integer cents only. A multi-currency implementation must decide whether to expose USD cents under existing names, rename them, or add explicit `usd_cents` fields; this is a compatibility and contract decision, not a client implementation detail.
- Structured error handling already maps validation failures to explicit codes/422 and preserves atomicity; currency, rate, unsupported-code, and conversion-rounding errors should follow that pattern.

### Web

- `web/src/features/expenses/expenses-panel.tsx` owns the current expense form/history flow and consumes generated `ExpenseResponse`/`ExpenseWriteRequest` types.
- `web/src/features/balances/balances-panel.tsx` and `web/src/features/settlement/settlement-panel.tsx` render server-derived integer values.
- `web/src/core/cents-formatter.ts` is the shared formatter and currently aliases `formatBolivianos` to a fixed `Bs.` convention. It cannot be reused unchanged for USD/EUR display or for original-currency plus USD presentation.
- TanStack Query and the existing WebSocket listener/refetch path are integration boundaries only; currency changes must not create a second source of truth or client-side conversion.
- `web-professional-redesign` is dirty and protected. Its files must not be used as an implementation surface or reformatted by this change.

### Mobile

- The mobile extension is independently governed by `mobile-domain-features`; its read models, repositories, Cubits, screens, write drafts, and generated Dart API currently represent one integer-cent amount and use `core/formatters/cents_formatter.dart`.
- `mobile/lib/domain/read_models/read_models.dart`, `domain/write_models/write_models.dart`, `data/repositories/expenses_repository.dart`, and expense/balance/settlement presentation are likely adaptation points after the contract is settled.
- Mobile is not the authority and must not calculate conversion, splits, balances, or settlement. Its scope, sequencing, acceptance ownership, and generated-client updates must be coordinated with (not absorbed into) the independent mobile change.

## Relevant existing specifications and dependencies

- `openspec/specs/money/spec.md`: current exact integer-cent parsing/display rules and explicit single-currency non-goal. It must be superseded/amended deliberately; do not silently rewrite it during exploration.
- `openspec/specs/expenses/spec.md`: expense lifecycle, contributor total invariant, equal split/CC-01, archived references, outing scope, and atomic create/edit/delete behavior.
- `openspec/specs/api/spec.md`: protected REST surface, structured errors, generated OpenAPI clients, server authority, and invalidation-only WebSocket.
- `openspec/specs/clients/spec.md`: thin web/mobile consumers, no client-side monetary authority, shared formatting, and REST refetch behavior.
- `openspec/specs/groups/spec.md`: group ownership/scope and the active `group-outing-workspaces` amendment, including group-wide derivations and nullable outing scope.
- `openspec/project-context.md` and `AGENTS.md`: PostgreSQL/FastAPI authority, integer-money invariant, generated-file prohibition, active-change ownership, and protected official fixture.
- `docs/sdd-evolution.md`: precedence and preservation rules for archived/current artifacts.
- `group-outing-workspaces` is an active, independently staged change. Its current exclusion of multiple currencies is a dependency boundary; this change should add currency orthogonally to its group/outing model rather than modify its in-progress files.
- `web-professional-redesign` is another dirty, independently owned change and is out of bounds.

## Likely impact surface for a later implementation

1. **Domain representation:** define source-money units for USD/BOB/EUR, exact exchange-rate representation, Binance quote normalization, fallback provenance, conversion precision, and deterministic USD-cent rounding. Convert the expense total to USD cents first, then apply CC-01 splitting in USD; extend balance/settlement inputs accordingly.
2. **Persistence:** add non-null currency, frozen-rate value, rate timestamp, provider, and fallback-provenance columns, choose fixed-precision database types or integer/rational storage, decide whether to persist derived USD cents, and migrate existing rows as USD without losing audit meaning.
3. **Expense children:** keep contributor amounts in the expense's original currency and ensure their sum equals the original amount; convert the total to USD cents before applying the equal split and document the resulting contributor/share accounting invariant.
4. **API:** extend write/read expense schemas and balance/settlement schemas, document supported ISO codes, normalized rate/provenance fields, edit semantics, fallback behavior, and rate format, preserve backward/forward compatibility where practical, and regenerate both clients from OpenAPI.
5. **Web/mobile presentation:** show original amount/currency and frozen rate/provider/timestamp/fallback provenance for auditability; show balances/transfers in USD; replace fixed `Bs.` formatters with explicit currency-aware formatting while retaining integer arithmetic.
6. **Seed/tests/gates:** validate the legacy-USD Samaipata policy and add mixed-currency examples, Binance success/fallback/unavailable behavior, conversion/rounding, invalid-rate, unsupported-currency, editable currency/rate, edit/delete, archival, outing, persistence, contract-drift, web, and mobile coverage.

## Risks and unresolved questions

### High-risk monetary questions

- **Exchange-rate scale and direction:** the confirmed normalized direction is source currency to USD, but the exact decimal precision and representation still need definition. A floating-point database/Python/TypeScript/Dart representation would violate the money invariant and undermine auditability.
- **Binance quote and fiat support:** do not assume Binance exposes every required BOB/USD or EUR/USD pair, symbol, or fiat market. Pair availability, endpoint semantics, authentication/limits, and whether Binance can provide the required fiat quotes are proposal/design validation items. No unsupported pair mapping should be invented during implementation.
- **Conversion rounding:** converting source minor units to USD cents can produce fractions of a cent. The change needs one deterministic rule (for example, decimal arithmetic with an explicitly documented half policy), plus a proof that converted totals and group balances sum exactly to zero.
- **Split ordering:** resolved by product decision: convert the expense total to USD cents first, then apply CC-01 equal splitting and residual selection in USD. The exact rounding and resulting contributor/share accounting invariant still require design proof.
- **Contributor conversion:** contributors remain recorded in the expense's original currency and must sum to the original amount; the total is converted once before USD derivation. The precise relationship between original-currency contributor amounts and USD paid/owed reporting still needs explicit API/domain design.
- **Editable frozen rates:** currency and rate are editable with the expense. Because editing replaces source values and can change historical USD results, audit fields must preserve the rate actually used for each saved version/current record and clearly define timestamp/provider/fallback replacement semantics.
- **Existing data migration:** current rows have no currency/rate and will migrate as USD by confirmed decision. The remaining risk is aligning the official Samaipata fixture, display expectations, and audit-field defaults without fabricating a historical Binance quote.

### Contract and product risks

- Existing fields are named `amount_cents`; changing their meaning risks silently treating source cents as USD cents. Prefer explicit field names where ambiguity would be dangerous, even if compatibility requires temporary aliases.
- USD-only balance/settlement is a changed display and semantic contract. Clients must not recompute USD values, and WebSocket invalidation must remain unchanged.
- Currency symbols/locales can introduce inconsistent formatting. ISO codes should be rendered explicitly, and formatting must avoid floating point in both clients.
- Adding required fields to generated clients affects the independent mobile read-mostly extension and may require a coordinated contract migration rather than a web-only slice.
- Active `group-outing-workspaces` may land schema/API changes concurrently. Integration must preserve nullable outing scope and ensure group derivations include each expense exactly once.
- The official Samaipata demo and existing tests assert BOB-style output and exact integer values, while legacy rows now migrate as USD. The proposal must reconcile those assertions with the confirmed legacy-USD policy and decide whether the fixture is displayed as USD, amended as a new mixed-currency fixture, or preserved only as historical evidence.

## Recommended investigation before proposal

- Inspect the pinned Alembic/export/regeneration workflow and all current expense/balance/settlement schemas before choosing field names.
- Validate Binance pair/fiat support and quote normalization for USD, BOB, and EUR without assuming unavailable markets; define the fallback lookup and provenance model.
- Establish a decimal/rational conversion model with worked examples for USD, BOB, and EUR, including total-first conversion, USD residuals, negative balances, and exact-zero proofs.
- Validate the confirmed legacy-USD migration and fixture/display policy with explicit human approval.
- Coordinate ownership and sequencing with `group-outing-workspaces`, `mobile-domain-features`, and the protected redesign; do not edit their files.
- Define an API compatibility/versioning strategy and focused RED tests before any implementation slice.

## Key Learnings

- Currency is currently excluded explicitly by `money`, project context, and several historical change boundaries; this new change must document deliberate supersession rather than treating absence as an implementation gap.
- The current monetary pipeline is integer cents end to end, with FastAPI/domain services authoritative and both clients display-only; conversion must fit that pipeline without introducing floating point or client authority.
- Expense source rows and child contributor rows are the central persistence seam, while balances and settlement are derived and should remain non-persisted.
- Generated TypeScript/Dart clients are downstream artifacts, and mobile currency work remains independently governed even though the API contract is shared.
- The largest unresolved correctness issue is deterministic total-first conversion and USD allocation/rounding while preserving exact-zero balances and CC-01 residual behavior; Binance pair/fiat support is an explicit proposal/design validation item.
