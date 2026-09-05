```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:32f24e34f6ba3005a3957e6a7694473b5ce4ad1e6a8feb506a0370bf1a2deeec
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 17/17
scenarios: 21/21
test_command: python -m pytest backend/tests -q
test_exit_code: 0
test_output_hash: sha256:202e7542c8321b7d8fb6db235a7eb71a7c611479fb913c249f3913d8f8432a54
build_command: npm --prefix web run build
build_exit_code: 0
build_output_hash: sha256:b840a4517af0d96753ae8f2374a22419092886759117b4571340673c1115e878
```

# Verification Report — `final-delivery-alignment`

## Verdict

**PASS WITH WARNINGS — no CRITICAL blocker remains.**

All 17 requirements, 21 scenarios, and 22 implementation tasks are covered. The current candidate passed the backend, web, lint, build, contract-drift, OpenSpec, and focused seed gates. The cumulative evidence also covers disposable PostgreSQL operation and the under-three-minute browser rehearsal. The browser rehearsal deliberately isolated the documented out-of-scope WebSocket defect; this report does not claim a live browser WebSocket pass.

## Structured SDD status and action context

Status was consumed from the authoritative repo-local OpenSpec status before verification:

```yaml
changeName: final-delivery-alignment
artifactStore: openspec
schema: spec-driven
artifacts:
  proposal: done
  specs: done
  design: done
  tasks: done
  applyProgress: done
  verifyReport: done
applyState: all_done
taskProgress:
  total: 22
  complete: 22
  remaining: 0
  unchecked: []
dependencies:
  proposal: all_done
  specs: all_done
  design: all_done
  tasks: all_done
  apply: all_done
  verify: ready
  archive: blocked
nextRecommended: verify
actionContext:
  mode: repo-local
  workspaceRoot: repository root
  allowedEditRoots:
    - repository root
  permittedWrite: openspec/changes/final-delivery-alignment/verify-report.md
```

The pre-existing `archive: blocked` status was caused by the previous report lacking the required machine envelope. This report supplies that envelope. Implementation ownership and all task files are inside the authoritative repository workspace. This verification wrote only the permitted report artifact; product source, tests, tasks, proposal/spec/design, apply-progress, mobile, WebSocket, generated clients, and unrelated files were not edited.

## Spec coverage

| Capability | Verdict | Evidence |
| --- | --- | --- |
| `documentation-governance` | PASS | `AGENTS.md`, `openspec/project-context.md`, and `docs/sdd-evolution.md` define current FastAPI/PostgreSQL authority, integer-cent monetary rules, protected sessions and server-derived roles, invalidation-only WebSocket behavior, generated-client boundaries, SDD precedence, and independent ownership. Historical artifacts remain linked and preserved. |
| `delivery-readiness` | PASS | `README.md`, setup docs, `.env.example` key-only scan, generator docs, and OpenSpec artifacts provide reproducible setup, migration, seed, startup, demo, and gate instructions without usable credentials. Same-origin API guidance and non-authoritative `VITE_GROUP_ID` are explicit. |
| `demo-readiness` | PASS | Current seed/tests verify the four official records, exact contributors and beneficiaries, idempotency, stable identities, fail-closed corruption handling, balances, zero sum, and ordered settlement. Cumulative host evidence covers PostgreSQL reset/migrate/seed-twice/startup/health and protected API results. |
| `web-presentation` | PASS | Current handwritten web code and passing Vitest suite cover Spanish protected presentation, accessibility labels, roles/policies, integer-only decimal-comma formatting, signed balances, settlement arrows, CRUD, auth/session, refresh behavior, and responsive REST presentation. Generated clients and preserved API-base/WebSocket paths are unchanged. |

### Acceptance-criterion findings

