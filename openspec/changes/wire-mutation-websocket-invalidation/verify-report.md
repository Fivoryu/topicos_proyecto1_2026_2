# Verification Report: wire-mutation-websocket-invalidation

## Verdict

**FAIL — one CRITICAL strict-TDD evidence blocker.**

The implementation and fresh backend verification commands are green. However, strict TDD is active and `apply-progress.md` does not contain the mandatory `TDD Cycle Evidence` table; it contains prose bullets instead. Archive is not ready until that evidence is reconciled by the parent/orchestrator.

## Structured SDD status and action context

Status was read from the native OpenSpec status engine before verification:

```yaml
schemaName: spec-driven
changeName: wire-mutation-websocket-invalidation
artifactStore: openspec
planningHome:
  root: D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1\openspec
  changesDir: openspec/changes
changeRoot: D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1\openspec\changes\wire-mutation-websocket-invalidation
artifacts:
  proposal: done
  specs: done
  design: done
  tasks: done
  applyProgress: done
  verifyReport: missing before this phase
applyState: all_done
taskProgress:
  total: 10
  complete: 10
  remaining: 0
  unchecked: []
dependencies:
  apply: all_done
  verify: ready
  archive: blocked
actionContext:
  mode: repo-local
  workspaceRoot: D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
  allowedEditRoots:
    - D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
nextRecommended: verify
isNonAuthoritative: false
```

The selected candidate scope was preserved. `mobile/README.md` remains untracked and excluded. `cuentas-claras-mvp` has no status changes; no web, generated-client, or other mobile files changed.

`openspec/config.yaml` currently declares project defaults of `artifact_store: both`, `delivery_strategy: exception-ok`, and `chain_strategy: stacked-to-main`, while the native status and this change's artifacts use `openspec` and `ask-on-risk`. Native status and the delegated phase context were treated as authoritative for this verification; this metadata mismatch is a WARNING for future orchestration, not an implementation blocker.

## Spec coverage

| Requirement / scenario | Result | Evidence |
| --- | --- | --- |
| Invalidation-only WebSocket frame | PASS | Existing `GroupEventBroadcaster.FRAME` remains exactly `{"type": "data_changed"}`; existing `test_ws_events.py` verifies no monetary, participant, role, or transfer fields. The focused mutation test receives the same exact frame after REST mutations. |
| Authenticated, group-scoped WebSocket access | PASS | Existing `events.py` validates origin, session, membership, and authorization before subscribing; existing handshake tests remain green. |
| Shared post-commit publisher wiring | PASS | `main.py:116-135` obtains one `app.state.broadcaster` reference and injects it into `ParticipantService`, `ExpenseService`, and `GroupService`. The focused composition-root test asserts object identity for all three services. |
| Group policy update publishes after commit | PASS | `GroupService` retains its existing post-context publication at `group_service.py:102-115`; focused REST test receives one frame after a successful policy update. `group_service.py` is unchanged in the candidate diff. |
| Participant add/rename/archive/reactivate/delete publishes once after commit | PASS by implementation inspection; partial integration coverage | `participant_service.py` publishes once after each successful mutation at lines 89-90, 100-101, 113-114, 133-134, and 168-169. The focused REST test directly exercises add; rename/archive/reactivate/delete are not individually exercised through REST in the new file. |
| Expense create/edit/delete publishes once after commit | PASS by implementation inspection; partial integration coverage | `expense_service.py` publishes once after create, edit, and delete at lines 125-126, 170-171, and 195-196. The focused REST test directly exercises create; edit and delete are not individually exercised through REST in the new file. |
| Failed validation/authorization/CSRF/transaction publishes nothing | PASS by control flow; partial test coverage | Publication is after the transaction context, so raised validation, authorization, and transaction errors skip it. The focused suite directly verifies CSRF rejection and commit failure; it does not add an invalid-validation or unauthorized subscriber assertion. |
| Group isolation | PASS for exercised mutation path | A group-one WebSocket receives one frame for each policy, participant-add, and expense-create REST mutation; the group-two probe remains empty. |
| Publisher/subscriber failure does not fail committed REST work | PASS | Existing broadcaster behavior catches subscriber queue failures and removes stale subscribers; `test_broadcaster_failure_does_not_break_committed_rest_work` remains green in the full suite. |
| No API/client/schema changes | PASS | Git status/diff shows only the three intended Python implementation files and the new focused Python test, plus the excluded `mobile/README.md` and OpenSpec artifacts. |

The main coverage gap is test-layer triangulation for all named participant and expense mutation variants. The production hooks themselves are present and correctly positioned, but the new integration file does not prove every variant end-to-end.

## Task completion

All implementation task markers are checked:

- T-01: `[x]` focused REST-to-WebSocket integration test exists and passes.
- T-02: `[x]` participant and expense post-commit hooks are present for every listed operation.
- T-03: `[x]` composition-root injection and identity assertion are present.
- Final acceptance checklist: all `[x]`.

**Unchecked implementation task lines:** none. A scan for `^\s*- \[ \]` returned no matches.

