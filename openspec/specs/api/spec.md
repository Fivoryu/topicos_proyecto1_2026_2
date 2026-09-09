# API Specification

## Purpose

Define the REST/OpenAPI contract: the protected session surface (login/logout/session state), the group-scoped endpoint surface, the structured error contract for every invalid case including authentication and authorization failures, the contract-first generation of TypeScript and Dart clients, and the WebSocket invalidation-only channel. The API is the only monetary and authorization authority; clients consume server-derived results and never supply roles.

## Requirements

### Requirement: Authentication and session surface

The system MUST expose login, logout, and session/identity operations. Login MUST accept seeded credentials, reject invalid credentials, and, on success, establish a server-recognized protected session and return the authenticated actor's identity and server-derived role (`owner` or `member`). Logout MUST invalidate the current session. The session operation MUST distinguish an absent session cookie from an unusable present cookie: a browser request without `cc_session` MUST return exactly HTTP `204 No Content` with an empty body, while an exact `X-Client: mobile` request without `cc_session` MUST retain HTTP `401` behavior. A request with a present unknown, malformed, revoked, expired, inactive-account, or otherwise unusable `cc_session` MUST remain HTTP `401`, preserving `session_expired` where applicable. A present valid session MUST return HTTP `200` with the unchanged identity and server-derived role. Session probing MUST NOT make missing credentials acceptable for protected resources.

Every session-operation response, including the browser anonymous response and authentication failures, MUST preserve server-owned CSRF-cookie initialization/normalization: the readable root `cc_csrf` cookie MUST be available and any legacy `/api`-scoped CSRF cookie MUST be expired. This CSRF invariant MUST remain separate from session authentication. The system MUST NOT treat session validation failure as anonymous state.

(Previously: The session operation reported identity or failed explicitly with no valid session, without defining a successful browser response for an absent cookie or the cookie/CSRF normalization invariants for that response.)

#### Scenario: Owner and member log in with seeded credentials

- GIVEN the seeded owner account and the seeded member account with their demo credentials
- WHEN each submits valid credentials to the login operation
- THEN a protected session is established for each
- AND the owner session reports role `owner` and the member session reports role `member`

#### Scenario: Invalid credentials are rejected

- GIVEN a login request with a correct username and an incorrect password
- WHEN login is attempted
- THEN the request is rejected with error `invalid_credentials` (HTTP 401)
- AND no session is established

#### Scenario: Session survives refresh while valid

- GIVEN a valid protected session
- WHEN the client reloads the page and resumes with the same session
- THEN the session is still valid and group resources remain accessible

#### Scenario: Logout invalidates the session

- GIVEN a valid protected session
- WHEN logout completes successfully
- THEN the session is invalidated
- AND any subsequent protected request with that session is rejected with error `unauthorized` or `session_expired` (HTTP 401)

#### Scenario: Browser without a session bootstraps anonymously

- GIVEN a browser request with no `cc_session` cookie and without the exact `X-Client: mobile` marker
- WHEN `GET /api/v1/auth/session` is requested
- THEN the response is exactly HTTP `204 No Content`
- AND the response body is empty
- AND a readable root-path `cc_csrf` cookie is initialized or normalized
- AND any legacy `/api`-scoped CSRF cookie is expired

#### Scenario: The exact mobile marker preserves native no-session behavior

- GIVEN a request with no `cc_session` cookie and exactly `X-Client: mobile`
- WHEN `GET /api/v1/auth/session` is requested
- THEN the existing HTTP `401` no-session behavior is preserved
- AND the response does not become anonymous HTTP `204`

#### Scenario: Present unusable cookies are never anonymous success

- GIVEN a request containing a present `cc_session` cookie that is unknown, malformed, revoked, expired, associated with an inactive account, or otherwise unusable
- WHEN `GET /api/v1/auth/session` is requested
- THEN the request is validated through the normal session semantics
- AND the response is HTTP `401`
- AND `session_expired` is preserved where the existing validation semantics emit it
- AND the response is never HTTP `204` and never an anonymous success
- AND CSRF-cookie initialization/legacy-cookie cleanup remains applied as required by the session route

#### Scenario: A valid session retains identity and role

- GIVEN a request containing a valid `cc_session` cookie
- WHEN `GET /api/v1/auth/session` is requested
- THEN the response is HTTP `200`
- AND the identity payload and server-derived `owner` or `member` role are unchanged
- AND no client-supplied role changes the result

#### Scenario: Login immediately after anonymous bootstrap remains protected

- GIVEN a browser has completed an anonymous `204` session bootstrap and has the initialized root `cc_csrf` token
- WHEN the browser submits login using that CSRF token
- THEN login succeeds or fails according to the existing credential rules
- AND existing CSRF-token and origin enforcement remains in force
- AND a successful login establishes the existing protected session and identity behavior

### Requirement: Protected session dependency for all group resources

Every group-scoped read and mutation MUST require a valid session with membership in that group. The server MUST reject missing, invalid, expired, or logged-out sessions with the documented auth error envelope before processing the request, and MUST NOT return or mutate data for a group the authenticated actor does not belong to.

