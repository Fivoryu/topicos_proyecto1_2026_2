# Delta for API

## ADDED Requirements

### Requirement: Account-scoped group and selection endpoints

The protected API MUST expose an authenticated account-scoped operation to list memberships and an operation to create a group. It MUST expose protected group-scoped operations for group summary, outings, membership lifecycle, join-code lifecycle, participant-link choices, expenses with nullable `outing_id`, scoped balances, and scoped settlement. Every response and mutation MUST be filtered by server-derived membership and role.

#### Scenario: Group list and creation are protected

- GIVEN a valid session for account `a1`
- WHEN `a1` lists groups or creates a group
- THEN the API returns only authorized groups and creates an owner/member group respectively
- AND an anonymous request receives `unauthorized`

#### Scenario: Selected group is not a client authorization claim

- GIVEN a member of `g1` submits a request naming `g2`
- WHEN the API authorizes the request
- THEN it returns `forbidden` or `not_found` according to the protected resource contract
- AND no `g2` data is returned or changed

### Requirement: Outing and membership endpoint authorization

The API MUST expose outing create/list/read/edit/archive/unarchive/delete operations and membership/join-code/link operations with stable schemas and structured errors. Members MAY create/edit outings; only owners MAY archive, unarchive, delete empty outings, manage the current join code, or remove members. Members MAY leave subject to final-owner protection.

#### Scenario: Archived outing rejects associated writes

- GIVEN an authenticated member and an archived outing in the selected group
- WHEN the member creates or edits an expense with that `outing_id`
- THEN the API returns a stable archived/read-only error
- AND no expense is written

#### Scenario: Owner-only membership operation rejects a member

- GIVEN an authenticated member
- WHEN the member regenerates a join code, removes another member, or deletes a non-empty outing
- THEN the API returns `forbidden` or the applicable conflict error
- AND source state is unchanged

### Requirement: Join-code lifecycle and participant-choice contract

The API MUST expose owner-protected generation, revocation, and regeneration of one current reusable join code, plus an authenticated consume operation. Token material MUST be treated as a bearer secret: it MUST NOT be logged or returned through unrelated group-data endpoints. A successful consume MUST require one explicit group-scoped choice to link an existing participant or create one, and invalid choices MUST fail atomically.

#### Scenario: Regeneration invalidates the prior token

- GIVEN current token `t1` for `g1`
- WHEN the owner regenerates the code and an authenticated account submits `t1`
- THEN the consume request is rejected
- AND only the new token can authorize a join

#### Scenario: Participant choice cannot cross groups

- GIVEN a valid token for `g1` and a participant identifier from `g2`
- WHEN the joining account chooses that participant
- THEN the API returns a structured validation/authorization error
- AND neither membership nor participant-link state changes

### Requirement: Nullable outing references and derived scope

Expense write and read schemas MUST represent `outing_id` as nullable. `null` MUST mean a general group expense. A non-null outing reference MUST belong to the same group as the expense. Group summary, balance, and settlement responses MUST include general and all outing-associated expenses; outing responses MUST include only expenses whose `outing_id` equals that outing.

#### Scenario: General expense remains group-only

- GIVEN a valid general expense with `outing_id = null`
- WHEN group and outing summaries are requested
- THEN the group result includes the expense
- AND no outing result includes or allocates it

#### Scenario: Cross-group outing reference is rejected

- GIVEN a group `g1` expense request with an outing from `g2`
- WHEN the API validates the request
- THEN it returns `invalid_outing_reference` or the equivalent stable validation error
- AND no expense is persisted

### Requirement: Generated contract workflow covers this delta

The OpenAPI document MUST be exported from handwritten FastAPI routes and schemas, and the TypeScript and Dart clients MUST be regenerated from that frozen contract. Generated files MUST NOT be hand-edited. Contract drift MUST fail when checked-in outputs do not match the generation workflow. This delta does not require mobile UI/domain parity; generated Dart changes are contract output only.

#### Scenario: Contract generation is authoritative

- GIVEN a handwritten endpoint or schema change for this delta
- WHEN the pinned export and generation workflow runs
- THEN OpenAPI and generated client outputs reflect the source contract
- AND no generated file is manually modified

#### Scenario: Contract drift is detected

