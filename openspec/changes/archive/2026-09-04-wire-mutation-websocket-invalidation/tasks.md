# Tasks: Wire mutation WebSocket invalidation

## Work-unit and delivery boundary

- Change: `wire-mutation-websocket-invalidation`
- Scope: backend application publisher hooks, composition-root wiring, and focused REST → WebSocket integration tests only.
- Artifact store: OpenSpec.
- Execution: automatic SDD flow; strict TDD.
- Delivery: `ask-on-risk`; one backend work unit, expected below the 600 changed-line review budget; no chained PR or size exception unless native accounting requires it.
- Out of scope: `cuentas-claras-mvp` artifacts, OpenAPI/generated clients, web, mobile, `mobile/README.md`, auth/authorization/CSRF/origin rules, database schema, monetary/domain algorithms, and WebSocket frame shape.

## Task list

### T-01 — Add mutation-to-WebSocket integration coverage (RED → GREEN → TRIANGULATE → REFACTOR)

- [x] Add `backend/tests/integration/api/test_ws_mutation_invalidation.py` with a shared `GroupEventBroadcaster`, authorized WebSocket subscribers for at least two groups, and REST mutation calls through the existing protected route surface. The test must exercise at least one successful group-policy, participant, and expense mutation, assert one exact `{"type": "data_changed"}` frame only on the mutated group, and prove the unrelated group receives no frame. Add failure cases proving invalid/CSRF-rejected/transaction-failed mutations publish nothing. Keep existing authorization, CSRF, and origin fixtures; do not manually call `broadcaster.publish()` as the success trigger.
- **Target:** `backend/tests/integration/api/test_ws_mutation_invalidation.py`.
- **Spec refs:** `specs/api/spec.md` WebSocket invalidation-only channel and shared post-commit wiring requirements.
- **Design refs:** `design.md` Testing and Runtime sequence.
- **TDD evidence:** write the focused test first and run `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q`; RED must demonstrate missing mutation delivery before implementation. GREEN, TRIANGULATE, and REFACTOR use the same focused command plus the recorded full backend suite.
- **Rollback:** remove this new integration test only; no existing test or client is changed.

### T-02 — Add post-commit publisher hooks to mutation services (RED → GREEN → TRIANGULATE → REFACTOR)

- [x] Extend `ParticipantService` and `ExpenseService` with an optional `InvalidationPublisher` dependency. After the existing transaction context exits successfully, publish exactly once with the mutated `group_id` for every applicable mutation: participant add, rename, archive, reactivate, delete; expense create, edit, delete. Never publish before commit or on validation, authorization, CSRF, or transaction failure. Preserve return values, rollback behavior, and compatibility with existing unit-test constructors. Keep `GroupService`'s existing post-commit behavior unchanged.
- **Target:** `backend/app/application/participant_service.py`, `backend/app/application/expense_service.py`, existing unit tests as needed for focused service-level assertions.
- **Spec refs:** `specs/api/spec.md` shared post-commit mutation publisher wiring.
- **Design refs:** `design.md` Proposed component changes and failure sequence.
- **TDD evidence:** the T-01 RED test remains the primary safety net; add or extend narrow service tests for commit ordering and no-publish-on-error, then run focused and full backend commands.
- **Rollback:** revert only the optional constructor parameters, post-commit calls, and their tests; all source mutation behavior remains otherwise unchanged.

### T-03 — Inject the shared app-scoped broadcaster (RED → GREEN → TRIANGULATE → REFACTOR)

- [x] Update `_wire_request_services()` to pass the existing `app.state.broadcaster` to `GroupService`, `ParticipantService`, and `ExpenseService` as the `InvalidationPublisher`. Add a composition-root assertion in the focused integration suite that all three services reference the exact same broadcaster instance consumed by the WebSocket route. Do not instantiate another broadcaster or alter dependency providers, authorization, CSRF, origin checks, or routes.
- **Target:** `backend/app/main.py`, `backend/tests/integration/api/test_ws_mutation_invalidation.py`.
- **Spec refs:** `specs/api/spec.md` production service graph scenario.
- **Design refs:** `design.md` Composition root and Compatibility and safety.
- **TDD evidence:** after T-02, run the focused integration suite to turn the wiring assertion GREEN; triangulate same-group isolation, unrelated-group silence, and all mutation families; rerun the full backend suite during REFACTOR.
- **Rollback:** revert the three constructor arguments and the composition assertion; leave the app-scoped broadcaster and WebSocket endpoint intact.

## Final acceptance checklist

- [x] `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q` passes with REST-triggered delivery.
- [x] `python -m pytest backend/tests -q` passes.
- [x] `python -m ruff check backend` passes.
- [x] Touched Python files have no blocking primary diagnostics.
- [x] Successful group, participant, and expense mutations publish one exact invalidation after commit; failed mutations publish none.
- [x] Group isolation is proven: unrelated subscribers receive no frame.
- [x] `cuentas-claras-mvp` files remain unchanged; generated/client/mobile files remain untouched; `mobile/README.md` remains untracked.
