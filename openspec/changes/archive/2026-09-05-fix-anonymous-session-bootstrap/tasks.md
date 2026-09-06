# Implementation Tasks: Anonymous Browser Session Bootstrap

## Review Workload Forecast

| Field | Value |
| ------- | ------- |
| Estimated changed lines | 360–430 authored lines, excluding workflow-generated output from the authored estimate |
| 400-line budget risk | Medium |
| Chained PRs recommended | No |
| Suggested split | Single cohesive work unit/commit: tests with the backend, contract, and web behavior they verify |
| Delivery strategy | exception-ok |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: stacked-to-main
400-line budget risk: Medium

The single work unit has one start boundary (current working tree preserved; focused RED tests added) and one finish boundary (all source, tests, generated outputs, and verification evidence for this session-probe behavior pass). If the measured authored diff exceeds 400 lines, record the accepted `size:exception` under the existing `exception-ok` strategy rather than deleting coverage or splitting tests from behavior. Generated OpenAPI/client output is workflow-derived and must be included in the final candidate identity, but is excluded from the authored-line estimate. Runtime evidence is required for the backend/web bootstrap and login continuity; if no runtime harness is available, record `N/A` with the reason and retain focused test evidence. Rollback is limited to the route branch, OpenAPI enrichment, handwritten web adapter/provider change, and outputs regenerated from them; do not revert unrelated auth/CSRF or Docker work.

## Implementation Work

### 1. RED — establish protected baseline and failing backend behavior

- [x] Inspect `git status --short` and the existing auth/CSRF and Docker diffs; record the exact unrelated paths that must remain untouched throughout implementation. <!-- sdd-owner: implementation -->
- [x] Add failing route tests in `backend/tests/integration/api/test_auth_routes.py` for browser no-cookie `204`, empty body, no call to `AuthService.session_identity()`, root `cc_csrf` initialization, `/api`-scoped CSRF cleanup, and absence of a session cookie. <!-- sdd-owner: implementation -->
- [x] Add failing exact-marker compatibility coverage in `backend/tests/integration/api/test_auth_routes.py` for no cookie plus exactly `X-Client: mobile` returning the existing `401` envelope and never `204`; cover near-miss marker values as browser behavior where the existing boundary requires it. <!-- sdd-owner: implementation -->
- [x] Add or preserve failing present-cookie cases in `backend/tests/integration/api/test_auth_routes.py` for empty, malformed, unknown, revoked, expired, inactive-account, and otherwise unusable cookies, proving validation is called and `401`/`session_expired` semantics remain unchanged; retain valid-cookie `200` identity and server-derived role coverage. <!-- sdd-owner: implementation -->
- [x] Add a failing bootstrap-to-login regression in `backend/tests/integration/api/test_auth_routes.py` or the existing auth integration seam proving the root CSRF token from anonymous bootstrap is accepted by the existing login/origin protections. <!-- sdd-owner: implementation -->
- [x] Add failing OpenAPI assertions in `backend/tests/test_openapi_contract.py` for session responses `200`, `204`, and `401`, no `content` under `204`, and description text distinguishing browser no-cookie, exact mobile no-cookie, and present-cookie validation. <!-- sdd-owner: implementation -->
- [x] Add failing web tests in `web/tests/features/auth/session-provider.test.tsx` and the narrow generated-client/transport seam for successful `204` status-before-JSON handling, clean `signedOut`, one probe only, no error/notice, disabled protected queries, preserved `200`, and preserved `401`/`session_expired` behavior. <!-- sdd-owner: implementation -->
- [x] Extend only the relevant assertions in `web/tests/core/core.test.ts` or `web/tests/api-client.test.ts` for existing successful-`204` response handling, auth-401 isolation, credentials, and login CSRF continuity; do not broaden global transport behavior. <!-- sdd-owner: implementation -->
- [x] Run the affected RED commands once and retain the failing evidence before production implementation. <!-- sdd-owner: implementation -->

### 2. GREEN — implement the smallest backend and web behavior

