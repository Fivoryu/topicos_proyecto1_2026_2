# Delta for API

## MODIFIED Requirements

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
