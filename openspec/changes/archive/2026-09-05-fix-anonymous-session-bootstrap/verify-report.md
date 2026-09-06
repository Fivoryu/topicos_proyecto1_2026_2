```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:cf3c0835bf118a0ef2c5667963a156f199c0778c01776b6834103e321a3b699e
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 4/4
scenarios: 21/21
test_command: python -m pytest backend/tests -q
test_exit_code: 0
test_output_hash: sha256:3a20eeebeb1296782b14a7685bf10e606fc90632b7f9d21f3176cedb0498d64f
build_command: npm --prefix web run build
build_exit_code: 0
build_output_hash: sha256:235fbf26f38d5b88caa96da6742b6bb42448201457a95715a8d98e47d1869f17
```

# Verification Report — Anonymous Browser Session Bootstrap

## Verdict

**PASS WITH WARNINGS — no critical blocker remains.**

The browser-only anonymous session bootstrap is implemented, the protected and mobile boundaries remain intact, the OpenAPI contract is current, generated-client drift is clean, and all 32 task rows are reconciled. The warnings are procedural: receipt-driven review is disabled for this clone, so delivery remains under ordinary repository policy; no commit or push was performed.

## Scope and task completion

- Requirements: **4/4**.
- Scenarios: **21/21**.
- Tasks: **32/32 checked** in `tasks.md`.
- Authored estimate: below the explicit 400-line budget; no size exception or chained PR was created.
- Existing unrelated auth/CSRF, security-transport, Docker, and documentation changes were preserved.
- No credentials, commits, pushes, resets, or broad cleans were introduced.

The parent-owned review row is closed with the explicit clone-local policy decision: `gentle-ai review mode status --scope clone --cwd .` reports receipt-driven development **off**, therefore no bounded review was started. The delivery row is closed as one ordinary-policy work unit because the authored estimate remains below 400 lines.

## Acceptance matrix

| Area | Evidence | Result |
| --- | --- | --- |
| Browser without `cc_session` | Auth integration tests and Docker HTTP smoke | PASS — `204`, empty body, no session validation, root `cc_csrf`, legacy `/api` cookie cleanup |
| Exact `X-Client: mobile` without a session | Auth integration tests and runtime smoke | PASS — existing `401 unauthorized` preserved |
| Near-miss client markers | Parametrized auth matrix | PASS — only the exact mobile marker keeps native `401`; other browser markers use `204` |
| Present cookies | Empty, malformed, unknown, revoked, expired, inactive-account, and valid cases | PASS — present values are validated; unusable values remain `401`/`session_expired`; valid identity remains `200` |
| CSRF and login continuity | Integration tests and runtime smoke | PASS — bootstrap initializes root CSRF, removes legacy `/api`, and immediate protected login succeeds with origin enforcement |
| Protected resources | Security transport suite and runtime smoke | PASS — anonymous session probing does not authorize protected resources |
| Web session provider | 67-test web suite, focused provider/core/API tests, typecheck, build | PASS — `204` becomes clean `signedOut`, one probe, no notice/error, no protected query call; `200` and `401` paths remain intact |
| OpenAPI contract | Export and contract tests | PASS — session `200`/`204`/`401`; `204` has no content; description documents browser, mobile, present-cookie, CSRF, and protected-resource boundaries |
| Generated clients | Pinned export → generation → Dart build → comparison | PASS — `Contract and generated clients are drift-free.` |

## Verification commands

| Command | Result |
| --- | --- |
| `python -m pytest backend/tests/integration/api/test_auth_routes.py backend/tests/test_openapi_contract.py -q` | PASS — `21 passed` after the present-cookie remediation |
| `python -m pytest backend/tests/test_openapi_contract.py -q` | PASS — `11 passed in 5.33s` after generated-auth-test normalization |
| `python -m pytest backend/tests/integration/api/test_security_transport.py -q` | PASS — `6 passed` |
| `python -m pytest backend/tests -q` | PASS — `208 passed`, one existing Starlette/httpx deprecation warning |
| `python -m ruff check backend` | PASS — all checks passed |
| `npm --prefix web run test` | PASS — 11 files, 67 tests |
| `npm --prefix web run test -- tests/features/auth/session-provider.test.tsx tests/core/core.test.ts tests/api-client.test.ts --run` | PASS — 29 tests |
| `npm --prefix web run typecheck` | PASS |
| `npm --prefix web run build` | PASS — 135 modules transformed |
| `python -m backend.scripts.check_contract_drift --cwd .` | PASS — `Contract and generated clients are drift-free.` |
| `openspec validate fix-anonymous-session-bootstrap --strict` | PASS — change is valid |
| `gentle-ai sdd-verify-validate --input openspec/changes/fix-anonymous-session-bootstrap/verify-report.md --requirements 4 --scenarios 21` | PASS — valid `gentle-ai.verify-result/v1` envelope |
| `git diff --check` | PASS — only existing LF/CRLF warnings |

The broad backend/web/build and Docker smoke evidence was recorded before this final generated-output reconciliation; the later changes are limited to the deterministic drift checker, generated output, and its contract-test coverage. The final focused tests and pinned drift run passed after those changes.

## Generated-output provenance

The pinned workflow now applies deterministic, idempotent post-generation normalization to host-stable output:

- TypeScript API files: non-reassigned generator `let urlPath` declarations become `const`.
- Dart API files: unused `ErrorResponse` imports receive a file-local suppression without removing used imports.
- Dart package metadata: the generated SDK floor is aligned with the host SDK.
- Generated auth test: the standalone scaffold receives a file-level analyzer suppression for unresolved host package-config diagnostics; test behavior is unchanged.

These normalizers run against both temporary and committed generated roots. No generated client was hand-authored; the final comparison is clean.

## Warnings and delivery boundary

1. Receipt-driven development is disabled at clone scope. No review receipt was fabricated or requested; ordinary repository policy remains the delivery gate.
2. The repository still contains the user's existing uncommitted worktree changes and untracked Docker/OpenSpec files. They were preserved and are not implicitly committed.
3. Coverage tooling was not configured; no coverage percentage is claimed. The backend suite retains its existing deprecation warning.

No critical finding or archive blocker remains in this verification report.