T-01's checked task text calls for invalid, CSRF-rejected, and transaction-failed negative cases. The new test directly covers CSRF and transaction failure, but no explicit invalid-validation negative case is present; this is a WARNING-level test coverage gap, not an unchecked task.

## Implementation and scope findings

- `ParticipantService` and `ExpenseService` accept an optional `InvalidationPublisher`, preserving existing constructor compatibility.
- Every new publisher call is outside the corresponding `with self._transaction()` block, so the call occurs only after normal context exit/commit.
- `GroupService`'s existing post-commit behavior was not modified.
- `_wire_request_services()` uses the single app-scoped broadcaster; no second broadcaster was created.
- The WebSocket endpoint continues to subscribe to `app.state.broadcaster`, preserving one subscription registry.
- No source files outside the assigned four Python implementation/test files were changed. `mobile/README.md` remains excluded and untracked.

## Verification commands

Commands were run fresh exactly as requested:

```text
python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q
.....                                                                    [100%]
5 passed, 1 warning in 3.50s
```

```text
python -m pytest backend/tests -q
........................................................................ [ 36%]
........................................................................ [ 73%]
...................................................                      [100%]
195 passed, 1 warning in 24.30s
```

```text
python -m ruff check backend
All checks passed!
```

The warning is the existing Starlette deprecation warning from `fastapi.testclient`/`httpx`; it did not fail either test run.

## Strict TDD compliance

Strict TDD is active. The required artifact check found:

- `apply-progress.md:16-23` has a `TDD and verification evidence` heading and RED/GREEN/TRIANGULATE/REFACTOR prose.
- **CRITICAL:** it does not contain a `TDD Cycle Evidence` table with per-task RED, GREEN, TRIANGULATE, SAFETY NET, and REFACTOR columns.
- The reported focused test file exists at `backend/tests/integration/api/test_ws_mutation_invalidation.py`.
- The focused test file currently passes: 5 tests passed.
- Reported full-suite and Ruff results are reproduced above.
- Test layer: one new integration test file with five test functions, using FastAPI `TestClient` and WebSocket interactions; no browser E2E tool is used.
- Coverage analysis skipped — no coverage tool was detected in the cached project capabilities.
- Type-checker analysis skipped — no type checker was listed in the cached project capabilities. Ruff passed.

**TDD compliance:** CRITICAL failure because the mandatory evidence table is absent, despite green current tests.

## Assertion quality

**Assertion quality: ✅ All assertions verify real behavior.**

The new test assertions check REST status codes, exact WebSocket frames, group isolation, empty negative-control queues, commit-before-publish ordering, publication suppression after commit failure, and exact shared broadcaster identity. No tautologies, ghost loops, type-only assertions, smoke-only tests, CSS/implementation-detail assertions, or mock-heavy assertions were found. The empty queue assertions are meaningful negative controls paired with positive delivery assertions.

## Quality metrics

- **Linter:** ✅ `python -m ruff check backend` — no errors.
- **Type checker:** ➖ Not detected; skipped.
- **Coverage:** ➖ Not detected; skipped.

## Review workload and PR boundary

- Candidate accounting observed: **479 additions + 5 deletions = 484 changed lines**, including the 438-line new integration test.
- This is below the change's explicit 600-line SDD review budget.
- Tasks forecast one backend work unit; no chained PR was recommended and no `size:exception` was recorded or needed under the 600-line change budget.
- Scope matches the assigned boundary: backend service hooks, composition-root wiring, and focused backend integration coverage only.
- Review transport previously returned `immutable_review_transport_unsupported`. No review lifecycle was invoked and no review approval or receipt is claimed.

## RDD evidence

- `rdd_mode`: review transport unsupported per parent context; no review lifecycle invoked.
- `issue_pr`: no issue or PR operation performed in this verify phase.
- `causal_invariant`: successful group-scoped source mutations publish one invalidation only after commit; notification failure must not affect committed REST data.
- `operator_flows`: protected group policy update, participant add, expense create, CSRF rejection, commit failure, and WebSocket subscription isolation.
- `journey_runtime_evidence`: focused REST/WebSocket integration run passed; full backend suite passed; Ruff passed.
- `changed_line_budget`: 484 total changed lines, below the configured 600-line change budget.
- `rollback`: revert the three service/composition changes and remove the focused test; no schema/client rollback is required.
- `unresolved_authority_decisions`: parent must reconcile the missing strict-TDD evidence table before archive; no review decision was made.

## Exact blockers and next action

1. **CRITICAL:** Add/reconcile the required per-task `TDD Cycle Evidence` table in `apply-progress.md` through the owning apply/orchestration path. This verify phase did not edit that artifact.
2. **WARNING:** Consider adding explicit invalid-validation and all-variant REST-to-WebSocket cases (participant rename/archive/reactivate/delete and expense edit/delete), or record why existing implementation inspection is sufficient for this slice.
3. **WARNING:** Reconcile the project config's `both`/`exception-ok`/`stacked-to-main` defaults with the native OpenSpec `ask-on-risk` status if those settings are intended to govern future phases.

**Next recommended action:** `remediate` the strict-TDD evidence blocker, then rerun verification before archive.
