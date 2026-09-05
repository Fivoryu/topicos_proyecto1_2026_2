# Design: Wire mutation WebSocket invalidation

## Context and constraints

The backend already has a `GroupEventBroadcaster` with a group-keyed subscription registry and a fixed invalidation-only frame. `events.py` authenticates the WebSocket handshake, verifies group membership and origin, and subscribes to `app.state.broadcaster`. The missing connection is between that adapter and the application mutation services.

The existing `SqlAlchemyUnitOfWork.__exit__` commits when the service's transaction context exits normally and rolls back on an exception. Therefore the publisher call belongs after the `with self._transaction()` block, never inside it. The broadcaster is best-effort and already isolates queue failures.

## Proposed component changes

1. **Composition root (`backend/app/main.py`)**
   - Read the existing app-scoped `GroupEventBroadcaster`.
   - Pass that same object as `invalidation_publisher` to `GroupService`, `ParticipantService`, and `ExpenseService`.
   - Do not create a second broadcaster, alter dependency resolution, or change the WebSocket route.

2. **Participant application service**
   - Add an optional `invalidation_publisher` constructor dependency so existing unit-test fakes remain source-compatible.
   - For `add`, `archive`, `reactivate`, `delete`, and `rename`, finish the current transaction first, then call `publish(group_id)` once.
   - Return the existing result and preserve all validation/authorization behavior. A raised exception skips the post-context call.

3. **Expense application service**
   - Add the same optional publisher dependency.
   - For `create`, `edit`, and `delete`, call `publish(group_id)` only after the transaction context successfully completes its commit.
   - Keep zero-sum validation and rollback inside the transaction; do not emit on any failure.

4. **Group application service**
   - Keep its existing post-commit publisher behavior unchanged; only wire the shared dependency at the composition root.

5. **Testing**
   - Preserve the existing frame/handshake/failure tests.
   - Add a focused integration test that mounts the actual mutation route functions with service instances and a shared `GroupEventBroadcaster`, connects authorized WebSocket subscribers for two groups, performs successful REST mutations, and reads only the expected group frame.
   - Exercise at least one mutation from each service family; parameterize participant and expense operations where the test fixture can prove the same contract without duplicating setup.
   - Add negative cases for a validation/CSRF failure and a transaction failure: assert no frame and unchanged failure behavior.
   - Assert the frame is exactly `{"type": "data_changed"}` and that the unrelated group subscription has no frame (use a bounded non-blocking queue check, not a hanging receive).
   - Add a composition-root assertion that all three services reference the exact same app-scoped broadcaster after `_wire_request_services()`.

## Runtime sequence

```text
REST request
  → CSRF + authenticated group dependency
  → application service validates and opens UoW
  → source rows mutate / derived invariant verifies
  → UoW exits successfully and commits
  → service calls shared InvalidationPublisher.publish(group_id)
  → GroupEventBroadcaster enqueues {"type": "data_changed"}
  → matching WebSocket client receives frame and refetches REST
```

Failure path:

```text
REST request
  → validation/auth/CSRF/UoW failure
  → exception or rejection
  → no successful service return
  → publisher call is skipped
  → no WebSocket frame
```

Notification failure path:

```text
commit succeeds
  → broadcaster.publish(group_id)
  → subscriber queue may fail
  → broadcaster drops stale subscriber
  → REST result remains successful and committed
```

## Compatibility and safety

- `InvalidationPublisher` remains the existing application port; no new event schema is introduced.
- The publisher dependency is optional for isolated unit tests, but production wiring always supplies the app-scoped adapter.
- Publish calls carry only the existing group identifier; authorization still happens before mutation and WebSocket handshake.
- No API schema, OpenAPI document, generated client, database model, CSRF rule, origin rule, or client code changes are permitted.

## Verification strategy

Strict TDD uses a focused integration test as the RED target, followed by the backend full suite for GREEN and REFACTOR. Triangulation covers all mutation families, group isolation, failed mutations, commit ordering, exact frame shape, and subscriber failure. The final verify run uses the detected `python -m pytest backend/tests -q` command plus static checks appropriate to the touched Python files.

## Rollback boundary

Revert the composition-root injection, the optional service dependencies/post-commit calls, and the new integration test. Existing WebSocket endpoint/frame behavior remains intact; only automatic mutation notifications are removed.
