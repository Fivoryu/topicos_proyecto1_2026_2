# Apply progress: wire-mutation-websocket-invalidation

## Status

- Implementation complete for T-01, T-02, and T-03.
- The closed `cuentas-claras-mvp` change was not modified.
- `mobile/README.md` remains untouched and untracked; it is excluded from the intended candidate.

## Implemented

- Added post-commit `InvalidationPublisher` hooks to participant add, rename, archive, reactivate, and delete operations.
- Added post-commit publisher hooks to expense create, edit, and delete operations.
- Injected the single app-scoped `GroupEventBroadcaster` into group, participant, and expense services from `_wire_request_services()`.
- Added REST-to-authorized-WebSocket integration coverage for group policy, participant, and expense mutations, exact invalidation frames, group isolation, CSRF rejection, commit ordering, commit failure, and composition-root identity.

## TDD and verification evidence

- RED: focused test run before implementation failed because `ParticipantService` did not accept the publisher dependency and the composition root supplied no publisher.
- GREEN/TRIANGULATE/REFACTOR: `python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q` → 5 passed, 1 warning.
- Full suite: `python -m pytest backend/tests -q` → 195 passed, 1 warning.
- Static check: `python -m ruff check backend` → all checks passed.
- Primary Python LSP diagnostics for touched Python files are clean; auxiliary import findings are the existing backend project-root configuration mismatch and do not affect pytest or runtime imports.

## Changed implementation files

- `backend/app/application/participant_service.py`
- `backend/app/application/expense_service.py`
- `backend/app/main.py`
- `backend/tests/integration/api/test_ws_mutation_invalidation.py`
