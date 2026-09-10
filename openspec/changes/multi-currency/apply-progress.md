# Apply Progress: multi-currency

## Structured status consumed

- **Change:** `multi-currency`
- **Artifact store:** authoritative `openspec`
- **Apply state:** ready; verify, sync, and archive remain blocked for the parent lifecycle.
- **Action context:** repo-local workspace at `D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1`; repository root is the allowed edit root; warnings: none.
- **Delivery boundary:** stacked slices; this run is only the already-existing Slice 2 persistence remediation. No `size:exception` was requested or inferred.
- **Skill resolution:** `paths-injected` (`C:\Users\HP\.pi\agent\git\github.com\Gentleman-Programming\gentle-pi\skills\gentle-ai\SKILL.md`).

## Slice 1 status

- **Slice:** 1 / PR 1, money domain and deterministic USD conversion.
- **Status:** implementation complete; ready for parent lifecycle.
- **Delivery boundary:** `stacked-to-main`; only Slice 1 was implemented in that prior run. The aggregate change was not implemented, and no `size:exception` was requested or inferred.
- **Review workload:** bounded to the 400-line attempt budget. Product code/test diff was kept below the budget; SDD bookkeeping is separate.
- **Protected surfaces:** persistence, API, generated clients, web, mobile, fixtures, redesign, WebSocket, and existing split/balance/settlement production services were not changed by Slice 1.

The five Slice 1 implementation rows in `tasks.md` remain visibly marked `- [x]` (rows 39–43): RED focused money tests; GREEN value objects/conversion/errors; RED/GREEN allocation and CC-01 coverage; TRIANGULATE edge and conservation coverage; and REFACTOR shared Decimal/integer helpers plus lint.

### Slice 1 files and evidence

- `backend/app/domain/money.py`
- `backend/app/domain/errors.py`
- `backend/app/domain/conversion_service.py`
- `backend/tests/unit/domain/test_money.py`
- `backend/tests/unit/domain/test_conversion_service.py`
- `openspec/changes/multi-currency/tasks.md`
- `openspec/changes/multi-currency/apply-progress.md`

| Cycle | Evidence | Observed result |
| --- | --- | --- |
| RED | Focused money/conversion command before production implementation | Collection failed as expected: missing `InvalidRateError` and missing `conversion_service`. |
| GREEN | Focused money/conversion command after implementation | `56 passed in 0.13s`. |
| RED/GREEN | Added largest-remainder, tie, conservation, and existing-service integration coverage | Final focused domain command: `79 passed in 0.13s`. |
| TRIANGULATE | Unsupported codes, invalid rates, half-cent rounding, signed conversion, ties, source conservation, and exact-zero balances | Included in the final 79 passing tests. |
| REFACTOR | `python -m ruff check backend` followed by the final focused domain command | `All checks passed!`; `79 passed in 0.13s`. |

### Slice 1 behavior retained

- `CurrencyCode` accepts only `USD`, `BOB`, and `EUR`.
- `SourceMoney` uses positive, non-boolean integer source cents.
- `ExchangeRate` uses Decimal-only validation and normalized scale up to 18 fractional digits.
- Total-first conversion uses a local Decimal context and `ROUND_HALF_UP`; signed intermediate values remain supported.
- Largest-remainder paid allocation preserves the converted total, and existing equal split, balance, and settlement contracts remain unchanged.

## Slice 2 remediation status

The partial Slice 2 candidate already contained `0007_multi_currency.py`, ORM metadata, migration persistence tests, and the Alembic harness update. The previous writer timed out after those files were created; the recorded root cause is that the apply writer stopped before completing the E501 cleanup and cumulative apply-progress/task reconciliation. Existing artifacts did not contain explicit Slice 2 RED/GREEN evidence, so this run records only triangulation and behavior-preserving refactor evidence; no prior RED result is invented.

### Scope and files changed in this remediation

