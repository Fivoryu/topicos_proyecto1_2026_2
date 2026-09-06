# Exploration: Anonymous session bootstrap without expected browser 401

## Scope and confirmed outcome

The requested behavior is a transport-level refinement of `GET /api/v1/auth/session`:

- A browser bootstrap with no `cc_session` cookie returns `204 No Content`.
- The bootstrap still initializes/normalizes the readable `cc_csrf` cookie, including removal of the legacy `/api`-scoped duplicate.
- A request carrying a `cc_session` cookie continues through normal validation. Unknown, malformed, revoked, expired, inactive-account, and otherwise unusable sessions remain `401` (with `session_expired` preserved where the service emits it).
- Login remains CSRF-protected and continues to reuse the initialized CSRF token.
- This exploration changed no product code and intentionally leaves all existing uncommitted work untouched.

## Current flow

```text
GET /api/v1/auth/session
        |
        +-- read cc_session
        |
        +-- AuthService.session_identity(token)
        |       missing token -> UnauthorizedError -> JSON 401
        |       invalid/expired/revoked -> typed AuthenticationError -> 401
        |       valid -> SessionIdentityResponse 200
        |
        +-- set_csrf_cookie(response/failure)
```

The route is `backend/app/api/routes/auth.py`. It currently calls the application service even when the cookie is absent, so the service deliberately collapses “no cookie” and “invalid cookie” into `UnauthorizedError`. The route must branch before service validation if those states are to have different HTTP outcomes.

The CSRF behavior is centralized in `backend/app/adapters/security/sessions.py`: `set_csrf_cookie()` deletes the legacy `/api` cookie and writes the root-path cookie. The session route already invokes it on both success and error responses. That behavior is a required invariant, not a side effect to remove.

## Browser and mobile boundary

The web transport uses `credentials: "include"` and the React `SessionProvider` currently interprets a rejected bootstrap `401` as `signedOut`. A browser `204` should therefore be represented as an anonymous/signed-out result by the web auth adapter rather than treated as a JSON session.

The mobile transport is independently implemented in `mobile/lib/data/auth/auth_transport.dart` and always sends the exact `X-Client: mobile` marker. Its generated Dart auth repository calls the same endpoint and its current session gate is built around a `401` failure. The existing marker is already an intentional transport distinction: the backend uses it when a native client has no browser `Origin` for CSRF checks.

**Recommended boundary:** make `204` browser-only by recognizing `X-Client: mobile` on the backend and retaining the current `401` no-session behavior for that native client. This avoids forcing the independently governed mobile client and generated Dart API to parse a new empty success response. The browser request needs no new header. The API contract should document both `204` and `401`, with the conditional nature explained in the operation description. If product owners instead want one shared semantic for all clients, the simpler route branch is “no cookie => 204” for everyone, but that would require explicit mobile client handling and generated-client verification.

The distinction must be based on cookie presence, not on whether validation succeeds:

```text
no cc_session + browser       -> set/normalize CSRF, 204
no cc_session + mobile       -> existing 401, set/normalize CSRF as applicable
cc_session present + invalid -> service validation, 401
cc_session present + expired -> service validation, 401/session_expired
cc_session present + valid   -> 200 identity, set/normalize CSRF
```

Do not use a failed `session_identity()` call to infer anonymous state: doing so would accidentally turn invalid, expired, or revoked cookies into anonymous success.

## Backend impact

Smallest coherent backend change:

1. Add a route-local distinction for a missing session cookie and the existing native-client marker.
2. Keep the existing `set_csrf_cookie()` call on every route outcome, including the new `204` response, so legacy-cookie cleanup and login initialization remain intact.
3. Return an empty `Response(status_code=204)` only for the browser/no-cookie branch.
4. Leave `AuthService._validated_session()` and all protected dependencies unchanged. They must continue to reject missing or invalid credentials for protected resources.

Likely backend acceptance coverage:

- no cookies: browser session probe is `204`, has no JSON body, and sets `cc_csrf` at `/` while expiring `/api` legacy CSRF;
- no cookies with `X-Client: mobile`: remains `401` if browser-only behavior is selected;
- arbitrary/unknown `cc_session`: `401` and no anonymous success;
- expired and revoked sessions: retain their current `401` semantics and error codes;
- valid session: remains `200` with the same identity payload;
- login after anonymous bootstrap: succeeds with the initialized CSRF token and preserves the existing session/cookie assertions;
- legacy CSRF normalization remains covered without changing the existing uncommitted test intent.

