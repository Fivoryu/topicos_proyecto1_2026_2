# API Specification

## Purpose

Define the REST/OpenAPI contract: the protected session surface (login/logout/session state), the group-scoped endpoint surface, the structured error contract for every invalid case including authentication and authorization failures, the contract-first generation of TypeScript and Dart clients, and the WebSocket invalidation-only channel. The API is the only monetary and authorization authority; clients consume server-derived results and never supply roles.

## Requirements

### Requirement: Authentication and session surface

The system MUST expose login, logout, and session/identity operations. Login MUST accept seeded credentials, reject invalid credentials, and, on success, establish a server-recognized protected session and return the authenticated actor's identity and server-derived role (`owner` or `member`). Logout MUST invalidate the current session. Session state MUST report the current authenticated actor and role, or fail explicitly when there is no valid session. A valid session MUST survive a page refresh; the exact transport (for example an HTTP-only session or an equivalent protected token) is a design decision and is not fixed by this specification.

> **Confirmed decision (CC-03):** Minimum authentication is part of the MVP: pre-seeded demo accounts, login/logout, protected sessions, and explicit server-derived owner/member roles. Recorded in the reconciled proposal and Engram observation `2587` (`sdd/cuentas-claras-mvp/confirmation-gates`).

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

The system MUST derive the OpenAPI contract from FastAPI and MUST generate the TypeScript client (web) and the Dart client (mobile) from that same frozen contract. The contract MUST include the login/logout/session state, protected group resources, participant rename, and the structured error envelope. The generation workflow (commands and regeneration order) MUST be documented, and a drift check MUST verify that checked-in generated clients match the current contract. Clients MUST NOT compute or claim any authoritative money result or any role; all monetary and role truth comes from the API.

#### Scenario: AO-08 — contract parity

- GIVEN the frozen OpenAPI contract
- WHEN both clients are regenerated and consumers are implemented against them
- THEN web and mobile issue the same endpoint calls with the same schemas, including auth and rename operations
- AND the drift check passes with no manual edits to generated files

### Requirement: WebSocket invalidation-only channel

The system MUST expose one WebSocket channel per group that sends only an invalidation signal (`data_changed`); it MUST NOT carry balances, transfers, expenses, roles, or any monetary payload. On receipt, clients MUST refetch the affected REST resources. If the WebSocket channel is unavailable or fails, REST refresh MUST remain fully functional; the notification path MAY be disabled without affecting monetary correctness. The channel MUST be reachable only through a valid session.

#### Scenario: Invalidation triggers refetch, not trust

- GIVEN two valid sessions connected to the group channel
- WHEN an expense mutation succeeds through REST
- THEN the server pushes `data_changed` to the group channel
- AND every connected client refetches the REST resources
- AND no monetary value or role ever appears in the WebSocket frame

#### Scenario: WS failure degrades to REST

- GIVEN the WebSocket channel failing to connect
- WHEN the user refreshes or performs a mutation
- THEN the client still fetches fresh REST data and displays correct server-derived results

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
