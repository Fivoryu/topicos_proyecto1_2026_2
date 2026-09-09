# Delta for Clients

## ADDED Requirements

### Requirement: Laptop-first protected workspace navigation

The web client MUST provide separate protected pages or stable navigation states for group list/create/select, selected-group summary, outing list/detail, outing expenses, general expenses, participant detail, balances, settlement, and group/membership settings. Existing hash anchors MUST remain reachable where applicable. No new routing dependency MAY be introduced, and mobile UI/domain parity is out of scope.

#### Scenario: Protected navigation follows selection

- GIVEN an authenticated account with multiple groups
- WHEN the account selects `g1` and opens each available workspace destination
- THEN each page is scoped to `g1`
- AND direct or stale navigation without valid membership returns to a protected error or selection state

#### Scenario: Existing anchors remain usable

- GIVEN a legacy hash anchor for expenses, balances, settlement, participants, or group settings
- WHEN the user opens that anchor in the protected shell
- THEN the corresponding new workspace state is reachable without exposing data outside the selected group

### Requirement: Selection and cache transitions are protected

TanStack Query keys and enabled states MUST include the selected group and relevant outing scope. On logout, session expiry, membership removal, or group switch, protected caches MUST be cleared, reset, or invalidated so stale data cannot render under another identity or group. The client MUST treat server errors as authoritative rather than hiding them through client role checks.

#### Scenario: Group switch does not leak cached data

- GIVEN cached `g1` balances and an account selects `g2`
- WHEN the selected-group state changes
- THEN `g1` data is not rendered in `g2` views
- AND `g2` resources are fetched only after membership validation

#### Scenario: Session expiry clears protected cache

- GIVEN protected workspace data is cached
- WHEN the session expires or logout completes
- THEN protected queries stop and cached group data is cleared or inaccessible
- AND the login/unauthorized state is rendered

### Requirement: Web workspace actions follow server authority

Any member MAY use the outing create/edit and active associated-expense flows. Owner-only archive/unarchive/delete-empty and membership/join-code controls MUST be presented from server-derived role state, while stale affordances MUST still surface the server's structured `forbidden` or conflict error. Clients MUST display server-derived integer-cent balances and settlement without computing money.

#### Scenario: Archived outing controls are read-only

- GIVEN an archived outing with historical expenses
- WHEN its detail and expense views render
- THEN history remains readable
- AND new associated expense controls are disabled or rejected with the server error

#### Scenario: General and outing expense screens are distinct

- GIVEN a general expense and an outing-linked expense in one group
- WHEN the user opens the group and outing expense pages
- THEN the group page includes the general expense and all outing expenses
- AND the outing page includes only its own linked expenses

### Requirement: WebSocket is invalidation-only for the new workspace

On `data_changed`, the web client MUST invalidate/refetch affected group and outing queries through REST. It MUST NOT read balances, settlement, membership, or expense details from the frame. REST refresh MUST continue to work when the WebSocket is unavailable.

#### Scenario: Cross-group invalidation is isolated

- GIVEN the client has selected `g1` and has no active `g2` workspace
- WHEN the `g2` channel changes
- THEN `g1` queries are not replaced with `g2` data

#### Scenario: WebSocket outage does not block refresh

- GIVEN the invalidation channel is unavailable
- WHEN the user refreshes or submits a valid mutation
- THEN the client fetches authoritative REST state and renders correct results

## MODIFIED Requirements

### Requirement: Web Must flow

The web client MUST provide the protected React/TanStack Query flow for authenticated multi-group selection and the separate group, outing, expense, participant, balance, settlement, and membership/settings views using the generated TypeScript client. It MUST preserve session/CSRF/origin behavior, server-derived roles and money, explicit auth/validation/empty/error states, and the existing hash-compatible protected shell.

(Previously: The web flow assumed one active group and exposed participant, expense, balance, and settlement views without multi-group or outing workspaces.)

#### Scenario: New account workspace flow

- GIVEN an authenticated account with no groups
- WHEN the protected app loads
- THEN it shows an explicit empty state with group creation
- AND no unrelated group data is fetched

#### Scenario: Complete record → calculate → settle → refresh flow

- GIVEN the seeded group and a valid session in the web client
- WHEN the user records an expense, opens balances and settlement, then refreshes the page
- THEN the persisted data and server-derived balances and settlement render identically before and after the refresh
- AND the session remains valid after the refresh

#### Scenario: Group summary derives from server data

- GIVEN a selected group containing general and outing expenses
- WHEN the summary, balances, and settlement render
- THEN they reflect server-derived group-wide results including both expense scopes
- AND the client performs no monetary arithmetic

### Requirement: Invalidation-driven refetch

On the WebSocket invalidation signal, the web client MUST invalidate and refetch the affected selected-group and outing resources, including membership and derived results where applicable. It MUST preserve REST-only correctness and group isolation.

(Previously: Invalidation covered the single group's participant, expense, balance, and settlement queries only.)

#### Scenario: Committed outing mutation refreshes workspace

- GIVEN a selected group with an outing list and cached balance
- WHEN another authorized client commits an outing or expense mutation
- THEN the client receives only `data_changed`, refetches REST resources, and shows the new authoritative state

#### Scenario: Refetch on invalidation

- GIVEN a web client connected to the group channel with cached balances
- WHEN `data_changed` arrives after another client creates an expense
- THEN TanStack Query invalidates the affected queries and refetches them
- AND the balances view updates to the fresh server result

## REMOVED Requirements

### Requirement: Mobile read-mostly parity for this feature

(Reason: The confirmed scope is laptop-first web workspace behavior; mobile parity is explicitly out of scope.)
(Migration: Regenerated Dart contract output MAY change through the official workflow, but no mobile UI/domain task is created by this change.)

### Requirement: No rich group-settings experience

(Reason: The new workspace requires membership and owner join-code settings.)
(Migration: Keep settlement-policy and existing settings behavior; add only the specified membership/join-code controls.)
