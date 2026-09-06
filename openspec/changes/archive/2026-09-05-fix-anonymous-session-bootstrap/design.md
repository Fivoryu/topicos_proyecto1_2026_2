# Design: Anonymous browser session bootstrap

The smallest safe change is a transport-boundary change, not an authentication-service change: distinguish a missing `cc_session` cookie from a present cookie in the session route, return a server-owned anonymous `204` only for the browser branch, and map that successful empty response to a clean web `signedOut` state before any JSON parser runs.

## Quick path

1. Add the missing-cookie branch in `backend/app/api/routes/auth.py`; use `token is None`, not a truthiness check.
2. Keep `AuthService.session_identity()`, `get_current_identity()`, CSRF enforcement, and cookie normalization unchanged.
3. Enrich the session operation with an empty `204` response and the exact `X-Client: mobile` condition.
4. Export and regenerate through the pinned workflow, then inspect the generated TypeScript and Dart results before changing handwritten web code.
5. Add RED tests first, implement the route and web mapping, triangulate invalid states, and finish with drift/typecheck/focused-suite gates.

## Existing seams and data flow

Current behavior is concentrated in these boundaries:

- `backend/app/api/routes/auth.py` reads `cc_session`, calls `auth_service.session_identity(token)`, maps `AuthenticationError` to the stable error envelope, and calls `set_csrf_cookie()` on both the failure and success response.
- `backend/app/application/auth_service.py` deliberately rejects `None`, empty, malformed, unknown, revoked, expired, inactive-account, and unusable sessions. It must remain the authority for every present cookie.
- `backend/app/api/deps.py` independently validates cookies for protected resources. It must not inherit the anonymous probe exception.
- `backend/app/adapters/security/sessions.py` already deletes the `/api` CSRF cookie and sets the readable root `/` CSRF cookie. The new response must reuse this function rather than duplicate cookie logic.
- `web/src/app/api-client.ts` supplies the generated client with `credentials: "include"` through the handwritten `createHttpClient` adapter.
- `web/src/core/http-client.ts` already treats every `response.ok` response as successful and its handwritten `json()` helper already returns `undefined` for `204`. The generated API path does not use that helper to parse the operation response.
- `web/src/app/auth/session-provider.tsx` currently assumes `getSession()` always resolves to `SessionIdentityResponse`; its generated session call reaches `JSONApiResponse.value()`.

Target flow:

```text
GET /api/v1/auth/session
  -> read request.cookies["cc_session"]
  -> token is None AND X-Client is not exactly "mobile"
       -> Response(status_code=204)
       -> set_csrf_cookie(response)
       -> empty response
  -> otherwise auth_service.session_identity(token)
       -> AuthenticationError -> stable 401 + set_csrf_cookie()
       -> valid identity -> existing 200 + set_csrf_cookie()
  -> handwritten generated-client boundary checks status before JSON parsing
       -> 204 -> undefined/anonymous result
       -> 200 -> existing identity model
       -> 401 -> existing AuthError normalization
  -> SessionProvider maps only the 204 result to clean signedOut
```

A cookie value of `""` is present and therefore must follow validation and return `401`; only `None` enters the anonymous branch. The native compatibility check is an exact value comparison against the existing `X-Client: mobile` marker. Header names remain HTTP case-insensitive, but values such as `"Mobile"`, `"mobile "`, or `"desktop"` are not the exact marker and therefore remain in the browser branch when no cookie is present.

## Backend design

### Route behavior

In `backend/app/api/routes/auth.py`, add the branch immediately after reading the cookie and before `session_identity()`:

- If the cookie is absent and `request.headers.get(NATIVE_CLIENT_HEADER_NAME) != NATIVE_CLIENT_MARKER`, construct an explicit `Response(status_code=204)`.
- Call `set_csrf_cookie()` on that response with the existing HTTPS decision.
- Return the response directly so FastAPI does not serialize a response model and no body is produced.
- For the exact native marker, and for every present value including an empty value, continue into the existing validation `try` block.
- Leave the existing success and failure cookie calls in place. This preserves root-cookie initialization and `/api` legacy cleanup for all session outcomes.

