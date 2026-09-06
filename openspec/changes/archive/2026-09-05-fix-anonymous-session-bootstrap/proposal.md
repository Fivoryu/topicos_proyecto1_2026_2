# Anonymous browser session bootstrap without an expected 401

## Intent

Remove the expected browser-console `401` during anonymous session bootstrap without weakening authentication. `GET /api/v1/auth/session` will return `204 No Content` when a browser has no `cc_session` cookie, while session-cookie validation and CSRF initialization remain server-owned.

The change preserves `401` for every present unusable session cookie and keeps login working with the CSRF token initialized during bootstrap.

## Product decision

The browser-only anonymous response is the smallest compatible behavior change:

| Request state | Required result |
| --- | --- |
| No `cc_session`, no exact `X-Client: mobile` marker | `204 No Content`, with normal CSRF-cookie initialization and legacy `/api` cleanup |
| No `cc_session`, exact `X-Client: mobile` marker | Preserve the existing native-client `401` behavior |
| Present unknown, malformed, revoked, expired, inactive-account, or otherwise unusable `cc_session` | Preserve normal validation and `401` semantics, including `session_expired` where emitted |
| Present valid `cc_session` | Preserve the existing `200` identity response |
| Login after anonymous bootstrap | Continue using the initialized CSRF token and preserve existing login behavior |

The route must distinguish cookie absence before calling session validation. A validation failure must never be interpreted as anonymous state.

## Scope

### In scope

1. **Backend route behavior**
   - Add the missing-cookie branch in `backend/app/api/routes/auth.py` before `AuthService.session_identity()` is called.
   - Return an empty `204` response only for the browser/no-cookie branch.
   - Continue calling `set_csrf_cookie()` for the new response and all existing success/error outcomes so the root `cc_csrf` cookie is written and the legacy `/api`-scoped duplicate is removed.
   - Leave `AuthService._validated_session()` and protected-resource dependencies unchanged.

2. **Web transport and session provider**
   - Adapt the handwritten web auth boundary to represent the generated client's successful `204` response as an anonymous/signed-out bootstrap result rather than a JSON session.
   - Preserve the existing state rules: `200` becomes `authenticated`; anonymous `204` becomes `signedOut` without an error or notice; cookie-backed `401` behavior remains available; `session_expired` remains distinct.
   - Avoid polling, duplicate bootstrap requests, client-side cookie probing, or a new request waterfall.
   - Verify the generated runtime after regeneration before choosing whether the adaptation belongs in the generated-client boundary or handwritten `session-provider.tsx`/transport code.

3. **OpenAPI and generated contracts**
   - Update the handwritten OpenAPI enrichment in `backend/scripts/export_openapi.py` to document both `204` and `401` for the session probe, retaining `200`.
   - Explain the anonymous browser behavior and the exact native-client marker behavior in the operation description without weakening the security contract.
   - Regenerate `contracts/openapi.json` through the repository's pinned workflow.
   - Regenerate web or mobile generated clients only when the authoritative contract workflow requires it; inspect the result rather than assuming a `204`/JSON response union is handled safely.
   - Never hand-edit generated TypeScript, Dart, or contract output.

4. **Focused tests and verification**
   - Add or adjust backend coverage for browser no-cookie `204`, empty body, CSRF root-cookie initialization, and legacy `/api` cleanup.
   - Preserve coverage for mobile no-cookie behavior if the exact native marker boundary is retained, present invalid/expired/revoked cookies, valid sessions, and login after bootstrap.
   - Add web transport/session-provider coverage for anonymous `204`, absence of bootstrap error/notice, no protected queries while signed out, invalid/expired-cookie handling, and login continuity.
   - Run the contract drift check, relevant backend tests, web typecheck, and focused web tests.
   - Keep existing uncommitted auth/CSRF normalization tests and Docker files untouched except for narrowly additive or required assertion changes; do not reset or reformat unrelated work.

## Affected areas

| Area | Expected impact |
| --- | --- |
| `backend/app/api/routes/auth.py` | Early distinction between missing and present session cookies; no change to service validation semantics. |
| `backend/app/adapters/security/sessions.py` | No behavior change; its CSRF normalization remains an invariant verified by the new response path. |
| `backend/scripts/export_openapi.py` and `contracts/openapi.json` | Add/document the `204` session-probe response while retaining `200` and `401`; snapshot is regenerated, not hand-edited. |
| `web/src/app/auth/session-provider.tsx` and generated auth runtime | Interpret successful anonymous `204` safely while preserving authenticated, expired, and invalid-session states. |
| `web/src/core/http-client.ts` and focused web tests | Verify existing successful-`204` handling and auth-error isolation without broad transport changes. |
| Mobile contract/runtime | No product behavior change. Mechanical generated updates are allowed only if required by contract regeneration and must be verified. |
| Docker and unrelated working-tree changes | Explicitly unchanged. |

## Non-goals

- Do not change mobile product behavior or mobile source/tests unless a contract-generation check requires a mechanical generated update.
- Do not change protected-resource authorization or make missing credentials acceptable outside this session-probe transport contract.
- Do not change credential storage, login credentials, session issuance, revocation, expiration, or CSRF policy.
- Do not hand-edit generated files.
- Do not change Docker files.
- Do not commit, push, or clean/revert existing working-tree changes.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| A present invalid, expired, or revoked cookie is accidentally treated as anonymous | Branch on cookie presence before validation; test each representative failure and preserve existing error codes. |
| The new `204` path skips CSRF initialization or legacy-cookie cleanup | Keep `set_csrf_cookie()` on the response and assert both root-cookie creation and `/api` cleanup. |
| The generated TypeScript client cannot safely parse a successful `204` alongside the typed `200` response | Regenerate through the pinned workflow, inspect the generated parser, and keep any required adaptation narrow and handwritten. |
| Mobile behavior changes unintentionally | Recognize only the existing exact `X-Client: mobile` marker for the native compatibility branch; verify mobile behavior and allow only mechanical generated output changes. |
| Existing uncommitted work is overwritten or obscured | Limit edits to the listed source/contract/test surfaces, inspect the working tree before and after, and avoid resets, broad formatting, Docker edits, commits, and pushes. |

## Rollback

Rollback is limited to this change's route branch, OpenAPI enrichment, handwritten web adaptation, and outputs regenerated from those sources. Restore the prior session-probe contract and regenerate affected snapshots/clients through the pinned workflows. Do not revert or clean unrelated uncommitted auth, CSRF, or Docker work.

## Success criteria

- An anonymous browser `GET /api/v1/auth/session` returns exactly `204 No Content` with no JSON body and does not produce the expected console `401`.
- The same anonymous response initializes the readable root `cc_csrf` cookie and removes the legacy `/api`-scoped CSRF cookie.
- Requests with present invalid, expired, revoked, inactive-account, malformed, or unknown session cookies remain `401`; `session_expired` behavior is unchanged.
- Valid sessions remain `200` with the same identity payload.
- The web `SessionProvider` reaches `signedOut` for anonymous `204` without an error/notice and does not enable protected queries.
- Login immediately after anonymous bootstrap continues to use the initialized CSRF token and succeeds under existing assertions.
- The OpenAPI contract documents `200`, `204`, and `401` for the session probe, generated outputs remain workflow-derived, and contract drift/typecheck/focused tests pass.
- No Docker changes, credential changes, commits, pushes, or unrelated working-tree modifications are introduced.

## Delivery boundary

This artifact is planning only. Product code, generated outputs, tests, and contract snapshots must be changed only in the later implementation phase, with the existing working tree preserved.