#### Scenario: Protected access without a session

- GIVEN no session
- WHEN any group read or mutation is attempted
- THEN the request is rejected with error `unauthorized` (HTTP 401)
- AND no data is returned and no state changes

#### Scenario: Expired or logged-out session

- GIVEN a session that has expired or been invalidated by logout
- WHEN a protected request is attempted
- THEN the request is rejected with error `unauthorized` or `session_expired` (HTTP 401)
- AND no data is returned and no state changes

#### Scenario: Out-of-group access is rejected

- GIVEN an authenticated member of group `g1` and no membership in `g2`
- WHEN a protected request for a `g2` resource is attempted
- THEN the request is rejected with error `forbidden` (HTTP 403)
- AND no `g2` data is returned and no `g2` state changes

### Requirement: REST endpoint surface

The system MUST expose group-scoped REST endpoints for: reading the authenticated session/identity; reading the active group and updating its settlement policy; creating and listing participants; renaming, archiving, reactivating, and deleting participants; creating, listing, editing, and deleting expenses; reading balances; and reading settlement. Balances and settlement endpoints MUST return server-derived values computed at read time, with monetary fields as integer cents. Participant rename MUST accept a name-only update and MUST NOT accept any other field change.

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

The system MUST reject every invalid case with a structured error containing a stable machine-readable `error_code` and a human-readable message, with no partial mutation. The codes MUST include: `invalid_amount` (zero, negative, or more than two decimals), `no_beneficiaries`, `no_participants`, `invalid_participant_reference`, `contribution_mismatch`, `invalid_participant_name` (blank/whitespace-only), `duplicate_participant_name`, `participant_in_use` (protected deletion), `invalid_credentials` (bad login), `unauthorized` (missing/invalid session), `session_expired` (expired/logged-out session), `forbidden` (role or membership denied), and `not_found` (unknown group-owned resource). Validation failures MUST return HTTP 422; invalid credentials and session failures MUST return HTTP 401; role/membership denials MUST return HTTP 403; protected-deletion conflicts MUST return HTTP 409; missing resources MUST return HTTP 404.

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

### Requirement: Server-derived role enforcement

The server MUST enforce the protected-operation matrix from the derived role: updating `settlementPolicy` under `owner_only` requires role `owner`, and under `any_member` permits any authenticated member; every other group read and mutation is permitted to any authenticated member of that group. The API MUST NOT accept or trust a client-supplied role.

#### Scenario: owner_only blocks a member policy change

- GIVEN an authenticated member session and `settlementPolicy: owner_only`
- WHEN the member requests a policy change
- THEN the response is HTTP 403 with error `forbidden`
- AND the group policy is unchanged

#### Scenario: any_member permits a member policy change

- GIVEN an authenticated member session and `settlementPolicy: any_member`
- WHEN the member requests a policy change
- THEN the change succeeds
- AND the new policy is reflected in the group payload

### Requirement: OpenAPI contract and generated clients

The system MUST derive the OpenAPI contract from FastAPI and MUST generate the TypeScript client (web) and the Dart client (mobile) from that same frozen contract. The session operation's contract MUST document HTTP `200` for a valid identity response, HTTP `204` with no content for an anonymous browser request without `cc_session`, and HTTP `401` for native no-session and present unusable-cookie failures. Its operation description MUST explain the exact `X-Client: mobile` conditional without weakening authentication or protected-resource requirements. The contract MUST retain the login/logout/session state, protected group resources, participant rename, and structured error envelope. The generation workflow and drift check MUST remain authoritative; generated clients and contract snapshots MUST be produced only through that workflow and MUST NOT be hand-edited. Generated runtime behavior for a successful `204` MUST be verified before selecting a handwritten consumer adaptation.

(Previously: The contract documented the session state and generated clients but did not require the session operation to describe a `204` anonymous response alongside `200` and `401`.)

#### Scenario: AO-08 — contract parity

- GIVEN the frozen OpenAPI contract
- WHEN both clients are regenerated and consumers are implemented against them
- THEN web and mobile issue the same endpoint calls with the same schemas, including auth and rename operations
- AND the drift check passes with no manual edits to generated files

#### Scenario: Session contract documents all outcomes

- GIVEN the exported OpenAPI contract
- WHEN the session operation is inspected
- THEN its responses include `200`, `204`, and `401`
- AND the `204` response has no content
- AND the description distinguishes browser no-cookie bootstrap, exact mobile no-cookie behavior, and present-cookie validation failures

#### Scenario: Generated outputs remain workflow-derived

- GIVEN a handwritten API/OpenAPI source change defining the session outcomes
- WHEN the pinned contract and client generation workflow is run
- THEN checked-in generated outputs reflect the authoritative contract or remain unchanged when the workflow produces no output change
- AND no generated TypeScript, Dart, or contract file is hand-edited
- AND the contract drift check passes

### Requirement: WebSocket invalidation-only channel

