# Apply progress: final-delivery-alignment

This file records the implementation state produced from the repository ZIP snapshot after the OpenCode quota interruption. It does not replace `tasks.md`; checkboxes remain authoritative.

## Implemented scope

- Current guidance reconciled in `openspec/project-context.md`, `openspec/config.yaml`, root `AGENTS.md`, and `docs/sdd-evolution.md`.
- Historical `docs/requerimiento-docente.md` and the independently governed `cuentas-claras-mvp`, `wire-mutation-websocket-invalidation`, and `mobile-domain-features` change directories were not edited.
- Samaipata seed changed from three aggregated source rows to four exact official source expenses with stable IDs `...0021`–`...0024` and explicit payer indices.
- Seed/recovery/DA-01..DA-04 tests updated for the four-expense fixture while domain balance/settlement code remains unchanged.
- Handwritten web delivery surface translated to Spanish; integer-only display formatting now uses decimal comma/thousands dot and signed balances; settlement rows use direct arrow notation.
- Root README, official timed demo, environment example, generator metadata/docs, and delivery-facing SDD status were updated.
- Generated TypeScript/Dart OpenAPI client trees were not modified.

## TDD / verification evidence

### Backend fixture RED

The changed seed/DA-01 tests were run against the pre-change source fixture in a clean copy:

```text
python -m pytest backend/tests/integration/persistence/test_seed.py backend/tests/acceptance/test_da_01_samaipata.py -q

F.F
2 failed, 1 passed
```

Observed failures were the intended ones: the old seed contained `3` expenses instead of `4`, and DA-01 returned `Samaipata - Ana` `96000` rather than separate `Cabaña` `80000` plus `Entradas a El Fuerte` `16000`.

### Backend GREEN / regressions

Run from repository root after implementation:

```text
python -m pytest backend/tests/integration/persistence/test_seed.py backend/tests/integration/api/test_recovery.py backend/tests/acceptance -q
14 passed

python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q
5 passed

python -m pytest backend/tests -q
195 passed

python -m compileall -q backend
passed
```

`python -m ruff check backend` could not be executed in this container because Ruff is not installed.

### Web implementation checks

Vitest/Vite dependencies are not bundled in the ZIP. This environment cannot access the npm registry, and its npm cache does not contain the required project packages, so the real web test/typecheck/build commands could not be executed here.

Checks completed without fabricating a green gate:

- All handwritten web `.ts`/`.tsx` and test files were parsed/transpiled with the installed TypeScript compiler: no syntax diagnostics.
- Direct formatter checks passed for `Bs. 0,00`, thousands grouping, negative amounts, `+Bs. 560,00`, zero, and debt output without floating-point conversion.
- Existing `web/src/core/config.ts`, `web/vite.config.ts`, `web/tests/core/config.test.ts`, and `web/tests/core/websocket.test.ts` are byte-identical to the input snapshot.
- `web/src/generated/api/**` is byte-identical to the input snapshot.

Required local commands remain:

```text
npm --prefix web ci
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
```

### Contract / generated clients

A fresh FastAPI OpenAPI export was produced and its parsed JSON is semantically identical to committed `contracts/openapi.json`. Byte comparison in this Linux container differs because the ZIP carries CRLF line endings while the local export uses LF.

The full drift workflow was not run because it requires the unavailable npm generator dependencies and Dart toolchain. Both committed generated client directories are byte-identical to the input snapshot. Required local command:

```text
python -m backend.scripts.check_contract_drift --cwd .
```

### OpenSpec / PostgreSQL / browser gates

This container does not include the OpenSpec CLI, Docker/PostgreSQL binaries, Flutter/Dart, or the installed web dependency tree. Therefore the following gates are intentionally not claimed as complete and their task checkboxes remain open:

```text
openspec validate final-delivery-alignment --strict
openspec status --change final-delivery-alignment
python -m ruff check backend
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
python -m backend.scripts.check_contract_drift --cwd .
# disposable PostgreSQL reset/migrate/seed-twice/startup/health
# timed browser rehearsal
```

## Preservation checks

- `docs/requerimiento-docente.md`: unchanged.
- `openspec/changes/cuentas-claras-mvp/`: unchanged.
- `openspec/changes/wire-mutation-websocket-invalidation/`: unchanged.
- `openspec/changes/mobile-domain-features/`: unchanged.
- Backend mutation-invalidation integration test: unchanged.
- Web API-base and WebSocket tests/config implementation: unchanged.
- Generated TypeScript/Dart API trees: unchanged.

## Successor apply: `fix-backend-lint-gate`

This bounded apply handled only task 5.2 of `final-delivery-alignment`, as explicitly authorized by the parent. No web, mobile, delivery-facing documentation, generated-client, WebSocket, configuration, or backend invalidation implementation/test files were changed.

### Completed task and persisted checkbox

- [x] 5.2 — The persisted checkbox in `tasks.md` was updated immediately after the required checks passed.

### TDD Cycle Evidence

| Phase | Command/evidence | Result |
| --- | --- | --- |
| RED | `python -m ruff check backend` before the edit | Failed with the single expected `E501` at `backend/scripts/check_contract_drift.py:33` (`91 > 88`). |
| GREEN | `python -m ruff check backend` after the edit | Passed: `All checks passed!` |
| TRIANGULATE | `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q` | Passed: `5 passed, 1 warning`. |
| TRIANGULATE | `python -m pytest backend/tests -q` | Passed: `197 passed, 1 warning`. |
| REFACTOR | Minimal style-only correction review | Wrapped the 91-character docstring; no behavior, lint configuration, tests, or unrelated code was changed. |