- [x] Update `backend/app/api/routes/auth.py` to branch immediately after reading `cc_session`: use `token is None`, compare the existing native header value exactly to `X-Client: mobile`, return a direct empty `Response(status_code=204)` only for the browser branch, and leave every present value—including `""`—on normal validation. <!-- sdd-owner: implementation -->
- [x] Reuse `set_csrf_cookie()` on the new `204` response while preserving its existing success and error calls, so root `cc_csrf` initialization and legacy `/api` cleanup remain server-owned; do not modify `backend/app/application/auth_service.py`, `backend/app/api/deps.py`, or `backend/app/adapters/security/sessions.py`. <!-- sdd-owner: implementation -->
- [x] Update `backend/scripts/export_openapi.py` to retain `200` and `401`, add a no-content `204`, and document the exact marker, present-cookie validation, CSRF normalization, and protected-resource boundary without adding a session security requirement. <!-- sdd-owner: implementation -->
- [x] Run the pinned export and inspect `contracts/openapi.json`; regenerate `web/src/generated/api/**` and `mobile/lib/generated/api/**` only through the repository workflow, never by hand, and retain only actual generator-produced changes. <!-- sdd-owner: implementation -->
- [x] Inspect the regenerated `web/src/generated/api/apis/AuthApi.ts`, `web/src/generated/api/runtime.ts`, and relevant mobile generated auth/runtime files to determine whether `204` is safely represented; document the observed parser/status shape before selecting the handwritten seam. <!-- sdd-owner: implementation -->
- [x] Implement the narrowest handwritten web adaptation in the generated-auth boundary or `web/src/app/auth/session-provider.tsx`: status-check before JSON parsing when required, map successful `204` to `undefined`/anonymous, preserve `200` identity, preserve `401` normalization and distinct `session_expired`, and avoid changes to shared transport unless inspection proves a minimal helper necessary. <!-- sdd-owner: implementation -->
- [x] Map anonymous `204` directly to a clean `signedOut` snapshot in `web/src/app/auth/session-provider.tsx` without `handleProtectedState`, duplicate probing, cookie probing, polling, protected-query enablement, or protected rendering; keep login/logout generated calls and CSRF/origin enforcement unchanged. <!-- sdd-owner: implementation -->
- [x] Run focused backend, OpenAPI, and web tests after each bounded GREEN slice until the RED cases pass. <!-- sdd-owner: implementation -->

### 3. TRIANGULATE — prove boundaries and prevent regressions

- [x] Add or rerun backend matrix coverage for exact versus near-miss mobile markers, present-empty cookie, malformed/unknown/revoked/expired/inactive cookies, valid identity, `204` body and headers, root-plus-legacy CSRF cookies, and no validation call on browser no-cookie requests. <!-- sdd-owner: implementation -->
- [x] Verify protected-resource regressions in `backend/tests/integration/api/test_security_transport.py`: missing credentials remain rejected and the session-probe exception does not authorize protected resources. <!-- sdd-owner: implementation -->
- [x] Verify web provider behavior with one session probe, clean anonymous state, no bootstrap notice/error, no protected TanStack Query function calls, no protected shell/data, unchanged authenticated `200`, and preserved invalid/expired-cookie behavior. <!-- sdd-owner: implementation -->
- [x] Verify immediate login after anonymous bootstrap consumes the initialized root CSRF token and retains existing origin enforcement, including rejection coverage for missing/invalid protection. <!-- sdd-owner: implementation -->
- [x] Run `python -m backend.scripts.check_contract_drift --cwd .` and compare generated trees to the pinned workflow; do not hand-edit `contracts/openapi.json`, TypeScript, Dart, or serialization outputs. <!-- sdd-owner: implementation -->
- [x] Inspect the final diff and status to confirm only the approved source/test/contract/generated paths changed, with existing uncommitted auth/CSRF and Docker work preserved exactly except for narrowly required assertions. <!-- sdd-owner: implementation -->

### 4. REFACTOR — stabilize without widening scope

- [x] Simplify only local route/provider helpers or fixtures after behavior passes; preserve the `token is None` distinction, exact marker comparison, server CSRF normalization, generated-runtime boundary, and protected-query guards. <!-- sdd-owner: implementation -->
- [x] Run focused suites and confirm the refactor produces no behavior or generated-output drift. <!-- sdd-owner: implementation -->

### 5. Full verification and evidence

- [x] Run `python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q`. <!-- sdd-owner: implementation -->
- [x] Run `python -m pytest backend/tests/integration/api/test_security_transport.py -q` and the broader applicable backend gates, including `python -m pytest backend/tests -q` and `python -m ruff check backend`. <!-- sdd-owner: implementation -->
- [x] Run `npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts`, `npm --prefix web run typecheck`, and `npm --prefix web run build`. <!-- sdd-owner: implementation -->
- [x] Record focused test results, typecheck/build results, contract drift result, generated-runtime inspection evidence, runtime bootstrap/login evidence, and rollback boundary; use explicit `N/A` plus a reason only where runtime evidence cannot be executed. <!-- sdd-owner: implementation -->
- [x] Confirm no Docker files, credentials, unrelated working-tree files, commits, pushes, resets, cleans, or broad reformatting were introduced. <!-- sdd-owner: implementation -->

## Parent-Owned Review and Lifecycle Actions

- [x] Start or reuse the bounded review for the single cohesive work unit after source-mutating normalization and verify the final candidate against the recorded evidence. **CLOSED: clone-local receipt-driven development is off (`gentle-ai review mode status`); no review was started, and the ordinary verification evidence is recorded in `verify-report.md`.** <!-- sdd-owner: parent -->
- [x] Apply the existing `exception-ok`/`stacked-to-main` delivery decision only if the measured authored diff exceeds the explicit 400-line budget; otherwise keep this as one reviewable work unit. **CLOSED: authored estimate remains below 400 lines, so no size exception or chain was created; delivery remains under ordinary repository policy.** <!-- sdd-owner: parent -->