The system MUST expose one WebSocket channel per group that sends only an invalidation signal (`data_changed`); it MUST NOT carry balances, transfers, expenses, roles, participants, or any monetary payload. On receipt, clients MUST refetch the affected REST resources. If the WebSocket channel is unavailable or fails, REST refresh MUST remain fully functional; the notification path MAY be disabled without affecting monetary correctness. The channel MUST be reachable only through a valid session. Every successful group-scoped mutation that changes group-visible state MUST publish exactly one signal for its group after the source transaction commits: group settlement-policy updates; participant add, rename, archive, reactivate, and delete; and expense create, edit, and delete. Failed validation, authorization, CSRF/origin rejection, or rolled-back transactions MUST publish no signal.

#### Scenario: Invalidation triggers refetch, not trust

- GIVEN two valid sessions connected to the group channel
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

- GIVEN the WebSocket channel failing to connect
- WHEN the user refreshes or performs a mutation
- THEN the client still fetches fresh REST data and displays correct server-derived results

### Requirement: Shared post-commit mutation publisher wiring

The application mutation services MUST receive one process-scoped `InvalidationPublisher` implementation backed by the existing `GroupEventBroadcaster`. `GroupService`, `ParticipantService`, and `ExpenseService` MUST invoke the publisher only after their unit-of-work context exits successfully. The publisher call MUST use the mutated `group_id`, MUST NOT be made before commit, and MUST NOT be made for read operations. The wiring MUST remain compatible with the existing authorization and CSRF/origin dependencies; this change does not grant permissions or alter request schemas.

#### Scenario: Production service graph shares the broadcaster

- **GIVEN** the FastAPI application is wired for requests
- **WHEN** the request services are constructed
- **THEN** all applicable mutation services reference the same app-scoped broadcaster adapter
- **AND** the WebSocket route subscribes to that same adapter

#### Scenario: Publisher failure is isolated

- **GIVEN** a committed mutation and a broadcaster subscriber that raises during delivery
- **WHEN** the publisher is invoked
- **THEN** the REST mutation remains successful
- **AND** the source transaction remains committed
- **AND** stale notification delivery is discarded according to the existing broadcaster behavior

### Requirement: Settlement policy exposure

The API MUST expose `settlementPolicy` in the group payload and MUST accept updates to it under the role rules of the groups specification. The rendered policy result in settlement responses MUST be consistent with the persisted setting.

#### Scenario: Policy reflected in payload

- GIVEN group settings with `settlementPolicy: owner_only`
- WHEN the group payload and settlement responses are read by an authenticated member of that group
- THEN both expose the policy consistently

## Non-goals

- No public registration, self-service account creation, password recovery, invitations, external OAuth, or a broader account-management product.
- No client-supplied role or client-side monetary calculation.
- No WebSocket monetary or role payloads; the WebSocket is never a source of truth.
- No persisted balance/transfer endpoints as independent ledgers.
- No anonymous endpoints for group data, and no multi-group or group-creation endpoints in the MVP surface beyond the seeded group.

## Active amendment: group-outing-workspaces

The endpoint and error exclusions above remain the historical MVP baseline. For this active change only, the protected API expands additively to support authenticated multi-group workspaces, outings, membership lifecycle, reusable join codes, participant-link choices, and nullable outing expense scope.

### Protected endpoint contract

- `GET/POST /api/v1/groups` is authenticated and account-scoped: list active memberships or atomically create an empty owner/member group. Existing group-scoped routes remain protected and recheck membership for every request; selection is navigation state, never an authorization claim.
- Group-scoped routes add outing CRUD/lifecycle, active-member reads, owner removal/member leave, owner join-code status/generate/regenerate/revoke, and authenticated `POST /api/v1/groups/join`. Expense, balance, and settlement routes accept the nullable `outing_id` scope where applicable.
- A join code is reusable for already-authenticated accounts until revoke/regeneration. Its plaintext is returned only by protected generation/regeneration, never by status or unrelated group data. Consumption requires exactly one same-group existing-participant link or new-participant choice and is atomic.

### Stable validation and authority rules

The additive contract uses stable `invalid_outing_reference`, `archived_outing_read_only`, `outing_not_empty`, `invalid_join_code`, `revoked_join_code`, `duplicate_membership`, `invalid_participant_link_choice`, `duplicate_participant_link`, `final_owner_exit`, `member_not_found`, and existing `forbidden` errors with the baseline `401`/`403`/`404`/`409`/`422` mapping. Invalid, cross-group, archived, duplicate, or unauthorized requests produce no partial mutation and no invalidation.

Group derivations include `outing_id = null` general expenses and every linked outing expense exactly once. Outing derivations filter to the exact outing and never allocate general expenses. FastAPI remains the sole authorization and integer-cent monetary authority.

### Narrow scope and preserved integrations

This amendment deliberately excludes public registration, account creation through QR, anonymous group data, email invitations, password recovery, OAuth, token expiry, approval queues, ownership transfer, mobile UI parity, new routing dependencies, client-side money/authorization, and new WebSocket payloads. Successful source mutations still publish exactly one post-commit group-scoped `{"type":"data_changed"}` frame; clients refetch REST and never read data from that frame. OpenAPI and clients remain workflow-generated, never hand-edited.
