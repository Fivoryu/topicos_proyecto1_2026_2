# API mutation invalidation delta

## MODIFIED Requirements

### Requirement: WebSocket invalidation-only channel

The system MUST expose one WebSocket channel per group that sends only an invalidation signal (`data_changed`); it MUST NOT carry balances, transfers, expenses, roles, participants, or any monetary payload. On receipt, clients MUST refetch the affected REST resources. If the WebSocket channel is unavailable or fails, REST refresh MUST remain fully functional; the notification path MAY be disabled without affecting monetary correctness. The channel MUST be reachable only through a valid session. Every successful group-scoped mutation that changes group-visible state MUST publish exactly one signal for its group after the source transaction commits: group settlement-policy updates; participant add, rename, archive, reactivate, and delete; and expense create, edit, and delete. Failed validation, authorization, CSRF/origin rejection, or rolled-back transactions MUST publish no signal.

#### Scenario: Invalidation triggers refetch, not trust

- GIVEN two valid sessions connected to the same group channel
- WHEN an authorized expense mutation succeeds through REST
- THEN the server pushes exactly one `data_changed` frame to that group's channel after commit
- AND every connected client refetches the REST resources
- AND no monetary value, participant detail, or role appears in the WebSocket frame

#### Scenario: Participant mutation reaches only its group

- GIVEN valid sessions connected to group `g1` and group `g2`
- WHEN an authorized participant rename, archive, reactivate, add, or delete succeeds for `g1`
- THEN the `g1` channel receives exactly one `{"type": "data_changed"}` frame
- AND the `g2` channel receives no frame

#### Scenario: Group policy mutation reaches only its group

- GIVEN valid sessions connected to a group channel
- WHEN an authorized settlement-policy update succeeds
- THEN that group's channel receives exactly one invalidation-only frame after commit

#### Scenario: Failed mutation does not publish

- GIVEN a valid session connected to a group channel
- WHEN a mutation fails validation, authorization, CSRF/origin checks, or transaction commit
- THEN no `data_changed` frame is published
- AND the existing error and rollback behavior is preserved

#### Scenario: WS failure degrades to REST

- GIVEN the WebSocket channel failing to connect or a subscriber failing during delivery
- WHEN the user refreshes or performs a mutation
- THEN the mutation response and REST reads remain functional
- AND a committed source mutation is not rolled back because notification delivery failed

## ADDED Requirements

### Requirement: Shared post-commit mutation publisher wiring

The application mutation services MUST receive one process-scoped `InvalidationPublisher` implementation backed by the existing `GroupEventBroadcaster`. `GroupService`, `ParticipantService`, and `ExpenseService` MUST invoke the publisher only after their unit-of-work context exits successfully. The publisher call MUST use the mutated `group_id`, MUST NOT be made before commit, and MUST NOT be made for read operations. The wiring MUST remain compatible with the existing authorization and CSRF/origin dependencies; this change does not grant permissions or alter request schemas.

#### Scenario: Production service graph shares the broadcaster

- GIVEN the FastAPI application is wired for requests
- WHEN the request services are constructed
- THEN all applicable mutation services reference the same app-scoped broadcaster adapter
- AND the WebSocket route subscribes to that same adapter

#### Scenario: Publisher failure is isolated

- GIVEN a committed mutation and a broadcaster subscriber that raises during delivery
- WHEN the publisher is invoked
- THEN the REST mutation remains successful
- AND the source transaction remains committed
- AND stale notification delivery is discarded according to the existing broadcaster behavior
