# Tasks: multi-currency

## Review Workload Forecast

| Field | Value |
| ------- | ------- |
| Estimated changed lines | 900–1,300 across backend, web, tests, migration, and generated outputs |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3 → PR 4 → PR 5 |
| Delivery strategy | exception-ok |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

## Authority, protected surfaces, and execution rules

- Implementation-owned surfaces are `backend/app/domain/`, `backend/app/application/`, `backend/app/adapters/`, handwritten `backend/app/api/`, `backend/migrations/versions/`, owned `backend/tests/`, owned non-redesign `web/src/`, and the relevant export/regeneration scripts.
- Before every slice, inspect the current Alembic head and the active `group-outing-workspaces` branch/head. If a shared file is protected or the head is not integrated, stop at the coordination gate; do not create a competing migration or edit the protected owner’s file.
- Never edit `group-outing-workspaces` artifacts/protected files, `web-professional-redesign`, `final-delivery-alignment`, official fixture/walkthrough files, `mobile-domain-features` implementation files, `web/src/generated/api/`, `mobile/lib/generated/api/`, or `contracts/openapi.json` by hand. Generated output may change only through the pinned workflow.
- Preserve invalidation-only WebSocket behavior: one post-commit group-scoped `data_changed`, with REST refetch as authority.
- Use strict TDD in every implementation slice: RED focused failing test and focused command; GREEN smallest implementation; TRIANGULATE edge/negative/concurrency coverage; REFACTOR behavior-preserving cleanup plus the affected suite. Mark a checkbox complete only with recorded RED/GREEN/TRIANGULATE/REFACTOR evidence.

## Ordered implementation slices

### Slice 0 — coordination and baseline gate

- [x] Confirm `group-outing-workspaces` nullable `outing_id`, composite integrity, authorization, scoped derivation, and actual Alembic/API heads; record the merge base and protected paths in the implementation notes without editing its artifacts. <!-- sdd-owner: implementation -->
- [x] Run baseline focused backend, web, contract, and OpenSpec checks and capture any pre-existing failures separately from this change. <!-- sdd-owner: implementation -->
- [x] Define the slice branch/stack boundaries so no slice exceeds the approved review budget and no generated or mobile-owned file is used as an implementation surface. <!-- sdd-owner: implementation -->

### Slice 1 — money domain and deterministic USD conversion (PR 1)

Allowed edit surfaces: `backend/app/domain/money.py`, new/adjacent domain conversion/error modules, and focused domain tests under `backend/tests/unit/` or the repository’s existing domain-test location.

- [x] RED: add focused tests for exact `USD`/`BOB`/`EUR` parsing, lexical source cents, invalid symbols/lowercase/JPY, invalid rates, Decimal-only conversion, `ROUND_HALF_UP`, signed intermediates, and no float/double arithmetic; run the focused test command and observe failure. <!-- sdd-owner: implementation -->
- [x] GREEN: implement closed currency/source-money/exchange-rate value objects, Decimal validation, total-first source-to-USD cent conversion, and stable `unsupported_currency`, `invalid_rate`, and `conversion_failed` errors. <!-- sdd-owner: implementation -->
- [x] RED/GREEN: test and implement largest-remainder paid allocation from the one converted total, then CC-01 USD residual selection and exact-zero balance/settlement inputs without changing existing split semantics. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE: cover high precision, excessive scale, half-cent ties, negative derived values, one/many contributors, residual ties, empty contributor-beneficiary intersection, and conservation invariants. <!-- sdd-owner: implementation -->
- [x] REFACTOR: centralize Decimal context and integer-cent helpers, remove duplicate conversion logic, run all domain/money tests and `python -m ruff check backend`. <!-- sdd-owner: implementation -->

### Slice 2 — additive persistence, cache, and legacy migration (PR 2)

Allowed edit surfaces: actual current-head revision in `backend/migrations/versions/`, `backend/app/adapters/db/tables.py`, `repositories.py`, `uow.py`, ports/records, and persistence/migration tests. Do not touch the workspace owner’s revision.