- **Official fixture:** `Cabaña` 80,000 paid by Ana; `Entradas a El Fuerte` 16,000 paid by Ana; `Cena` 40,000 paid by Beto; `Gasolina` 24,000 paid by Carla. Every expense has Ana, Beto, Carla, and Diego as beneficiaries; Diego contributes to none.
- **Derived result:** Ana `+56,000`, Beto `0`, Carla `-16,000`, Diego `-40,000` cents; total is exactly zero. Settlement order is Diego → Ana `40,000`, then Carla → Ana `16,000` cents.
- **Seed safety:** current `_ensure_participant` validates stable group, name, and `normalized_name`; the focused regressions assert `PersistenceCorruptedError` and unchanged corrupted values for both name and normalization. The idempotency regression verifies zero creations and unchanged password hashes on rerun.
- **Spanish UI:** current tests assert `+Bs. 560,00`, `Bs. 0,00`, negative values, `Le deben`, `Debe`, `Saldado`, and the ordered rows `Diego → Ana: Bs. 400,00` and `Carla → Ana: Bs. 160,00`.
- **Scope preservation:** no tracked diff exists in the OpenAPI contract, generated TypeScript/Dart trees, mobile tree, backend mutation-invalidation test, WebSocket implementation, API-base resolver, Vite proxy, or preserved config/WebSocket regression tests.

## Task completion

The authoritative `tasks.md` contains **22 checked implementation tasks and no unchecked implementation task markers**:

- 1.1–1.3: checked
- 2.1–2.3: checked
- 3.1–3.5: checked
- 4.1–4.5: checked
- 5.1–5.6: checked

**Unchecked implementation task lines:** none.

Current files and executable evidence were cross-checked rather than treating checkboxes as sufficient. The full backend suite includes the seed, recovery, acceptance, mathematical, persistence, authorization, rename, and API coverage. The full web suite includes the preserved configuration and WebSocket tests plus auth, API, participant, expense, balance, and settlement coverage.

## Verification commands and results

Commands were run from the repository root unless noted. Exit codes are reported exactly.

| Command | Result |
| --- | --- |
| `python -m pytest backend/tests/integration/persistence/test_seed.py -q` | **PASS**, exit 0 — 4 passed in 15.05s |
| `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q` | **PASS**, exit 0 — 5 passed, 1 existing deprecation warning |
| `python -m pytest backend/tests -q` | **PASS**, exit 0 — 200 passed, 1 existing Starlette/httpx deprecation warning |
| `python -m ruff check backend` | **PASS**, exit 0 — all checks passed |
| `npm --prefix web run test` | **PASS**, exit 0 — 11 files, 63 tests passed; preserved config 12 and WebSocket 2 tests passed |
| `npm --prefix web run typecheck` | **PASS**, exit 0 |
| `npm --prefix web run build` | **PASS**, exit 0 — 135 modules transformed |
| `python -m backend.scripts.check_contract_drift --cwd .` | **PASS**, exit 0 — contract and generated clients are drift-free; temporary outputs cleaned |
| `openspec validate final-delivery-alignment --strict` | **PASS**, exit 0 — change is valid |
| `openspec status --change final-delivery-alignment` | **PASS**, exit 0 — schema `spec-driven`, planning artifacts 4/4 complete |
| `git diff --check` | **PASS**, exit 0 — no whitespace errors; expected line-ending warnings only |
| Preservation diff for contract/generated/mobile/WebSocket/config paths | **PASS**, exit 0 — no tracked changes |

The focused seed command was rerun in this verification; it was not treated as static evidence. The exact cumulative PostgreSQL and browser evidence is additionally recorded in `apply-progress.md`; those operations were not repeated because the bounded operational evidence had already been completed and cleaned up.

## Strict TDD compliance

Strict TDD is active. `apply-progress.md` contains multiple `TDD Cycle Evidence` tables, and the remediation now supplies executable RED evidence for web tasks 3.1–3.4.

| Check | Result | Details |
| --- | --- | --- |
| TDD evidence table present | PASS | Backend, web, contract, request-scoped, and remediation evidence tables are present. Execution-only gates explicitly identify RED as not applicable. |
| Seed RED/GREEN evidence | PASS | Focused seed regressions cover source corruption and idempotent behavior; current focused execution is 4 passed. |
| Web 3.1–3.4 RED evidence | PASS | A disposable sibling worktree at production-source revision `42357cb` (the pre-localization source) received only the desired current `web/tests/` overlay. The formatter/balance/settlement slice exited 1 with 15 failed and 4 passed; the shell/session/group/participant/expense slice exited 1 with 26 failed and 2 passed. The evidence explicitly states it was not a RED run against the mutated current candidate. |
| Web 3.1–3.4 GREEN evidence | PASS | The current candidate’s focused GREEN evidence is 18 passed for tasks 3.1–3.2 and 27 passed for tasks 3.3–3.4; the full current suite is 63 passed. |
| Test files cross-referenced | PASS | Reported backend and web test files exist and the relevant current suites pass. |
| Assertion quality | PASS with warnings | No tautologies, ghost loops, smoke-only tests, CSS-only assertions, or type-only assertions standing alone were found. Three low-risk implementation-coupled assertions remain warnings below. |
| Cleanup/preservation | PASS | The disposable baseline worktree was removed; `INICIO_LOCAL.md` remains present; current `git worktree list` contains only the main repository. |