The route's response annotation can continue to permit a direct `Response`. Do not make `SessionIdentityResponse` optional in the API schema as a substitute for documenting a no-content response, and do not move this exception into `AuthService` or `deps.py`.

### Security invariants

- The session probe remains an optional-credential operation in OpenAPI; do not add a global `cc_session` security requirement that would contradict the anonymous branch.
- Protected routes continue through `get_current_identity()` and still reject missing credentials with `401`.
- Login still runs `require_csrf`, exact origin/native handling, and the existing credential/session issuance flow.
- The route does not inspect or synthesize a client-side session cookie. The server decides whether the cookie is absent and initializes CSRF state.

## Web design

### Generated parser decision gate

The current generated TypeScript session method returns `JSONApiResponse<SessionIdentityResponse>`, and the current generated runtime calls `raw.json()` unconditionally. A raw `204` would therefore fail if the regenerated output keeps that parser shape. This is a verified baseline observation, not an assumption about the post-regeneration output.

After the contract is exported and the pinned generator runs, inspect:

- `web/src/generated/api/apis/AuthApi.ts`: the session operation's raw response type, response wrapper, status handling, and public return type.
- `web/src/generated/api/runtime.ts`: whether the operation uses a no-content/void wrapper or still invokes JSON parsing for `204`.
- `mobile/lib/generated/api/lib/src/api/auth_api.dart` and its generated model/serialization parts: whether the session response becomes nullable or a union and whether a `204` is safely represented.

Use this order of preference without editing generated output:

1. If the regenerated TypeScript public/raw method safely exposes the `204` as `undefined`/void, update only the handwritten `AuthClient.getSession` result type and consume that result.
2. If the generated raw method is available but the public method would parse JSON before returning, keep the generated operation and inspect `response.raw.status` first in the handwritten `generatedAuthClient` boundary. Return `undefined` for `204`; call the generated value parser only for a non-204 success. The current raw-method seam supports this narrow adaptation.
3. If regeneration changes the method shape so the raw seam is unavailable, use the existing handwritten transport (`generatedFetchApi`/`createHttpClient`) for one session request, check the status before parsing, and keep login/logout on the generated client. This is a fallback only; do not broaden `http-client.ts` or copy generated code.

The likely handwritten contract is `getSession: () => Promise<SessionIdentityResponse | undefined>`. `SessionProvider` must branch on the result:

- identity object -> existing `authenticated` snapshot;
- `undefined` from a successful `204` -> `signedOut` with `session: null`, `errorCode: null`, `errorMessage: null`, and `notice: null`;
- rejected `401` -> existing unauthorized/session-expired handling, preserving `session_expired` as distinct.

The `204` branch must not call `handleProtectedState`; that handler is for a protected request losing an established session and creates a notice/clears state as a side effect. The anonymous bootstrap path should directly install the clean signed-out snapshot. Do not issue a second probe, poll, probe browser cookies, or enable any protected query. The existing `ProtectedRoute` and TanStack Query `enabled: isAuthenticated` boundary should continue to prevent protected rendering/fetching.

Keep `web/src/app/api-client.ts` and `web/src/core/http-client.ts` unchanged unless the post-generation inspection proves that a tiny transport helper is required. In particular, do not change global `204` handling or 401 notification rules to solve a generated-parser problem.

## OpenAPI and generated-contract design

`backend/scripts/export_openapi.py` remains the enrichment authority after FastAPI creates the base document.

For `/api/v1/auth/session`:

- retain the generated `200` identity response;
- add `204` with a description and **no `content` key**;
- retain `401` as the stable `ErrorResponse` reference;
- replace/enrich the operation description with wording that explicitly states:
  - no `cc_session` plus no exact `X-Client: mobile` returns browser `204` with no content;
  - no `cc_session` plus exact `X-Client: mobile` remains `401`;
  - every present cookie is validated and unusable values remain `401`, including `session_expired` where emitted;
  - all outcomes retain server-owned CSRF initialization/legacy `/api` cleanup;
  - this exception applies only to the session probe and does not authorize protected resources.