- `backend/migrations/versions/0007_multi_currency.py`: fixed exactly the eight Ruff E501 violations using behavior-preserving wrapping/formatting. Migration semantics, revision lineage, constraints, backfill predicate, child preservation, cache schema, and index definition were not changed. The existing `Column.copy()` deprecation warning remains; removing it was not needed for this remediation.
- `openspec/changes/multi-currency/tasks.md`: marked the implementation-owned Slice 0 coordination row 31 complete after recording current-head and ownership evidence. Existing rows 32–33 and Slice 2 rows 49–50 remain `[x]`; rows 51–53 remain unchecked. Parent-owned rows 111–113 were preserved byte-for-byte.
- `openspec/changes/multi-currency/apply-progress.md`: merged this evidence with the prior Slice 1 record.

The existing partial candidate files `backend/app/adapters/db/tables.py`, `backend/tests/integration/persistence/test_multi_currency_tables.py`, and `backend/tests/test_alembic_harness.py` were read and preserved; they were not expanded in this remediation.

### Coordination and head evidence

- Source migration head observed with `python -m alembic -c backend/alembic.ini heads`: `0007_multi_currency (head)`.
- Migration test `test_revision_is_based_on_the_current_source_head` verifies `0007_multi_currency` revises `0006_join_codes`.
- Existing persistence coverage verifies nullable `outing_id`, composite `(outing_id, group_id)` foreign-key ordering, same-group references, and source/child relationship preservation.
- The active workspace contract remains authoritative for nullable outing scope, composite integrity, authorization, and scoped derivation; no workspace-owned file was edited.

### Triangulation and refactor evidence

| Scope | Existing focused evidence | Result |
| --- | --- | --- |
| Legacy backfill and repeatability | `test_migration_backfills_legacy_rows_without_changing_source_relationships` calls the backfill path again and compares metadata/children; `test_partial_metadata_guard_does_not_rewrite_a_populated_expense` checks the partial-metadata guard | Passed. No fabricated cache quote was created. |
| Source and child preservation | Legacy fixture assertions preserve group, outing, description, amount, timestamps, contributions, beneficiaries, and participant IDs | Passed. |
| Nullable outing and same-group integrity | `test_expense_keeps_nullable_same_group_outing_foreign_key_after_migration` | Passed. |
| Numeric Decimal mapping and source cents | `test_orm_numeric_rates_round_trip_as_decimal_and_preserve_source_cents` checks `Decimal` round-trip and unchanged source cents; schema test checks precision 30 and scale 18 | Passed. |
| Cache checks and latest-valid index | Cache schema/index assertions plus unsupported direction/provider/non-positive-rate rejection tests | Passed. |
| Revision head | Focused revision assertion plus Alembic CLI head command | Passed; observed head is `0007_multi_currency (head)`. |

### TDD Cycle Evidence for this remediation

| Cycle | Evidence | Observed result |
| --- | --- | --- |
| RED/GREEN | No explicit prior Slice 2 RED/GREEN evidence exists in the read apply-progress or existing candidate artifacts | Not claimed. |
| TRIANGULATE | `python -m pytest backend/tests/integration/persistence/test_multi_currency_tables.py backend/tests/test_alembic_harness.py -q` | `8 passed in 22.50s`; 18 existing `Column.copy()` deprecation warnings. |
| REFACTOR | Wrapped the eight reported E501 lines without changing migration behavior, then ran `python -m ruff check backend` | `All checks passed!`. |
| Head verification | `python -m alembic -c backend/alembic.ini heads` | `0007_multi_currency (head)`. |

### Persisted task updates

- Row 31 is now visibly `- [x]` because current source/runtime Alembic head and the workspace ownership boundary were verified without editing protected artifacts.
- Rows 32–33 were already visibly `- [x]` and remain so.
- Rows 49–50 were already visibly `- [x]` and remain so.
- Rows 51–53 remain visibly `- [ ]`; repository/UoW/cache lookup behavior, append-only repository semantics, concurrency, derived rollback, and seed compatibility were not implemented or claimed.