### Files changed in this successor

- `backend/scripts/check_contract_drift.py` — wrapped the flagged docstring to satisfy Ruff E501.
- `openspec/changes/final-delivery-alignment/tasks.md` — marked only task 5.2 complete.
- `openspec/changes/final-delivery-alignment/apply-progress.md` — appended this cumulative evidence without removing prior evidence.

### Workload / PR boundary

The work-unit boundary is `fix-backend-lint-gate` only. The parent owns native attempt settlement and all review, verification, and delivery lifecycle actions. No `gentle-ai sdd-attempt` or review lifecycle command was run. The checked-in configuration specifies `exception-ok` with `stacked-to-main`; no broader change slice was attempted. The task artifact did not contain the requested `Review Workload Forecast` guard lines; this bounded successor was nevertheless explicitly authorized by the parent.

### Structured status consumed / produced

- `activeChange`: `final-delivery-alignment`.
- `artifactStore`: `both`, with the checked-in OpenSpec artifacts authoritative for this run.
- `schema`: `spec-driven`.
- `applyState`: successor objective complete; the overall change remains in progress because other task checkboxes remain open.
- `dependencies`: proposal, delivery-readiness spec, design, tasks, and prior apply-progress were present and read before editing.
- `blockedReasons`: none for this successor.
- `actionContext`: edit authority was limited to the three surfaces supplied by the parent; all edits stayed within them. Warning: the native OpenSpec CLI/status command was unavailable (`openspec: command not found`), so status was consumed using the checked-in artifacts and explicit parent context. Warning: the edit tool reported an unrelated pre-existing analyzer finding at `check_contract_drift.py:159`; that line was not changed.
- `nextRecommended`: `parent-lifecycle`.

### Remaining tasks

The following exact unchecked task lines remain and were not changed:

```text
- [ ] 3.1 Update formatter, balance, and settlement tests to require Spanish separators, signed balance output, `Le deben`/`Debe`/`Saldado`, Spanish empty states, and exact official rows `Diego → Ana: Bs. 400,00` and `Carla → Ana: Bs. 160,00`; run the focused Vitest files and record the expected RED failures.
- [ ] 3.2 Implement integer-only Spanish amount formatting plus signed-balance formatting, translate the balance and settlement panels, and render direct arrow transfers in server order; verify `web/tests/core/core.test.ts`, `web/tests/features/balances/balances.test.tsx`, and `web/tests/features/settlement/settlement.test.tsx` pass with no client monetary computation.
- [ ] 3.3 Update shell, auth/session, group, participant, expense, and app tests to query natural Spanish visible and accessible text while retaining every existing interaction assertion; run those focused tests and record the expected RED failures before changing production components.
- [ ] 3.4 Translate the handwritten web shell, login/session notices, group settings, participant and expense panels, known-error presentation, loading/empty/validation states, role/policy labels, and `web/index.html` language metadata; verify all focused tests from task 3.3 pass and no file under `web/src/generated/api/` is manually edited.
- [ ] 3.5 Run `npm --prefix web run test` after localization and verify participant CRUD/archive/rename, expense create/edit/delete and beneficiary defaults/exclusions, auth/session, balances, settlement, API adapters, and the existing API-base/WebSocket behavior remain green; do not modify `web/tests/core/config.test.ts` or `web/tests/core/websocket.test.ts`.
- [ ] 4.2 Correct only `web/.env.example` and setup documentation to use the existing Vite same-origin route without duplicating `/api/v1`, explain the non-authoritative status of `VITE_GROUP_ID`, and verify the documented generated login request resolves through the web origin and proxy plus the existing config/WebSocket tests pass unchanged; do not edit `web/src/core/config.ts`, `web/vite.config.ts`, or their tests.
- [ ] 5.1 Run `openspec validate final-delivery-alignment --strict` and `openspec status --change final-delivery-alignment`; verify all proposal capabilities have valid delta specs and every apply-required artifact is complete.
- [ ] 5.3 Run `npm --prefix web run test`, `npm --prefix web run typecheck`, and `npm --prefix web run build`; verify `web/tests/core/config.test.ts` and `web/tests/core/websocket.test.ts` pass unchanged with all other web tests and the production build.
- [ ] 5.4 Run `python -m backend.scripts.check_contract_drift --cwd .`; verify `contracts/openapi.json` and both generated client trees are reproducible and review the diff to confirm generated TODOs and handwritten generated-client edits are absent.
- [ ] 5.5 From a disposable local demo database, run the documented PostgreSQL reset/start, Alembic upgrade, seed twice, and backend startup/health sequence; verify the second seed creates zero records, exactly four official expenses exist, the backend starts, and protected API results match all exact cent assertions.
- [ ] 5.6 Rehearse the documented browser demo at delivery viewport sizes; verify it completes in under three minutes, uses Spanish primary text, shows the exact four records/balances/transfers, preserves results after refresh, and introduces no functional or responsive regression.
```

## Successor apply: `harden-contract-drift-cleanup`

This bounded correction hardens the generated-mobile cleanup in `backend/scripts/check_contract_drift.py` only. It preserves successful generation and normalization, confines generated paths to the temporary root, rejects malformed generated mobile output, and reports cleanup failures instead of suppressing them. No task checkbox was changed in this work unit; task 5.2 remains checked and all other task states remain unchanged.

### TDD Cycle Evidence