## Web transport and provider impact

Relevant files are under `web/` (not repository-root `src/`):

- `web/src/app/auth/session-provider.tsx` calls the generated `AuthApi` session method and currently expects `Promise<SessionIdentityResponse>`.
- `web/src/core/http-client.ts` already handles generic `204` for its `json()` helper, but the generated auth call uses the generated runtime response parser directly.
- `web/tests/core/core.test.ts` currently asserts auth-session `401`; that assertion must become the new anonymous transport contract while preserving “auth 401 does not notify protected state”.
- `web/tests/features/auth/session-provider.test.tsx` covers bootstrap failures, expired sessions, and login continuity; it needs explicit anonymous-bootstrap coverage and must retain invalid/expired-cookie coverage.

The generated TypeScript client under `web/src/generated/api/**` is derived output and must not be hand-edited. The contract source is `contracts/openapi.json`, generated from the FastAPI app by `backend/scripts/export_openapi.py`; `web/package.json` pins the regeneration command. The implementation phase should change the handwritten route/export source first, regenerate the contract/client through the pinned workflow, and inspect the generated `AuthApi` behavior for a `204` response. If the generator cannot safely model a no-content alternative for the existing typed method, keep the generated files untouched and put the narrow 204-aware adaptation in handwritten `web/src/app/auth/session-provider.tsx` or the shared transport wrapper, according to the generated runtime’s verified behavior.

The web provider should preserve these state rules:

- `200` identity -> `authenticated`;
- browser anonymous `204` -> `signedOut` without an error/notice and without protected queries;
- `401 unauthorized` from a request with a session cookie -> signed-out/error behavior remains available;
- `401 session_expired` -> `sessionExpired` and the existing explicit message;
- login still reads `getCsrfToken()` and sends the generated login request normally.

Avoid adding polling, duplicate bootstrap requests, or a client-side cookie probe. A single request with server-owned semantics is the smallest path and keeps the existing React provider waterfall unchanged.

## Contract and generated-client drift

Current OpenAPI export logic explicitly adds only `401` to the session probe (`backend/scripts/export_openapi.py`) and the checked-in snapshot documents `200` plus `401`. The contract change should add a `204` response with no content and retain `401`. The operation description should explain that anonymous browser bootstrap is `204`, while authenticated/invalid session-cookie validation remains distinct; if the mobile-only branch is retained, document the native marker behavior without weakening the general security contract.

Expected contract work:

- update handwritten OpenAPI export enrichment;
- regenerate `contracts/openapi.json` through the repository workflow;
- regenerate the web client only if the generator output changes and the generated method remains usable;
- run the contract drift check and web typecheck/tests;
- do not manually edit generated TypeScript or Dart artifacts.

The mobile generated contract may be regenerated if the authoritative OpenAPI change requires it, but mobile behavior is independently owned. The preferred design avoids changing the mobile runtime behavior and should not modify mobile source/tests in this change unless a contract-generation check proves a required mechanical update.

## Files/surfaces to preserve

The user identified existing uncommitted work that must not be reverted or edited:

- backend session/auth tests already in progress;
- CSRF cookie normalization changes, especially legacy `/api` cleanup;
- Docker files.

This exploration itself created only `openspec/changes/fix-anonymous-session-bootstrap/exploration.md`. No source, generated client, contract snapshot, test, Docker, or unrelated OpenSpec file was edited.

## Risks and unresolved implementation checks

- OpenAPI generators differ in how they represent a response union containing `204` and a JSON `200`; generated runtime behavior must be inspected after regeneration rather than assumed.
- A browser-only status requires preserving the exact native marker contract. Treating any arbitrary `X-Client` value as native would be unsafe; only the existing exact `mobile` marker should select the native path.
- The route must not use `204` for a present but invalid cookie, otherwise stale/revoked cookies would be silently accepted as anonymous and the requested security behavior would regress.
- Existing test files are uncommitted. Implementation must add focused assertions without broad rewrites or conflict-prone formatting changes.
- CodeGraph was checked first but was unavailable in this execution surface; read-only repository inspection therefore used targeted filesystem reads/searches. No CodeGraph-dependent worktree was created.

## Recommended next phase

Proceed to proposal/specification with the browser-only boundary as the working recommendation, explicitly recording the mobile tradeoff and the generated-client verification spike. Keep the product invariant order: preserve CSRF initialization and invalid-cookie `401` behavior first, then introduce browser anonymous `204`, then adapt/regenerate the web contract/client only as required by the pinned generator.
