# Apply Progress: Anonymous Browser Session Bootstrap

## Phase status

- Phase: `sdd-apply` retry, bounded implementation slice
- Change: `fix-anonymous-session-bootstrap`
- Execution mode: `auto`
- Artifact context requested by parent: `both`; native local status reported authoritative `artifactStore: openspec` because the OpenSpec directory exists
- Delivery: `exception-ok`, `stacked-to-main`
- Review budget: 400 changed lines; no chained PR recommended
- Strict TDD: active (`RED -> GREEN -> TRIANGULATE -> REFACTOR`)
- Native status consumed before editing: `applyState: ready`, `dependencies.apply: ready`, `nextRecommended: apply`, `actionContext.mode: repo-local`, workspace root is the repository, and the allowed root covers the approved edit surfaces. No action-context or edit-root warnings.
- Runtime attempt: authenticated the parent-owned ordinal-2 attempt with its opaque token; native status reported `max_changed_lines: 400`, `changed_lines: 0` at start, and the prior timed-out attempt as cleaned/invalidated by the user-authorized reset.

## Completed implementation work and persisted checkboxes

The following implementation-owned tasks are checked in `tasks.md` immediately after completion:

- Inspected the starting worktree and preserved the pre-existing auth/CSRF, security-transport, Docker, and documentation changes.
- Added RED coverage for browser no-cookie `204`, empty body, CSRF initialization, validation bypass, exact mobile `401`, non-exact marker browser behavior, OpenAPI `200`/`204`/`401`, the generated-client parser boundary, clean web signed-out state, one probe, protected-query disablement, and login CSRF continuity.
- Implemented the backend `token is None` branch with an exact `X-Client: mobile` exception and reused `set_csrf_cookie()` on the direct `204` response. Present cookies, including empty values, remain on normal validation.
- Enriched the session OpenAPI operation and regenerated `contracts/openapi.json` only through `python -m backend.scripts.export_openapi`.
- Inspected the existing generated TypeScript raw method/runtime and the current mobile generated auth/runtime seam. The TypeScript raw method exposes `response.raw`; `JSONApiResponse.value()` calls `raw.json()` unconditionally, so the handwritten boundary checks status before calling it.
- Added the narrow `generatedAuthClient.getSession()` adapter and mapped only `undefined` to a clean `signedOut` snapshot without `handleProtectedState`. Authenticated `200`, `401`, `session_expired`, login/logout, CSRF, and protected-query guards remain on their existing paths.
- Added the present-cookie triangulation for empty, unknown, and expired tokens, while retaining existing valid-session and revoked-session coverage.
- Completed final focused tests and typecheck after formatting cleanup.

## Files changed by this apply slice