| Phase | Command/evidence | Result |
| --- | --- | --- |
| Safety net | `python -m ruff check backend` before editing | Passed: `All checks passed!` |
| Safety net | `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q` before editing | Passed: `5 passed, 1 warning`. |
| Safety net | `python -m pytest backend/tests -q` before editing | Passed: `197 passed, 1 warning`. |
| RED | Parent-provided pi-lens diagnostics before editing | Blocker at line 159 for unchecked `shutil.rmtree`; warning at line 143 for generated path/file handling. |
| RED | Inline cleanup-failure harness against the pre-edit function | Failed as expected with uncaught `OSError: cleanup denied` from `shutil.rmtree(..., ignore_errors=True)`. |
| RED | Inline malformed-pubspec harness against the intermediate implementation | Failed as expected because unsupported generated content was accepted. |
| GREEN | Minimal correction: confinement helper, explicit read/write/unlink/rmtree handling, malformed SDK guard, and explicit temporary-root call | Implemented in the target file only. |
| GREEN | `python -m ruff check backend` after implementation | Passed: `All checks passed!` |
| GREEN | Focused inline hardening harness | Passed normalization, malformed/missing output rejection, cleanup failure reporting, cleanup-path escape rejection, and successful cleanup cases. |
| TRIANGULATE | `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q` | Passed: `5 passed, 1 warning`. |
| TRIANGULATE | `python -m pytest backend/tests -q` | Passed: `197 passed, 1 warning`. |
| REFACTOR | Final review and repeated lint/regression checks | No behavior-changing refactor remained; analyzer-sensitive calls are guarded and `ignore_errors=True` was removed. |

### Files changed in this successor

- `backend/scripts/check_contract_drift.py` — confined generated paths, validated generated SDK output, and converted expected file-operation failures into clear `RuntimeError` exceptions.
- `openspec/changes/final-delivery-alignment/apply-progress.md` — appended this cumulative evidence without deleting prior evidence.
- `openspec/changes/final-delivery-alignment/tasks.md` — unchanged in this work unit; no checkbox update was needed.

### Scope, workload, and lifecycle boundary

The work-unit boundary is `harden-contract-drift-cleanup` only. The parent explicitly authorized this narrowly scoped correction after the pi-lens findings and owns native attempt settlement, review, verification, and delivery lifecycle actions. No `gentle-ai sdd-attempt` or review lifecycle command was run. The tasks artifact still has no `Review Workload Forecast` guard lines; the checked-in configuration remains `exception-ok` with `stacked-to-main`, and no broader slice or size exception was introduced.

### Structured status consumed / produced

- `activeChange`: `final-delivery-alignment`.
- `artifactStore`: `openspec` from authoritative native status; `openspec/config.yaml` declares hybrid settings, but the native status selected the repo-local OpenSpec artifact store for this run.
- `schema`: `spec-driven`.
- `applyState`: `ready` before this work unit; the overall change remains in progress because 11 of 22 tasks are pending.
- `dependencies`: proposal, specs, design, tasks, and prior apply-progress were present and read before editing; verify remains blocked until all tasks are complete.
- `blockedReasons`: none for this bounded apply.
- `actionContext`: native status reported repo-local edit authority rooted at the repository; the parent narrowed effective edits to `backend/scripts/check_contract_drift.py` and this progress file, and all edits stayed within those surfaces.
- `nextRecommended`: `parent-lifecycle` for this completed apply work unit; remaining unchecked tasks and final verification stay with the parent workflow.

### Remaining tasks

The exact unchecked task lines remain in the preceding `Remaining tasks` block above and were not changed. They are tasks 3.1, 3.2, 3.3, 3.4, 3.5, 4.2, 5.1, 5.3, 5.4, 5.5, and 5.6; task 5.2 remains checked.

## Revalidation: `accept-contract-drift-hardening`

- Re-verified the already-implemented hardening without changing production code or task checkboxes.
- Confirmed `_confined_generated_path` resolves and rejects paths outside the temporary root; generated pubspec reads/writes and transient file/directory cleanup use explicit error handling, with no `ignore_errors=True`. `run_drift_check` passes the temporary root explicitly.
- `python -m ruff check backend` — passed.
- `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q` — `5 passed, 1 warning`.
- `python -m pytest backend/tests -q` — `197 passed, 1 warning`.
- The warnings are the existing Starlette/httpx deprecation warning. User changes and untracked `INICIO_LOCAL.md` were preserved.

The bounded work-unit scope remains `accept-contract-drift-hardening`; parent-owned attempt settlement, review, verification, and delivery lifecycle actions remain deferred. Structured status consumed: active change `final-delivery-alignment`, repo-local OpenSpec artifacts authoritative, schema `spec-driven`, no blockers for this revalidation, and next recommendation `parent-lifecycle`.

## Successor apply: `check-contract-drift`

This bounded apply executed only task 5.4. No source code, contracts, generated clients, web, mobile, or documentation files were edited. The persisted task checkbox was updated immediately after the required workflow passed:

- [x] 5.4 — `python -m backend.scripts.check_contract_drift --cwd .`

### Contract-drift evidence

Executed from the repository root with npm offline to prevent network access:

```text
NPM_CONFIG_OFFLINE=true python -m backend.scripts.check_contract_drift --cwd .

Contract and generated clients are drift-free.
Process exit: 0
```

The workflow exported the OpenAPI contract and regenerated TypeScript and Dart clients into temporary directories, then completed the mobile build step and comparisons successfully. The generator output reported the existing informational warnings about the missing `servers` value, Dart post-processing, the removed `--delete-conflicting-outputs` option, and the `json_annotation` version constraint; none caused drift. The generated temporary files were cleaned up by the workflow.

Post-run preservation checks from the repository root:

```text
git status --short --untracked-files=all
 M README.md
 M backend/scripts/check_contract_drift.py
 M openspec/changes/final-delivery-alignment/apply-progress.md
 M openspec/changes/final-delivery-alignment/tasks.md
 M web/src/app/App.tsx
 M web/src/core/theme.css
 M web/src/features/auth/login-screen.tsx
 M web/src/features/expenses/expenses-panel.tsx
 M web/src/index.css
?? INICIO_LOCAL.md

git diff --name-status -- contracts/openapi.json web/src/generated/api mobile/lib/generated/api
(no output)

git diff --quiet -- contracts/openapi.json web/src/generated/api mobile/lib/generated/api
No tracked contract/generated-client diff.
```

The pre-existing unrelated README/web changes and untracked `INICIO_LOCAL.md` remain preserved. `contracts/openapi.json`, `web/src/generated/api/`, and `mobile/lib/generated/api/` have no tracked or untracked changes.

### TDD Cycle Evidence

This task is an execution-only reproducibility gate and authorized no production behavior change, so no separate RED test or GREEN source edit was applicable. The strict-TDD evidence for this bounded task is recorded explicitly:

| Phase | Command/evidence | Result |
| --- | --- | --- |
| RED | No production/test edit was authorized for task 5.4; the gate itself is the required executable check. | Not applicable; no source behavior was changed. |
| GREEN | `NPM_CONFIG_OFFLINE=true python -m backend.scripts.check_contract_drift --cwd .` | Passed, exit 0; contract and generated clients are drift-free. |
| TRIANGULATE | `git diff --name-status -- contracts/openapi.json web/src/generated/api mobile/lib/generated/api` and `git diff --quiet -- ...` | Passed; no contract/generated-client diff. |
| REFACTOR | No refactor permitted or performed. | Preserved source and generated trees. |

### Files and deviations

- Files changed in this work unit: `openspec/changes/final-delivery-alignment/tasks.md` and `openspec/changes/final-delivery-alignment/apply-progress.md` only.
- Design deviation: none.
- Parent-owned actions deferred: native attempt settlement, review lifecycle, verification, and delivery gates.

### Workload / PR boundary

The work-unit boundary is `check-contract-drift` only. The tasks artifact contains no `Review Workload Forecast` guard lines; the configured delivery strategy remains `exception-ok` with `stacked-to-main`. No broader slice, PR exception, review lifecycle, or `gentle-ai sdd-attempt` operation was performed.

### Structured status consumed / produced

- `activeChange`: `final-delivery-alignment`.
- `artifactStore`: `openspec` from authoritative `gentle-ai sdd-status`; `openspec/config.yaml` declares hybrid settings, while native status selected repo-local OpenSpec artifacts for this run.
- `schema`: `spec-driven`.
- `applyState`: `ready` before this work unit; overall change remains in progress because other tasks remain unchecked.
- `dependencies`: proposal, all four specs, design, tasks, and prior apply-progress were present and read before execution; verify remains blocked until all tasks are complete.
- `blockedReasons`: none.
- `actionContext`: native status reported repo-local workspace authority; the parent narrowed effective edit surfaces to `tasks.md` and `apply-progress.md`, and all edits stayed within those surfaces. Warning: the `openspec` CLI itself was unavailable in PATH (`openspec: command not found`), so native `gentle-ai sdd-status` and checked-in artifacts were used for status.
- `nextRecommended`: `parent-lifecycle` for this bounded apply; remaining tasks and final verification stay with the parent workflow.

### Remaining tasks

The following exact unchecked task lines remain and were not changed:

```text
- [ ] 3.1 Update formatter, balance, and settlement tests to require Spanish separators, signed balance output, `Le deben`/`Debe`/`Saldado`, Spanish empty states, and exact official rows `Diego → Ana: Bs. 400,00` and `Carla → Ana: Bs. 160,00`; run the focused Vitest files and record the expected RED failures.
- [ ] 3.2 Implement integer-only Spanish amount formatting plus signed-balance formatting, translate the balance and settlement panels, and render direct arrow transfers in server order; verify `web/tests/core/core.test.ts`, `web/tests/features/balances/balances.test.tsx`, and `web/tests/features/settlement/settlement.test.tsx` pass with no client monetary computation.
- [ ] 3.3 Update shell, auth/session, group, participant, expense, and app tests to query natural Spanish visible and accessible text while retaining every existing interaction assertion; run those focused tests and record the expected RED failures before changing production components.
- [ ] 3.4 Translate the handwritten web shell, login/session notices, group settings, participant and expense panels, known-error presentation, loading/empty/validation states, role/policy labels, and `web/index.html` language metadata; verify all focused tests from task 3.3 pass and no file under `web/src/generated/api/` is manually edited.
- [ ] 3.5 Run `npm --prefix web run test` after localization and verify participant CRUD/archive/rename, expense create/edit/delete and beneficiary defaults/exclusions, auth/session, balances, settlement, API adapters, and the existing API-base/WebSocket behavior remain green; do not modify `web/tests/core/config.test.ts` or `web/tests/core/websocket.test.ts`.
- [ ] 4.2 Correct only `web/.env.example` and setup documentation to use the existing Vite same-origin route without duplicating `/api/v1`, explain the non-authoritative status of `VITE_GROUP_ID`, and verify the documented generated login request resolves through the web origin and proxy plus the existing config/WebSocket tests pass unchanged; do not edit `web/src/core/config.ts`, `web/vite.config.ts`, or their tests.
- [ ] 5.1 Run `openspec validate final-delivery-alignment --strict` and `openspec status --change final-delivery-alignment`; verify all proposal capabilities have valid delta specs and every apply-required artifact is complete.
- [ ] 5.3 Run `npm --prefix web run test`, `npm --prefix web run typecheck`, and `npm --prefix web run build`; verify `web/tests/core/config.test.ts` and `web/tests/core/websocket.test.ts` pass unchanged with all other web tests and the production build.
- [ ] 5.5 From a disposable local demo database, run the documented PostgreSQL reset/start, Alembic upgrade, seed twice, and backend startup/health sequence; verify the second seed creates zero records, exactly four official expenses exist, the backend starts, and protected API results match all exact cent assertions.
- [ ] 5.6 Rehearse the documented browser demo at delivery viewport sizes; verify it completes in under three minutes, uses Spanish primary text, shows the exact four records/balances/transfers, preserves results after refresh, and introduces no functional or responsive regression.
```

