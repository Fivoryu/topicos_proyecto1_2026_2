# Groups Specification

## Purpose

Define the protected group foundation of the MVP: one active seeded group with exactly one owner, group-scoped data and API paths, a persisted settlement policy (`owner_only` default, `any_member` optional), and a server-derived `owner`/`member` role model backed by minimum seeded-account authentication (CC-03 confirmed). Every group read and mutation requires a valid session; the server—never a client flag—decides the actor's role and authorization.

## Requirements

### Requirement: Group foundation and scope

The system MUST persist at least one group with exactly one owner; every group-owned entity (participants, expenses, balances, settlement) MUST carry the `group_id`. All API paths for group-owned resources MUST be scoped under the group. The MVP UI MUST expose one active group only; there MUST be no group switcher, group discovery, group creation, or multi-group workflow in the first slice.

#### Scenario: All resources are group-scoped

- GIVEN an active session in group `g1`
- WHEN participants, expenses, balances, and settlement are created or read through the protected API
- THEN every resource is reachable under `/groups/g1/...` and every record stores `group_id = g1`

#### Scenario: Single-group UI

- GIVEN the web and mobile clients with a valid session
- WHEN they render the app
- THEN they show the active group's data without any group switcher, group creation, or group discovery UI

### Requirement: Protected sessions for group data

The system MUST require a valid, unexpired, server-recognized session to read or mutate any group-owned resource. An unauthenticated, invalid, expired, or logged-out session MUST be rejected with the documented auth error envelope before any group data is returned or changed, and the group MUST NOT be accessible anonymously or through any anonymous fallback.

> **Confirmed decision (CC-03):** Minimum authentication is part of the MVP: pre-seeded demo accounts, login/logout, protected sessions, and explicit server-derived owner/member roles. There is no public registration, password recovery, invitations, or OAuth. Recorded in the reconciled proposal and Engram observation `2587` (`sdd/cuentas-claras-mvp/confirmation-gates`).

#### Scenario: Unauthenticated read is rejected

- GIVEN no session
- WHEN a protected group read (`GET /groups/g1`) is attempted
- THEN the request is rejected with error `unauthorized` (HTTP 401)
- AND no group data is returned

#### Scenario: Unauthenticated mutation is rejected

- GIVEN no session
- WHEN a protected mutation (for example, creating an expense) is attempted
- THEN the request is rejected with error `unauthorized` (HTTP 401)
- AND no state changes

#### Scenario: Invalid or logged-out session is rejected

- GIVEN a session that has been invalidated by logout or is otherwise unrecognized
- WHEN any protected group request is attempted with it
- THEN the request is rejected with error `unauthorized` or `session_expired` (HTTP 401)
- AND no data is returned and no state changes

### Requirement: Server-derived owner and member roles

The system MUST derive each authenticated actor's role from server-side group membership: `owner` for the account that owns the group and `member` for any other authenticated group member. Roles MUST be returned to the client only as server-derived values and MUST NOT be accept, trust, or store a client-supplied role. The protected-operation matrix MUST be enforced from server-derived roles, never from a client role flag.

> **Confirmed decision (CC-03):** role derivation is server-side and observable through the protected session/identity response; clients cannot choose or override the role.

#### Scenario: Session reports the derived role

- GIVEN a seeded owner account and a seeded member account that both log in
- WHEN each account reads its session/identity response
- THEN the owner's response reports role `owner` and the member's response reports role `member`
- AND neither response can be changed by client input

#### Scenario: Client role claim is ignored

- GIVEN a member session that submits a request claiming role `owner`
- WHEN the protected operation is evaluated
- THEN the server ignores the client claim and enforces the role it derived
- AND the operation is authorized or denied exactly as for a normal `member`

### Requirement: Settlement policy setting with owner/member authorization

The system MUST persist a `settlementPolicy` setting per group with exactly two values: `owner_only` (default) and `any_member`. The setting MUST be changeable through group settings and MUST be exposed consistently in the group API payload and in both generated clients. Changing `settlementPolicy` is the only owner-sensitive operation in the MVP: under `owner_only` it MUST require role `owner`; under `any_member` it MUST be permitted for any authenticated member of the group.

#### Scenario: Default and change by owner

- GIVEN the seeded active group
- WHEN an authenticated owner reads the group payload
- THEN `settlementPolicy` is `owner_only`

- GIVEN an authenticated owner changes the setting to `any_member`
- WHEN the group payload is read again after refresh
- THEN `settlementPolicy` is `any_member` and remains so

#### Scenario: Member denied under owner_only

- GIVEN an authenticated member session and `settlementPolicy: owner_only`
- WHEN the member attempts to change the policy to `any_member`
- THEN the request is rejected with error `forbidden` (HTTP 403)
- AND `settlementPolicy` remains `owner_only`

#### Scenario: Member permitted under any_member

- GIVEN an authenticated member session and `settlementPolicy: any_member`
- WHEN the member changes the policy to `owner_only`
- THEN the change succeeds
- AND the setting persists across refresh

### Requirement: Group membership isolation

The system MUST scope every group-owned read and mutation to the authenticated actor's group membership. An actor authenticated but not a member of the requested group MUST NOT read or mutate that group's data.

#### Scenario: Out-of-group access is rejected

- GIVEN an authenticated member of group `g1` and no membership in group `g2`
- WHEN a protected request for a `g2` resource is attempted
- THEN the request is rejected with error `forbidden` (HTTP 403)
- AND no `g2` data is returned and no `g2` state changes

## Non-goals

- No public registration, self-service account creation, password recovery, invitations, external OAuth, or a broader account-management product; only the minimum seeded-account authentication slice is in scope (CC-03).
- No multiple groups in the UI, group discovery, group creation, or group switcher.
- No anonymous or unauthenticated access to any group data.
- No cloud collaboration or real-time editing.
