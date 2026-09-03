# Clients Specification

## Purpose

Define client responsibilities for web (React/Vite, TanStack Query, Tailwind) and mobile (Flutter, Cubit, Dio): thin consumers of the generated OpenAPI clients that handle the protected-session lifecycle, display server-derived results and server-derived roles, refetch on invalidation, render money with the shared cents formatter, support participant rename, use the warm finance-friendly token set, and surface explicit session/auth, validation, and empty states. Neither client ever computes money, chooses a role, or bypasses login.

## Requirements

### Requirement: Web Must flow

The web client MUST provide the responsive React flow for login/logout, protected group access, participants (including rename), expenses (create/edit/delete), balances, and settlement against the generated TypeScript client, with TanStack Query owning data fetching and cache invalidation, and with the warm finance-friendly token set (design-phase tokens for colors and spacing, referenced as theme tokens, not ad-hoc values).

#### Scenario: Complete record → calculate → settle → refresh flow

- GIVEN the seeded group and a valid session in the web client
- WHEN the user records an expense, opens balances and settlement, then refreshes the page
- THEN the persisted data and server-derived balances and settlement render identically before and after the refresh
- AND the session remains valid after the refresh

### Requirement: Protected session flow on web

The web client MUST present a login screen that accepts seeded credentials and stores the server-established session for subsequent protected requests; MUST NOT render group data, a group shell, or any screen that looks like protected group access before a session exists; MUST offer logout that invalidates the session; MUST detect session expiry or logout invalidation and return to the login screen with an explicit "session expired" or "logged out" state; and MUST NOT persist or trust any client-supplied role.

#### Scenario: Login then protected shell

- GIVEN a user with valid seeded credentials and no session
- WHEN the user submits the login form
- THEN a session is established and the protected group shell renders
- AND the session/identity response drives the displayed role

#### Scenario: Invalid credentials stay on login

- GIVEN incorrect credentials
- WHEN the user submits the login form
- THEN the form shows the `invalid_credentials` error
- AND no session is created and no group data appears

#### Scenario: Session expiry returns to login

- GIVEN a web client whose session has expired or been invalidated by logout
- WHEN the user continues to use protected views or refreshes
- THEN the client clears protected state and shows the login screen with an explicit expiry/logout message
- AND no group data is displayed anonymously

#### Scenario: No anonymous protected shell

- GIVEN a user with no session
- WHEN the app loads
- THEN no group, participant, expense, balance, or settlement data is fetched or rendered
- AND the only screen shown is the login/unauthorized state

### Requirement: Server-derived role display without client override

Both clients MUST render the authenticated actor's role from the server-derived session/identity response and MUST NOT send, persist, or trust any client-supplied role. The UI MAY conditionally offer owner actions (for example, changing settlement policy under `owner_only`), but the server remains the sole authorization authority, and the client MUST surface a `forbidden` error if a stale affordance is rejected.

#### Scenario: Role comes from the session/identity response

- GIVEN an owner login and a member login
- WHEN each opens the protected app
- THEN the web turns over owner/member role display from the session response
- AND a client-side role claim is never accepted

#### Scenario: Owner-only action rejection is surfaced

- GIVEN an authenticated member under `settlementPolicy: owner_only`
- WHEN the member attempts to change the policy
- THEN the client shows the `forbidden` error from the server
- AND the policy display remains unchanged

### Requirement: Mobile read-mostly parity with protected sessions

The mobile client MUST provide the Flutter/Dio generated-client integration with Cubit state and MUST support login/logout/session, server-derived role display, and protected reads of participants, balances, settlement, and expense history with parity to the web views. Mobile MUST NOT bypass login or fetch group data without a valid session. Mobile expense create/edit/delete is approved Stretch, not Must; until it ships, the mobile client MUST NOT expose write controls that would mislead users.

#### Scenario: Read-mostly parity behind login

- GIVEN the generated Dart client and a valid session for the seeded group
- WHEN the mobile app opens the participants, balances, settlement, and expense history views after login
- THEN each view renders the same server-derived data as the web client
- AND no money value is computed in Dart and no unauthenticated group fetch occurs

#### Scenario: Session-expired state on mobile

- GIVEN a mobile session that has expired or been invalidated by logout
- WHEN the app tries to load a protected read
- THEN the app clears protected state and shows the login/session-expired state
- AND no group data is rendered anonymously