### Generated TODO clarification

A read-only scan found standard pre-existing OpenAPI Generator TODO comments under `mobile/lib/generated/api/test/` and `mobile/lib/generated/api/doc/`. They are unchanged generated baseline content, not handwritten edits or drift introduced by this work unit. The contract-drift task's required diff review found no generated TODO changes and no generated-client file changes.

## Direct verification: `verify-postgresql-direct-final`

The user-authorized final host-side verification used a new disposable PostgreSQL 16 container on host port `15435`; existing `infra-db-1` and `cc-final-alignment-db` containers were not touched. Demo passwords were generated only in memory and were not printed or persisted.

- Alembic upgrade to the head revision passed.
- First seed created the official four expenses; the second seed created zero expenses.
- PostgreSQL query confirmed exactly four expenses for the official Samaipata group.
- Uvicorn started on the verification port and `/health` returned HTTP 200 with both API and database status `ok`.
- A protected login/session check obtained CSRF through the session endpoint, authenticated the seeded owner, and verified server-derived balances: Ana `56000`, Beto `0`, Carla `-16000`, Diego `-40000` cents.
- The protected settlement endpoint returned the required ordered transfers: Diego → Ana `40000`, then Carla → Ana `16000` cents.
- The verification process and disposable container were cleaned up; no production, generated, or unrelated files changed.

Task 5.5 is checked in `tasks.md` based on this complete operational evidence. The direct run was parent-owned after the delegated operational attempts timed out; no review lifecycle command was used.

## Successor apply: `web-delivery-gates`

This bounded continuation resumed the already-implemented web localization and delivery setup work. It did not redo handwritten translation or formatter changes and did not modify any generated client, API-base resolver, Vite proxy, configuration test, WebSocket test, mobile, backend invalidation, or unrelated pre-existing file.

### Completed tasks and persisted checkbox updates

The following implementation-owned tasks were verified and marked immediately in `tasks.md`:

- [x] 3.1 — Focused formatter, balance, and settlement tests passed with Spanish separators, signed balances, state labels, settled empty state, and ordered arrow transfers.
- [x] 3.2 — Existing integer-only formatter and server-authoritative balance/settlement presentation passed focused verification.
- [x] 3.3 — Focused Spanish shell, session, group, participant, and expense tests passed while preserving interaction assertions.
- [x] 3.4 — Focused presentation tests passed; handwritten web implementation and Spanish document metadata are present, with generated API files unchanged.
- [x] 3.5 — Full web test suite passed.
- [x] 4.2 — Environment/setup guidance was verified; same-origin configuration, non-authoritative `VITE_GROUP_ID`, and unchanged config/WebSocket tests remain aligned.
- [x] 5.3 — Full web test, typecheck, and production build gates passed.

### TDD Cycle Evidence

The implementation and test updates for tasks 3.1–3.4 were already present at the handoff. Per the task artifact instruction, they were not reverted or rewritten to manufacture a second RED cycle. The prior progress records that the npm dependency tree was unavailable; this continuation records the first executable GREEN evidence.

| Task | Test file(s) | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 3.1 | `web/tests/core/core.test.ts`; balance and settlement tests | Unit/integration | Existing implementation present; no source edit | Not rerun; pre-existing test/implementation pair preserved | 3 files, 18 passed | Spanish positive/zero/negative formatting, settled empty state, and two ordered transfers passed | None; no source edit |
| 3.2 | Same three focused files | Unit/integration | Focused suite passed before task marking | Not rerun; behavior already implemented at handoff | 18 passed | Multiple formatter inputs and both settlement states passed | None; no source edit |
| 3.3 | `web/tests/app.test.tsx`; auth, group, participant, expense tests | Integration | Focused suite run before task marking | Not rerun; test updates pre-existed | 5 files, 27 passed | Authentication lifecycle, policy permissions, participant lifecycle/errors, and expense validation passed | None; no source edit |
| 3.4 | Same five focused files plus preserved document metadata | Integration/structural | Focused suite passed | Not rerun; presentation implementation pre-existed | 27 passed | Shell/session, role/policy, accessibility, CRUD/error, and Spanish empty/error states passed | None; generated tree unchanged |
| 3.5 | Full `web` suite | Integration | Focused suites passed | N/A; execution-only gate | `npm --prefix web run test`: 11 files, 61 passed | Includes unchanged config (12 tests), WebSocket (2 tests), API adapter, auth, CRUD, balances, and settlement coverage | N/A; no source edit |
| 4.2 | `web/tests/core/config.test.ts`; `web/tests/core/websocket.test.ts` | Integration | Full suite passed | N/A; setup/documentation already present | 14 preserved config/WebSocket tests passed | Non-secret scan confirmed empty `VITE_API_BASE_URL` and `VITE_GROUP_ID`; README documents no duplicated API prefix and server-owned group selection | N/A; no source edit |
| 5.3 | Full web suite plus compiler/build | Integration/build | Focused and full tests passed | N/A; execution-only gate | `npm --prefix web run typecheck` passed; `npm --prefix web run build` passed | Production build transformed 135 modules successfully | N/A; no source edit |