- GIVEN a generated client or contract snapshot that differs from the authoritative workflow
- WHEN the drift check runs
- THEN the check fails and identifies the mismatch

### Requirement: WebSocket invalidation remains signal-only

Every successful source mutation introduced by this delta that changes group-visible state MUST publish exactly one group-scoped `{"type":"data_changed"}` frame after commit. The frame MUST contain no group data, monetary values, participant details, roles, or join token. Clients MUST invalidate and refetch REST resources. Failed or rolled-back operations MUST publish no frame.

#### Scenario: Outing mutation invalidates only its group

- GIVEN sessions connected to `g1` and `g2`
- WHEN an authorized outing or membership/expense mutation commits in `g1`
- THEN `g1` receives exactly one invalidation frame
- AND `g2` receives none

#### Scenario: Invalidation never becomes a data source

- GIVEN a client receives `data_changed`
- WHEN the client updates its view
- THEN it refetches authoritative REST results
- AND it does not derive or accept balances, settlement, membership, or expense data from the frame

#### Scenario: Rejected mutation does not invalidate

- GIVEN an invalid, unauthorized, archived, cross-group, or rolled-back mutation
- WHEN the request fails
- THEN no invalidation frame is published

## MODIFIED Requirements

### Requirement: REST endpoint surface

The system MUST expose protected REST endpoints for account group listing and creation; selected-group summary and settings; participants and participant links; outings and their lifecycle; membership and join-code lifecycle; expenses with nullable `outing_id`; general and outing-scoped expense reads; balances; and settlement. Balances and settlement MUST remain server-derived integer-cent results and MUST be filtered to the requested group or outing scope.

(Previously: The API exposed one active group plus participant, expense, balance, settlement, and policy operations, with no group discovery, creation, outing, membership, join-code, or nullable outing scope.)

#### Scenario: Full selected-group surface is protected

- GIVEN an authenticated owner or member of `g1`
- WHEN supported selected-group endpoints are called
- THEN documented schemas and server-derived results are returned
- AND a session without `g1` membership receives no `g1` data

#### Scenario: Full protected CRUD surface responds

- GIVEN an authenticated owner or member session for the seeded group
- WHEN each endpoint is exercised against the seeded group
- THEN participants, rename, expenses, balances, settlement, and group settings respond with the documented schemas
- AND every monetary field is an integer `amount_cents` value

#### Scenario: Rename is name-only

- GIVEN an authenticated session
- WHEN a participant rename request is sent
- THEN the request contains exactly the new name and no other participant field
- AND the response returns the renamed participant with the same ID

### Requirement: Structured error contract

The API MUST reject invalid cases with a stable `error_code`, human-readable message, and no partial mutation. In addition to the baseline codes, the contract MUST define stable errors for duplicate membership, invalid or revoked join code, archived outing writes, invalid/cross-group outing reference, forbidden owner operation, non-empty outing deletion, final-owner exit, and invalid participant-link choice. HTTP status mapping MUST distinguish authentication (`401`), membership/role denial (`403`), validation (`422`), conflict (`409`), and missing protected resource (`404`).

(Previously: The contract covered baseline amount, participant, session, role, and resource errors but had no outing, join, membership, or link lifecycle errors.)

#### Scenario: Invalid lifecycle request is explicit

- GIVEN a request that uses a revoked code, writes to an archived outing, or deletes a non-empty outing
- WHEN the API processes it
- THEN the response identifies the applicable stable error
- AND no source state changes

#### Scenario: AO-06 — every invalid case is explicit

- GIVEN each baseline invalid case (CB-01 through CB-09, CB-15) plus invalid credentials, missing/expired/logged-out sessions, role denial, and invalid rename input
- WHEN the corresponding request is sent
- THEN the response carries the matching `error_code` and an understandable message
- AND no state changed

#### Scenario: Auth failures use 401 and never leak group data

- GIVEN a request with invalid credentials or an absent/invalid session
- WHEN the request is sent
- THEN the response is HTTP 401 with the matching auth `error_code`
- AND the response body contains no group data

## REMOVED Requirements

### Requirement: API non-goal excluding group creation and multi-group endpoints

(Reason: This delta adds authenticated account-scoped group discovery, creation, and selection.)
(Migration: Update generated consumers and API tests to the new protected surface; retain the single-group endpoints for compatibility where applicable.)