- [x] RED: add migration tests proving legacy rows, source contribution cents, beneficiaries, participant/group IDs, timestamps, and nullable outing relations are preserved; assert repeatable backfill and no fabricated quote. <!-- sdd-owner: implementation -->
- [x] GREEN: add one additive Alembic revision based on the coordinated current head, `exchange_rate_cache`, expense currency/rate/provider/provenance/timestamp fields, constraints/indexes, and USD legacy backfill with explicit `legacy_migration` metadata. <!-- sdd-owner: implementation -->
- [ ] RED/GREEN: add repository/ORM tests for Decimal-to-`NUMERIC(30,18)` mapping, append-only valid observations, latest-valid ordering, invalid-row exclusion, optional cache linkage, and atomic child replacement. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: run upgrade/backfill twice, test partial metadata guards, concurrent latest selection, rollback on derived failure, and compatibility with fail-closed/idempotent seed without modifying protected fixture files. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: keep schema checks and repository mappings explicit, verify migration head/foreign-key ordering, run persistence tests and the relevant backend suite. <!-- sdd-owner: implementation -->

### Slice 3 — Frankfurter adapter and rate policy (PR 3)

Allowed edit surfaces: `backend/app/adapters/rates/`, application rate-service/ports, configuration/observability modules owned by this change, and provider/cache tests.

- [ ] RED: test Frankfurter URL construction for only `BOB`/`EUR` to `/v2/rate/{SOURCE}/USD`, absence of API keys, bounded timeout, Decimal JSON parsing, valid date normalization, and malformed/wrong-direction/zero/negative/non-finite/excess-scale responses. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement the timeout-bounded Frankfurter adapter and typed unavailable/invalid-provider results without logging response bodies, credentials, or raw request data. <!-- sdd-owner: implementation -->
- [ ] RED/GREEN: test and implement provider-first selection, latest-valid stored fallback, `rate_unavailable` with no fallback, USD identity, explicit manual rate, timestamps/provenance, and manual exclusion from provider cache. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: cover timeout/DNS/404/429/5xx, missing quote, stale-but-valid fallback, provider date versus frozen timestamp, transaction-boundary timing, and cache race ordering. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: isolate provider transport from domain code, centralize provenance mapping, run provider/rate tests and `python -m ruff check backend`. <!-- sdd-owner: implementation -->

### Slice 4 — expense lifecycle, derived pipeline, and outing integration (PR 4)

Allowed edit surfaces: owned expense/derived application services, handwritten backend tests, and shared seams only after the workspace owner’s contract is integrated. Preserve all outing authorization and scope ownership.

- [ ] RED: add service/integration tests for create, edit, delete, source contributor invariants, rate resolution outside the transaction, group locking, atomic replacement, and exactly one post-commit invalidation. <!-- sdd-owner: implementation -->
- [ ] GREEN: wire currency/rate metadata through expense records and services; validate the complete candidate before mutation; persist source rows/cache/children atomically; derive converted totals, paid allocation, USD CC-01, balances, and settlement server-side. <!-- sdd-owner: implementation -->
- [ ] RED/GREEN: add the USD/BOB/EUR general/outing matrix, proving `outing_id = null`, exact outing filtering, same-group validation, no double counting, and preservation of workspace-owned archived-outing behavior. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: cover invalid edits preserving prior metadata/results, provider failure with/without fallback, archived references, mixed positive/negative balances, deletion rollback, concurrent edits, exact-zero assertions, and failed mutations publishing no invalidation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: preserve the existing group/outing contract rather than duplicating it, keep WebSocket payload unchanged, run focused expense/outing/WebSocket tests and the backend suite. <!-- sdd-owner: implementation -->

### Slice 5 — handwritten API, OpenAPI, and generated consumers (PR 5)

Allowed edit surfaces: handwritten schemas/routes/error mapping, API tests, and repository export/regeneration workflow. Generated files and `contracts/openapi.json` are outputs only.

- [ ] RED: add API tests for canonical source fields, string rates, provenance/timestamps, explicit USD balance/settlement fields, deprecated USD aliases, nullable outing scope, structured 422 errors, authentication/authorization, and atomic no-partial-row behavior. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement authoritative FastAPI request/response schemas and routes with `extra=forbid`, compatibility omission rules, stable error envelopes, clear source-to-USD/frozen-reference descriptions, and no client-side calculation contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: exercise full protected CRUD, mixed-currency reads, manual/fallback/legacy provenance, invalid rate/currency, no fallback, conversion failure, outing filters, and one invalidation-only WebSocket frame after successful mutation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: export OpenAPI, regenerate TypeScript and Dart through the pinned workflow, review generated diffs as outputs only, run `python -m backend.scripts.check_contract_drift --cwd .`, and never hand-edit generated clients or the snapshot. <!-- sdd-owner: implementation -->

### Slice 6 — owned web presentation and synchronization

Allowed edit surfaces: existing non-redesign expense/history/balance/settlement features, owned formatters, query/refetch code, and web tests. Do not touch redesign files or generated TypeScript by hand.