### Verification commands and results

```text
npm --prefix web run test -- tests/core/core.test.ts tests/features/balances/balances.test.tsx tests/features/settlement/settlement.test.tsx
3 files, 18 tests passed

npm --prefix web run test -- tests/app.test.tsx tests/features/auth/session-provider.test.tsx tests/features/group/group-settings.test.tsx tests/features/participants/participants.test.tsx tests/features/expenses/expenses.test.tsx
5 files, 27 tests passed

npm --prefix web run test
11 files, 61 tests passed

npm --prefix web run typecheck
passed

npm --prefix web run build
passed; 135 modules transformed
```

Preservation checks passed: `git diff --quiet -- web/src/generated/api web/src/core/config.ts web/vite.config.ts web/tests/core/config.test.ts web/tests/core/websocket.test.ts`; the exit code was zero. `git diff --check` reported only existing Git line-ending normalization warnings. The direct sensitive-path read for `web/.env.example` was blocked by the tool safety guard; a non-secret key/comment scan confirmed `VITE_API_BASE_URL=` is empty, `VITE_GROUP_ID=` is present, and the only `/api/v1` occurrence is the explanatory “do not add it here” comment. The already-read README provides the corresponding setup guidance.

### Deviations and blockers

- No production or test source edit was needed in this continuation because the bounded web implementation was already present and all executable web gates passed.
- The required RED stage for 3.1–3.4 was not recreated after the handoff; doing so would require reverting valid pre-existing implementation/test work, which the parent explicitly prohibited. No RED result is fabricated.
- `openspec validate final-delivery-alignment --strict` and `openspec status --change final-delivery-alignment` were attempted exactly and both remain unavailable because `openspec` is not installed in PATH. Task 5.1 remains unchecked.
- Task 5.6 remains unchecked because no browser rehearsal tool was available in this phase; the documented timed walkthrough was not claimed from unit/build evidence.

### Remaining tasks

The following exact unchecked task lines remain in `tasks.md`:

```text
- [ ] 5.1 Run `openspec validate final-delivery-alignment --strict` and `openspec status --change final-delivery-alignment`; verify all proposal capabilities have valid delta specs and every apply-required artifact is complete.
- [ ] 5.6 Rehearse the documented browser demo at delivery viewport sizes; verify it completes in under three minutes, uses Spanish primary text, shows the exact four records/balances/transfers, preserves results after refresh, and introduces no functional or responsive regression.
```

### Workload / PR boundary

The work-unit boundary is `web-delivery-gates`, limited to verifying the pre-existing final-alignment web presentation and setup work. The configured delivery strategy remains `exception-ok` with chain strategy `stacked-to-main` and a 600 changed-line review budget. The task artifact still has no usable `Review Workload Forecast` guard lines; no oversized unrelated slice was attempted. The parent owns runtime-attempt settlement, review lifecycle, verification, and delivery gates. No `gentle-ai sdd-attempt` or review lifecycle command was run.

### Structured status consumed / produced

- `activeChange`: `final-delivery-alignment`.
- `artifactStore`: `openspec`, from the authoritative parent native status.
- `schema`: `spec-driven`.
- `applyState`: `ready` at handoff; this bounded web objective is complete while tasks 5.1 and 5.6 remain open.
- `dependencies`: proposal, all four specs, design, tasks, and cumulative apply-progress were read before work; verify remains blocked by the two unchecked tasks.
- `blockedReasons`: none for the completed web objective; OpenSpec CLI unavailability blocks task 5.1 and missing browser tooling blocks task 5.6.
- `actionContext`: parent-authorized workspace and edit surfaces were respected; unrelated README/backend/web changes and untracked `INICIO_LOCAL.md` were preserved. CodeGraph MCP initialization was unavailable, but the read-only upstream `codegraph status` and `codegraph explore` commands succeeded before filesystem fallback.
- `nextRecommended`: `parent-lifecycle` for this apply work unit; parent-owned lifecycle actions remain deferred.

## Successor apply: `validate-openspec-artifacts`

This bounded apply completed only task 5.1 using the fresh verification actor's exact command evidence. No source, generated-client, backend, mobile, WebSocket, configuration, or documentation files were edited. Task 5.6 remains untouched.

### Completed task and persisted checkbox

- [x] 5.1 — `openspec validate final-delivery-alignment --strict` exited 0 with `Change is valid.`; `openspec status --change final-delivery-alignment` exited 0 and reported schema `spec-driven`, proposal/specs/design/tasks `4/4` complete, and planning artifacts complete.

### TDD Cycle Evidence

This task is an execution-only artifact-validation gate and authorized no production or test edit; a separate RED/GREEN behavior cycle was not applicable.

| Phase | Command/evidence | Result |
| --- | --- | --- |
| RED | No production/test edit was authorized; the gate itself was the required executable check. | Not applicable. |
| GREEN | Fresh verification actor: `openspec validate final-delivery-alignment --strict` | Passed, exit 0; `Change is valid.` |
| TRIANGULATE | Fresh verification actor: `openspec status --change final-delivery-alignment` | Passed, exit 0; schema `spec-driven`, all proposal capabilities and apply-required planning artifacts complete. |
| REFACTOR | No refactor permitted or performed. | Preserved implementation and unrelated working-tree changes. |

### Files and deviations