## Review workload and PR boundary

This is a bounded remediation of the existing Slice 2 / PR 2 persistence candidate. The current boundary remains the approved 400 changed-line review budget for the slice; the eight-line wrapping fix and bookkeeping do not justify expanding into repositories, UoW, cache lookup, application behavior, API, web, mobile, generated, fixture, group-outing, redesign, or final-delivery files. Delivery remains stacked slices with no size exception.

## Remaining unchecked implementation tasks

The following exact implementation-owned rows remain unchecked in `tasks.md`:

- [ ] RED/GREEN: add repository/ORM tests for Decimal-to-`NUMERIC(30,18)` mapping, append-only valid observations, latest-valid ordering, invalid-row exclusion, optional cache linkage, and atomic child replacement. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: run upgrade/backfill twice, test partial metadata guards, concurrent latest selection, rollback on derived failure, and compatibility with fail-closed/idempotent seed without modifying protected fixture files. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: keep schema checks and repository mappings explicit, verify migration head/foreign-key ordering, run persistence tests and the relevant backend suite. <!-- sdd-owner: implementation -->
- [ ] RED: test Frankfurter URL construction for only `BOB`/`EUR` to `/v2/rate/{SOURCE}/USD`, absence of API keys, bounded timeout, Decimal JSON parsing, valid date normalization, and malformed/wrong-direction/zero/negative/non-finite/excess-scale responses. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement the timeout-bounded Frankfurter adapter and typed unavailable/invalid-provider results without logging response bodies, credentials, or raw request data. <!-- sdd-owner: implementation -->
- [ ] RED/GREEN: test and implement provider-first selection, latest-valid stored fallback, `rate_unavailable` with no fallback, USD identity, explicit manual rate, timestamps/provenance, and manual exclusion from provider cache. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: cover timeout/DNS/404/429/5xx, missing quote, stale-but-valid fallback, provider date versus frozen timestamp, transaction-boundary timing, and cache race ordering. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: isolate provider transport from domain code, centralize provenance mapping, run provider/rate tests and `python -m ruff check backend`. <!-- sdd-owner: implementation -->
- [ ] RED: add service/integration tests for create, edit, delete, source contributor invariants, rate resolution outside the transaction, group locking, atomic replacement, and exactly one post-commit invalidation. <!-- sdd-owner: implementation -->
- [ ] GREEN: wire currency/rate metadata through expense records and services; validate the complete candidate before mutation; persist source rows/cache/children atomically; derive converted totals, paid allocation, USD CC-01, balances, and settlement server-side. <!-- sdd-owner: implementation -->
- [ ] RED/GREEN: add the USD/BOB/EUR general/outing matrix, proving `outing_id = null`, exact outing filtering, same-group validation, no double counting, and preservation of workspace-owned archived-outing behavior. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: cover invalid edits preserving prior metadata/results, provider failure with/without fallback, archived references, mixed positive/negative balances, deletion rollback, concurrent edits, exact-zero assertions, and failed mutations publishing no invalidation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: preserve the existing group/outing contract rather than duplicating it, keep WebSocket payload unchanged, run focused expense/outing/WebSocket tests and the backend suite. <!-- sdd-owner: implementation -->
- [ ] RED: add API tests for canonical source fields, string rates, provenance/timestamps, explicit USD balance/settlement fields, deprecated USD aliases, nullable outing scope, structured 422 errors, authentication/authorization, and atomic no-partial-row behavior. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement authoritative FastAPI request/response schemas and routes with `extra=forbid`, compatibility omission rules, stable error envelopes, clear source-to-USD/frozen-reference descriptions, and no client-side calculation contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: exercise full protected CRUD, mixed-currency reads, manual/fallback/legacy provenance, invalid rate/currency, no fallback, conversion failure, outing filters, and one invalidation-only WebSocket frame after successful mutation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: export OpenAPI, regenerate TypeScript and Dart through the pinned workflow, review generated diffs as outputs only, run `python -m backend.scripts.check_contract_drift --cwd .`, and never hand-edit generated clients or the snapshot. <!-- sdd-owner: implementation -->
- [ ] RED: add Vitest/component tests for integer-only USD/BOB/EUR formatting, negatives/zero/separators, currency selection, lexical rate input, provenance/reference disclaimer, structured errors, and authoritative refetch behavior. <!-- sdd-owner: implementation -->
- [ ] GREEN: add source-currency expense entry/history and frozen rate context; render server-provided USD totals, balances, and settlement; keep amount/rate lexical and perform no conversion, split, or settlement math in the browser. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: cover omitted/default USD behavior, edit currency/rate, no-fallback rejection without optimistic cache mutation, mixed history, outing selection, WebSocket `data_changed` invalidation, and REST-only recovery. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: consolidate currency-aware integer formatter usage and accessible labels/copy for daily/reference rates, run `npm --prefix web run test`, `typecheck`, and `build`. <!-- sdd-owner: implementation -->
- [ ] Provide the regenerated Dart contract, compatibility rules, source-cent/rate-string semantics, USD server-result semantics, and invalidation-only WebSocket expectations to the `mobile-domain-features` owner without editing its artifacts or implementation files. <!-- sdd-owner: implementation -->
- [ ] Coordinate an independent mobile-owner RED/GREEN/TRIANGULATE/REFACTOR acceptance run for read models, formatters, forms, and REST refetch; record its result as a handoff dependency, not as work performed here. <!-- sdd-owner: implementation -->
- [ ] Verify that mobile parity is not made a prerequisite for enabling the web demo, while the shared OpenAPI/drift contract remains green. <!-- sdd-owner: implementation -->
- [ ] RED: add checks for provider status/latency, timeout and malformed counts, fallback count/age buckets, no-fallback rejection, manual/identity use, conversion/rollback failures, cache age/missing-currency gauges, and exact-zero/persistence-corruption failures with secret/body redaction. <!-- sdd-owner: implementation -->
- [ ] GREEN: instrument the adapter and mutation/derivation boundaries with authorized request/group/expense identifiers, currency, provenance, status, and duration; add alerts for sustained provider failure, old cache observations, conversion failures, and non-zero invariants without default rate/body payload logging. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: test provider outage, fallback-age reporting, rollback configuration, disabled non-USD writes, legacy readers, already-persisted non-USD rows, and expand/contract safety without destructive production downgrade or reinterpretation as USD. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: document the deployment sequence—migration/backfill, compatible reader, disabled writes, generated consumers, web enablement, monitoring—and preserve metadata/cache history for rollback. <!-- sdd-owner: implementation -->
- [ ] Run all required gates from the repository root: `python -m pytest backend/tests -q`, `python -m ruff check backend`, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, `python -m backend.scripts.check_contract_drift --cwd .`, `openspec validate multi-currency --strict`, the focused WebSocket integration gate, and coordinated group-outing tests. <!-- sdd-owner: implementation -->

## Deferred parent-owned lifecycle actions

- [ ] Start or reuse bounded review for each stacked slice, verify changed-line budgets and protected-file cleanliness, and resolve only review findings within this change’s ownership. <!-- sdd-owner: parent -->
- [ ] Confirm the coordinated Alembic/OpenAPI heads, mobile handoff status, rollout approval, and final regression receipts before applying/archive lifecycle actions. <!-- sdd-owner: parent -->
- [ ] Start or reuse bounded review and lifecycle-gate evidence for the final delivery without editing or accepting concurrent change artifacts. <!-- sdd-owner: parent -->

## Risks

- PostgreSQL applied-state was not verified; only the source migration head and the direct SQLite migration harness were observed.
- The existing `Column.copy()` SADeprecationWarning remains in the migration; it is unrelated to the requested eight E501 violations and was not changed.
- Repository/UoW/cache lookup behavior and all later application/API/client work remain intentionally deferred.