Do not add `security` to the session probe. Existing protected operation security and CSRF header enrichment remain untouched.

The implementation phase must use the repository workflow, from the repository root:

```bash
python -m backend.scripts.export_openapi
cd web
npm exec -- openapi-generator-cli generate \
  -i ../contracts/openapi.json -g typescript-fetch \
  -o src/generated/api --skip-validate-spec \
  --additional-properties=supportsES6=true
npm exec -- openapi-generator-cli generate \
  -i ../contracts/openapi.json -g dart-dio \
  -o ../mobile/lib/generated/api --skip-validate-spec \
  --additional-properties=serializationLibrary=json_serializable
cd ../mobile/lib/generated/api
dart pub get
dart run build_runner build --delete-conflicting-outputs
cd ../../..
python -m backend.scripts.check_contract_drift --cwd .
```

The generator version remains the root-pinned `7.14.0`; `web/package.json`, `openapitools.json`, and mobile metadata are not independently changed. `contracts/openapi.json`, `web/src/generated/api/**`, and `mobile/lib/generated/api/**` are workflow outputs, never hand-edited. The actual generated diff must decide whether client trees change: leave a tree untouched if the pinned workflow reproduces it byte-for-byte; retain only generator-produced changes when it does not. No mobile product source or mobile behavior change is authorized by this design.

## Exact file boundary

| File or tree | Design disposition |
| --- | --- |
| `backend/app/api/routes/auth.py` | Expected source change: exact missing-cookie/native-marker branch and 204 response. |
| `backend/scripts/export_openapi.py` | Expected source change: session response/description enrichment. |
| `web/src/app/auth/session-provider.tsx` | Expected narrow handwritten adaptation after generated-runtime inspection; map successful empty response to clean signed-out state. |
| `backend/tests/integration/api/test_auth_routes.py` | Add/adjust route and cookie normalization assertions. Preserve existing tests; only change expectations that are necessarily changed from anonymous 401 to 204. |
| `backend/tests/test_openapi_contract.py` | Assert session responses `200`/`204`/`401`, empty 204 content, and exact marker description. |
| `web/tests/features/auth/session-provider.test.tsx` | Add successful 204, clean state, one-probe, protected-query-disabled, parser/error, and login-continuity coverage. |
| `web/tests/core/core.test.ts` | Add/retain the existing `json()` successful-204 regression and auth-401 isolation coverage; no broad transport behavior change. |
| `web/tests/api-client.test.ts` | Extend only if needed to exercise the generated session boundary; retain credentials/base-path assertions. |
| `contracts/openapi.json` | Generated from `export_openapi.py`; never hand-edit. |
| `web/src/generated/api/**` | Conditional generator output only; inspect whether it changes and whether its parser is safe. Never hand-edit. |
| `mobile/lib/generated/api/**` | Conditional generator output only; inspect, regenerate, and build serialization parts if required. Never hand-edit. |
| `backend/app/api/deps.py`, `backend/app/adapters/security/sessions.py`, `backend/app/application/auth_service.py` | Read-only invariants for this change; no production edits. |
| `web/src/app/api-client.ts`, `web/src/core/http-client.ts`, `web/package.json` | Read/verify seams; no production edits expected unless the generated-runtime decision gate proves a minimal helper necessary. |
| Docker files, credentials, mobile product source/tests, commits, and unrelated worktree files | Explicitly out of scope. |

## Test seams and strict-TDD ordering

### 1. RED

Write focused failing tests before implementation, then run the affected command once:

- Backend browser/no-cookie route: status exactly `204`, empty body, no validation-service call, root `cc_csrf` set, `/api` CSRF cookie deletion emitted, and no session cookie created.
- Backend exact mobile marker/no-cookie route: existing `401` and `unauthorized`; assert it is not `204`.
- Backend present-cookie matrix: unknown, malformed/empty, revoked, expired, inactive-account, and other unusable values reach validation and remain `401`; preserve `session_expired` for expiry. Use the service spy/calls to prove a present cookie is not bypassed.
- Backend valid session: existing `200` identity and server-derived role remain unchanged.
- Backend bootstrap-to-login: after anonymous response cookie normalization, login still succeeds with the root CSRF token and existing origin enforcement.
- OpenAPI export: session responses contain `200`, `204`, and `401`; `204` has no content and the description distinguishes browser/no-cookie, exact mobile/no-cookie, and present-cookie failures.
- Web generated boundary: a mocked successful `204` resolves to the anonymous result without invoking JSON parsing; a `200` still parses identity and a `401` still normalizes its error code.
- Web provider: a single `getSession()` call resolving to the anonymous result yields `signedOut` with no error/notice, protected queries never call their query function, and login can still read the initialized CSRF token.

The existing `backend/tests/integration/api/test_security_transport.py` protected-resource tests remain regression gates; do not weaken or redirect them to the session-probe behavior.

### 2. GREEN

Implement only the route branch and response cookie reuse. Export the contract. Inspect generated output. Then implement the smallest handwritten web mapping selected by the parser decision gate. Keep login/logout generated calls and existing error normalization intact. Run the focused backend, OpenAPI, and web tests after each bounded slice.

### 3. Triangulation

Add/re-run boundary cases: exact versus non-exact marker values, an empty present cookie, malformed/unknown/revoked cookies, expired and inactive identities, pre-existing root plus legacy CSRF cookies, valid identity, 204 body/header assertions, auth-path 401 notification isolation, and one-request/no-protected-query assertions. Run generated output inspection and contract drift before accepting any generated diff.

### 4. Refactor

Only after behavior passes, simplify local helpers or test fixtures without moving authentication responsibility. Do not refactor the shared transport, session service, cookie adapter, protected dependencies, or mobile code. Finish with the affected full suites and typecheck/build gates.

## Verification and rollout

Required final evidence includes:

```bash
python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q
python -m pytest backend/tests/integration/api/test_security_transport.py -q
npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts
npm --prefix web run typecheck
python -m backend.scripts.check_contract_drift --cwd .
```

The broader repository gates remain applicable in verification (`python -m pytest backend/tests -q`, `python -m ruff check backend`, and `npm --prefix web run build`). No tests or commands are run by this design phase.

Because an old web client currently expects JSON from a successful session probe, deploy the tolerant web boundary before or atomically with the backend 204 behavior when release units are separable. The adapted client still handles the old `401`, so it is backward-compatible with the prior server. Do not remove the adaptation before the server is restored to its prior contract.

## Risks and rollback

| Risk | Mitigation / rollback |
| --- | --- |
| `if not token` treats an empty present cookie as anonymous | Use `token is None`; keep a present-empty test. Roll back only the route branch if violated. |
| A broad or normalized marker check changes native behavior | Compare the existing header value exactly to `mobile`; test exact marker and near misses. |
| The 204 response skips CSRF cleanup or gains a body | Construct a direct `Response`, call `set_csrf_cookie()` on it, and assert root/legacy `Set-Cookie` headers plus empty bytes. |
| Generated TypeScript parses 204 as JSON | Inspect the regenerated raw wrapper and status-check before `.value()`; never edit generated runtime. |
| `undefined` is accidentally treated as authenticated or a 204 flows through an error handler | Make the provider's anonymous branch explicit and clean; assert no notice/error/protected query. |
| Existing 401/session-expired semantics drift | Keep all validation in `AuthService`, preserve `ResponseError` normalization, and triangulate representative failure classes. |
| Contract/client churn is assumed or hand-edited | Run the pinned export/generation/drift workflow; accept only actual generator output and leave unchanged trees unchanged. |
| Uncommitted auth/CSRF tests or Docker work is overwritten | Inspect before/after scope, edit only the listed files, avoid reset/clean/reformat/commit/push, and make only required assertion updates. |

Rollback restores the prior route behavior and OpenAPI enrichment, then re-exports/regenerates affected outputs through the same pinned workflow. Roll back the backend before removing the web 204 parser if releases cannot be reversed atomically. Never revert unrelated uncommitted authentication, CSRF, or Docker changes.