- `openspec/changes/final-delivery-alignment/tasks.md` — marked only task 5.1 complete.
- `openspec/changes/final-delivery-alignment/apply-progress.md` — appended this cumulative evidence without removing prior progress.
- Design deviation: none.

### Workload / PR boundary

The work-unit boundary is `validate-openspec-artifacts` only. The parent owns runtime-attempt settlement, review lifecycle, verification, and delivery gates; no `gentle-ai sdd-attempt`, review, commit, or push operation was run. The configured delivery strategy remains `exception-ok` with `stacked-to-main`.

### Structured status consumed / produced

- `activeChange`: `final-delivery-alignment`.
- `artifactStore`: `openspec` from the authoritative parent native status.
- `schema`: `spec-driven`.
- `applyState`: `ready` before this work unit; after marking 5.1, 21/22 tasks are complete and 5.6 remains open.
- `dependencies`: proposal, all four specs, design, tasks, and cumulative apply-progress were read before editing; verify and archive remain blocked by task 5.6.
- `blockedReasons`: none for this bounded apply; task 5.6 remains the browser-rehearsal blocker for downstream completion.
- `actionContext`: parent-authorized edits were limited to `tasks.md` and `apply-progress.md`; existing modifications and untracked `INICIO_LOCAL.md` were preserved. No action-context warning was reported.
- `nextRecommended`: `parent-lifecycle` for this completed apply work unit; parent-owned lifecycle actions remain deferred.

### Remaining task

```text
- [ ] 5.6 Rehearse the documented browser demo at delivery viewport sizes; verify it completes in under three minutes, uses Spanish primary text, shows the exact four records/balances/transfers, preserves results after refresh, and introduces no functional or responsive regression.
```

## Successor apply: investigate-expense-auth-401-request-scoped

This bounded remediation corrected the reproducible post-login REST race without changing the mobile client, WebSocket implementation, generated clients, or unrelated delivery work. HTTP requests now receive independent synchronous SQLAlchemy service graphs; dependency getters prefer request state and retain app-state fallback for compatibility. Expense history also renders the server-provided beneficiary names required by the Samaipata walkthrough.

### TDD cycle evidence

| Phase | Evidence | Result |
| --- | --- | --- |
| RED | Fresh Chrome rehearsal after the earlier web-only auth correction | Login returned `200`, but the immediately concurrent expenses request returned `401`; sequential API calls had passed. |
| RED | `npm --prefix web run test -- tests/features/expenses/expenses.test.tsx` after adding the beneficiary-row assertion | `1 failed, 4 passed`; the expense row did not render beneficiaries. |
| RED | `python -m pytest backend/tests/integration/api/test_expense_derived_routes.py -q` before request-scoped wiring | The deterministic concurrent regression observed both requests using the shared session marker. |
| GREEN | HTTP request middleware plus request-state-aware dependency resolution | Each concurrent request receives and closes its own session/service graph; app-state fallback remains available when the middleware is not configured. |
| GREEN | `npm --prefix web run test -- tests/features/expenses/expenses.test.tsx` | `5 passed`, including beneficiary visibility and existing CRUD interactions. |
| TRIANGULATE | `python -m pytest backend/tests -q` | `198 passed`, 1 existing deprecation warning. |
| TRIANGULATE | `python -m ruff check backend` | Passed. |
| TRIANGULATE | `npm --prefix web run test` | `11 files, 63 tests passed`. |
| TRIANGULATE | `npm --prefix web run typecheck` and `npm --prefix web run build` | Both passed; build transformed 135 modules. |
| REFACTOR | `git diff --check` and targeted LSP diagnostics | No whitespace errors and zero diagnostics; only expected Git line-ending normalization warnings were reported. |

### Browser rehearsal evidence

A fresh non-persistent Chrome context used the web origin and Vite `/api` proxy at `1280x800`, then `390x844`. The known out-of-scope WebSocket defect was disabled in the harness only to keep the REST rehearsal isolated; no WebSocket source was changed.

- Anonymous `/api/v1/auth/session` probes returned the expected `401` responses.
- Login returned `200`; the five concurrent protected requests (group, participants, expenses, balances, settlement) all returned `200`, with no post-login failures.
- The protected shell stayed authenticated and showed Spanish primary text.
- Exactly four expenses appeared: `Cabaña` `Bs. 800,00`, `Entradas a El Fuerte` `Bs. 160,00`, `Cena` `Bs. 400,00`, and `Gasolina` `Bs. 240,00`.
- Each expense row displayed Ana, Beto, Carla, and Diego as beneficiaries.
- Balances showed Ana `+Bs. 560,00`, Beto `Bs. 0,00`, Carla `-Bs. 160,00`, and Diego `-Bs. 400,00`.
- Settlement showed `Diego → Ana` `Bs. 400,00`, followed by `Carla → Ana` `Bs. 160,00`.
- Refresh preserved the group, four expenses, balances, settlement, and beneficiary labels.
- Mobile `scrollWidth` equaled `clientWidth` (`390`); no horizontal overflow occurred, and zero `pageerror` events were observed.
- The complete rehearsal finished in approximately four seconds, below the three-minute budget.

### Scope and cleanup

- Source/test surfaces changed: `backend/app/main.py`, `backend/app/api/deps.py`, `backend/app/api/routes/_common.py`, `backend/tests/integration/api/test_expense_derived_routes.py`, `web/src/features/expenses/expenses-panel.tsx`, and `web/tests/features/expenses/expenses.test.tsx`.
- Disposable PostgreSQL, backend, and frontend processes were stopped and the generated `web/dist/`/`.vite/` artifacts were removed. The pre-existing untracked `INICIO_LOCAL.md` was preserved.
- Existing WebSocket, mobile, generated-client, contract, and unrelated worktree changes remain outside this remediation.