- [ ] RED: add Vitest/component tests for integer-only USD/BOB/EUR formatting, negatives/zero/separators, currency selection, lexical rate input, provenance/reference disclaimer, structured errors, and authoritative refetch behavior. <!-- sdd-owner: implementation -->
- [ ] GREEN: add source-currency expense entry/history and frozen rate context; render server-provided USD totals, balances, and settlement; keep amount/rate lexical and perform no conversion, split, or settlement math in the browser. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: cover omitted/default USD behavior, edit currency/rate, no-fallback rejection without optimistic cache mutation, mixed history, outing selection, WebSocket `data_changed` invalidation, and REST-only recovery. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: consolidate currency-aware integer formatter usage and accessible labels/copy for daily/reference rates, run `npm --prefix web run test`, `typecheck`, and `build`. <!-- sdd-owner: implementation -->

### Slice 7 — coordinated mobile handoff (no mobile implementation)

Allowed edit surfaces: this change’s coordination notes/tests only; implementation remains under `openspec/changes/mobile-domain-features/` and its owner.

- [ ] Provide the regenerated Dart contract, compatibility rules, source-cent/rate-string semantics, USD server-result semantics, and invalidation-only WebSocket expectations to the `mobile-domain-features` owner without editing its artifacts or implementation files. <!-- sdd-owner: implementation -->
- [ ] Coordinate an independent mobile-owner RED/GREEN/TRIANGULATE/REFACTOR acceptance run for read models, formatters, forms, and REST refetch; record its result as a handoff dependency, not as work performed here. <!-- sdd-owner: implementation -->
- [ ] Verify that mobile parity is not made a prerequisite for enabling the web demo, while the shared OpenAPI/drift contract remains green. <!-- sdd-owner: implementation -->

## Observability, rollout, rollback, and final gates

- [ ] RED: add checks for provider status/latency, timeout and malformed counts, fallback count/age buckets, no-fallback rejection, manual/identity use, conversion/rollback failures, cache age/missing-currency gauges, and exact-zero/persistence-corruption failures with secret/body redaction. <!-- sdd-owner: implementation -->
- [ ] GREEN: instrument the adapter and mutation/derivation boundaries with authorized request/group/expense identifiers, currency, provenance, status, and duration; add alerts for sustained provider failure, old cache observations, conversion failures, and non-zero invariants without default rate/body payload logging. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: test provider outage, fallback-age reporting, rollback configuration, disabled non-USD writes, legacy readers, already-persisted non-USD rows, and expand/contract safety without destructive production downgrade or reinterpretation as USD. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: document the deployment sequence—migration/backfill, compatible reader, disabled writes, generated consumers, web enablement, monitoring—and preserve metadata/cache history for rollback. <!-- sdd-owner: implementation -->
- [ ] Run all required gates from the repository root: `python -m pytest backend/tests -q`, `python -m ruff check backend`, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, `python -m backend.scripts.check_contract_drift --cwd .`, `openspec validate multi-currency --strict`, the focused WebSocket integration gate, and coordinated group-outing tests. <!-- sdd-owner: implementation -->

## Parent-owned review and lifecycle gates

- [ ] Start or reuse bounded review for each stacked slice, verify changed-line budgets and protected-file cleanliness, and resolve only review findings within this change’s ownership. <!-- sdd-owner: parent -->
- [ ] Confirm the coordinated Alembic/OpenAPI heads, mobile handoff status, rollout approval, and final regression receipts before applying/archive lifecycle actions. <!-- sdd-owner: parent -->
- [ ] Start or reuse bounded review and lifecycle-gate evidence for the final delivery without editing or accepting concurrent change artifacts. <!-- sdd-owner: parent -->

## Key Learnings

- The 600-line configured budget is likely exceeded by backend domain, migration, API, web, tests, and generated outputs; stacked-to-main slices protect review focus while preserving strict acceptance coverage.
- `group-outing-workspaces` owns nullable outing semantics and the current migration/API seams; a head/ownership blocker requires coordination, never a competing revision or protected-file edit.
- `amount_cents` remains source-currency cents; canonical API names must distinguish source values from derived USD cents, and legacy rows use USD identity with `legacy_migration` provenance.
- Total-first Decimal conversion plus largest-remainder paid allocation and USD CC-01 is required to keep balances and settlement exactly reconciled.
- Mobile work is a contract handoff only here; generated clients are regenerated outputs, not manual edit surfaces.
