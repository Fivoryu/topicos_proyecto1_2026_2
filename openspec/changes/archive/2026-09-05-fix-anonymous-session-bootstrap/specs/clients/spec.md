# Delta for Clients

## MODIFIED Requirements

### Requirement: Protected session flow on web

The web client MUST present a login screen that accepts seeded credentials and stores the server-established session for subsequent protected requests; MUST NOT render group data, a group shell, or any screen that looks like protected group access before a session exists; MUST offer logout that invalidates the session; MUST detect session expiry or logout invalidation and return to the login screen with an explicit `session_expired` or logged-out state; and MUST NOT persist or trust any client-supplied role. During one normal bootstrap, the web SessionProvider MUST issue only the existing session probe and MUST interpret its outcomes without duplicate requests or client-side cookie probing: HTTP `200` becomes `authenticated`, browser HTTP `204` becomes `signedOut` without a bootstrap error or notice, and HTTP `401` handling remains available for unusable cookie errors, including distinct `session_expired` handling. While signed out after anonymous `204`, protected TanStack Query operations MUST remain disabled and no protected group data MAY be fetched or rendered.

(Previously: The web client handled a no-session bootstrap through failure behavior but did not define successful anonymous `204` handling or the no-duplicate-request and protected-query invariants.)

#### Scenario: Login then protected shell

- GIVEN a user with valid seeded credentials and no session
- WHEN the user submits the login form
- THEN a session is established and the protected group shell renders
- AND the session/identity response drives the displayed role

#### Scenario: Anonymous `204` is a clean signed-out state

- GIVEN the web app starts without a `cc_session` cookie
- WHEN the SessionProvider's single session probe receives HTTP `204 No Content`
- THEN the provider state becomes `signedOut`
- AND no bootstrap error or notice is shown
- AND no protected group query is enabled or requested
- AND no duplicate session probe is issued

#### Scenario: Invalid credentials stay on login

- GIVEN incorrect credentials
- WHEN the user submits the login form
- THEN the form shows the `invalid_credentials` error
- AND no session is created and no group data appears

#### Scenario: Present invalid or expired cookie remains an auth failure

- GIVEN the web app sends a present unusable session cookie
- WHEN the session probe receives HTTP `401` with `unauthorized` or `session_expired`
- THEN the provider preserves the existing signed-out/error or session-expired behavior
- AND it does not reinterpret the response as anonymous success
- AND no protected group data is fetched or rendered

#### Scenario: Authenticated `200` state is unchanged

- GIVEN the web app sends a valid session cookie
- WHEN the session probe receives HTTP `200` with identity and role
- THEN the provider becomes `authenticated`
- AND the same server-derived identity and role drive protected access
- AND the provider does not issue an additional bootstrap request

#### Scenario: Session expiry returns to login

- GIVEN a web client whose session has expired or been invalidated by logout
- WHEN the user continues to use protected views or refreshes
- THEN the client clears protected state and shows the login screen with an explicit expiry/logout message
- AND no group data is displayed anonymously

#### Scenario: No anonymous protected shell

- GIVEN a user with no session and a provider state of `signedOut`
- WHEN the app finishes bootstrap
- THEN no group, participant, expense, balance, or settlement data is fetched or rendered
- AND the only screen shown is the login/unauthorized state

## ADDED Requirements

### Requirement: Web login preserves server CSRF and origin enforcement

The web login flow MUST use the server-initialized readable CSRF token after anonymous session bootstrap and MUST preserve the existing CSRF and origin enforcement. The client MUST NOT bypass, synthesize, or downgrade those protections because the session probe succeeded with `204`.

#### Scenario: Bootstrap token is used for immediate login

- GIVEN the browser received an anonymous `204` and a root `cc_csrf` token
- WHEN the user immediately submits valid login credentials
- THEN the login request uses the initialized CSRF token
- AND the existing origin enforcement is applied
- AND the login succeeds with the normal authenticated session result

#### Scenario: Missing or invalid login protection remains rejected

- GIVEN login is attempted with a missing, invalid, or disallowed CSRF/origin context
- WHEN the request is processed
- THEN the existing CSRF/origin rejection is returned
- AND no session is established

## ACCEPTANCE CRITERIA

- [ ] Browser no-cookie session bootstrap is exactly `204` with an empty body and clean `signedOut` provider state.
- [ ] Root `cc_csrf` initialization and legacy `/api` CSRF-cookie expiration are preserved.
- [ ] Exact `X-Client: mobile` no-cookie behavior remains `401` when that boundary is retained.
- [ ] Every present unusable cookie remains `401`; `session_expired` remains distinguishable where applicable.
- [ ] Valid session behavior remains `200` with unchanged server identity and role.
- [ ] Protected queries stay disabled while signed out, and bootstrap does not duplicate requests.
- [ ] Login immediately after bootstrap preserves CSRF and origin enforcement.
- [ ] OpenAPI documents `200`/`204`/`401`, and generated artifacts are changed only by the pinned workflow.
- [ ] No Docker files or unrelated uncommitted work are modified.