- `backend/app/api/routes/auth.py`
- `backend/scripts/export_openapi.py`
- `backend/tests/integration/api/test_auth_routes.py` (required assertions and additive focused coverage layered over the user's pre-existing auth/CSRF changes)
- `backend/tests/test_openapi_contract.py`
- `contracts/openapi.json` (workflow output)
- `web/src/app/auth/session-provider.tsx`
- `web/tests/features/auth/session-provider.test.tsx`
- `web/tests/core/core.test.ts`
- `openspec/changes/fix-anonymous-session-bootstrap/tasks.md`
- `openspec/changes/fix-anonymous-session-bootstrap/apply-progress.md`

No `web/src/generated/api/**` file changed. No `mobile/lib/generated/api/**` file changed. No Docker, credential, mobile product, shared session-service, protected-dependency, commit, push, reset, clean, or broad-formatting action was performed.

## Strict TDD cycle evidence

| Cycle/task group | Test layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- |
| Backend session route and cookie behavior | Integration | `12 passed` baseline auth/OpenAPI run | Added browser `204`, exact mobile, near-miss, and cookie-matrix tests; RED run had `6 failed, 10 passed` | Route implementation followed; focused auth/OpenAPI run `16 passed` | Added empty/unknown/expired present-cookie cases; auth route run `12 passed`; final auth/OpenAPI run `19 passed` | No production refactor needed; final focused run remained green |
| OpenAPI enrichment | Contract/unit | Included in `12 passed` baseline | Added response/status/description assertions; RED failed on missing `204` | Export enrichment made focused contract tests pass | Confirmed `204` has no `content` and session description distinguishes browser/mobile/present-cookie paths | Local enrichment remains narrow; no security requirement added |
| Generated web session boundary | Unit/integration seam | Web baseline: `25 passed`; typecheck passed | Successful mocked `204` initially rejected with `SyntaxError: Unexpected end of JSON input` | Raw status check returns `undefined`; focused web run `28 passed` | Preserved generated `200`/`401` path through raw response/value normalization | No generated-file refactor; handwritten adapter only |
| SessionProvider anonymous state and login continuity | Component/integration | Included in web baseline | Anonymous result initially became `authenticated` with no session | Explicit `undefined` branch produces clean `signedOut` | One probe, no query function call, no error/notice, and bootstrap CSRF login were asserted; final provider file `12 tests passed` | No provider helper refactor needed |

### RED evidence

- Backend RED command: `python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q`; result: `6 failed, 10 passed in 2.72s`.
- Web RED command: `npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts --run`; result: `2 failed, 26 passed` (the core/API-client files passed; generated `204` parsing and provider state failed as expected).

## Verification evidence

Safety net before edits:

- `python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q` -> `12 passed in 3.33s`.
- `npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts --run` -> `3 files, 25 tests passed`.
- `npm --prefix web run typecheck` -> passed with no output.

Final bounded focused checks:

- `python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q` -> `19 passed in 2.97s`.
- `npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts --run` -> `3 files, 29 tests passed` (`15` core, `2` API-client, `12` session-provider).
- `npm --prefix web run typecheck` -> passed with no output.
- `git diff --check` for all apply-owned source/test/contract paths -> passed; only Git's existing LF/CRLF warnings were reported.

Runtime and broad contract limitations required by this bounded retry:

- Browser/Docker runtime evidence: `N/A` in apply; the parent explicitly deferred Docker runtime and broad verification to `sdd-verify`. Focused HTTPX coverage proves the route's `204`/cookie/login behavior, and Vitest covers the web state/login boundary.
- `python -m backend.scripts.check_contract_drift --cwd .`: not run in apply; deferred to `sdd-verify`.
- Full backend suite, security-transport regression suite, Ruff, web build, Flutter tooling, and Docker runtime: not run in apply by explicit scope.
- Pinned web-generator dry run showed writes across the entire generated tree, not a minimal change. The current generated raw seam was already available, so no generated TypeScript files were changed. The mobile generator/build was intentionally not run: the parent explicitly excluded `mobile/lib/generated/api/**` after the prior 1350-line churn and timeout. This is an intentional scope decision, not an unverified generated-file mutation.

## Workload and PR boundary

The implementation remains one cohesive work unit: route behavior, contract enrichment, handwritten web boundary, and tests together. The repository diff for touched paths reports `334` added/deleted lines including pre-existing auth/CSRF working-tree changes; the apply-authored portion is estimated at approximately `275` lines after excluding those pre-existing changes, under the explicit 400-line budget. No `size:exception` is needed for this retry. Parent-owned bounded review and delivery lifecycle actions remain deferred.

## Deviations from design

- The design's full mobile generation path was deliberately not executed because the parent retry scope explicitly forbids regenerating mobile output. Existing mobile generated files remain byte-for-byte untouched.
- The pinned TypeScript generator was evaluated with `--dry-run`; it reported broad generated-tree writes rather than a minimal actual change. The handwritten adapter was therefore implemented against the existing generated raw method as instructed, without hand-editing generated files.
- Broad verification and contract drift remain for `sdd-verify`; no full-verification success is claimed.

## Remaining tasks and deferred lifecycle actions

The following exact unchecked rows remain in `tasks.md`:

- [ ] Add or preserve failing present-cookie cases in `backend/tests/integration/api/test_auth_routes.py` for empty, malformed, unknown, revoked, expired, inactive-account, and otherwise unusable cookies, proving validation is called and `401`/`session_expired` semantics remain unchanged; retain valid-cookie `200` identity and server-derived role coverage. <!-- sdd-owner: implementation -->
- [ ] Add or rerun backend matrix coverage for exact versus near-miss mobile markers, present-empty cookie, malformed/unknown/revoked/expired/inactive cookies, valid identity, `204` body and headers, root-plus-legacy CSRF cookies, and no validation call on browser no-cookie requests. <!-- sdd-owner: implementation -->
- [ ] Verify protected-resource regressions in `backend/tests/integration/api/test_security_transport.py`: missing credentials remain rejected and the session-probe exception does not authorize protected resources. <!-- sdd-owner: implementation -->
- [ ] Run `python -m backend.scripts.check_contract_drift --cwd .` and compare generated trees to the pinned workflow; do not hand-edit `contracts/openapi.json`, TypeScript, Dart, or serialization outputs. <!-- sdd-owner: implementation -->
- [ ] Run `python -m pytest backend/tests/integration/api/test_security_transport.py -q` and the broader applicable backend gates, including `python -m pytest backend/tests -q` and `python -m ruff check backend`. <!-- sdd-owner: implementation -->
- [ ] Run `npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts`, `npm --prefix web run typecheck`, and `npm --prefix web run build`. <!-- sdd-owner: implementation -->
- [ ] Start or reuse the bounded review for the single cohesive work unit after source-mutating normalization and verify the final candidate against the recorded evidence. <!-- sdd-owner: parent -->
- [ ] Apply the existing `exception-ok`/`stacked-to-main` delivery decision only if the measured authored diff exceeds the explicit 400-line budget; otherwise keep this as one reviewable work unit. <!-- sdd-owner: parent -->

## Native attempt settlement

- The first settle request was rejected with `undeclared_untracked`; it made no mutation and was retried with an explicit `select` ruling for the existing untracked candidate paths.
- The second settle request returned `state: blocked`, `reason: maintainer_decision`. Native status records the attempt outcome as `passed` but reports `decision_required: true`, `next_action: reset`, and `changed_lines: 1369`, exceeding the native 400-line budget because its accounting includes the preserved pre-existing/untracked candidate state. This is distinct from the authored apply estimate above and includes no mobile-generator churn from this retry.
- No automatic reset, commit, push, clean, or review action was attempted. A maintainer must resolve the native attempt accounting/reset decision before the parent can route verification.

Next phase recommendation: `blocked` pending the native maintainer decision/reset. After that decision is explicitly resolved, route to `sdd-verify` for the deferred backend security, full gates, drift, and build checks. Native review/lifecycle remains parent-owned and must not be started by `sdd-apply`.

## Bounded remediation continuation

- Phase: `sdd-apply` remediation for the missing present-cookie evidence identified by `verify-report.md`.
- Scope honored: only `backend/tests/integration/api/test_auth_routes.py`, this file, and the corresponding implementation-owned rows in `tasks.md` were edited. Product source, generated outputs, contract snapshot, Docker, mobile, credentials, and unrelated worktree changes were left untouched.
- The parent supplied the active native remediation attempt and explicitly authorized the bounded 400-line path. No additional attempt was acquired or reset.
- Native status consumed before editing: `artifactStore: openspec` (authoritative because `openspec/` exists), `applyState: ready`, `dependencies.apply: ready`, `nextRecommended: apply`, `actionContext.mode: repo-local`, and the repository root was the allowed edit root. The status also retained the pre-existing verification blocker for the missing valid `gentle-ai.verify-result/v1` envelope; this remediation does not claim to resolve that parent/verification artifact issue.

### Remediation evidence

- Extended the existing parametrized present-cookie route test with `malformed-token` and `inactive-account-token` cases.
- Configured both added fake-service cases to raise `UnauthorizedError`, keeping the public result indistinguishable as `401`/`unauthorized` while proving `session_identity()` receives the present token.
- Retained the existing empty, unknown, and expired cases, including `session_expired`; revoked-after-logout, valid `200` identity/role, exact mobile `401`, near-miss marker `204`, browser `204`, CSRF normalization, and login-continuity evidence remain unchanged.
- The new assertions were written before execution. Because the bounded implementation was already present, no new RED failure was observed; this is recorded rather than fabricated as a failing run.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| Present malformed and inactive cookies | `backend/tests/integration/api/test_auth_routes.py` | Integration | ✅ Existing auth route baseline: `12 passed` | ✅ Assertions written first; no new RED observed because implementation already existed | ✅ Parametrized matrix now covers empty, malformed, unknown, inactive-account, and expired cookies; each asserts validation call and public `401` semantics | ➖ Test-only change; no production refactor needed |

### Required remediation test command

- `python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q` -> `21 passed in 5.59s`.
- This was the one required post-remediation execution. No product source was changed.

### Persisted task updates

The following two implementation-owned rows were changed from `- [ ]` to `- [x]` in `tasks.md` immediately after the remediation was completed:

- Present-cookie cases for empty, malformed, unknown, revoked, expired, inactive-account, and otherwise unusable cookies, with validation-call and `401`/`session_expired` evidence.
- Backend session-route matrix coverage for marker boundaries, present unusable cookies, valid identity, `204` body/headers, CSRF normalization, and validation bypass on browser no-cookie requests.

### Remaining tasks and warnings

The following exact unchecked rows remain in `tasks.md`:

- [ ] Verify protected-resource regressions in `backend/tests/integration/api/test_security_transport.py`: missing credentials remain rejected and the session-probe exception does not authorize protected resources. <!-- sdd-owner: implementation -->
- [ ] Run `python -m backend.scripts.check_contract_drift --cwd .` and compare generated trees to the pinned workflow; do not hand-edit `contracts/openapi.json`, TypeScript, Dart, or serialization outputs. <!-- sdd-owner: implementation -->
- [ ] Run `python -m pytest backend/tests/integration/api/test_security_transport.py -q` and the broader applicable backend gates, including `python -m pytest backend/tests -q` and `python -m ruff check backend`. <!-- sdd-owner: implementation -->
- [ ] Run `npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts`, `npm --prefix web run typecheck`, and `npm --prefix web run build`. <!-- sdd-owner: implementation -->
- [ ] Start or reuse the bounded review for the single cohesive work unit after source-mutating normalization and verify the final candidate against the recorded evidence. <!-- sdd-owner: parent -->
- [ ] Apply the existing `exception-ok`/`stacked-to-main` delivery decision only if the measured authored diff exceeds the explicit 400-line budget; otherwise keep this as one reviewable work unit. <!-- sdd-owner: parent -->

The generated-client drift warning remains explicit and unresolved: the pinned drift check recorded in `verify-report.md` reports existing/generated differences in `web/src/generated/api/apis/AuthApi.ts`, `mobile/lib/generated/api/lib/src/api/auth_api.dart`, three mobile generated model files, and `mobile/lib/generated/api/pubspec.yaml` (plus transient generated metadata). Generated outputs were intentionally left unchanged in this remediation, and the required focused pytest command is not evidence that contract drift passed. Parent review must continue to reconcile the existing generated-client provenance and drift warning.

## Remediation next action

After the parent resolves the native attempt/verification-envelope state, route to verification for the remaining implementation rows and preserve the generated-client drift warning. Parent-owned review, receipts, and delivery lifecycle actions remain deferred.

## Final-state handoff

The post-verification remediation added malformed and inactive present-cookie cases and passed `python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q` with `21 passed in 5.59s`. The recorded verification evidence also passed the security-transport suite (`6 passed`), full backend suite (`208 passed`), Ruff, full web suite (`67 passed`), typecheck, build, and Docker HTTP smoke. The generated-client drift warning described in the preceding intermediate sections was subsequently resolved by the deterministic web and mobile postprocessors.

## Final reconciliation — supersedes intermediate deferred sections

- The web normalizer now converges host-lint `let urlPath` changes to `const` for generated API files.
- The mobile normalizers now converge unused generated imports, SDK metadata, and the changed generated auth-test analyzer suppression in both temporary and committed output.
- `python -m pytest backend/tests/test_openapi_contract.py -q` -> `11 passed in 5.33s`.
- `python -m backend.scripts.check_contract_drift --cwd .` -> `Contract and generated clients are drift-free.`
- `openspec validate fix-anonymous-session-bootstrap --strict` and `gentle-ai sdd-verify-validate` both pass.
- All 32 task rows are now checked. Authored changes remain below the explicit 400-line budget; no `size:exception` or chained PR was created.
- Clone-local receipt-driven development is off, so no review receipt was started or fabricated. Delivery remains under ordinary repository policy; no commit, push, reset, or clean was performed.