### Current state

Task 5.6 is now verified and marked complete in `tasks.md`; all final-delivery task checkboxes are complete. Downstream SDD verification/archive remain parent lifecycle actions.

## Successor apply: remediate-final-verification-blockers

This evidence-only remediation addressed the two verification blockers within the parent-authorized surfaces. The existing seed correction was retained; no task checkbox was changed and no web source/test file was edited.

### TDD Cycle Evidence

| Scope | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- |
| Seed guard | The prior verifier's ephemeral SQLite probe changed stable Ana's name and showed that the pre-correction rerun returned success. This historical failure was not rerun here. | `python -m pytest backend/tests/integration/persistence/test_seed.py -q` — `4 passed in 7.65s`. | The focused suite exercises idempotency, amount corruption, stable-name corruption, and stable-normalization corruption; `python -m ruff check backend/scripts/seed_demo.py backend/tests/integration/persistence/test_seed.py` also passed. | Inspected the existing correction; no further source refactor was needed. |
| Web tasks 3.1–3.4 | Disposable pre-localization baseline experiment below: current desired tests were overlaid on commit `42357cb` production sources. Both focused slices failed against that unlocalized source; this was not a rerun against the mutated current candidate. | The current candidate's previously recorded focused GREEN evidence remains: 3.1–3.2 `18 passed`, 3.3–3.4 `27 passed`. Those gates were not rerun in this bounded remediation. | The two baseline slices covered formatter/balance/settlement plus shell/session/group/participant/expense behavior and produced bounded, task-relevant failures. | Only this progress file was appended; no web implementation or test refactor was performed. |

### Seed correction and focused results

- `backend/scripts/seed_demo.py` was inspected at `_ensure_participant`. The existing stable-ID path compares both `participant.name` and `participant.normalized_name` with the official fixture and calls the existing `_corrupted(...)` helper, which raises `PersistenceCorruptedError`. `seed_demo` rolls back and re-raises that error; it does not overwrite the corrupted row.
- `backend/tests/integration/persistence/test_seed.py` contains the stable-name and stable-normalization corruption regressions, including assertions that the corrupted values remain unchanged.
- Required focused command, run exactly once: `python -m pytest backend/tests/integration/persistence/test_seed.py -q` → `4 passed in 7.65s`.
- Focused lint: `python -m ruff check backend/scripts/seed_demo.py backend/tests/integration/persistence/test_seed.py` → `All checks passed!`.
- Neither seed file required an edit in this successor; the prior worker's correction is the implementation under test.

### Reproducible web RED baseline

Method: create disposable sibling worktree `D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1-sdd-red-baseline` at commit `42357cb`, the pre-localization protected web source; replace only its `web/tests/` directory with the current desired test directory and link the current dependency tree. Production sources in the baseline remained at `42357cb`, so the experiment did not mutate the current candidate or use it as RED evidence.

Exact focused commands and bounded results:

```text
npm --prefix D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1-sdd-red-baseline/web run test -- tests/core/core.test.ts tests/features/balances/balances.test.tsx tests/features/settlement/settlement.test.tsx
3 test files: 15 failed, 4 passed (19 total); exit 1.

npm --prefix D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1-sdd-red-baseline/web run test -- tests/app.test.tsx tests/features/auth/session-provider.test.tsx tests/features/group/group-settings.test.tsx tests/features/participants/participants.test.tsx tests/features/expenses/expenses.test.tsx
5 test files: 26 failed, 2 passed (28 total); exit 1.
```

The first slice failed on the Spanish formatter/signed-balance and balance/settlement presentation expectations. The second failed on Spanish shell/session/group/participant/expense expectations. These executable baseline failures replace the earlier historical `Not rerun` qualification for tasks 3.1–3.4 without claiming a RED run against the already-mutated candidate.

### Cleanup, preservation, and scope

- The disposable worktree was removed with `git worktree remove --force`; the final worktree list contained only the main repository. No disposable files remain.
- `INICIO_LOCAL.md` and all unrelated worktree changes were preserved. Only `openspec/changes/final-delivery-alignment/apply-progress.md` changed in this successor.
- No task, spec, design, verify-report, mobile, WebSocket, generated-client, or web file was edited. No `gentle-ai sdd-attempt` or review command was run; the parent retains the supplied attempt token and owns settlement.
- Design deviation: none; this successor added verification evidence only and made no production or test-source change.

### Workload / PR boundary and structured status

The work-unit boundary is `remediate-final-verification-blockers`, limited to seed evidence and a disposable web RED baseline. The configured delivery strategy remains `exception-ok` with `stacked-to-main`; no broader slice or task-checkbox update was authorized.

Structured status consumed: `activeChange: final-delivery-alignment`, `artifactStore: openspec` (repo-local artifacts authoritative for this run), `schema: spec-driven`, original task progress `22/22`, and `actionContext` limited by the parent to the three allowed edit surfaces. The original change is all-done at the task level; this is a parent-authorized evidence successor, not a new task implementation. Action-context warning: no native status command was needed for this bounded continuation; the parent supplied the authoritative runtime context.

### Remaining verification handoff

The parent should rerun independent verification against the unchanged implementation plus this cumulative evidence, then settle the already-acquired attempt. The bounded browser WebSocket caveat and any other non-critical verification warnings remain parent-owned follow-ups; no new product work is claimed here. Next recommendation: `parent-lifecycle`.