### Requirement: No client-side monetary authority

Clients MUST NOT compute balances, splits, residuals, or transfers; they MUST display only server-derived values. Each client MUST render money exclusively through its single shared, unit-tested cents formatter (see money spec); no client MAY implement ad-hoc money arithmetic.

#### Scenario: Server results are displayed verbatim

- GIVEN balances and settlement fetched from the API
- WHEN either client renders them
- THEN the rendered values are the fetched integer-cent values formatted through the shared formatter
- AND no client code recomputes or rounds a monetary value

### Requirement: Invalidation-driven refetch

On receipt of the WebSocket `data_changed` signal (api spec), every connected client MUST invalidate and refetch the affected REST resources (TanStack Query invalidation on web; Cubit-triggered refetch on mobile). On page load or app start, clients MUST fetch the authoritative REST state. If the WebSocket is unavailable, refresh behavior MUST still work through REST.

#### Scenario: Refetch on invalidation

- GIVEN a web client connected to the group channel with cached balances
- WHEN `data_changed` arrives after another client creates an expense
- THEN TanStack Query invalidates the affected queries and refetches them
- AND the balances view updates to the fresh server result

### Requirement: Rename interaction and archived visibility

The web client MUST provide a rename action for participants that submits a name-only update, shows inline `invalid_participant_name` and `duplicate_participant_name` errors bound to the name field, and does not change any displayed amounts. The balances view MUST list referenced archived participants at their derived value including `Bs. 0.00`; new expense forms MUST default to active participants only; edit forms MUST retain referenced archived participants (CC-02).

#### Scenario: Rename updates the displayed name without changing money

- GIVEN a participant with a derived balance
- WHEN the user renames them to a valid, unique name
- THEN the displayed name updates and the derived balance is unchanged
- AND the participant ID and history still resolve to the same participant

#### Scenario: Rename conflict is bound to the field

- GIVEN a rename attempt whose normalized name matches another participant
- WHEN the user submits
- THEN the name field shows the `duplicate_participant_name` error
- AND the current name and all balances are unchanged

#### Scenario: Archived zero balance is rendered

- GIVEN a referenced archived participant with derived balance `0`
- WHEN the balances view renders
- THEN the participant appears with `Bs. 0.00` and its archived label

### Requirement: Validation and error states

The web client MUST surface each baseline invalid case (CB-01..CB-09, CB-15) plus auth errors (`invalid_credentials`, `unauthorized`, `session_expired`, `forbidden`) and rename errors as explicit, understandable inline states, and MUST keep invalid submissions from mutating state. Empty states MUST be explicit: a group with no participants shows the add-participants-first message (CB-01); an all-settled group shows "everyone is settled" with no transfers (CB-13); a corrupted-persistence response shows the recovery error instead of a broken UI (CB-16).

#### Scenario: Field-bound errors

- GIVEN an expense form with more than two decimal places
- WHEN the user submits
- THEN the amount field shows the `invalid_amount` message
- AND the form remains editable with no server mutation

#### Scenario: All-settled and empty states

- GIVEN balances all at zero
- WHEN the settlement view renders
- THEN it displays "everyone is settled" and no transfer rows

- GIVEN a group with no participants
- WHEN the expense form opens
- THEN it displays the add-participants-first guidance and blocks expense creation

### Requirement: Warm finance-friendly presentation

Both clients MUST render with the warm, finance-friendly visual token set defined in the design phase; components MUST consume theme tokens only. The presentation MUST remain responsive on the web flow at demo widths.

#### Scenario: Token usage

- GIVEN the web and mobile designs
- WHEN component styles are inspected
- THEN colors and spacing resolve from the theme token set, and no ad-hoc color literals diverge from it

## Non-goals

- No client-side money math or authoritative calculations of any kind.
- No client-side role assertion, authorization decision, or role storage as truth.
- No localStorage persistence of group data; clients hold only cache and the session mechanism, never durable truth.
- No anonymous group-data screen that appears to be protected access.
- No mobile write parity in the Must slice (approved Stretch).
- No rich group-settings experience beyond the settlement policy control (approved Stretch).
- No registration, password recovery, invitations, or OAuth flows in either client (see groups/api specs).