**TDD compliance: PASS.** The RED baseline was bounded, executable, task-relevant, and honestly separated from the already-mutated candidate; it is not being presented as current-candidate RED evidence.

## Test-layer distribution

| Layer | Evidence | Tools |
| --- | --- | --- |
| Unit/domain | Backend mathematical/domain tests and web cents formatter tests within the current suites | pytest, Vitest |
| Integration | Backend persistence/API tests and web Testing Library auth, CRUD, presentation, and transport tests | pytest, Vitest + Testing Library |
| Acceptance/E2E-like | Backend DA-01–DA-07 acceptance tests; cumulative fresh Chrome rehearsal for REST/UI and responsive behavior | pytest, Chrome evidence |
| Total | Backend 200 tests and web 63 tests passed in this verification | pytest, Vitest |

Coverage analysis was skipped; no configured coverage tool was available in the cached project capabilities. This is informational and non-blocking.

## Assertion quality findings

| File | Finding | Severity |
| --- | --- | --- |
| `backend/tests/integration/api/test_expense_derived_routes.py` | `expenses.mutation_calls == 3` checks a test-double call count in addition to real response/source-state assertions. | WARNING |
| `web/tests/features/balances/balances.test.tsx` | Query/refetch `toHaveBeenCalledTimes(...)` assertions are implementation-boundary checks supporting sequencing coverage. | WARNING |
| `web/tests/features/auth/session-provider.test.tsx` | Logout cleanup includes mock call-count and React Query cache-size assertions; behavior assertions are also present. | WARNING |

**Assertion quality: 0 CRITICAL, 3 WARNING.** No assertion is vacuous, and all audited tests call production code, render through the tested boundary, or exercise a real request path.

## Review workload and PR boundary

`tasks.md` still lacks a `Review Workload Forecast` section, so workload conformance is less auditable. `apply-progress.md` records `exception-ok`, `stacked-to-main`, a 600 changed-line review budget, and bounded work-unit scopes. No `size:exception` was used or claimed. The implementation and remediation stayed within final-alignment delivery scope; no mobile, WebSocket implementation, generated-client, contract, API-base, or unrelated ownership was expanded.

**WARNING:** Add the forecast in the owning planning workflow if the repository requires it for archive-level auditability. This is not a product or verification blocker because the configured delivery strategy and bounded work-unit boundaries are explicit.

## Bounded deviations and risks

1. **WARNING — browser WebSocket coverage is intentionally bounded.** The fresh browser rehearsal disabled the known out-of-scope WebSocket defect to isolate REST/UI behavior. Backend invalidation (5 tests) and web WebSocket (2 tests) pass, but no live browser WebSocket success is claimed. No WebSocket source was changed.
2. **WARNING — existing dependency warning.** Backend tests emit one pre-existing Starlette/httpx deprecation warning; it does not fail a gate.
3. **WARNING — workload forecast absent.** The configured chain strategy and bounded work units are recorded, but the task artifact does not include the requested forecast section.
4. **INFO — coverage unavailable.** No coverage command was run because no configured coverage tool was available; required test/build gates passed.

No CRITICAL blockers remain. The disposable baseline worktree is absent, `INICIO_LOCAL.md` was preserved, and no production-data mutation was performed by this verification.

## Final recommendation

**PASS WITH WARNINGS.** The change is ready for the parent-owned archive lifecycle, subject to preserving the documented WebSocket caveat and the non-blocking workload/coverage notes. No implementation remediation is requested by this verification.
