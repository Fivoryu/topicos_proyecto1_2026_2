# Proposal: Wire mutation WebSocket invalidation

## Summary

Repair the backend runtime path from successful group-scoped mutations to the existing group WebSocket broadcaster. The endpoint and broadcaster already enforce authenticated, group-scoped, invalidation-only delivery, but the request-service wiring does not connect the broadcaster to the mutation services, and participant/expense services have no publication hook.

## Problem

`backend/app/main.py` creates one `GroupEventBroadcaster`, while `_wire_request_services()` constructs `GroupService`, `ParticipantService`, and `ExpenseService` without a shared invalidation publisher. Consequently, the existing WebSocket tests prove frame shape and manually invoked broadcaster delivery, but a successful REST mutation does not notify connected clients. This leaves the implementation inconsistent with the existing `cuentas-claras-mvp` API specification and design.

## Goals

- Connect the shared broadcaster to all applicable group-scoped mutation services.
- Publish one group-scoped `data_changed` signal only after a successful transaction commit.
- Cover group policy updates, participant add/rename/archive/reactivate/delete, and expense create/edit/delete.
- Prove through focused end-to-end API/WebSocket tests that a successful REST mutation reaches the matching group channel and never reaches another group channel.
- Preserve the existing invalidation-only frame (`{"type": "data_changed"}`), authorization, membership isolation, CSRF, and origin checks.

## Non-goals

- Do not change the `cuentas-claras-mvp` change, its tasks, specs, verify report, or archive state.
- Do not change OpenAPI, generated clients, web, mobile, `mobile/README.md`, authentication, authorization rules, database schema, or monetary calculations.
- Do not add event payload data, optimistic client behavior, retries, or a second source of truth.
- Do not publish for failed validation, rejected authorization/CSRF, or rolled-back transactions.

## Product and technical constraints

- FastAPI remains the sole authorization and monetary authority.
- `GroupEventBroadcaster` remains best-effort: subscriber failures must not roll back committed source data or fail the REST response.
- The publisher call must occur after the unit-of-work context has successfully exited, matching the existing post-commit contract.
- The same publisher instance must serve all services in a process so each group has one coherent subscription registry.
- The correction is one small backend work unit intended to remain below the configured 600 changed-line review budget; no size exception or chained PR is expected unless native accounting says otherwise.

## Acceptance outcomes

1. The production service graph injects the application publisher into `GroupService`, `ParticipantService`, and `ExpenseService`.
2. Each successful applicable mutation emits exactly one `data_changed` notification for its `group_id` after commit.
3. Invalid, unauthorized, CSRF-rejected, or failed mutations emit no notification and preserve existing failure behavior.
4. A subscriber for group A receives group A notifications, while a subscriber for group B receives none for group A mutations.
5. The WebSocket frame remains exactly `{"type": "data_changed"}` and contains no monetary, participant, role, or transfer data.
6. Existing backend tests remain green, and the new focused integration tests exercise REST mutation → WebSocket delivery rather than manually calling `publish()`.

## Rollback

Revert the single implementation/test work unit. The existing WebSocket endpoint and broadcaster can remain available; without the wiring hook, REST behavior returns to the prior manual-publish-only state. No database migration or client rollback is required.

## Delivery and evidence

The new change uses the already resolved OpenSpec artifact store and automatic SDD execution with `ask-on-risk` delivery. Strict TDD evidence will record RED, GREEN, TRIANGULATE, and REFACTOR runs using the detected backend pytest commands. Runtime-bearing apply and verify attempts must acquire and settle through the native `gentle-ai sdd-attempt` ledger before launch.
