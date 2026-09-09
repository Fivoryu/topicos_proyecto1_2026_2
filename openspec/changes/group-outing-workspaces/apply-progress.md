# Apply Progress: Group Outing Workspaces

## PR 0 — Policy/spec synchronization

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `dependencies.apply=ready`, `nextRecommended=apply`.
- Delivery boundary: PR 0 only; `exception-ok`, `stacked-to-main`, forecast `180–340`, hard maximum `800` changed lines.
- Parent-owned native SDD attempt authority is already held for this work unit; no second acquire was issued.
- `actionContext` was not included in the parent status summary. Warning: this run was constrained to the explicit repository-local PR 0 allowed edit surfaces and did not edit outside them.
- Produced phase status: `blocked` because the required strict OpenSpec validation remains red on pre-existing change-local delta omissions outside the allowed edit surfaces.

### TDD Cycle Evidence

| Task | Test/validation input | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR 0 RED | `openspec validate group-outing-workspaces --strict` | Artifact validation | Existing artifact readback | ✅ Ran; exit 1 with expected pre-amendment delta omissions | — | — | — |
| PR 0 GREEN | Eight allowed living-policy files | Policy/spec artifact | ✅ Existing canonical specs read | ✅ Acceptance rules identified before edits | ✅ Amendments written | — | — |
| PR 0 TRIANGULATE | Read-only policy/path assertions | Artifact/path audit | ✅ Protected dirty paths observed before edits | ✅ Preconditions recorded | ✅ Passed: exclusions, Samaipata, scope, and protected-path checks | — |
| PR 0 REFACTOR/evidence | `openspec validate group-outing-workspaces --strict` and `git diff --check` | Artifact validation | ✅ `git diff --check` clean | — | — | ✅ Path/line checks passed | ⚠ Markdown clean, strict gate blocked by out-of-scope pre-existing errors |

### Completed implementation-owned tasks

- [x] PR 0 RED — the pre-amendment strict validation was run and its expected failures were recorded.
- [x] PR 0 GREEN — the accepted policy was amended only in the allowed living-policy files.
- [x] PR 0 TRIANGULATE — exclusions, protected boundaries, and the changed-line cap were checked read-only.

The corresponding three cycle rows and the focused-evidence row in `tasks.md` are visibly marked `[x]`. Only PR 0 REFACTOR remains unchecked because the strict artifact gate is not green.

### Files changed by this apply

- `openspec/project-context.md`
- `openspec/specs/groups/spec.md`
- `openspec/specs/api/spec.md`
- `openspec/specs/persistence/spec.md`
- `openspec/specs/expenses/spec.md`
- `openspec/specs/settlement/spec.md`
- `openspec/specs/clients/spec.md`
- `docs/sdd-evolution.md`
- `openspec/changes/group-outing-workspaces/tasks.md` — only the four completed PR 0 RED/GREEN/TRIANGULATE/evidence checkboxes
- `openspec/changes/group-outing-workspaces/apply-progress.md`

No product source, tests, generated client, mobile file, proposal, exploration, design, change-local spec, `AGENTS.md`, historical/archive artifact, official fixture, or `web-professional-redesign` file was edited.

### Validation and exact line count

- RED command: `openspec validate group-outing-workspaces --strict` — exit `1` before amendments. It reported omitted scenarios in `api/spec.md`, `clients/spec.md`, `demo-readiness/spec.md`, `groups/spec.md`, `persistence/spec.md`, and `web-presentation/spec.md`.
- GREEN/recheck command: `openspec validate group-outing-workspaces --strict` — exit `1` after amendments with the same 13 pre-existing omissions. Resolving them requires editing protected change-local specs, which is forbidden for this PR 0 run.
- `git diff --check` — clean for the tracked policy files.
- Changed-line count: **274** authored PR 0 lines = 150 living-policy additions + 8 task-checkbox transitions + 116 apply-progress lines; the candidate remains below the 800-line cap. The pre-existing untracked proposal/design/change-local specs are excluded from this phase count.
- The four task checkbox transitions are the only task-artifact edits; apply-progress records this evidence without changing any PR 1–PR 9 task.
- Protected-path audit: no tracked `backend/`, `contracts/`, `mobile/`, `openspec/changes/`, `AGENTS.md`, historical, or fixture path appears in the implementation diff. Existing dirty `web/` and untracked `web-professional-redesign` paths were preserved and are unrelated pre-existing work.

### Policy outcome

The living policy now records authenticated multi-group creation/selection, owner/member and outing rules, reusable authenticated QR/code joining, atomic participant link-or-create, group-versus-outing derivation, membership history preservation, laptop-first navigation without a new dependency, the 800-line slice cap, and the explicit exclusions: public registration, QR account creation, anonymous access, email invitations, password recovery, OAuth, expiry, approval queues, ownership transfer, mobile UI parity, new routing dependencies, client-side money/authorization, new WebSocket payloads, and redesign edits. The official Samaipata fixture remains four all-general expenses with its documented exact balances and transfer order.

### Deviation/blocker

Rollback boundary: revert only the eight living-policy amendments and the PR 0 task/progress edits; never reset or clean protected web, redesign, source, generated, mobile, historical, or fixture paths.

Strict OpenSpec validation cannot be made green without modifying `openspec/changes/group-outing-workspaces/specs/**`, including `demo-readiness` and `web-presentation`, but those change-local specs are explicitly outside PR 0 allowed edit surfaces. Do not begin PR 1 until the parent resolves this scope conflict and reruns native status/validation.

### Remaining tasks (exact unchecked implementation and parent-owned rows)

```text
- [ ] REFACTOR — Normalize the living-policy prose for traceability and confirm no archived path, `AGENTS.md`, official fixture, or redesign path changed; run strict OpenSpec validation. <!-- sdd-owner: implementation -->
- [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
- [ ] RED — Add Testing Library tests for authenticated group list/create, zero-group state, one-group auto-selection, multi-group switching, stale/deep-link protection, query-key identity, cache clearing, and no protected render before session authentication; run affected Vitest files and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the additive hash parser/serializer, protected group picker/create flow, selected-group summary/empty workspace, account/group/selection query keys, and cache reset/refetch transitions using the generated client without adding a router or client authorization. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add session expiry/logout, forbidden selection, WebSocket outage/manual refresh, focus/accessible-name, Spanish empty/error/loading, and preserved `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo` behavior tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate only through an additive protected-shell seam after a changed-path audit proves no `web-professional-redesign` file is touched; preserve server-derived roles, CSRF flow, WebSocket signal-only handling, and existing anchors. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact path audit, and final <=780 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for `outing_id = null`, valid same-group association, cross-group rejection, malformed reference, archived-outing create/edit/delete rejection, default all-expense reads, general-only filtering, and atomic child-row validation; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Add nullable `expenses.outing_id`, composite same-group foreign-key protection, repository filters, schema serialization, and service validation while preserving integer cents, participant/contribution/beneficiary invariants, and existing general expenses as `NULL`. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Test PostgreSQL constraint enforcement, archived history readability, failed transaction/no invalidation, old client compatibility, official four-expense values, and migration survival of existing source rows. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate the contract through the pinned workflow, build generated Dart serialization only when frozen models require it, run drift, and update no generated output manually. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/migration tests, lint, contract drift, path audit, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add derived-service/API tests proving group scope includes every general and outing-linked expense exactly once, outing scope filters exact `outing_id`, general expenses never appear in outing totals, participants remain the authorized group set, sums equal zero, and transfer order is stable. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement optional outing scope in server-derived balance/settlement reads and REST schemas; keep all arithmetic, residual allocation, exact-zero checks, and formatting authority on the server/domain services. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add mixed-scope, empty-outing, archived-outing, cross-group, stale-cache, and official Samaipata regression cases with exact expected balances/transfers; assert no derived state is persisted. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Regenerate contract outputs from handwritten API changes and add scope-aware query-key definitions without client calculations or WebSocket payload changes. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full monetary tests, lint, contract drift, and final <=720 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner generation/status/revoke/regenerate, hash-only persistence, reusable consumption by existing sessions, prior-token invalidation, anonymous/invalid/duplicate joins, exact-one participant choice, same-group link/create, cross-group choice rejection, token non-disclosure, and atomic rollback; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement one current SHA-256-hashed 256-bit URL-safe token per group, owner-protected lifecycle endpoints, authenticated consume transaction, group-scoped account-participant link table, and explicit existing-participant-or-new-participant command with stable errors. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add lock/concurrency, CSRF/origin, replay/reusable-code, active-membership conflict, participant uniqueness, no-log/no-summary-secret, post-commit one-frame, and no-frame-on-failure tests; preserve account/participant identity separation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate OpenAPI/TypeScript/Dart outputs through the pinned workflow, keeping plaintext code only in generation response and never hand-editing generated trees. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/security/migration tests, lint, contract drift, secret-output audit, path audit, and final <=800 changed-line count; split before apply if forecast exceeds the cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner removal, member leave, ended-member denial across every group resource, participant-link inactivity, preserved participant/expense/outing history, rejoin eligibility, member forbidden removal, and final-owner protection. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement nullable `ended_at` active-membership semantics, owner-remove/member-leave operations, immutable owner safety, inactive link handling, active-membership listing, and one post-commit group invalidation per successful mutation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add concurrent exit/remove, stale sessions, cross-group account IDs, final-owner conflict, rejoin with a new explicit link choice, rollback/no-invalidation, and official fixture regression coverage. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Reconcile handwritten API schemas/routes, regenerate clients only where the frozen contract changes, run drift, and keep role derivation server-owned. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full regression tests, migration proof if applicable, lint, contract drift, and final <=740 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add behavior tests for outing/general expense separation, outing archived read-only state, server-provided scoped balances/settlement, participant detail, loading/empty/forbidden/error states, route/deep-link protection, and cache invalidation/refetch; audit redesign paths before running. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement additive laptop-first pages/states for outing detail/expenses, general expenses, group summary, participant detail, balances, and settlement using generated client data and shared integer-cent formatter; perform no client monetary arithmetic. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Cover mixed-scope no-double-counting, stale selected group/outing, archived history, WebSocket outage/manual refresh, membership changes, Spanish accessible names, keyboard focus, visible state cues, and preserved legacy anchors. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate through the protected shell without overwriting `web-professional-redesign`; remove only additive duplication, preserve query identity and REST authority, then rerun focused web tests. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact dirty-path audit, and final <=800 changed-line count; stop and split at a screen boundary if over cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner join-code display/regenerate/revoke/status secrecy, member/owner membership controls, leave/final-owner errors, forbidden actions, empty/error/recovery states, accessibility/laptop-first behavior, and official-flow preservation. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement group/membership settings, authenticated join-code consumption UI with explicit participant link/create choice, member removal/leave actions, Spanish copy, and safe protected recovery states using server-derived role/error responses. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add full regression cases for account selection, outing lifecycle, scoped expenses/derived results, invalidation-only WebSocket behavior, no public join/account creation, no token leakage, official Samaipata exact data/result, and all protected deep links. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Normalize source-mutating files before candidate freeze, preserve all redesign bytes/modes, remove no required acceptance coverage, and confirm the final web remains dependency-free with mobile UI out of scope. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, complete backend/web/contract/migration gates, manual laptop-first accessibility/browser flow, protected-path and generated-output audits, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

## PR 0 corrective rerun — delta completeness

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`, workspace root `D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1`, allowed edit root is the repository root.
- Parent handoff: the user-authorized native objective reset is complete; the parent-held remediation token is `sha256:41bd2ec50a00863a3a21a0c5a2cb8a6564d02c91f3421e3a6ed387d7ed1e4988`. No second acquire was issued.
- Failed evidence revision preserved exactly: `sha256:b1051adffdde1304fb008f947517992d01bc817473d3a8dfba1750a21981badc`. The original failed evidence record was not modified.
- Delivery boundary: PR 0 only; `exception-ok`, `stacked-to-main`, hard cap `800` changed lines. PR 1–PR 9 remain deferred.
- Produced phase status: `success` for the PR 0 corrective slice. The native attempt remains parent-owned for settlement; this executor does not start review or delivery gates.

### TDD Cycle Evidence

| Task | Test/validation input | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR 0 correction | `openspec validate group-outing-workspaces --strict` | OpenSpec artifact validation | Existing six delta files and prior progress read | ✅ Exit 1 reproduced the inherited-scenario omissions before edits | ✅ Exit 0 after copying baseline scenarios | ✅ Scenario-title, protected-path, whitespace, and line-budget audits passed | ✅ Final strict validation and `git diff --check` passed |

### Correction performed

- RED reproduced the prior blocker: the six change-local delta files had MODIFIED blocks that replaced baseline requirements without retaining the validator-named inherited scenarios. The affected blocks were API `REST endpoint surface` and `Structured error contract`; Clients `Web Must flow` and `Invalidation-driven refetch`; Demo Readiness `Official Samaipata seed contains four separate expenses`, `Seeded balances and settlement match the official result`, and `Official seed remains deterministic and idempotent`; Groups `Group foundation and scope` and `Protected sessions for group data`; Persistence `PostgreSQL persistence of source data` and `Minimum account and session persistence`; and Web Presentation `Main protected web flow is presented in Spanish`.
- GREEN copied the current baseline scenarios into those six MODIFIED blocks without removing, weakening, or changing any accepted group, outing, join, persistence, expense, settlement, client, demo, or web rule.
- TRIANGULATE read back all six MODIFIED blocks and confirmed the inherited scenarios now coexist with the new accepted scenarios. The allowed correction surfaces contain no trailing whitespace. The protected redesign directory was present in the initial and final dirty-path audits and was not edited.
- REFACTOR completed the strict artifact gate, marked only the implementation-owned PR 0 REFACTOR row complete, and left every PR 1–PR 9 and parent-owned row unchecked.

### Validation and audit evidence

- RED command: `openspec validate group-outing-workspaces --strict` — exit `1`; it reported the omitted inherited scenarios listed above.
- Final command: `openspec validate group-outing-workspaces --strict` — exit `0`, exact result: `Change 'group-outing-workspaces' is valid`. The validator emitted one informational note that archive would refuse the Web Presentation `Presentation preserves authoritative behavior` MODIFIED header because it is not found; this is non-blocking and the strict validator result is valid.
- `git diff --check` — clean for tracked files. The untracked correction files were independently scanned: zero trailing-whitespace findings.
- Protected-path audit — no correction edit touched `AGENTS.md`, product code/tests, contracts/generated clients, mobile files, archived/historical artifacts, the official fixture, or `openspec/changes/web-professional-redesign/**`. Existing dirty redesign bytes and existing web work were preserved.
- Auxiliary `openspec show group-outing-workspaces --json --deltas-only` was not used as acceptance evidence because it returned `show_error: Change must have a Why section`; strict validation remained the authoritative gate and passed.

### Changed paths and exact line accounting

- Correction paths: `openspec/changes/group-outing-workspaces/specs/api/spec.md`, `clients/spec.md`, `demo-readiness/spec.md`, `groups/spec.md`, `persistence/spec.md`, `web-presentation/spec.md`, `tasks.md`, and `apply-progress.md`.
- Six local delta files added exactly `137` inherited-scenario lines: API `+28`, Clients `+14`, Demo Readiness `+30`, Groups `+33`, Persistence `+26`, Web Presentation `+6`.
- The persisted task transition is one logical checkbox row (`REFACTOR [ ] → [x]`), counted as `2` raw diff lines (`1` deletion + `1` addition). No other task row changed.
- Prior PR 0 accounting was `274` authored lines. This corrective progress entry adds `97` lines (including the separator and evidence inventory); cumulative PR 0 accounting is `274 + 137 + 1 + 97 = 509` authored lines, below the hard `800`-line cap.

### Rollback boundary

Revert only the six copied inherited-scenario additions, the single PR 0 REFACTOR checkbox transition, and this appended corrective evidence section. Retain the prior eight living-policy amendments and prior progress evidence. Do not reset, clean, reformat, or remove any redesign, web, product, generated, mobile, historical, fixture, proposal, exploration, or design bytes. The failed evidence revision remains preserved for parent settlement.

### Remaining tasks after PR 0

The following are the exact current unchecked rows from `tasks.md`; all are deferred to later slices or parent lifecycle work:

```text
- [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
- [ ] RED — Add Testing Library tests for authenticated group list/create, zero-group state, one-group auto-selection, multi-group switching, stale/deep-link protection, query-key identity, cache clearing, and no protected render before session authentication; run affected Vitest files and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the additive hash parser/serializer, protected group picker/create flow, selected-group summary/empty workspace, account/group/selection query keys, and cache reset/refetch transitions using the generated client without adding a router or client authorization. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add session expiry/logout, forbidden selection, WebSocket outage/manual refresh, focus/accessible-name, Spanish empty/error/loading, and preserved `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo` behavior tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate only through an additive protected-shell seam after a changed-path audit proves no `web-professional-redesign` file is touched; preserve server-derived roles, CSRF flow, WebSocket signal-only handling, and existing anchors. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact path audit, and final <=780 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for `outing_id = null`, valid same-group association, cross-group rejection, malformed reference, archived-outing create/edit/delete rejection, default all-expense reads, general-only filtering, and atomic child-row validation; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Add nullable `expenses.outing_id`, composite same-group foreign-key protection, repository filters, schema serialization, and service validation while preserving integer cents, participant/contribution/beneficiary invariants, and existing general expenses as `NULL`. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Test PostgreSQL constraint enforcement, archived history readability, failed transaction/no invalidation, old client compatibility, official four-expense values, and migration survival of existing source rows. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate the contract through the pinned workflow, build generated Dart serialization only when frozen models require it, run drift, and update no generated output manually. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/migration tests, lint, contract drift, path audit, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add derived-service/API tests proving group scope includes every general and outing-linked expense exactly once, outing scope filters exact `outing_id`, general expenses never appear in outing totals, participants remain the authorized group set, sums equal zero, and transfer order is stable. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement optional outing scope in server-derived balance/settlement reads and REST schemas; keep all arithmetic, residual allocation, exact-zero checks, and formatting authority on the server/domain services. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add mixed-scope, empty-outing, archived-outing, cross-group, stale-cache, and official Samaipata regression cases with exact expected balances/transfers; assert no derived state is persisted. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Regenerate contract outputs from handwritten API changes and add scope-aware query-key definitions without client calculations or WebSocket payload changes. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full monetary tests, lint, contract drift, and final <=720 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner generation/status/revoke/regenerate, hash-only persistence, reusable consumption by existing sessions, prior-token invalidation, anonymous/invalid/duplicate joins, exact-one participant choice, same-group link/create, cross-group choice rejection, token non-disclosure, and atomic rollback; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement one current SHA-256-hashed 256-bit URL-safe token per group, owner-protected lifecycle endpoints, authenticated consume transaction, group-scoped account-participant link table, and explicit existing-participant-or-new-participant command with stable errors. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add lock/concurrency, CSRF/origin, replay/reusable-code, active-membership conflict, participant uniqueness, no-log/no-summary-secret, post-commit one-frame, and no-frame-on-failure tests; preserve account/participant identity separation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate OpenAPI/TypeScript/Dart outputs through the pinned workflow, keeping plaintext code only in generation response and never hand-editing generated trees. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/security/migration tests, lint, contract drift, secret-output audit, path audit, and final <=800 changed-line count; split before apply if forecast exceeds the cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner removal, member leave, ended-member denial across every group resource, participant-link inactivity, preserved participant/expense/outing history, rejoin eligibility, member forbidden removal, and final-owner protection. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement nullable `ended_at` active-membership semantics, owner-remove/member-leave operations, immutable owner safety, inactive link handling, active-membership listing, and one post-commit group invalidation per successful mutation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add concurrent exit/remove, stale sessions, cross-group account IDs, final-owner conflict, rejoin with a new explicit link choice, rollback/no-invalidation, and official fixture regression coverage. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Reconcile handwritten API schemas/routes, regenerate clients only where the frozen contract changes, run drift, and keep role derivation server-owned. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full regression tests, migration proof if applicable, lint, contract drift, path audit, and final <=740 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add behavior tests for outing/general expense separation, outing archived read-only state, server-provided scoped balances/settlement, participant detail, loading/empty/forbidden/error states, route/deep-link protection, and cache invalidation/refetch; audit redesign paths before running. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement additive laptop-first pages/states for outing detail/expenses, general expenses, group summary, participant detail, balances, and settlement using generated client data and shared integer-cent formatter; perform no client monetary arithmetic. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Cover mixed-scope no-double-counting, stale selected group/outing, archived history, WebSocket outage/manual refresh, membership changes, Spanish accessible names, keyboard focus, visible state cues, and preserved legacy anchors. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate through the protected shell without overwriting `web-professional-redesign`; remove only additive duplication, preserve query identity and REST authority, then rerun focused web tests. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact dirty-path audit, and final <=800 changed-line count; stop and split at a screen boundary if over cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner join-code display/regenerate/revoke/status secrecy, member/owner membership controls, leave/final-owner errors, forbidden actions, empty/error/recovery states, accessibility/laptop-first behavior, and official-flow preservation. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement group/membership settings, authenticated join-code consumption UI with explicit participant link/create choice, member removal/leave actions, Spanish copy, and safe protected recovery states using server-derived role/error responses. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add full regression cases for account selection, outing lifecycle, scoped expenses/derived results, invalidation-only WebSocket behavior, no public join/account creation, no token leakage, official Samaipata exact data/result, and all protected deep links. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Normalize source-mutating files before candidate freeze, preserve all redesign bytes/modes, remove no required acceptance coverage, and confirm the final web remains dependency-free with mobile UI out of scope. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, complete backend/web/contract/migration gates, manual laptop-first accessibility/browser flow, protected-path and generated-output audits, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

## PR 1 schema/migration foundation slice

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`.
- Native action context: `mode=repo-local`; workspace root is the repository root. The delegated edit boundary was narrower: only the listed tables, migration, persistence test, tasks, and apply-progress files were eligible.
- Parent-owned runtime authority: active token `sha256:737c7275f7014e0abfb7e6c9897b96b2696b4d6d771ab1829bd1fdfbc54443cd`; this worker did not acquire, settle, reset, commit, clean, or start review/delivery gates.
- Produced status: `partial` apply progress; the full PR 1 remains incomplete and verification/archive remain blocked by unchecked implementation tasks.

### Completed implementation task and persisted checkbox

- Added and marked this exact implementation-owned task in `tasks.md`:
  `- [x] Schema/migration foundation — Add nullable \`GroupMembership.ended_at\`, the \`(account_id, ended_at, group_id)\` active-membership index, and reversible \`0003_workspace\` migration from \`0002_source\`; cover the schema and migration shape with focused persistence assertions. <!-- sdd-owner: implementation -->`
- The broader PR 1 RED/GREEN/TRIANGULATE/REFACTOR/Verify rows remain unchecked. No parent-owned row was changed.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Schema/migration foundation | `backend/tests/integration/persistence/test_auth_tables.py` | SQLite persistence/Alembic integration | ✅ `5 passed` before edits | ✅ Focused run: 5 existing passed; new model assertion failed with missing `ended_at`, migration assertion failed with missing `0003_workspace` | ✅ `7 passed` after implementation | ➖ Structural slice: upgrade and downgrade assertions cover both migration directions; no branching behavior was introduced | ✅ Focused tests remained green; ruff clean |

- Tests written: 2 focused persistence tests; focused total: 7 passing.
- Approval tests: none. Pure functions created: none. Full backend suite intentionally not run.

### Files changed in this slice

- `backend/app/adapters/db/tables.py` — nullable `GroupMembership.ended_at` and `(account_id, ended_at, group_id)` index metadata.
- `backend/migrations/versions/0003_workspace.py` — additive revision from `0002_source`; downgrade drops only its index and column.
- `backend/tests/integration/persistence/test_auth_tables.py` — schema/index assertions and `0002_source` → `0003_workspace` upgrade/downgrade shape test. Existing parent Pyright cleanup was preserved.
- `openspec/changes/group-outing-workspaces/tasks.md` — one checked implementation-owned foundation row; all broader rows remain unchanged and unchecked.
- `openspec/changes/group-outing-workspaces/apply-progress.md` — this cumulative slice evidence.

### Exact verification commands and outcomes

- `python -m pytest backend/tests/integration/persistence/test_auth_tables.py -q` before edits: **5 passed**.
- Same focused command after RED tests: **5 passed, 2 failed** as expected (`ended_at` absent; `0003_workspace` absent).
- Same focused command after implementation: **7 passed**.
- `python -m ruff check backend/app/adapters/db/tables.py backend/migrations/versions/0003_workspace.py backend/tests/integration/persistence/test_auth_tables.py`: **All checks passed**.
- `pyright backend/app/adapters/db/tables.py backend/migrations/versions/0003_workspace.py backend/tests/integration/persistence/test_auth_tables.py`: **not run; executable unavailable** (`command not found`).
- `python -m pyright ...` bounded fallback: **not run; module unavailable**.
- Full backend suite, contract export/drift, PostgreSQL migration run, review, and delivery gates: **not run by delegated scope**.

### Design deviations and boundaries

- No repositories, services, routes, auth wiring, contracts, generated clients, web/mobile files, outing table, expense association, or membership lifecycle behavior was implemented.
- The migration is data-preserving for existing rows by using a nullable column with no backfill and retains the existing composite membership primary key and legacy account index.
- Rollback boundary: revert only the new `0003_workspace` revision, its model metadata, the two focused assertions, the foundation task row, and this appended progress section; do not reset or clean unrelated dirty paths.

### Workload and remaining work

- Boundary: one tiny PR 1 schema/migration foundation slice, `exception-ok`, `stacked-to-main`; estimated authored change is approximately **190–210 lines**, below the parent-provided 300-line worker bound and the PR 1 790-line ceiling. This is not a complete PR 1 candidate.
- The exact unchecked task inventory remains in the preceding `Remaining tasks after PR 0` block. In particular, the five broader PR 1 rows remain exactly unchecked:

  ```text
  - [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
  - [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
  - [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
  - [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
  - [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
  ```

- PR 2–PR 9 implementation rows and all parent-owned lifecycle rows remain unchecked as recorded above.

### Structured status snapshot

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: openspec
applyState: ready
taskProgress: {total: 54, complete: 6, remaining: 48}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
  allowedEditRoots: [D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1]
  warnings: ["Delegated worker used the narrower explicit allowed edit surfaces."]
    nextRecommended: apply
    ```
    
    
    ## PR 1 — Zero-group authenticated session identity slice
    
    ### Status consumed and produced
    
    - Consumed native runtime authority for the bounded PR1e objective: an active account with no active membership can authenticate without being treated as a group-scoped actor.
    - The delegated apply worker timed out after writing the candidate changes. A fresh, read-only verification worker inspected the exact three implementation/test files and confirmed the candidate is complete; no retry or second writer was launched.
    - Parent settled the native attempt after the independent verification and preserved the broader PR1/API boundary. The overall change remains partial; API routes, generated contracts, and later slices are deferred.
    
    ### Completed implementation task and persisted checkbox
    
    - The existing `Zero-group authenticated session identity` implementation row in `tasks.md` is checked and is the only task row attributable to this slice.
    - All broader PR1 RED/GREEN/TRIANGULATE/REFACTOR/Verify rows, later slices, and parent-owned lifecycle rows remain unchecked.
    
    ### TDD Cycle Evidence
    
    | Task | Test file | Layer | RED | GREEN/TRIANGULATE/REFACTOR |
    | --- | --- | --- | --- | --- |
    | Zero-group authenticated session identity | `backend/tests/unit/application/test_auth_service.py` | Unit/service/schema | The candidate adds focused coverage for zero-group login, session validation, nullable response fields, malformed non-null membership rejection, and token safety; the timed-out apply transcript did not provide a separately readable RED exit. | `python -m pytest backend/tests/unit/application/test_auth_service.py -q` — **13 passed**; bounded Ruff, compileall, and diff checks all **passed**. |
    
    ### Implementation and security boundary
    
    - `AuthService.login` and `session_identity` now accept `None` as the valid absence of an active membership while continuing to reject present unusable membership records.
    - `SessionIdentity` and `SessionIdentityResponse` expose nullable `active_group_id` and `role`; existing owner/member role derivation and token-safe serialization remain unchanged.
    - No group authorization was weakened: group-scoped dependencies still require an active selected membership. Anonymous session probing remains unchanged.
    
    ### Files changed in this slice
    
    - `backend/app/application/auth_service.py`
    - `backend/app/api/schemas/auth.py`
    - `backend/tests/unit/application/test_auth_service.py`
    - `openspec/changes/group-outing-workspaces/tasks.md` — one checked implementation row
    - `openspec/changes/group-outing-workspaces/apply-progress.md` — this evidence section
    
    ### Exact verification and scope outcomes
    
    - `python -m pytest backend/tests/unit/application/test_auth_service.py -q` — **13 passed**.
    - `python -m ruff check backend/app/application/auth_service.py backend/app/api/schemas/auth.py backend/tests/unit/application/test_auth_service.py` — **All checks passed**.
    - `python -m compileall -q backend/app/application/auth_service.py backend/app/api/schemas/auth.py backend/tests/unit/application/test_auth_service.py` — **passed with no output**.
    - `git diff --check` for the bounded files — **clean**; only the repository's LF/CRLF conversion warning was emitted.
    - Full backend/API/PostgreSQL/contract/generated-client/web/mobile/review/delivery gates remain intentionally deferred.
    
    ### Rollback boundary and next work
    
    - Rollback boundary: revert only the nullable auth identity/schema changes, the focused auth tests, this checked task row, and this evidence section. Preserve all prior schema/migration/repository/UoW/workspace-service slices and unrelated dirty paths.
    - Next implementation slice: add focused API tests and implement account-scoped `GET /api/v1/groups` plus authenticated empty-group `POST /api/v1/groups`, including CSRF, server-derived roles, atomic owner membership, and one post-commit invalidation.
    
    ### Structured phase result
    
    ```yaml
    schemaName: spec-driven
    changeName: group-outing-workspaces
    artifactStore: hybrid
    applyState: ready
    taskProgress: {total: 58, complete: 10, remaining: 48}
    dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
    nextRecommended: apply
    ```
    ## PR 1 — Membership repository/UoW foundation slice

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `dependencies.verify=blocked`, `nextRecommended=apply`, and no blocked reasons.
- Native action context: `mode=repo-local`; workspace root is `D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1`; the native allowed edit root is the repository root. This delegated worker used only the explicitly listed repository/UoW, persistence-test, task, and progress surfaces.
- Parent-owned runtime authority: active token `sha256:a45efe16969b0cacc3a623e1284f131b2e57c8721bee4869aa759f5b3cca8c04`; this worker did not acquire, settle, reset, commit, clean, start review, or run delivery gates.
- Produced status: partial apply progress; native status reports `taskProgress={total:55, complete:7, remaining:48}`, `applyState=ready`, `dependencies.verify=blocked`, and `nextRecommended=apply`. The full PR 1 remains incomplete.

### Completed implementation task and persisted checkbox

- Added and marked only this implementation-owned foundation task in `tasks.md`:
  `- [x] Membership repository/UoW foundation — Add active account membership listing, group-scoped lookup, create/reactivate/end primitives, server-owned owner counting, and transaction exposure; cover the adapters with focused persistence assertions. <!-- sdd-owner: implementation -->`
- The broader PR 1 RED/GREEN/TRIANGULATE/REFACTOR/Verify rows remain unchecked. No parent-owned row was changed.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Membership repository/UoW foundation | `backend/tests/integration/persistence/test_auth_tables.py` | SQLite persistence/integration | ✅ `7 passed` before edits | ✅ New tests written first; focused run `7 passed, 3 failed` because the new repository/UoW APIs were absent | ✅ `10 passed` after the minimum implementation | ✅ `10 passed` with ended-history listing, active-only lookup, reactivation, duplicate-active rejection, and UoW commit coverage | ✅ Final focused tests `10 passed`; ruff, compile, and diff checks clean |

### Test Summary

- Tests written: **3** focused persistence tests; focused file total: **10 passing**.
- Focused compatibility tests: `backend/tests/integration/auth/test_auth_adapters.py -q` — **8 passed**.
- Focused source/UoW regression tests: `backend/tests/integration/persistence/test_source_tables.py -q` — **6 passed**.
- Focused transport regression tests: `backend/tests/integration/api/test_security_transport.py -q` — **6 passed**.
- Approval tests: none. Pure functions created: none. Full backend suite intentionally not run.

### Implementation and transaction boundary

- `MembershipRecord` now carries optional `ended_at`; the membership port exposes active account listing, both group lookup spellings, create/reactivate, end, and active-owner counting.
- `MembershipRepositoryAdapter.list_for_account` filters ended memberships and inactive accounts by default, orders memberships deterministically, and derives `owner_account_id` only from the joined server-owned `Group` row. `active_only=False` remains available for history reads.
- `find_for_account`, `find_for_account_in_group`, and `find_active_by_group_account` all enforce active-membership semantics. Existing `find_for_account_and_group`, `owner_has_membership`, and `create`/`add` compatibility APIs were preserved.
- `create_or_reactivate` keeps the composite membership row, rejects an already-active duplicate, reactivates an ended row, and flushes without committing. `end` records `ended_at`, preserves the row, and flushes without committing. The UoW now exposes `memberships` and its existing commit/rollback transaction boundary, plus the declared `flush` operation.
- No services, routes, schemas, auth wiring, contracts, generated clients, web/mobile files, new migrations, or schema/table files were added in this slice. The prior `tables.py`/`0003_workspace.py` foundation was read and left unchanged.

### Files changed in this slice

- `backend/app/application/ports.py`
- `backend/app/adapters/db/repositories.py`
- `backend/app/adapters/db/uow.py`
- `backend/tests/integration/persistence/test_auth_tables.py`
- `openspec/changes/group-outing-workspaces/tasks.md`
- `openspec/changes/group-outing-workspaces/apply-progress.md`

### Exact verification commands and outcomes

- `python -m pytest backend/tests/integration/persistence/test_auth_tables.py -q` safety net: **7 passed**.
- Same focused command after RED tests: **7 passed, 3 failed** as expected because the new methods/transaction property did not exist.
- Same focused command after GREEN: **10 passed**.
- Same focused command after TRIANGULATE and REFACTOR: **10 passed**.
- `python -m pytest backend/tests/integration/auth/test_auth_adapters.py -q`: **8 passed**.
- `python -m pytest backend/tests/integration/persistence/test_source_tables.py -q`: **6 passed**.
- `python -m pytest backend/tests/integration/api/test_security_transport.py -q`: **6 passed**.
- `python -m ruff check backend/app/application/ports.py backend/app/adapters/db/repositories.py backend/app/adapters/db/uow.py backend/tests/integration/persistence/test_auth_tables.py`: **All checks passed**.
- `python -m compileall -q backend/app/application/ports.py backend/app/adapters/db/repositories.py backend/app/adapters/db/uow.py backend/tests/integration/persistence/test_auth_tables.py`: **passed with no output**.
- `git diff --check` on the six slice surfaces: **clean**.
- `pyright ...` and `python -m pyright ...`: **not available** (`command not found` / `No module named pyright`); no type-check result is claimed.
- Full backend suite, contract export/drift, PostgreSQL migration run, review, and delivery gates: **not run by delegated scope**.

### Design deviations and rollback boundary

- No deviation from the repository/UoW design boundary. New mutation methods intentionally flush only so a future workspace service can compose membership changes atomically; the legacy `create`/`add` method still commits to preserve existing callers.
- Rollback boundary: revert only the new membership port fields/methods, adapter membership behavior, UoW membership exposure/flush, the three focused tests, this checked task row, and this appended progress section. Retain the prior schema/migration foundation and all unrelated dirty paths.

### Workload and remaining work

- Boundary: one tiny PR 1 repository/UoW foundation slice, `exception-ok`, `stacked-to-main`; estimated authored change is approximately **390 changed lines including this evidence/task update** (approximately 285 product/test lines plus progress/task evidence), below the parent-provided 500-line worker bound and the PR 1 790-line ceiling. This is not a complete PR 1 candidate.
- The following exact broader PR 1 implementation rows remain unchecked; API/service wiring, group creation, authorization routes, contract generation, and final verification are deferred:

  ```text
  - [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
  - [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
  - [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
  - [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
  - [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
  ```

- PR 2–PR 9 implementation rows and all parent-owned lifecycle rows remain unchecked exactly as recorded in the preceding cumulative inventory.

### Structured status snapshot

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: openspec
applyState: ready
taskProgress: {total: 55, complete: 7, remaining: 48}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
  allowedEditRoots: [D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1]
  warnings:
    - "Delegated worker used the narrower explicit allowed edit surfaces."
    - "Parent-owned native runtime token remained active and was not mutated by this executor."
nextRecommended: apply
```

## PR 1 — Workspace service application slice

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, and repo-local action context rooted at `D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1`.
- The parent-held native runtime token remained authoritative and untouched. This worker did not acquire, settle, reset, commit, clean, start review, or run delivery gates.
- Produced status: partial PR 1 apply progress; verify and archive remain blocked because broader implementation tasks are unchecked.

### Completed implementation task and persisted checkbox

- Added and checked only this clearly named implementation task in `tasks.md`: `Workspace service application slice`.
- The broader PR 1 RED/GREEN/TRIANGULATE/REFACTOR/Verify rows, all later slices, and every parent-owned row remain unchecked byte-for-byte.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Workspace service application slice | `backend/tests/unit/application/test_workspace_service.py` | Unit/fakes | N/A (new files) | ✅ Focused pytest exited 2: missing `workspace_service` module | ✅ 12 passed after the minimum implementation | ✅ Final 11 passed covering active/ended isolation, server owner/member roles, selected membership recheck, invalid names, empty creation, and two rollback paths | ✅ Final focused tests, Ruff, compileall, and import check passed |

### Files changed in this slice

- `backend/app/application/workspace_service.py`
- `backend/tests/unit/application/test_workspace_service.py`
- `openspec/changes/group-outing-workspaces/tasks.md` — one checked workspace-service task only
- `openspec/changes/group-outing-workspaces/apply-progress.md` — cumulative evidence appended

### Exact verification and scope outcomes

- RED: `python -m pytest backend/tests/unit/application/test_workspace_service.py -q` — exit 2 during collection with `ModuleNotFoundError` before the service existed.
- GREEN/Triangulate/Refactor: the same focused command — **11 passed**.
- `python -m ruff check backend/app/application/workspace_service.py backend/tests/unit/application/test_workspace_service.py` — **All checks passed**.
- `python -m compileall -q backend/app/application/workspace_service.py backend/tests/unit/application/test_workspace_service.py` — **passed**.
- `python -c "from backend.app.application.workspace_service import WorkspaceService; print(WorkspaceService.__name__)"` — **passed**.
- Full backend suite, API routes, auth service, repositories/UoW, migrations, OpenAPI export, generated clients, web/mobile files, review, and delivery gates — **not run or changed by this slice**.

### Design deviations and rollback boundary

- No product/API contract wiring was added. The service consumes the existing membership/UoW boundaries and uses a small application group record; selection remains non-persistent and API compatibility is deferred to the next slice.
- Group names are trimmed and reject blank/non-string/>255 input before opening the transaction. Creation validates the persisted owner membership before flush/commit; UoW exceptions provide rollback/no-partial-create behavior.
- Rollback boundary: revert only the new service, its focused fake tests, the one workspace-service task row, and this appended evidence. Preserve all prior schema/migration/repository foundations and unrelated dirty paths.

### Workload and remaining work

- Boundary: one partial PR 1 application-service slice, `exception-ok`, `stacked-to-main`; approximately **560 authored changed lines including the two new files plus task/progress evidence**, under the parent-provided 600-line bound. This is not a complete PR 1 candidate.
- The exact remaining PR 1 implementation rows are unchanged and remain unchecked:

  ```text
  - [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
  - [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
  - [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
  - [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
  - [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
  ```

- PR 2–PR 9 and parent-owned lifecycle rows remain unchecked as recorded in the cumulative inventory above.

### Structured status snapshot

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: openspec
applyState: ready
taskProgress: {total: 56, complete: 8, remaining: 48}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
  allowedEditRoots: [D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1]
  warnings:
    - "Worker edit scope was narrower than the native repository root."
    - "Parent-owned native runtime token remained active and was not mutated."
nextRecommended: apply
```

## PR 1 — GroupRepository create primitive slice

### Status consumed and produced

- Consumed native status: `artifactStore=openspec` (the selected session mode is hybrid with the OpenSpec workspace authoritative because `openspec/` exists), change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, and `actionContext.mode=repo-local`.
- Workspace root: `D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1`; the delegated allowed edit surfaces were limited to the three backend files plus this change's `tasks.md` and `apply-progress.md`.
- Parent-owned native runtime authority remained active as `sha256:a2533aba8c9632556e704a02077f634ab617cfff4e998d9be4459aebbf536b50`; this executor did not acquire, settle, reset, commit, clean, start review, or run delivery gates.
- Produced status: partial apply progress. After the persisted checkbox update, native status reports `taskProgress={total:57, completed:9, pending:48}`, `applyState=ready`, `dependencies.verify=blocked`, and `nextRecommended=apply`.
- Action-context warning: the native repository root is broader than this worker's explicit surfaces; no file outside those surfaces was edited. Pre-existing dirty redesign/PR0 and prior foundation/service bytes remain protected.

### Completed implementation task and persisted checkbox

- Added and checked only this clearly named implementation-owned task in `tasks.md`:
  `- [x] GroupRepository create primitive — Extend the group port and concrete SQLAlchemy adapter with a no-commit create that accepts application group records or ORM groups; cover record mapping, ORM preservation, and rollback visibility with focused persistence assertions. <!-- sdd-owner: implementation -->`
- The broader PR 1 RED/GREEN/TRIANGULATE/REFACTOR/Verify rows remain unchecked. PR 2–PR 9 rows and every parent-owned lifecycle row remain unchecked. No ownership marker was changed or introduced in malformed form.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GroupRepository create primitive | `backend/tests/integration/persistence/test_auth_tables.py` | SQLite persistence/integration | ✅ `10 passed` before edits | ✅ New record-mapping test written first; focused run was `1 failed, 10 passed` with `AttributeError` because `GroupRepositoryAdapter.create` was absent | ✅ Focused run `11 passed` after the port/adapter implementation | ✅ Added ORM-input preservation and rollback visibility; focused run `12 passed` | ✅ Final focused run `12 passed`; Ruff, compileall, and diff checks clean |

### Implementation and transaction boundary

- `backend/app/application/ports.py` now declares `GroupRepository.create(group)` as a current-transaction, no-commit primitive.
- `backend/app/adapters/db/repositories.py` now maps attribute-based application group records to `Group` ORM rows, preserves an existing ORM `Group`, adds the row, flushes it for same-transaction visibility, and returns the ORM row without committing.
- `backend/tests/integration/persistence/test_auth_tables.py` covers application-record mapping, ORM preservation, uncommitted visibility, and rollback removing the uncommitted group.
- Existing `find_by_id`, membership behavior, participant behavior, expense behavior, schema/migration, UoW, workspace service, API, and contract surfaces were not changed in this slice.

### Exact verification commands and outcomes

- `python -m pytest backend/tests/integration/persistence/test_auth_tables.py -q` safety net: **10 passed**.
- Same focused command after the RED test: **1 failed, 10 passed**; the failure was the expected missing `GroupRepositoryAdapter.create` primitive.
- Same focused command after GREEN: **11 passed**.
- Same focused command after TRIANGULATE and REFACTOR: **12 passed**.
- `python -m ruff check backend/app/application/ports.py backend/app/adapters/db/repositories.py backend/tests/integration/persistence/test_auth_tables.py`: **All checks passed**.
- `python -m compileall -q backend/app/application/ports.py backend/app/adapters/db/repositories.py backend/tests/integration/persistence/test_auth_tables.py`: **passed with no output**.
- `git diff --check -- backend/app/application/ports.py backend/app/adapters/db/repositories.py backend/tests/integration/persistence/test_auth_tables.py openspec/changes/group-outing-workspaces/tasks.md`: **clean**.
- Full backend suite, PostgreSQL migration run, API/contract generation, generated clients, web/mobile checks, review, and delivery gates: **not run by delegated scope**.

### Design deviations and rollback boundary

- No deviation from the bounded repository design. The adapter intentionally flushes but does not commit so `WorkspaceService` can compose group creation with owner membership in one UoW transaction.
- The adapter accepts the existing ORM type or an attribute-based application group record without importing the workspace service, preserving the repository/application boundary.
- Rollback boundary: revert only the `GroupRepository.create` port/adapter method, the two focused persistence tests, the one GroupRepository task row, and this appended progress section. Preserve the prior schema/migration, membership/UoW, workspace-service, auth/participant/expense behavior, and all unrelated dirty paths.

### Workload and remaining work

- Boundary: one tiny PR 1 `GroupRepository` create primitive slice, `exception-ok`, `stacked-to-main`; estimated authored change is approximately **180 changed lines including focused tests, task checkbox, and cumulative evidence**, below the parent-provided 300-line bound. This is not a complete PR 1 candidate and does not claim full PR 1.
- The exact broader PR 1 implementation rows remain unchecked:

  ```text
  - [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
  - [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
  - [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
  - [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
  - [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
  ```

- The cumulative inventory above remains the exact source for the other 40 unchecked implementation rows and 3 parent-owned lifecycle rows; no row beyond the named create primitive was checked.

### Structured phase result

- Status: `success` for this assigned slice; the overall change remains partial because 48 implementation/lifecycle rows are still unchecked.
- Next recommendation: `parent-lifecycle` for parent-owned native attempt settlement/gating and any later explicit slice selection.
- Skill resolution: `paths-injected` — loaded the four exact skill paths supplied by the parent, including strict TDD guidance.

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: hybrid
applyState: ready
taskProgress: {total: 57, complete: 9, remaining: 48}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
  allowedEditRoots: [D:\universidad\Proyectos\2doSemestre2026\topicos\proyecto_1]
  warnings:
    - "Worker edit surfaces were narrower than the native repository root."
    - "Parent-owned native runtime token remained active and was not mutated."
nextRecommended: parent-lifecycle
```

## PR 1 — Workspace account collection API and invalidation slice

### Status consumed and produced

- Consumed native status from `gentle-ai sdd-status group-outing-workspaces --cwd . --json --instructions`: `artifactStore=openspec`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, and no blocked reasons.
- Native action context: `mode=repo-local`; workspace root is the repository root and its root is the native allowed edit root. This worker used only the explicitly delegated edit surfaces.
- Workload guard: `Decision needed before apply: No`, `Chained PRs recommended: Yes`, `Chain strategy: stacked-to-main`, `400-line budget risk: High`; parent selected `exception-ok`. This worker implemented only the bounded account collection API slice.
- Parent-owned native runtime authority remained active as the token supplied in the parent prompt. This worker did not acquire, settle, reset, commit, clean, start review, or run delivery gates.
- Produced phase result: `success` for this assigned slice. The overall change remains partial; verify/archive stay blocked by unchecked implementation rows.
- Action-context warning: the native repository root is broader than this worker's delegated surfaces. Existing PR0/redesign and prior-slice bytes were preserved.

### Completed implementation task and persisted checkbox

- Added and checked exactly one implementation-owned task row in `tasks.md`: `Workspace account collection API`.
- The broad PR1 `RED`, `GREEN`, `TRIANGULATE`, `REFACTOR`, and `Verify` rows remain unchecked. Later slices and all parent-owned lifecycle rows remain unchanged.
- Re-read `tasks.md`: 48 unchecked rows remain, including the five broad PR1 rows and three parent-owned rows.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Workspace account collection API | `backend/tests/integration/api/test_workspace_routes.py`, `backend/tests/unit/application/test_workspace_service.py` | FastAPI integration and application unit | ✅ `19 passed` before editing existing surfaces | ✅ Integration collection exited 2 with the expected missing dependency; publisher test RED: `1 failed, 12 passed` with publication disabled | ✅ Integration `7 passed`; service unit `13 passed` | ✅ Integration `10 passed` with origin, client-role/group-id, empty, domain-error, and compatibility cases; publisher/no-publish unit cases passed | ✅ Focused regression `31 passed`; Ruff and compileall passed |

### Exact commands and outcomes

- Safety net: `python -m pytest backend/tests/integration/api/test_group_participant_routes.py backend/tests/integration/api/test_ws_mutation_invalidation.py backend/tests/unit/application/test_workspace_service.py -q` — **19 passed**.
- RED: `python -m pytest backend/tests/integration/api/test_workspace_routes.py -q` after writing the test file and before API implementation — **exit 2**, expected `ImportError` for the not-yet-added `get_workspace_service` dependency.
- GREEN: same workspace-route command after handwritten route/schema/dependency wiring — **7 passed**.
- Publisher RED: `python -m pytest backend/tests/unit/application/test_workspace_service.py -q` with the publisher call temporarily absent — **1 failed, 12 passed**, expected missing publication assertion; implementation was restored immediately.
- GREEN/Triangulate: `python -m pytest backend/tests/unit/application/test_workspace_service.py -q` — **13 passed**.
- Triangulate: `python -m pytest backend/tests/integration/api/test_workspace_routes.py -q` — **10 passed**.
- Refactor/final focused regression: `python -m pytest backend/tests/integration/api/test_workspace_routes.py backend/tests/integration/api/test_group_participant_routes.py backend/tests/integration/api/test_ws_mutation_invalidation.py backend/tests/unit/application/test_workspace_service.py -q` — **31 passed**, one pre-existing Starlette/httpx deprecation warning.
- Refactor lint: `python -m ruff check backend/app/application/workspace_service.py backend/app/api/routes/_common.py backend/app/api/routes/groups.py backend/app/api/schemas/groups.py backend/app/main.py backend/tests/integration/api/test_workspace_routes.py backend/tests/unit/application/test_workspace_service.py` — **all checks passed**.
- Refactor syntax: `python -m compileall -q backend/app/application/workspace_service.py backend/app/api/routes/_common.py backend/app/api/routes/groups.py backend/app/api/schemas/groups.py backend/app/main.py backend/tests/integration/api/test_workspace_routes.py backend/tests/unit/application/test_workspace_service.py` — **passed**.
- Bounded whitespace check: `git diff --check` plus a trailing-whitespace scan of the untracked bounded files — **clean**; Git emitted only its existing LF/CRLF conversion warning for `_common.py`.
- Full backend suite, contract export/drift, OpenAPI/client generation, PostgreSQL migration run, review, and delivery gates — **not run by delegated scope**.

### Implementation and contract boundary

- Added `GroupCreateRequest` and `GroupSummaryResponse` with forbidden extras, the existing `settlementPolicy` alias, server-derived `role`, and nullable summary counts. Existing `GroupResponse` and `GroupUpdateRequest` wire shapes remain unchanged.
- Added static account-scoped `GET`/`POST /api/v1/groups` routes before the dynamic route. They obtain account identity only from the validated server session; POST alone uses the existing CSRF/origin dependency and accepts no client role or group ID.
- Added the request-state `get_workspace_service` dependency and wired a request-scoped `WorkspaceService` with the existing repositories/UoW and shared broadcaster.
- Extended group creation to publish exactly once with the persisted group ID after the UoW context successfully commits. Validation, invariant, and transaction failures publish nothing.
- OpenAPI export and TypeScript/Dart generation are deliberately deferred until the handwritten API stabilizes; no generated file was edited.

### Files changed in this slice

- `backend/app/application/workspace_service.py`
- `backend/app/api/routes/_common.py`
- `backend/app/api/routes/groups.py`
- `backend/app/api/schemas/groups.py`
- `backend/app/main.py`
- `backend/tests/integration/api/test_workspace_routes.py`
- `backend/tests/unit/application/test_workspace_service.py`
- `openspec/changes/group-outing-workspaces/tasks.md`
- `openspec/changes/group-outing-workspaces/apply-progress.md`

### Changed-line estimate, rollback, and remaining work

- Estimated authored candidate change for this bounded slice: **approximately 630 additions/deletions**, including focused tests, task evidence, and the cumulative remaining-task inventory; below the parent-provided 650-line maximum. This excludes pre-existing PR0/redesign and prior-slice bytes.
- Rollback boundary: revert only the account collection schemas/routes/dependency, workspace publisher/wiring additions, focused API/publisher tests, the single named task row, and this progress section. Preserve existing dynamic `GET/PATCH /api/v1/groups/{group_id}`, prior workspace foundations, PR0, redesign, and unrelated dirty paths.
- The OpenAPI/client generation task is deferred until this handwritten API contract stabilizes.

### Exact unchecked task rows remaining

```text
- [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

The preceding cumulative inventory preserves the exact unchecked rows for PR2–PR9; those rows remain unchanged.

Next recommendation: `parent-lifecycle` for the parent-owned native attempt settlement and lifecycle decisions; do not run verify or delivery gates from this executor.

## PR 1 — Contract freeze and generated-client regeneration slice

### Status consumed and produced

- Consumed native status: `artifactStore=openspec` (the session context is hybrid with the repository OpenSpec tree present), `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, and `actionContext.mode=repo-local` with the repository root as the authoritative allowed edit root.
- Workload guard: `Decision needed before apply: No`, `Chained PRs recommended: Yes`, `Chain strategy: stacked-to-main`, `400-line budget risk: High`; the parent supplied the resolved `exception-ok` delivery path. This worker executed only the contract-freeze/generated-output slice.
- Parent-owned native runtime authority was already active for this work unit. This worker did not acquire, settle, reset, commit, clean, start review, or run delivery gates.
- Produced status: **blocked/partial**. The handwritten contract exported and both pinned generators completed, but Dart serialization and the bounded contract-drift check failed. No implementation task checkbox was changed because the completion condition was not met.

### TDD Cycle Evidence

| Task | Test/validation input | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Contract freeze and generated clients | `export_openapi`, pinned TypeScript/Dart generators, Dart `build_runner`, contract drift | Generated contract/toolchain | ✅ Existing OpenAPI and generated trees were read before mutation | ➖ Not applicable: generator-only structural output; no handwritten production behavior or test seam was added | ➖ Not applicable: one deterministic generator output per frozen contract | ⚠ Generation completed, but serialization/drift did not reach a green refactor gate |

### Exact command outcomes

- `python -m backend.scripts.export_openapi` — **passed**; exporter reported `JSON clean`.
- From `web/`: `npm exec -- openapi-generator-cli generate -i ../contracts/openapi.json -g typescript-fetch -o src/generated/api --skip-validate-spec --additional-properties=supportsES6=true` — **passed** with OpenAPI Generator `7.14.0`; TypeScript output includes the additive group request/summary models and account collection operations.
- From `web/`: `npm exec -- openapi-generator-cli generate -i ../contracts/openapi.json -g dart-dio -o ../mobile/lib/generated/api --skip-validate-spec --additional-properties=serializationLibrary=json_serializable` — **passed** with OpenAPI Generator `7.14.0`.
- From `mobile/lib/generated/api`: `dart pub get` — **passed**; dependencies resolved.
- From `mobile/lib/generated/api`: `dart run build_runner build --delete-conflicting-outputs` — **failed**. The available Dart toolchain emitted generator/formatter errors for null-aware elements in existing generated models and could not generate `SessionIdentityResponse.activeGroupId` (`AnyOf`/`InvalidType`). It also warned that `--delete-conflicting-outputs` is ignored by the installed build_runner version. No success is claimed.
- `python -m backend.scripts.check_contract_drift --cwd .` — **failed** in its temporary Dart serialization build for the same `SessionIdentityResponse.activeGroupId` `AnyOf`/`InvalidType` error; the script exited with `CalledProcessError` from `dart run build_runner build`.
- `git diff --check` — **failed** on generator-produced trailing whitespace in regenerated TypeScript/Dart files. Generated output was not hand-edited or normalized.
- Generated-path audit — **passed**; all contract/client status paths attributable to this slice are under `contracts/openapi.json`, `web/src/generated/api/**`, or `mobile/lib/generated/api/**`. Existing unrelated dirty paths were preserved.
- Focused backend/web/mobile suites, full backend suite, typecheck, build, review, delivery gates, and any second drift run — **not run** by this bounded contract-only scope.

### Generated file scope

- `contracts/openapi.json` was regenerated from the current handwritten FastAPI contract.
- `web/src/generated/api/**` was regenerated, including `GroupsApi.ts`, model exports, `SessionIdentityResponse.ts`, and new `GroupCreateRequest.ts` and `GroupSummaryResponse.ts` outputs plus generator metadata.
- `mobile/lib/generated/api/**` was regenerated, including API sources/docs, model sources, new group request/summary outputs, metadata, and serialization artifacts. The failed local serialization build left partial generated serialization changes/deletions; these are recorded as a toolchain blocker and were not repaired by hand.
- `tasks.md` was intentionally left unchanged: the PR 1 `REFACTOR` row and all broader implementation/parent rows remain unchecked because required Dart serialization and drift did not complete.
- `apply-progress.md` contains this cumulative evidence only.

### Changed-line estimate, rollback boundary, and blockers

- Pre-evidence generated/contract estimate: **approximately 4,144 additions/deletions** (`3,514` tracked changed lines plus `630` lines in newly generated untracked files), already above the parent-provided 800-line authority. This is an honest generated-output count; no generated content was compressed or omitted.
- The generated diff also contains tool-produced formatting churn and generator-produced trailing whitespace. The `git diff --check` failure is therefore preserved rather than “fixed” by hand.
- Rollback boundary: revert only this contract export, the regenerated TypeScript/Dart client tree, and this appended progress section. Do not reset, clean, or alter handwritten backend, tests, specs, web handwritten code, mobile handwritten code, fixtures, policies, redesign paths, or unrelated dirty work.
- Blocker 1: required Dart serialization did not complete because the pinned generated Dart model contains an unsupported `AnyOf`/`InvalidType` nullable session field and related formatter incompatibilities; the exact failed output above is preserved.
- Blocker 2: the single bounded drift check failed during its temporary Dart serialization step.
- Risk: the generated candidate exceeds the 800-line bound before progress/task evidence. Parent must decide whether to discard/re-slice this generated contract boundary or explicitly handle the generated-output overage; this worker does not split, reset, or mutate another slice.

### Remaining tasks and task ownership

- No task was completed in this slice, so no persisted checkbox transition is reported.
- The exact PR 1 generated-contract row remains unchecked:

  ```text
  - [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
  ```

- All broader PR 1 RED/GREEN/TRIANGULATE/Verify rows, later implementation rows, and parent-owned lifecycle rows remain deferred and unchanged.
- Next recommendation: `parent-lifecycle` for the parent-owned runtime settlement/blocker decision. Do not report this slice as ready for verify or rerun generation without an explicit parent decision on the Dart/toolchain blocker and the generated-output line bound.

## PR 1 corrective slice — authenticated session wire contract

### Status consumed and produced

- Consumed native status from `gentle-ai sdd-status group-outing-workspaces --cwd . --json --instructions`: `artifactStore=openspec` because the repository OpenSpec tree is present, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`, and the repository root is the native allowed edit root.
- The parent prompt supplied the resolved corrective delivery path: `exception-ok`, `stacked-to-main`; the workload guard remains `Decision needed before apply: No`, `Chained PRs recommended: Yes`, and `400-line budget risk: High`. This worker implemented only the assigned corrective slice.
- Correction relationship: this slice remediates the failed generated-contract evidence revision `sha256:2553f14f279f157c50615bfdc1345cab8fef3145d9185b9cb386ef03a3bcd451`. The failed generated outputs remain untouched by this writer and are not regenerated here.
- Parent-owned native runtime authority remained active as `sha256:0e250e09b53efd90fd1ccef67621571df3ddf654f1db0b797ddf2b2e59439979`; this worker did not acquire, settle, reset, commit, clean, generate clients, or run review/delivery gates.
- Produced phase result: `success` for this bounded corrective implementation slice. Native status remains `applyState=ready`, `taskProgress={total:60, completed:12, pending:48}`, `dependencies.verify=blocked`, and `nextRecommended=apply`; the executor handoff is `parent-lifecycle` for parent settlement and the separate regeneration step.
- Action-context warning: the native repository edit root is broader than the explicit delegated surfaces. Only `backend/app/api/schemas/auth.py`, `backend/tests/unit/application/test_auth_service.py`, this `tasks.md`, and this `apply-progress.md` were edited. CodeGraph MCP was unavailable (`MCP not initialized`); the repository already had `.codegraph/`, so bounded filesystem reads were used after that read-only intelligence path failed.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Corrective session wire-contract schema | `backend/tests/unit/application/test_auth_service.py` | Unit/schema and auth service | ✅ `13 passed` before edits | ✅ Added null/string serialization, nullable-role, token-safe, and arbitrary-value rejection assertions; focused run `1 failed, 13 passed` because `Any | None` accepted `object()` | ✅ Changed only `SessionIdentityResponse.active_group_id` to `str | None`; focused run:`14 passed` | ✅ Added `from_identity` string-group triangulation; focused run `15 passed`; Ruff, compileall, and diff checks passed |

### Test Summary

- Tests written: **2** focused schema/service tests; the first covers nullable, normal-string, serialization, nullable-role, token-safe, and invalid-arbitrary-value behavior; the second exercises `SessionIdentityResponse.from_identity` with a normal string group ID.
- Safety net: `python -m pytest backend/tests/unit/application/test_auth_service.py -q` — **13 passed** before edits.
- RED: the same focused command after the first test and before the production change — **1 failed, 13 passed**, expected because `Any | None` accepted an arbitrary object.
- GREEN: focused command after the schema correction — **14 passed**.
- TRIANGULATE: focused command after the `from_identity` case — **15 passed**.
- REFACTOR/final focused test: same command — **15 passed**.
- `python -m ruff check backend/app/api/schemas/auth.py backend/tests/unit/application/test_auth_service.py` — **All checks passed**.
- `python -m compileall -q backend/app/api/schemas/auth.py backend/tests/unit/application/test_auth_service.py` — **passed with no output**.
- `git diff --check -- backend/app/api/schemas/auth.py backend/tests/unit/application/test_auth_service.py` — **clean**; Git emitted only its existing LF/CRLF conversion warning.
- Approval tests: **None**. Pure functions created: **None**. Runtime harness: **N/A** — this wire-contract correction has no runtime harness boundary, and regeneration is explicitly deferred to the parent.

### Implementation and contract boundary

- `SessionIdentityResponse.active_group_id` now has the explicit wire type `str | None`; `Role` remains nullable and unchanged.
- The focused tests prove both `None` and a normal string serialize predictably, preserve nullable role behavior, reject arbitrary non-string values, and never expose a session token.
- The application-layer `SessionIdentity`, routes, generated contracts/clients, and all unrelated behavior remain unchanged in this slice.
- No OpenAPI export, client generation, Dart build, or contract-drift command was run. The next step is to regenerate separately from the corrected handwritten schema after parent lifecycle handling.

### Files changed in this slice

- `backend/app/api/schemas/auth.py` — one wire-type correction: `Any | None` → `str | None`.
- `backend/tests/unit/application/test_auth_service.py` — two focused schema/service tests plus required import cleanup.
- `openspec/changes/group-outing-workspaces/tasks.md` — one checked corrective implementation row only.
- `openspec/changes/group-outing-workspaces/apply-progress.md` — this cumulative corrective evidence.

Generated output paths, routes, main wiring, web/mobile handwritten code, migrations/tables/repositories, specs/proposal/design, fixtures, and unrelated paths were not edited. Existing dirty generated output from the failed contract attempt remains untouched and is not claimed as produced by this slice.

### Correction relationship, rollback, and next step

- Failed evidence remediated: `sha256:2553f14f279f157c50615bfdc1345cab8fef3145d9185b9cb386ef03a3bcd451`.
- Rollback boundary: revert only the `active_group_id` annotation, the two focused auth/schema tests, the single corrective task row, and this appended evidence section. Do not reset, clean, regenerate, or alter the failed generated candidate or any prior slice.
- The corrective task row was checked only after focused tests, Ruff, compileall, and bounded diff checks passed. Broad PR1 rows, all later implementation rows, and all parent-owned lifecycle rows remain unchecked.
- Next step: parent-owned settlement must name `--remediates-evidence-revision sha256:2553f14f279f157c50615bfdc1345cab8fef3145d9185b9cb386ef03a3bcd451` if this correction passes; regenerate OpenAPI/TypeScript/Dart separately afterward. This worker does not perform that generation or settlement.

### Remaining tasks and ownership

The following are the exact unchecked rows after this slice; implementation rows are deferred, and parent rows are lifecycle actions owned by the parent:

```text
- [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
- [ ] RED — Add Testing Library tests for authenticated group list/create, zero-group state, one-group auto-selection, multi-group switching, stale/deep-link protection, query-key identity, cache clearing, and no protected render before session authentication; run affected Vitest files and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the additive hash parser/serializer, protected group picker/create flow, selected-group summary/empty workspace, account/group/selection query keys, and cache reset/refetch transitions using the generated client without adding a router or client authorization. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add session expiry/logout, forbidden selection, WebSocket outage/manual refresh, focus/accessible-name, Spanish empty/error/loading, and preserved `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo` behavior tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate only through an additive protected-shell seam after a changed-path audit proves no `web-professional-redesign` file is touched; preserve server-derived roles, CSRF flow, WebSocket signal-only handling, and existing anchors. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact path audit, and final <=780 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for `outing_id = null`, valid same-group association, cross-group rejection, malformed reference, archived-outing create/edit/delete rejection, default all-expense reads, general-only filtering, and atomic child-row validation; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Add nullable `expenses.outing_id`, composite same-group foreign-key protection, repository filters, schema serialization, and service validation while preserving integer cents, participant/contribution/beneficiary invariants, and existing general expenses as `NULL`. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Test PostgreSQL constraint enforcement, archived history readability, failed transaction/no invalidation, old client compatibility, official four-expense values, and migration survival of existing source rows. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate the contract through the pinned workflow, build generated Dart serialization only when frozen models require it, run drift, and update no generated output manually. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/migration tests, lint, contract drift, path audit, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add derived-service/API tests proving group scope includes every general and outing-linked expense exactly once, outing scope filters exact `outing_id`, general expenses never appear in outing totals, participants remain the authorized group set, sums equal zero, and transfer order is stable. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement optional outing scope in server-derived balance/settlement reads and REST schemas; keep all arithmetic, residual allocation, exact-zero checks, and formatting authority on the server/domain services. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add mixed-scope, empty-outing, archived-outing, cross-group, stale-cache, and official Samaipata regression cases with exact expected balances/transfers; assert no derived state is persisted. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Regenerate contract outputs from handwritten API changes and add scope-aware query-key definitions without client calculations or WebSocket payload changes. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full monetary tests, lint, contract drift, and final <=720 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner generation/status/revoke/regenerate, hash-only persistence, reusable consumption by existing sessions, prior-token invalidation, anonymous/invalid/duplicate joins, exact-one participant choice, same-group link/create, cross-group choice rejection, token non-disclosure, and atomic rollback; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement one current SHA-256-hashed 256-bit URL-safe token per group, owner-protected lifecycle endpoints, authenticated consume transaction, group-scoped account-participant link table, and explicit existing-participant-or-new-participant command with stable errors. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add lock/concurrency, CSRF/origin, replay/reusable-code, active-membership conflict, participant uniqueness, no-log/no-summary-secret, post-commit one-frame, and no-frame-on-failure tests; preserve account/participant identity separation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate OpenAPI/TypeScript/Dart outputs through the pinned workflow, keeping plaintext code only in generation response and never hand-editing generated trees. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/security/migration tests, lint, contract drift, secret-output audit, path audit, and final <=800 changed-line count; split before apply if forecast exceeds the cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner removal, member leave, ended-member denial across every group resource, participant-link inactivity, preserved participant/expense/outing history, rejoin eligibility, member forbidden removal, and final-owner protection. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement nullable `ended_at` active-membership semantics, owner-remove/member-leave operations, immutable owner safety, inactive link handling, active-membership listing, and one post-commit group invalidation per successful mutation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add concurrent exit/remove, stale sessions, cross-group account IDs, final-owner conflict, rejoin with a new explicit link choice, rollback/no-invalidation, and official fixture regression coverage. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Reconcile handwritten API schemas/routes, regenerate clients only where the frozen contract changes, run drift, and keep role derivation server-owned. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full regression tests, migration proof if applicable, lint, contract drift, and final <=740 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add behavior tests for outing/general expense separation, outing archived read-only state, server-provided scoped balances/settlement, participant detail, loading/empty/forbidden/error states, route/deep-link protection, and cache invalidation/refetch; audit redesign paths before running. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement additive laptop-first pages/states for outing detail/expenses, general expenses, group summary, participant detail, balances, and settlement using generated client data and shared integer-cent formatter; perform no client monetary arithmetic. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Cover mixed-scope no-double-counting, stale selected group/outing, archived history, WebSocket outage/manual refresh, membership changes, Spanish accessible names, keyboard focus, visible state cues, and preserved legacy anchors. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate through the protected shell without overwriting `web-professional-redesign`; remove only additive duplication, preserve query identity and REST authority, then rerun focused web tests. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact dirty-path audit, and final <=800 changed-line count; stop and split at a screen boundary if over cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner join-code display/regenerate/revoke/status secrecy, member/owner membership controls, leave/final-owner errors, forbidden actions, empty/error/recovery states, accessibility/laptop-first behavior, and official-flow preservation. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement group/membership settings, authenticated join-code consumption UI with explicit participant link/create choice, member removal/leave actions, Spanish copy, and safe protected recovery states using server-derived role/error responses. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add full regression cases for account selection, outing lifecycle, scoped expenses/derived results, invalidation-only WebSocket behavior, no public join/account creation, no token leakage, official Samaipata exact data/result, and all protected deep links. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Normalize source-mutating files before candidate freeze, preserve all redesign bytes/modes, remove no required acceptance coverage, and confirm the final web remains dependency-free with mobile UI out of scope. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, complete backend/web/contract/migration gates, manual laptop-first accessibility/browser flow, protected-path and generated-output audits, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

## PR 1i — OpenAPI and generated client synchronization retry

### Status consumed and produced

- Consumed native status for `group-outing-workspaces`: `artifactStore=openspec` because the hybrid session has an `openspec/` directory, `applyState=ready`, `dependencies.apply=ready`, `dependencies.verify=blocked`, `nextRecommended=apply`, `actionContext.mode=repo-local`, and repository-root edit authority. The parent-owned native PR1i token is `sha256:1dc835ac23f94b1a4ed7690b5ed101fd489377e91384782bb73fd7219dbab161`; this executor did not acquire, settle, reset, clean, commit, start review, or run delivery gates.
- Workload guard: `Decision needed before apply: No`; `Chained PRs recommended: Yes`; `Chain strategy: stacked-to-main`; `400-line budget risk: High`. The parent supplied `exception-ok`; this worker executed only the assigned generated-contract synchronization boundary.
- CodeGraph ordering was followed: `.codegraph/` was present; CodeGraph MCP was unavailable (`MCP not initialized`), then upstream `codegraph status` and `codegraph explore` succeeded before bounded filesystem reads. No handwritten source or consumer was edited.
- The generated candidate had been rolled back before PR1i. The three pre-existing mobile markdown residue files were preserved; no manual normalization or generated-file repair was performed.
- Produced phase result: **blocked/partial**. Export, both generators, `dart pub get`, focused auth tests, and Ruff passed. Dart serialization failed, so drift was not run under the explicit fail-stop rule. The broad PR1 `REFACTOR` row and all broad/later/parent rows remain unchecked.

### TDD Cycle Evidence

Strict TDD is active, but this is a generator-only structural boundary with no meaningful RED test or handwritten production behavior to design. No production source or test was written.

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR1i generated contract synchronization | N/A — generator-only | OpenAPI/generated-client toolchain | Read corrected schema, contract, generated models, workflow, tasks, and cumulative progress | Not applicable | Not applicable: deterministic export/generation | Read-only checks confirmed nullable string output in OpenAPI, TypeScript, Dart, and Dart serialization source | Blocked by `build_runner`; drift and successful diff check were not reached |

### Exact command outcomes

1. `python -m backend.scripts.export_openapi` from repository root — **passed**, exit `0`, no output.
2. From `web/`, `npm exec -- openapi-generator-cli generate -i ../contracts/openapi.json -g typescript-fetch -o src/generated/api --skip-validate-spec --additional-properties=supportsES6=true` — **passed**, OpenAPI Generator `7.14.0`.
3. From `web/`, `npm exec -- openapi-generator-cli generate -i ../contracts/openapi.json -g dart-dio -o ../mobile/lib/generated/api --skip-validate-spec --additional-properties=serializationLibrary=json_serializable` — **passed**, OpenAPI Generator `7.14.0`.
4. From `mobile/lib/generated/api`, `dart pub get` — **passed**, dependencies resolved.
5. From `mobile/lib/generated/api`, `dart run build_runner build --delete-conflicting-outputs` — **failed**, exit `1`. The installed runner said `--delete-conflicting-outputs` was ignored, then raised `FormatterException` for generator-emitted null-aware elements requiring the `null-aware-elements` language feature in `error_response.dart`, `expense_response.dart`, `group_summary_response.dart`, and `participant_response.dart`; it reported `Failed to build with build_runner/aot` and `wrote 19 outputs`.
6. `python -m backend.scripts.check_contract_drift --cwd .` — **not run** after the build failure because the user-required stop rule prohibits further mutating commands. No drift success is claimed.
7. `python -m pytest backend/tests/unit/application/test_auth_service.py -q` — **passed**, `15 passed in 0.56s`.
8. `python -m ruff check backend` — **passed**, `All checks passed!`.
9. `git diff --check -- contracts/openapi.json web/src/generated/api mobile/lib/generated/api` — **failed**, exit `2`; generator-produced trailing whitespace was reported in generated TypeScript API files and generated Dart API/documentation files. LF→CRLF warnings were also emitted. No cleanup was run.
10. `git status --short`, targeted `git diff --stat`, and `git diff --numstat` — **passed as read-only inventory**. The generated/contract snapshot has 45 tracked changed paths with `1,741` additions and `1,792` deletions (`3,533` tracked changed-line units), plus 9 generated untracked files containing `630` lines. Raw snapshot: `4,163` line units relative to `HEAD`, including the three pre-existing mobile markdown residue files; this exceeds the broad PR1 `<=790` ceiling.

### Corrected nullable session contract evidence

- OpenAPI represents `active_group_id` as nullable string (`string` plus `null`), sourced from the corrected handwritten `str | None` annotation.
- `web/src/generated/api/models/SessionIdentityResponse.ts` contains `activeGroupId: string | null`.
- `mobile/lib/generated/api/lib/src/model/session_identity_response.dart` contains `final String? activeGroupId` and nullable `role`.
- `mobile/lib/generated/api/lib/src/model/session_identity_response.g.dart` uses `(v) => v as String?`.
- The generated TypeScript/Dart session files contain neither `AnyOf` nor `InvalidType`. The targeted nullable-string criterion passes, but the slice completion predicate does not.

### Changed-path inventory

Tracked paths from `git diff --name-status` are exactly the contract plus generated outputs: `contracts/openapi.json`; mobile `.openapi-generator/FILES`, `README.md`, `doc/GroupsApi.md`, `doc/SessionIdentityResponse.md`, `lib/openapi.dart`, seven generated API Dart files, `lib/src/deserialize.dart`, 20 generated model `.g.dart` files (with `error_response.g.dart`, `expense_response.g.dart`, and `participant_response.g.dart` deleted by the failed build), `session_identity_response.dart`, `session_identity_response.g.dart`, and `pubspec.yaml`; web `.openapi-generator/FILES`, seven generated API TypeScript files, `models/SessionIdentityResponse.ts`, and `models/index.ts`.

Newly generated untracked paths are:

```text
mobile/lib/generated/api/doc/GroupCreateRequest.md
mobile/lib/generated/api/doc/GroupSummaryResponse.md
mobile/lib/generated/api/lib/src/model/group_create_request.dart
mobile/lib/generated/api/lib/src/model/group_create_request.g.dart
mobile/lib/generated/api/lib/src/model/group_summary_response.dart
mobile/lib/generated/api/test/group_create_request_test.dart
mobile/lib/generated/api/test/group_summary_response_test.dart
web/src/generated/api/models/GroupCreateRequest.ts
web/src/generated/api/models/GroupSummaryResponse.ts
```

`.dart_tool` build files are ignored by Git and are not part of the changed-path inventory. No handwritten source, test, consumer, fixture, policy, redesign, or unrelated file was changed by this slice.

### Task checkbox and remaining work

The broad PR1 generated-contract row was **not** checked: Dart build failed, drift was not run, diff check failed, and the generated snapshot is over the PR1 ceiling. No task checkbox changed in this slice. The exact immediate unchecked rows remain:

```text
- [ ] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

The preceding cumulative inventory retains the unchanged unchecked rows for PR2–PR9. Broad PR1 verification, later slices, and parent lifecycle actions remain deferred.

### Rollback boundary and deviations

- No rollback, cleanup, normalization, manual repair, or second generation attempt was performed. The exact generator/build-produced state is preserved for the parent-owned attempt decision.
- Any later rollback of this failed slice is limited to PR1i contract/client output and this appended evidence; prior handwritten PR1 slices, corrected PR1h schema/tests, pre-existing mobile markdown residue, redesign bytes, fixtures, and unrelated work remain outside that boundary.
- The only workflow deviation is the required fail-stop after Dart build failure; drift was intentionally not executed.

### Structured phase result

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: hybrid
applyState: ready
taskProgress: {total: 60, complete: 12, remaining: 48}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
  allowedEditRoots: [D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1]
  warnings:
    - "Parent-owned PR1i runtime token remained active and was not mutated by this executor."
    - "Generated output contains preserved formatter/line-ending residue and partial build outputs after the failed build."
        - "Current raw generated/contract snapshot is above the PR1 790-line ceiling."
    nextRecommended: parent-lifecycle
    ```

    ## PR 1l — Generated Dart serialization repair

    ### Status consumed and produced

    - This bounded slice isolated the generated Dart serialization pipeline after PR1k. No handwritten product source, consumer, fixture, redesign path, or task checkbox was changed.
    - Native SDD runtime authority was completed for `PR1l Dart serialization bounded repair`; the final passing settlement remediated the immediately preceding failed evidence revision `sha256:59e0826ffc36034ffa9676bd5c414a84059455898b104e80a3d2b5422b16d317`.
    - The broad PR1 generated-contract `REFACTOR` row remains unchecked until contract drift and the remaining verification gates pass.

    ### TDD Cycle Evidence

    Strict TDD is active, but this is a generator-only structural boundary with no handwritten behavior seam. The prior PR1h nullable-wire test remains the behavior evidence; this slice records toolchain RED/GREEN evidence.

    | Task | Test/validation input | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | PR1l generated Dart serialization repair | Existing deterministic normalizers, `dart pub get`, `build_runner` | Generated contract/toolchain | PR1k generated models and PR1j failure evidence | ✅ First build reproduced the SDK-floor/`null-aware-elements` failure; a second actor also failed before Dart because it used the repository root | ✅ After the user-authorized objective reset, normalizers and correctly-cwded Dart commands completed | ✅ Both new `.g.dart` parts exist and the runner wrote 44 outputs; no transient generated package artifacts remain tracked | Deferred: contract drift and broad PR1 verification remain separate gates |

    ### Exact command outcomes

    1. Existing normalizers from `backend/scripts/check_contract_drift.py` — **passed**: `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, and `_normalize_mobile_auth_test` ran without hand-editing generated files. The mobile generated package now uses the host-compatible `>=3.10.0` SDK floor.
    2. `dart pub get` from `mobile/lib/generated/api` — **passed**, exit `0`; dependencies resolved.
    3. `dart run build_runner build --delete-conflicting-outputs` from `mobile/lib/generated/api` — **passed**, exit `0`; 44 outputs written. The installed runner emitted only the known warning that `--delete-conflicting-outputs` is ignored by this runner version, plus its dependency-constraint warning.
    4. Generated serialization readback — **passed**: both `mobile/lib/generated/api/lib/src/model/group_create_request.g.dart` and `mobile/lib/generated/api/lib/src/model/group_summary_response.g.dart` exist and are paired with their generated model sources.
    5. Native final evidence revision — `sha256:3f63e6112db66a238d252a8096887cca3ceef7a21ac3a4b0bfc43edf3b40ee51`; the bounded objective settled as complete.

    ### Failed attempts preserved

    - The first PR1l actor ran `dart pub get` successfully, but `build_runner` failed because the generated package still declared `>=3.5.0` while generated parts required the `null-aware-elements` language feature.
    - The first repair actor applied the existing normalizers but invoked `dart pub get` from the repository root and exited `66`; no build was claimed. The user explicitly authorized a reset of only this PR1l runtime objective, preserving the generated candidate.
    - No generated output was hand-edited. The final repair ran the same normalizers from the repository root and both Dart commands from the generated package directory.

    ### Changed/generated path scope

    - Generated-only output remains confined to `contracts/openapi.json`, `web/src/generated/api/**`, and `mobile/lib/generated/api/**`, with the cumulative progress file as the sole evidence artifact touched by this slice.
    - Newly present serialization parts are `group_create_request.g.dart` and `group_summary_response.g.dart`. Transient `pubspec.lock`, `.dart_tool`, and `.build` artifacts were not retained as deliverables.
    - The generator-produced trailing whitespace warning remains a known generated-output concern; no manual whitespace repair was performed. Contract drift is the next required independent check.

    ### Rollback boundary

    Revert only the final PR1l normalizer/build effects in `mobile/lib/generated/api/**` and this appended evidence section. Preserve the prior PR1j/PR1k failure and reset evidence, all handwritten backend/API changes, OpenSpec specifications, fixtures, redesign bytes, and unrelated dirty paths.

    ### Structured phase result

    ```yaml
    schemaName: spec-driven
    changeName: group-outing-workspaces
    artifactStore: hybrid
    applyState: ready
    taskProgress: {total: 60, complete: 12, remaining: 48}
    dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
    actionContext:
      mode: repo-local
      allowedEditRoots: [mobile/lib/generated/api, openspec/changes/group-outing-workspaces/apply-progress.md]
      warnings:
        - "Generated-client contract drift has not yet been run after the successful Dart build."
        - "The installed build_runner ignores --delete-conflicting-outputs; the build nevertheless completed successfully."
        - "No handwritten generated output was edited."
    nextRecommended: parent-lifecycle
    ```
    
    
    ## PR 1j — Corrected FastAPI OpenAPI snapshot and pinned TypeScript regeneration

    ### Status consumed and produced

    - Parent-owned native PR1j attempt authority was acquired before this worker started. This worker did not acquire, settle, reset, clean, commit, run Dart commands, run `build_runner`, run drift, or start review/delivery gates.
    - The bounded generator objective used only the explicitly allowed contract, generated TypeScript, and cumulative OpenSpec progress surfaces. Existing handwritten PR1 changes, prior mobile formatter residue, redesign bytes, and unrelated dirty paths were preserved.
    - Produced phase result: **partial**. The corrected FastAPI OpenAPI snapshot exported successfully and the pinned TypeScript client regenerated successfully. Structural model checks passed. The required `git diff --check` reported generator-produced trailing whitespace, so no clean verification result or broad PR1 completion is claimed.

    ### TDD Cycle Evidence

    Strict TDD is active, but this is a mechanical generator-only contract synchronization phase with no meaningful behavior seam or handwritten production change. No RED/GREEN behavior cycle applies; the prior PR1h schema RED/GREEN evidence remains the behavior evidence for the nullable-string correction.

    | Task | Test/validation input | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
    | --- | --- | --- | --- | --- | --- | --- | --- |
    | PR1j corrected contract generation | OpenAPI exporter, pinned TypeScript generator, generated model readback | Generated contract/toolchain | Corrected FastAPI schema and prior PR1h evidence | Justified exception: no meaningful behavior RED applies | Justified exception: deterministic export/generation commands completed | ✅ `SessionIdentityResponse.ts` exposes `activeGroupId: string | null`; `GroupCreateRequest.ts` and `GroupSummaryResponse.ts` exist and are exported | ⚠ `git diff --check` failed on generator-produced trailing whitespace; Dart generation, build, drift, and broad PR1 REFACTOR remain deferred |

    ### Exact command outcomes

    1. `python -m backend.scripts.export_openapi` from repository root — **passed**, exit `0`, no output.
    2. `npm --prefix web exec -- openapi-generator-cli generate -i contracts/openapi.json -g typescript-fetch -o web/src/generated/api --skip-validate-spec --additional-properties=supportsES6=true` from repository root — **passed** with the repository-pinned OpenAPI Generator `7.14.0`. Generator output included the account collection API methods and group request/summary models. The runner also reported its existing `supportsES6` option warning and applied its automatic generated-file Biome fixes; no generated file was hand-edited.
    3. Generated-model verification — **passed**: `web/src/generated/api/models/SessionIdentityResponse.ts` contains `activeGroupId: string | null`; `web/src/generated/api/models/GroupCreateRequest.ts` and `web/src/generated/api/models/GroupSummaryResponse.ts` exist; both are exported from `web/src/generated/api/models/index.ts`.
    4. `git diff --check -- contracts/openapi.json web/src/generated/api` — **failed**, exit `2`; it reported trailing whitespace in generated TypeScript API files and emitted existing LF→CRLF conversion warnings. No normalization or manual repair was run.
    5. `git diff --stat -- contracts/openapi.json web/src/generated/api` — **passed** as read-only evidence: `11` tracked paths, `762` insertions, and `802` deletions.
    6. `git status --short` — **passed** as read-only evidence; it confirmed the two new generated TypeScript model files and preserved pre-existing dirty paths.

    ### Changed-path and line inventory

    - Tracked generated/contract paths from the bounded `git diff --stat`: `contracts/openapi.json`; `web/src/generated/api/.openapi-generator/FILES`; `web/src/generated/api/apis/AuthApi.ts`; `BalancesApi.ts`; `ExpensesApi.ts`; `GroupsApi.ts`; `HealthApi.ts`; `ParticipantsApi.ts`; `SettlementApi.ts`; `web/src/generated/api/models/SessionIdentityResponse.ts`; and `web/src/generated/api/models/index.ts`.
    - Newly generated untracked paths from `git status --short`: `web/src/generated/api/models/GroupCreateRequest.ts` and `web/src/generated/api/models/GroupSummaryResponse.ts`.
    - Tracked snapshot inventory: **11 paths, +762/-802 lines**. The two untracked model files are included in the path inventory but are not counted by `git diff --stat` until parent settlement inventories them.
    - No mobile, backend handwritten source, tests, fixtures, specs/design/proposal, redesign, or unrelated path was edited by this slice. The broad PR1 `REFACTOR` checkbox remains unchecked, and no other task checkbox changed.

    ### Deferred work, risks, and rollback boundary

    - Dart generation, Dart serialization/build, contract drift, focused backend tests, broad verification, and all lifecycle review/delivery actions remain deferred to the parent or a separately authorized bounded unit. This slice intentionally does not claim the PR1 generated-contract REFACTOR row complete.
    - Risk: the generated TypeScript snapshot contains generator-produced trailing whitespace, and its tracked diff is above the earlier PR1 forecast. The failure is preserved exactly rather than normalized by hand.
    - Rollback boundary: revert only the corrected OpenAPI snapshot, the regenerated `web/src/generated/api/**` files listed above, the two new generated model files, and this appended PR1j evidence section. Preserve handwritten PR1 changes, prior mobile residue, prior PR1h evidence, specs, fixtures, redesign bytes, and unrelated dirty paths.

    ### Structured phase result

    ```yaml
    schemaName: spec-driven
    changeName: group-outing-workspaces
    artifactStore: openspec
    applyState: ready
    taskProgress: {total: 60, complete: 12, remaining: 48}
    dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
    actionContext:
      mode: repo-local
      workspaceRoot: D:\universidad\proyectos\2doSemestre2026\topicos\proyecto_1
      allowedEditRoots: [D:\universidad\proyectos\2doSemestre2026\topicos\proyecto_1]
      warnings:
        - "Parent-owned PR1j runtime authority remained active and was not mutated by this executor."
        - "Generated TypeScript output preserves generator-produced trailing whitespace reported by git diff --check."
            - "Dart generation, serialization, drift, and broad PR1 REFACTOR remain deferred."
        nextRecommended: parent-lifecycle
        ```

## PR 1k — Dart generated client slice

### Status consumed and produced

- This bounded slice used the parent-supplied native PR1k context and changed only the Dart generated-client tree plus this cumulative progress file. The parent owns native attempt authority; this worker did not acquire, settle, reset, clean, commit, run build_runner, run `dart pub get`, run contract drift, start review/delivery, or edit handwritten source.
- The pinned OpenAPI Generator `7.14.0` Dart command completed successfully. Dart serialization/build and contract drift are explicitly deferred to the separate follow-up verification slice.
- The broad PR1 `REFACTOR` task row remains unchecked; no task checkbox changed.
- If the parent treats this corrective candidate as passing for settlement, the settlement must name the previous PR1j failed evidence revision `sha256:adea320078b6ae020132a5017f4750c638d4b679efe954e933d3bef5c66a1205`.

### TDD Cycle Evidence

Strict TDD is active, but this is a generator-only structural slice with no meaningful RED/GREEN behavior seam. The prior PR1j failure evidence remains preserved, and no RED/GREEN cycle was run here.

| Task | Test/validation input | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR1k Dart generated client | Pinned Dart OpenAPI Generator and read-only generated-source checks | Generated contract/toolchain | Prior PR1j generated-contract evidence and corrected nullable schema | Justified exception: no meaningful behavior RED applies | Generator completed with exit `0`; no Dart serialization/build was run | ✅ Nullable session fields and GroupCreateRequest/GroupSummaryResponse source/docs/tests were confirmed | Deferred to the separately authorized Dart serialization/drift slice |

### Exact command outcomes

1. `npm --prefix web exec -- openapi-generator-cli generate -i contracts/openapi.json -g dart-dio -o mobile/lib/generated/api --skip-validate-spec --additional-properties=serializationLibrary=json_serializable` from the repository root — **passed**, exit `0`, OpenAPI Generator `7.14.0`.
2. `mobile/lib/generated/api/lib/src/model/session_identity_response.dart` readback — **passed**: declares `final String? activeGroupId` and nullable role (`final SessionIdentityResponseRoleEnum? role`).
3. Generated GroupCreateRequest and GroupSummaryResponse source/docs/tests existence — **passed**. Generated paths include:
   - `mobile/lib/generated/api/lib/src/model/group_create_request.dart`
   - `mobile/lib/generated/api/lib/src/model/group_summary_response.dart`
   - `mobile/lib/generated/api/doc/GroupCreateRequest.md`
   - `mobile/lib/generated/api/doc/GroupSummaryResponse.md`
   - `mobile/lib/generated/api/test/group_create_request_test.dart`
   - `mobile/lib/generated/api/test/group_summary_response_test.dart`
4. `git diff --check -- mobile/lib/generated/api` — **failed**, exit `2`, on generator-produced trailing whitespace in generated Dart documentation/API files; existing LF→CRLF conversion warnings were also emitted. No hand-edit, formatting, normalization, or repair was performed.
5. `git diff --stat -- mobile/lib/generated/api` — **passed** as read-only evidence: **14 tracked paths, 546 insertions, 461 deletions**. The six newly generated untracked GroupCreateRequest/GroupSummaryResponse source, documentation, and test paths are not included in this stat until parent settlement inventories them.
6. Final read-only `git status --short --untracked-files=all` confirmed no new handwritten backend, web, or mobile consumer path; all such dirty paths were pre-existing and preserved.

### Generated path inventory

The command regenerated the tracked Dart paths reported by the stat: `mobile/lib/generated/api/.openapi-generator/FILES`, `mobile/lib/generated/api/README.md`, `mobile/lib/generated/api/doc/GroupsApi.md`, `mobile/lib/generated/api/doc/SessionIdentityResponse.md`, `mobile/lib/generated/api/lib/openapi.dart`, `mobile/lib/generated/api/lib/src/api/auth_api.dart`, `mobile/lib/generated/api/lib/src/api/balances_api.dart`, `mobile/lib/generated/api/lib/src/api/expenses_api.dart`, `mobile/lib/generated/api/lib/src/api/groups_api.dart`, `mobile/lib/generated/api/lib/src/api/participants_api.dart`, `mobile/lib/generated/api/lib/src/api/settlement_api.dart`, `mobile/lib/generated/api/lib/src/deserialize.dart`, `mobile/lib/generated/api/lib/src/model/session_identity_response.dart`, and `mobile/lib/generated/api/pubspec.yaml`. It added the six untracked model/documentation/test paths listed above. Existing generated serialization `.g.dart` changes from PR1j were preserved; no Dart build was run.

During the generator command, the terminal also reported automatic `pi-lens`/Dart analysis fixes on generated files. Those side effects remained inside the generator-owned surface; this worker did not manually format or repair generated output.

### Deferred work, risks, and rollback boundary

- Dart serialization/build, contract drift, Dart tooling, and broad PR1 verification remain deferred exactly as requested. This slice does not claim the generated-contract REFACTOR row complete.
- Risk: `git diff --check` remains red on generator-produced trailing whitespace, and the tracked generated diff is `+546/-461` before untracked-file accounting. Generated output was preserved rather than normalized by hand.
- Rollback boundary: revert only the Dart generated-client outputs from this PR1k command and this appended progress section. Preserve PR1j failure evidence, handwritten backend/web/mobile consumer files, prior generated residue, specs, fixtures, redesign bytes, and unrelated dirty paths.

### Structured phase result

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: hybrid
applyState: ready
taskProgress: {total: 60, complete: 12, remaining: 48}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  allowedEditRoots: [mobile/lib/generated/api, openspec/changes/group-outing-workspaces/apply-progress.md]
  warnings:
    - "Parent-owned PR1k runtime authority remained active and was not mutated by this executor."
    - "Dart serialization/build and contract drift are deferred to a separate verification slice."
    - "git diff --check reports generator-produced trailing whitespace; no manual normalization was performed."
nextRecommended: parent-lifecycle
```

## PR 1m — Contract drift and generated Markdown policy

### Status consumed and produced

- This bounded corrective slice resolved the remaining PR1m contract-drift failure without editing generated output by hand.
- The native runtime objective `PR1m markdown policy and contract drift` settled as complete at objective generation `23`, with passing evidence revision `sha256:2c8831b23c82c0f7b5daf8fccd4f46e9b8dbb1c197f01868876d6e55005d48e1` remediating failed evidence `sha256:24cf80c0663614a9813d63870c4b1d0d05aa4d80ec605ab33c0ee881e20c33c9`.
- The separate evidence-closeout attempt records this section only; the broad PR1 `REFACTOR` row remains unchecked until focused backend tests, Ruff, and the bounded diff/path checks are complete.

### Deterministic policy and regeneration

- `.pi-lens.json` now ignores OpenAPI Generator-owned mobile Markdown (`README.md` and `doc/**`) plus generated test scaffolds (`test/**`) so host formatters and analyzer diagnostics cannot mutate or block on generator bytes.
- `.markdownlintignore` mirrors those generated Markdown paths for repository markdownlint consumers.
- Both generated client roots were cleared and regenerated from empty output roots. OpenAPI Generator recreated `.openapi-generator-ignore` and matching `.openapi-generator/FILES` manifests; the Dart package then ran the existing normalizers, `dart pub get`, and `build_runner` from `mobile/lib/generated/api`.
- No generated file was hand-edited. Ignored `.dart_tool`, `pubspec.lock`, and temporary drift roots are not deliverables.

### Exact command outcomes

1. OpenAPI export, pinned TypeScript/Dart generation, and Dart serialization — **passed**; build_runner wrote 44 outputs and emitted only the known removed-option/dependency-constraint warnings.
2. `python -m backend.scripts.check_contract_drift --cwd .` — **passed**, exit `0`: `Contract and generated clients are drift-free.` The regenerated temporary workspace was cleaned.
3. Native `gentle-ai sdd-attempt settle` — **passed**; the runtime objective is complete and the failed drift evidence is explicitly remediated.

### Scope and remaining gates

- Generated contract surfaces remain under `contracts/openapi.json`, `web/src/generated/api/**`, and `mobile/lib/generated/api/**`; the only policy additions are `.pi-lens.json` and `.markdownlintignore`, required to keep generated Markdown and test scaffolds reproducible and quiet.
- The broad PR1 `REFACTOR` row and the separate full-verification row remain unchecked. Focused backend tests, `python -m ruff check backend`, `git diff --check`, exact path/line audits, and later native review/delivery gates remain pending.

### Structured phase result

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: hybrid
applyState: ready
taskProgress: {total: 60, complete: 12, remaining: 48}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\\Universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1
  allowedEditRoots: [D:\\Universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1]
  warnings:
    - "Generated contract drift is green; focused/backend verification and delivery remain pending."
    - "Pyright and CodeGraph remain unavailable and are not treated as passing evidence."
nextRecommended: parent-lifecycle
```

## PR 1 generated serialization remediation — deterministic Dart restoration

### Status consumed and produced

- Consumed native status: `schemaName=gentle-ai.sdd-status`, `changeName=group-outing-workspaces`, `artifactStore=openspec`, `applyState=ready`, `dependencies.apply=ready`, `dependencies.verify=blocked`, `nextRecommended=apply`.
- `actionContext.mode=repo-local`; workspace root is `D:\\Universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1`; the parent-provided allowed edit surface for this unit is `mobile/lib/generated/api/**` plus this cumulative progress file.
- Workload guard remains: `Decision needed before apply: No`, `Chained PRs recommended: Yes`, `Chain strategy: stacked-to-main`, `400-line budget risk: High`; the parent supplied the `exception-ok` delivery path for the broader chained work.
- The parent-held native runtime objective was reused without acquiring, resetting, or settling another attempt. No review actor, receipt, lifecycle gate, commit, push, reset, or clean operation was run.
- Produced bounded result: **success** for restoration of the interrupted generated Dart serialization state. The broad PR1 `REFACTOR` and verification rows remain unchecked; this does not complete PR1 or start PR2.

### TDD Cycle Evidence

Strict TDD is active. This unit is a generator-only structural boundary with no handwritten behavior seam, so the failing build is the equivalent RED test and the existing PR1m contract-drift evidence remains the behavior safety net.

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR1 generated Dart serialization remediation | N/A — generator-only | Generated contract/toolchain | Existing PR1m drift evidence and current generated-source readback | ✅ `build_runner` failed from the generated package directory under the legacy SDK floor; missing generated parts were reproduced | ✅ Existing normalizers plus correctly-cwded `dart pub get` and `build_runner` completed; 44 outputs written | ✅ `dart test` passed 96 tests; all 22 model source/part pairs are present | ✅ No generated file was hand-edited; only the repository normalizer and build tool produced generated changes |

### Exact command outcomes

1. RED `cd mobile/lib/generated/api && dart pub get` — **passed**, exit `0`.
2. RED `cd mobile/lib/generated/api && dart run build_runner build --delete-conflicting-outputs` — **failed as expected**, exit `1`; the runner warned that `--delete-conflicting-outputs` is removed/ignored and `json_serializable` could not format null-aware elements because the generated package still declared `>=3.5.0`. It reported the `null-aware-elements` failure for `error_response.dart`, `expense_response.dart`, `group_summary_response.dart`, and `participant_response.dart`, and wrote `0` outputs.
3. Existing normalizers, run from the repository root through `backend.scripts.check_contract_drift` — **passed**: `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, and `_normalize_mobile_auth_test` completed without hand-editing generated output. The SDK floor was normalized to `>=3.10.0 <4.0.0`.
4. GREEN `cd mobile/lib/generated/api && dart pub get` — **passed**, exit `0`.
5. GREEN `cd mobile/lib/generated/api && dart run build_runner build --delete-conflicting-outputs` — **passed**, exit `0`; the runner warned that `--delete-conflicting-outputs` is removed/ignored and that `^4.9.0` permits `json_annotation` versions before `4.12.0`. It completed in 44 seconds and wrote `44` outputs.
6. `cd mobile/lib/generated/api && dart test` — **passed**: `96` tests passed.
7. Generated serialization path audit — **passed**: every model source with a `part` declaration has its `.g.dart` file, including restored `error_response.g.dart`, `expense_response.g.dart`, `participant_response.g.dart`, and `group_summary_response.g.dart`.
8. `git diff --check -- mobile/lib/generated/api` — **exit `2`** on generator-produced trailing whitespace in generated API/documentation files; Git also emitted expected LF-to-CRLF conversion warnings. No manual whitespace repair was performed. This known generated-output warning is not a serialization build failure.

### Changed files and path audit

- The generated package now contains the four previously missing serialization parts and the normalized SDK floor. All generated changes remain under `mobile/lib/generated/api/**`; no handwritten backend, web, mobile, test, contract, canonical-spec, fixture, redesign, or unrelated path was introduced by this unit.
- The final scoped snapshot reports `21` tracked generated paths with `571` insertions and `504` deletions, plus `486` lines in eight untracked generated source/documentation/test files. Those totals include pre-existing PR1 generated-contract churn and are not treated as this remediation's authored-line count.
- Ignored `.dart_tool` and `pubspec.lock` remain inside the generated package after the commands. They are not deliverables and were not removed because this unit was explicitly prohibited from cleanup.
- The full dirty-tree audit preserved the existing backend, contract, web, canonical-spec, proposal/design, task, and `web-professional-redesign` paths. `tasks.md` was not modified, and no checkbox changed.

### Deviations and remaining tasks

- No design or generation-workflow deviation: the repository's existing normalizer and the documented generated-package working directory were used. OpenAPI export, client regeneration, contract drift, focused backend verification, broad PR1 verification, and delivery gates were intentionally not run because they are outside this bounded restoration objective.
- The exact immediate unchecked implementation rows remain unchanged:

```text
- [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

The preceding cumulative inventories retain the exact unchecked PR2–PR9 implementation rows; no later slice was started or changed.

### Rollback boundary

Revert only the normalizer/build effects attributable to this bounded restoration under `mobile/lib/generated/api/**` and this appended evidence section. Preserve the prior PR1 handwritten/API work, existing generated-contract snapshot, OpenSpec artifacts, official fixture, redesign bytes, and all unrelated dirty paths. Do not use `git reset`, `git clean`, or a broad generated-tree rollback.

### Structured phase result

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: openspec
applyState: ready
taskProgress: {total: 60, complete: 15, remaining: 45}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\\Universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1
  allowedEditRoots: [mobile/lib/generated/api, openspec/changes/group-outing-workspaces/apply-progress.md]
  warnings:
    - "Generated Dart serialization was restored deterministically; no generated file was hand-edited."
    - "The installed build_runner ignores --delete-conflicting-outputs and emits its dependency-constraint warning."
    - "git diff --check reports known generator-produced trailing whitespace and line-ending conversion warnings."
    - "Broad PR1 contract/verification and parent lifecycle work remain pending."
    - "CodeGraph MCP was unavailable (`MCP not initialized`); the upstream read-only CLI was used after confirming the existing index."
nextRecommended: parent-lifecycle
```

## PR 1 evidence closeout — blocked

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `dependencies.verify=blocked`, and `nextRecommended=apply`; action context is repo-local with the repository as the authoritative root.
- The parent-held native verification token was reused as instructed. This executor did not acquire, reset, settle, commit, push, clean, start review, or run delivery gates.
- Workload guard remains `Decision needed before apply: No`, `Chained PRs recommended: Yes`, `Chain strategy: stacked-to-main`, and `400-line budget risk: High`. The native PR1 boundary is **790 changed-line units** for this closeout; no size exception was invented or accepted here.
- Produced phase result: **blocked**. The focused behavior and lint evidence passed, but current contract drift failed and the frozen PR1 candidate cannot fit the 790-line boundary.

### Task ownership and transition reconciliation

- `tasks.md` readback found 60 checkbox rows: 15 complete and 45 pending. Every `sdd-owner` marker is a single valid terminal `implementation` or `parent` marker; no malformed ownership marker was found.
- The persisted PR1 RED/GREEN/TRIANGULATE rows remain checked and were independently corroborated by the current focused workspace/auth suite. No checkbox was changed in this closeout.
- PR1 `REFACTOR` and `Verify` remain unchecked because their completion predicates are not satisfied. All PR2–PR9 rows and all parent-owned lifecycle rows remain unchanged.

### TDD Cycle Evidence

Strict TDD is active. This unit added no behavior and made no product-source edits; it preserves the historical generator RED/GREEN evidence and independently reruns the applicable PR1 acceptance/verification checks.

| Task/evidence | Test or command | Result |
| --- | --- | --- |
| PR1 RED/GREEN/TRIANGULATE corroboration | `python -m pytest backend/tests/integration/api/test_workspace_routes.py backend/tests/unit/application/test_workspace_service.py backend/tests/unit/application/test_auth_service.py backend/tests/integration/api/test_auth_routes.py backend/tests/integration/auth/test_auth_adapters.py backend/tests/integration/api/test_security_transport.py backend/tests/integration/api/test_ws_mutation_invalidation.py backend/tests/integration/persistence/test_auth_tables.py backend/tests/integration/persistence/test_source_tables.py -q` | **94 passed**, 1 pre-existing Starlette/httpx deprecation warning |
| Migration upgrade/downgrade and source-shape safety | `python -m pytest backend/tests/integration/persistence/test_auth_tables.py backend/tests/integration/persistence/test_source_tables.py -q -k 'migration or source'` | **8 passed**, 10 deselected |
| Backend lint | `python -m ruff check backend` | **Passed** |
| Contract drift | `python -m backend.scripts.check_contract_drift --cwd .` | **Failed, exit 1**. The current temporary regeneration reported `.openapi-generator/FILES` content differences and missing regenerated `mobile/.dart_tool/**`, `mobile/.openapi-generator/FILES`, mobile generated API/test files, and `mobile/pubspec.lock` entries. No drift success is claimed. |
| Generated serialization historical safety net | Prior PR1 remediation evidence, recorded above | **96 Dart tests passed** and all 22 model source/`.g.dart` pairs were present; this closeout did not rerun or modify generated output. |
| Protected-path audit | Read-only `git status --short --untracked-files=all` and exact candidate/path inventory | No path was changed by this closeout. The seven existing untracked `openspec/changes/web-professional-redesign/**` paths remain present and preserved; no `AGENTS.md`, official fixture, historical/archive, redesign, or unrelated path was edited. |

### Current candidate boundary evidence

- Generated/contract snapshot: **2,637** tracked additions/deletions plus **706** lines in 10 untracked generated files = **3,343 changed-line units** before any task/progress accounting. The generated snapshot alone exceeds the native **790-line** PR1 cap.
- PR1 candidate inventory estimate, counting current PR1 backend/migration/test/contract/generated paths and untracked file contents: **5,139 changed-line units** across 57 paths.
- The overage is generated snapshot churn already present in the frozen candidate; it cannot be honestly reduced by hand-editing, deleting required generated output, or borrowing capacity from another slice. This is a hard blocker under the supplied context.
- Existing generator-produced trailing-whitespace/line-ending warnings remain historical evidence; no normalization or generated-file hand edit was performed in this unit.

### Deviations and remaining work

- No product source, test source, generated output, canonical spec, fixture, redesign path, or unrelated dirty path was modified. Only this `apply-progress.md` evidence section was appended.
- PR1 `REFACTOR` cannot be marked complete because current drift is red. PR1 `Verify` cannot be marked complete because the exact current candidate is over the 790-line cap, despite focused tests, migration checks, and Ruff passing.
- Parent decision required: resolve the generated snapshot/PR1 slicing boundary and the current drift discrepancy before any PR1 checkbox transition. Do not start PR2.

### Remaining tasks (exact persisted unchecked rows)

```text
- [ ] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->
- [ ] RED — Add Testing Library tests for authenticated group list/create, zero-group state, one-group auto-selection, multi-group switching, stale/deep-link protection, query-key identity, cache clearing, and no protected render before session authentication; run affected Vitest files and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the additive hash parser/serializer, protected group picker/create flow, selected-group summary/empty workspace, account/group/selection query keys, and cache reset/refetch transitions using the generated client without adding a router or client authorization. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add session expiry/logout, forbidden selection, WebSocket outage/manual refresh, focus/accessible-name, Spanish empty/error/loading, and preserved `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo` behavior tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate only through an additive protected-shell seam after a changed-path audit proves no `web-professional-redesign` file is touched; preserve server-derived roles, CSRF flow, WebSocket signal-only handling, and existing anchors. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact path audit, and final <=780 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for `outing_id = null`, valid same-group association, cross-group rejection, malformed reference, archived-outing create/edit/delete rejection, default all-expense reads, general-only filtering, and atomic child-row validation; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Add nullable `expenses.outing_id`, composite same-group foreign-key protection, repository filters, schema serialization, and service validation while preserving integer cents, participant/contribution/beneficiary invariants, and existing general expenses as `NULL`. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Test PostgreSQL constraint enforcement, archived history readability, failed transaction/no invalidation, old client compatibility, official four-expense values, and migration survival of existing source rows. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate the contract through the pinned workflow, build generated Dart serialization only when frozen models require it, run drift, and update no generated output manually. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/migration tests, lint, contract drift, path audit, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add derived-service/API tests proving group scope includes every general and outing-linked expense exactly once, outing scope filters exact `outing_id`, general expenses never appear in outing totals, participants remain the authorized group set, sums equal zero, and transfer order is stable. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement optional outing scope in server-derived balance/settlement reads and REST schemas; keep all arithmetic, residual allocation, exact-zero checks, and formatting authority on the server/domain services. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add mixed-scope, empty-outing, archived-outing, cross-group, stale-cache, and official Samaipata regression cases with exact expected balances/transfers; assert no derived state is persisted. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Regenerate contract outputs from handwritten API changes and add scope-aware query-key definitions without client calculations or WebSocket payload changes. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full monetary tests, lint, contract drift, and final <=720 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner generation/status/revoke/regenerate, hash-only persistence, reusable consumption by existing sessions, prior-token invalidation, anonymous/invalid/duplicate joins, exact-one participant choice, same-group link/create, cross-group choice rejection, token non-disclosure, and atomic rollback; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement one current SHA-256-hashed 256-bit URL-safe token per group, owner-protected lifecycle endpoints, authenticated consume transaction, group-scoped account-participant link table, and explicit existing-participant-or-new-participant command with stable errors. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add lock/concurrency, CSRF/origin, replay/reusable-code, active-membership conflict, participant uniqueness, no-log/no-summary-secret, post-commit one-frame, and no-frame-on-failure tests; preserve account/participant identity separation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate OpenAPI/TypeScript/Dart outputs through the pinned workflow, keeping plaintext code only in generation response and never hand-editing generated trees. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/security/migration tests, lint, contract drift, secret-output audit, path audit, and final <=800 changed-line count; split before apply if forecast exceeds the cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner removal, member leave, ended-member denial across every group resource, participant-link inactivity, preserved participant/expense/outing history, rejoin eligibility, member forbidden removal, and final-owner protection. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement nullable `ended_at` active-membership semantics, owner-remove/member-leave operations, immutable owner safety, inactive link handling, active-membership listing, and one post-commit group invalidation per successful mutation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add concurrent exit/remove, stale sessions, cross-group account IDs, final-owner conflict, rejoin with a new explicit link choice, rollback/no-invalidation, and official fixture regression coverage. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Reconcile handwritten API schemas/routes, regenerate clients only where the frozen contract changes, run drift, and keep role derivation server-owned. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full regression tests, migration proof if applicable, lint, contract drift, path audit, and final <=740 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add behavior tests for outing/general expense separation, outing archived read-only state, server-provided scoped balances/settlement, participant detail, loading/empty/forbidden/error states, route/deep-link protection, and cache invalidation/refetch; audit redesign paths before running. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement additive laptop-first pages/states for outing detail/expenses, general expenses, group summary, participant detail, balances, and settlement using generated client data and shared integer-cent formatter; perform no client monetary arithmetic. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Cover mixed-scope no-double-counting, stale selected group/outing, archived history, WebSocket outage/manual refresh, membership changes, Spanish accessible names, keyboard focus, visible state cues, and preserved legacy anchors. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate through the protected shell without overwriting `web-professional-redesign`; remove only additive duplication, preserve query identity and REST authority, then rerun focused web tests. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact dirty-path audit, and final <=800 changed-line count; stop and split at a screen boundary if over cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner join-code display/regenerate/revoke/status secrecy, member/owner membership controls, leave/final-owner errors, forbidden actions, empty/error/recovery states, accessibility/laptop-first behavior, and official-flow preservation. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement group/membership settings, authenticated join-code consumption UI with explicit participant link/create choice, member removal/leave actions, Spanish copy, and safe protected recovery states using server-derived role/error responses. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add full regression cases for account selection, outing lifecycle, scoped expenses/derived results, invalidation-only WebSocket behavior, no public join/account creation, no token leakage, official Samaipata exact data/result, and all protected deep links. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Normalize source-mutating files before candidate freeze, preserve all redesign bytes/modes, remove no required acceptance coverage, and confirm the final web remains dependency-free with mobile UI out of scope. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, complete backend/web/contract/migration gates, manual laptop-first accessibility/browser flow, protected-path and generated-output audits, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

### Structured phase result

```yaml
schemaName: spec-driven
changeName: group-outing-workspaces
artifactStore: openspec
applyState: blocked
blockedReasons:
  - current contract drift check failed
  - frozen PR1 generated snapshot is 3343 changed-line units, above the 790-line cap
  - full PR1 candidate estimate is 5139 changed-line units
artifactPaths:
  tasks: openspec/changes/group-outing-workspaces/tasks.md
  applyProgress: openspec/changes/group-outing-workspaces/apply-progress.md
actionContext:
  mode: repo-local
  allowedEditRoots:
    - openspec/changes/group-outing-workspaces/tasks.md
    - openspec/changes/group-outing-workspaces/apply-progress.md
nextRecommended: parent-lifecycle
```

- Contract drift evidence: `python -m backend.scripts.check_contract_drift --cwd .` — completed, exit `1`; drift detected in 13 generated/OpenAPI snapshot files (full command output returned to parent).

## PR 1r — Bounded generated Dart correction

- Status consumed: `artifactStore=openspec`, `change=group-outing-workspaces`, repo-local root; parent-held native attempt token reused, with no acquire/settle/review/delivery operation by this executor. This is the first of two generated batches; overall drift closure is not claimed.
- Generator: inline Python exported the current contract to `TemporaryDirectory`, ran `_run_generator(..., "dart-dio", "serializationLibrary=json_serializable")`, applied `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, `_normalize_mobile_auth_test`, and `_build_mobile_parts`; web generation and full drift were not run.
- Selected copied paths only: `mobile/lib/generated/api/lib/src/api/auth_api.dart`, `mobile/lib/generated/api/lib/src/api/balances_api.dart`, `mobile/lib/generated/api/lib/src/api/expenses_api.dart`, `mobile/lib/generated/api/test/auth_api_test.dart`. Pre-copy numstat versus current files was `2/0` each, `8` changed-line units total, within the `500`-line objective.
- Result: copied generated bytes from the temporary output. Post-copy Git numstat was `35/28`, `10/17`, `60/114`, and `2/0` respectively. The status audit found no repository path changed beyond the selected paths and pre-existing dirty state. No task checkbox or other generated path was modified; no generated content was hand-edited.

## PR 1s — Bounded generated Dart correction

- Exported the current OpenAPI contract to a `TemporaryDirectory`, generated `dart-dio` with `serializationLibrary=json_serializable`, applied the three mobile normalizers, built serialization parts, and copied only `groups_api.dart`, `participants_api.dart`, and `settlement_api.dart` into `mobile/lib/generated/api`.
- Pre-copy regenerated delta: `2/0` for each file, **6 changed-line units**, below the native `500`-line cap. Final Git numstat: `186/38`, `71/142`, and `10/18` (**465** changed-line units). Audit passed; no other repository path changed beyond pre-existing dirty state. No tasks or other generated files were modified; full drift was not run.
- TDD Cycle Evidence: generated-only correction; no production or test source changed, so RED/GREEN/TRIANGULATE were not applicable; REFACTOR was the normalized generator build, exact three-file copy, and path audit.

## PR 1t — Bounded generated Dart manifest and test correction

- Exported the current OpenAPI contract to a `TemporaryDirectory`, generated `dart-dio` with `serializationLibrary=json_serializable`, applied the three mobile normalizers, built serialization parts, and copied only `.openapi-generator/FILES`, `group_create_request_test.dart`, `group_summary_response_test.dart`, `groups_api_test.dart`, and `session_identity_response_test.dart` into `mobile/lib/generated/api`.
- The selected batch measured below the native `300`-line cap: manifest `75` lines, new model tests `15` and `55` lines, and existing test files `45` and `31` lines; no other generated file was copied. The executor stalled after the bounded copy, so the parent completed this append-only evidence entry and will perform the final path audit and drift verification separately.
- No task checkbox, source/spec file, redesign path, or unselected generated output was modified; generated content was not hand-edited.

## PR 1 — Post-generation contract drift validation

- Command run exactly once from the repository root: `python -m backend.scripts.check_contract_drift --cwd .`.
- Result: **timed out after 120 seconds** while compiling Dart builders (`compiling builders/aot`); the timed-out runner did not provide an exit code.
- Remaining drift differences: **none emitted**; the validator timed out before reporting its contract comparison result. No task checkbox or generated/source/spec/task file was edited, and no attempt was acquired or settled.

## PR 1w — Dart builder diagnostic

- From `mobile/lib/generated/api`, ran `dart pub get --offline` followed by `dart run build_runner build --delete-conflicting-outputs --low-resources-mode`. Dependency resolution and builder AOT compilation completed; build_runner wrote 44 outputs in approximately 63 seconds. The two removed CLI flags were ignored by the installed build_runner version.
- This diagnostic demonstrates that the Dart builder is available when run in the existing generated package, but it is not a contract-drift verdict. It rewrote generator-owned serialization outputs, so the resulting bytes remain part of the generated candidate and require a later bounded audit. No handwritten source, tasks, specs, or redesign path was edited.
- Generated-package transient metadata must remain outside the candidate: remove `mobile/lib/generated/api/.dart_tool` and `mobile/lib/generated/api/pubspec.lock` before the next native settlement/verification.

## PR 1x — Contract drift after Dart cache warm-up

- Ran the exact validator once: `python -m backend.scripts.check_contract_drift --cwd .`. The Dart builder completed in about 59 seconds after cache warm-up, but the validator exited `1` with deterministic generated-client drift.
- Remaining differences: web `.openapi-generator/FILES`, eight web API files, and three web models; mobile `.openapi-generator/FILES`, `lib/openapi.dart`, seven mobile API/serialization files, three mobile models, and four mobile tests. No repository source was edited by the validator and no completion was inferred.
- Next correction must regenerate/copy generator-owned web and mobile outputs in bounded batches; transient Dart metadata remains excluded.

## PR 1y - Bounded generated TypeScript correction (blocked)

- Selected paths: `web/src/generated/api/.openapi-generator/FILES`, `apis/AuthApi.ts`, `apis/BalancesApi.ts`, `apis/ExpensesApi.ts`, `apis/GroupsApi.ts`, `apis/HealthApi.ts`, `apis/ParticipantsApi.ts`, `apis/SettlementApi.ts`, `models/GroupCreateRequest.ts`, `models/GroupSummaryResponse.ts`, `models/SessionIdentityResponse.ts`.
- The inline generator script exported OpenAPI to a `TemporaryDirectory`, ran `typescript-fetch` with `supportsES6=true`, and applied `_normalize_web_api_paths`.
- Pre-copy numstat measured **1,805 changed-line units** (722 additions + 1,083 deletions), exceeding the native 800-line cap. **Stopped before copying**; no selected web bytes changed, no task checkbox changed, and no non-selected path was touched. Full drift was not run.
- TDD Cycle Evidence: generator-only structural batch with no handwritten behavior seam; RED/GREEN/TRIANGULATE/REFACTOR were not applicable because the cap gate stopped before copying.
- Failed evidence remediation target for parent settlement: `sha256:ee8c28618760e3b3fbb551964551bd991547c9ebe3906c5453500d775f90594c`.

## PR 1z — Bounded generated TypeScript correction (web batch A)

- Exported the current OpenAPI document to a `TemporaryDirectory`, ran the existing `_run_generator` with `typescript-fetch` and `supportsES6=true`, applied `_normalize_web_api_paths`, and copied only `AuthApi.ts`, `BalancesApi.ts`, and `ExpensesApi.ts`.
- Pre-copy exact numstat: 60/94 web/src/generated/api/apis/AuthApi.ts, 26/36 web/src/generated/api/apis/BalancesApi.ts, 131/229 web/src/generated/api/apis/ExpensesApi.ts; total **576** changed-line units, within the **800** cap.
- Post-copy Git numstat:

```text
60 94 web/src/generated/api/apis/AuthApi.ts
26 36 web/src/generated/api/apis/BalancesApi.ts
131 229 web/src/generated/api/apis/ExpensesApi.ts
```

- Path audit passed: status delta `['web/src/generated/api/apis/AuthApi.ts', 'web/src/generated/api/apis/BalancesApi.ts', 'web/src/generated/api/apis/ExpensesApi.ts']`; content changes outside the allowed selected files and existing progress file: `['none']`. No tasks/specs, non-selected web files, mobile output, protected source, redesign path, or delivery operation was touched.

### TDD Cycle Evidence

| Phase | Evidence |
| --- | --- |
| RED | N/A — generator-only structural batch with no handwritten behavior seam. |
| GREEN | Temporary OpenAPI export, pinned TypeScript generation, and `_normalize_web_api_paths` completed. |
| TRIANGULATE | Exact selected-file diff measured at **576** changed-line units; byte and protected-path audits passed. |
| REFACTOR | Only the three selected generated files were copied; no generated content was hand-edited. Full drift and task checkbox updates remain deferred to the parent. |

## PR 1aa — Bounded generated TypeScript correction (web batch B)

- Exported the current OpenAPI document to a `TemporaryDirectory`, ran the existing `_run_generator` with `typescript-fetch` and `supportsES6=true`, applied `_normalize_web_api_paths`, and copied only `GroupsApi.ts`, `HealthApi.ts`, and `ParticipantsApi.ts`.
- Pre-copy exact numstat:

  - `85/141` `web/src/generated/api/apis/GroupsApi.ts`
  - `24/24` `web/src/generated/api/apis/HealthApi.ts`
  - `163/285` `web/src/generated/api/apis/ParticipantsApi.ts`
- Pre-copy total: **722** changed-line units; within the **800** cap.
- Post-copy exact generated-byte numstat:

  - `0/0` `web/src/generated/api/apis/GroupsApi.ts`
  - `0/0` `web/src/generated/api/apis/HealthApi.ts`
  - `0/0` `web/src/generated/api/apis/ParticipantsApi.ts`
- Path audit: status delta before progress append was added/changed=[b' M web/src/generated/api/apis/HealthApi.ts', b' M web/src/generated/api/apis/ParticipantsApi.ts'], removed=[]; only the three selected generated paths were copied, and each destination matched the temporary generated bytes exactly.
- No task checkbox, spec, source, redesign, mobile, non-selected generated file, full drift, commit, push, reset, clean, or second attempt operation was run.
  - TDD Cycle Evidence: generator-only structural batch; RED/GREEN/TRIANGULATE were not applicable; REFACTOR was the normalized generator output, exact three-file copy, byte check, and path audit.

## PR 1ab - Bounded generated TypeScript correction (web batch C)

- Structured status consumed: `artifactStore=openspec`, `change=group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`; parent-owned runtime authority was reused, with no second acquire/settle/review/delivery operation. No action-context warning. Produced batch status: success for bounded PR 1ab; overall change remains partial with persisted tasks at 15/60 complete and 45 remaining.
- Exported current OpenAPI to a `TemporaryDirectory`, ran existing `_run_generator` with `typescript-fetch` and `supportsES6=true`, applied `_normalize_web_api_paths`, and measured only the selected paths before copying.
- Pre-copy exact numstat (current repository vs normalized temporary generation):

```text
26 37 web/src/generated/api/apis/SettlementApi.ts
30 35 web/src/generated/api/models/GroupCreateRequest.ts
106 122 web/src/generated/api/models/GroupSummaryResponse.ts
70 80 web/src/generated/api/models/SessionIdentityResponse.ts
0 0 web/src/generated/api/models/index.ts
1 0 web/src/generated/api/.openapi-generator/FILES
TOTAL 507 changed-line units
```

- The set was within the 800-line cap. Copied exactly these six generated paths, preserving temporary generated bytes:
  - `web/src/generated/api/apis/SettlementApi.ts`
  - `web/src/generated/api/models/GroupCreateRequest.ts`
  - `web/src/generated/api/models/GroupSummaryResponse.ts`
  - `web/src/generated/api/models/SessionIdentityResponse.ts`
  - `web/src/generated/api/models/index.ts`
  - `web/src/generated/api/.openapi-generator/FILES`
- Post-copy exact numstat (HEAD/current repository):

```text
26 37 web/src/generated/api/apis/SettlementApi.ts
66 0 web/src/generated/api/models/GroupCreateRequest.ts
154 0 web/src/generated/api/models/GroupSummaryResponse.ts
3 3 web/src/generated/api/models/SessionIdentityResponse.ts
2 0 web/src/generated/api/models/index.ts
2 0 web/src/generated/api/.openapi-generator/FILES
TOTAL 293 changed-line units
```

- Path audit: copied-byte equality passed; no non-selected path was copied or introduced by this batch. No task checkbox, spec, source, mobile output, redesign path, full drift, commit, push, reset, clean, or second attempt operation was run. The broader generated-client task remains unchecked.
- Check-only note: bounded `git diff --check` reports generator-preserved trailing spaces in `SettlementApi.ts` lines 8 and 33; generated bytes were preserved and not hand-edited.

### TDD Cycle Evidence

| Phase | Evidence |
| --- | --- |
| RED | N/A - generator-only structural batch with no handwritten behavior seam. |
| GREEN | Temporary OpenAPI export, pinned TypeScript generation, and `_normalize_web_api_paths` completed. |
| TRIANGULATE | Exact selected-file delta measured at **507** changed-line units; copied-byte and path audits passed. |
| REFACTOR | Exact six-file normalized generated copy; no focused test runner was applicable or run. |

- Workload boundary: `PR 1ab`, `exception-ok`, `stacked-to-main`; parent owns settlement and lifecycle actions.

## PR 1ac — Exact contract drift gate

- Command run exactly once from repository root: `python -m backend.scripts.check_contract_drift --cwd .` — **exit code 1; DRIFT DETECTED**.
- Complete drift diagnostics: `mobile/.openapi-generator/FILES`, `mobile/lib/openapi.dart`, `mobile/lib/src/api/{auth_api,balances_api,expenses_api,groups_api,participants_api,settlement_api}.dart`, `mobile/lib/src/deserialize.dart`, `mobile/lib/src/model/{group_create_request,group_summary_response,session_identity_response}.dart`, and `mobile/test/{group_create_request_test,group_summary_response_test,groups_api_test,session_identity_response_test}.dart` each reported **content differs**.
- The validator's temporary output was under `C:\Users\HP\AppData\Local\Temp\cuentas-claras-drift-482o65mc`; no repository/generated/redesign file was modified by this gate. Evidence payload SHA-256: `879abc2c05c49d07c70cd4c06c560840cff4c3b57bce1cc0222d8bc5ad756e10`.

## PR 1ad — Bounded mobile generated batch A

- Structured status consumed: `artifactStore=openspec`, `change=group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`; the repository root was the authoritative allowed edit root. Parent owns token `sha256:4c95344665603afdb8aa6d57da230551c404b6392c6602e1c09f1adcff61d8b0`; no acquire/settle or lifecycle gate was run.
- In one `TemporaryDirectory`, exported the current contract with `export_contract`, ran `_run_generator(..., "dart-dio", "serializationLibrary=json_serializable")`, then `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, `_normalize_mobile_auth_test`, and `_build_mobile_parts`. Temporary output was removed by `TemporaryDirectory`.
- Exact pre-copy normalized diff (additions/deletions/changed lines): `auth_api.dart 35/28/63`, `balances_api.dart 10/17/27`, `expenses_api.dart 60/114/174`; total **264** changed lines, below the 800-line stop threshold.
- Copied only `auth_api.dart`, `balances_api.dart`, and `expenses_api.dart` under `mobile/lib/generated/api/lib/src/api/`. All three passed byte equality; the path audit found no unexpected new status paths. No task checkbox was changed; the broader generated-client task remains unchecked.
- Remaining exact unchecked implementation rows relevant to this slice:
  - `- [ ] REFACTOR — Export \`contracts/openapi.json\`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->`
  - `- [ ] Verify separately with native attempt authority, \`python -m pytest backend/tests -q\` where applicable, \`python -m ruff check backend\`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count before stacking PR 2. <!-- sdd-owner: implementation -->`

### TDD Cycle Evidence

| Phase | Evidence |
| --- | --- |
| RED | Pre-copy generated parity check failed as expected: the normalized selected-file diff measured **264** changed lines. |
| GREEN | Exact three-file copy completed and all three destination bytes matched the normalized temporary output. |
| TRIANGULATE | Path audit found no unexpected new status paths; non-selected generated paths remained untouched. |
| REFACTOR | Existing generator normalizers/build helper produced the copied bytes; no hand edits or alternate workflow used. |

## PR 1ae — Bounded mobile generated batch B

- Structured status consumed: `artifactStore=openspec`, `change=group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`; parent owns token `sha256:de85cb8597dc159b6e90ce951bd399eba373cd7e4420bdb98a95467c37aadf46`, so no acquire/settle or lifecycle gate was run. Workload boundary: `stacked-to-main`, native 800-line cap; no task checkbox was changed. Action-context warning: delegated edit surfaces were narrower than the native repository root.
- In one `TemporaryDirectory`, ran `export_contract`, `_run_generator(..., "dart-dio", "serializationLibrary=json_serializable")`, `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, `_normalize_mobile_auth_test`, and `_build_mobile_parts`; temporary output was cleaned by `TemporaryDirectory`.
- Exact pre-copy normalized diff: `groups_api.dart 53/64/117`, `participants_api.dart 71/142/213`, `settlement_api.dart 10/18/28`; total **358** changed-line units, below 800. Copied exactly those three API paths; all destination bytes matched the temporary generated bytes, and the path audit found no unexpected repository path changes.
- TDD evidence: generator-only structural batch; RED/GREEN/TRIANGULATE were not applicable. REFACTOR was the normalized generator build, exact three-file copy, byte verification, and path audit. No models, tests, manifest, facade, deserialize, README/docs, pubspec, transient metadata, tasks/spec/source, redesign path, full drift, commit, push, reset, clean, or alternate attempt operation was run.

## PR 1af — Bounded mobile generated batch C

- Structured status consumed: `artifactStore=openspec`, `change=group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`; parent owns token `sha256:e18e94f5a87f8c30ca578a7c73a4cf61e3980727e424c56a5c8ad1246d17651e`, so no acquire/settle or lifecycle gate was run. Workload boundary: `exception-ok`, `stacked-to-main`, native 800-line cap; delegated edit surfaces were narrower than the native repository root.
- In one `TemporaryDirectory`, ran `export_contract`, pinned `_run_generator(..., "dart-dio", "serializationLibrary=json_serializable")`, `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, `_normalize_mobile_auth_test`, and `_build_mobile_parts`; temporary output was cleaned automatically.
- Exact pre-copy normalized diff: `openapi.dart 2/0/2`, `deserialize.dart 87/128/215`, `group_create_request.dart 26/10/36`, `group_summary_response.dart 164/76/240`, `session_identity_response.dart 73/32/105`; total **598** changed-line units, below 800. Copied exactly the five requested paths; byte equality and non-selected path audit passed.
- TDD Cycle Evidence: generator-only structural batch; RED/GREEN/TRIANGULATE were not applicable. REFACTOR was the normalized generator build, bounded copy, byte verification, and path audit. No task checkbox changed; the broader generated-client and verification rows remain unchecked, with the exact cumulative unchecked inventory recorded above. Full drift and delivery gates remain deferred to the parent.

## PR 1ag — Bounded mobile generated batch D

- Structured status consumed: `artifactStore=openspec`, `change=group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`; delegated surfaces were narrower than the repository-root allowed edit root. Parent owns token `sha256:235edc177a8d8176e65c4b44fa82274e40f647d3249b5cab4996ddeb0f953f40`; no acquire/settle, full drift, or lifecycle gate was run. Workload boundary: `exception-ok`, `stacked-to-main`, native 800-line cap.
- Exported the current contract to one `TemporaryDirectory`, ran pinned `dart-dio` with `serializationLibrary=json_serializable`, applied `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, `_normalize_mobile_auth_test`, and `_build_mobile_parts`; temporary output was cleaned by `TemporaryDirectory`.
- Exact pre-copy normalized diff: `.openapi-generator/FILES 32/0/32`, `group_create_request_test.dart 1/0/1`, `group_summary_response_test.dart 1/0/1`, `groups_api_test.dart 2/0/2`, `session_identity_response_test.dart 2/2/4`; total **40** changed-line units, below 800. Copied exactly the five requested paths and no other mobile path.
- Byte verification passed for all five selected files: SHA-256 `c4d8e025b60a85fd7db76bf08b57a944851f5ef98a32ac74bb27219e3d394c9b`, `bfede6225d6df23cde59c715a19d26bbf81afe149f1520d13a0e773143c3cb9a`, `488c0ebeff2554f1afc912b57857376d3ff5870997d965c114c2a68f2ab4662c`, `cc5d511832af1c509381ab3635ef230b95d50b3d1c81d08ecd2455504b297925`, `9e8ab97468a1521bb745f2632d3abd00b25195734d9c09da3256939c148bdf6f`. Path audit passed: no new repository status paths beyond the five selected paths. No task checkbox, source/spec, redesign, unselected generated output, commit, push, reset, clean, or alternate attempt operation was run.

### TDD Cycle Evidence

| Phase | Evidence |
| --- | --- |
| RED | N/A — generator-only structural batch with no handwritten behavior seam. |
| GREEN | Temporary OpenAPI export, pinned Dart generation, required mobile normalizers, and serialization build completed. |
| TRIANGULATE | Exact selected-file normalized diff measured **40** changed-line units; byte and path audits passed. |
| REFACTOR | Exact five-file generated copy completed without hand edits; broader REFACTOR and Verify task rows remain unchecked and full drift remains parent-deferred. |

## PR 1ah — Exact contract drift validation

- Command run exactly once from repository root: `python -m backend.scripts.check_contract_drift --cwd .`.
- Exit code: `0`; result: **Contract and generated clients are drift-free.**
- Exact terminal output: `Contract and generated clients are drift-free.` Generator and Dart build logs were emitted before this final line; no repository file was modified by the validator.
- Evidence hash (SHA-256 of the exact terminal result line plus newline): `sha256:7968549b41f8f745b0e1742ac45405c1b73341c09ace891ec5cae4ca8c95f9c8`.

## PR 1 verification actions — blocked by stale migration harness and line boundary

- Structured status consumed: `schemaName=gentle-ai.sdd-status`, `changeName=group-outing-workspaces`, `artifactStore=openspec`, `applyState=ready`, `taskProgress=15/60 complete (45 pending)`, `actionContext.mode=repo-local`, workspace root and native allowed root `D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1`; the parent-owned token `sha256:b5765d1ff100a8e10245f21ca693b521ceb4d0d9cda2b1799b886c0a2b5a2694` was not acquired, settled, or otherwise mutated. The delegated write surface remained this file only.
- Exact command 1, run once: `python -m pytest backend/tests -q` — **exit 1**, **254 passed, 1 failed, 1 warning** in `8.31s`. Exact failure: `backend/tests/test_alembic_harness.py::test_alembic_harness_includes_source_revision`; the assertion expected `[0001_auth.py, 0002_source.py]` but found an additional `0003_workspace.py`. This known stale test was not patched.
- Exact command 2, run once: `python -m ruff check backend` — **exit 0**, `All checks passed!`.
- Exact command 3, run once: `python -m pytest backend/tests/integration/persistence/test_auth_tables.py backend/tests/integration/persistence/test_source_tables.py backend/tests/test_alembic_harness.py -q` — **exit 1**, **18 passed, 1 failed** in `1.31s`; the same stale `0003_workspace.py` harness assertion failed. The direct `0003` migration upgrade/downgrade/source-shape tests passed within the 18 passing tests.
- Contract drift was **not rerun** by this actor, per instruction; the settled PR1ah evidence above remains the parent-provided exit-0 result.
- Read-only pre-entry audit: `git diff --numstat`/`git diff HEAD --numstat` had no staged entries and totaled **+2,903/-1,503 = 4,406 tracked units**. All untracked files totaled **6,411 lines**, so all current dirty/untracked units were **10,817** before this evidence append.
- Objective PR1 backend + contract + generated-client scope (`backend/**`, `contracts/openapi.json`, `web/src/generated/api/**`, `mobile/lib/generated/api/**`) measured **+2,065/-1,317 = 3,382 tracked units**, plus **1,720 untracked generated/backend lines = 5,102 units**. SDD prose, redesign paths, unrelated pre-existing web handwritten/test paths, and root `.markdownlintignore` were excluded. This is **4,312 units over** the PR1 `<=790` boundary; no `<=790` claim is made.
- Dirty/untracked path audit found 104 paths. The seven pre-existing paths under `openspec/changes/web-professional-redesign/**` were present and unchanged by this actor: `apply-progress.md`, `design.md`, `exploration.md`, `preproposal.md`, `proposal.md`, `specs/web-presentation/spec.md`, and `tasks.md`. No generated path was hand-edited or written by this actor; only the three requested commands and read-only audits ran before this append.
- Strict TDD is active. `apply-progress.md` contains the TDD evidence tables; the four changed PR1 backend test files exist and passed in the current suite except for the unrelated stale harness test. Assertion audit found no tautologies, ghost loops, smoke-only tests, type-only-only assertions, or implementation-detail CSS assertions. The exact persisted unchecked inventory remains in `tasks.md`: 42 implementation rows and 3 parent rows; the two current PR1 blockers remain the unchecked `REFACTOR` generated-contract row and `Verify` row. No checkbox changed.
- Review workload remains `Chained PRs recommended: Yes`, `exception-ok`, `stacked-to-main`; this actor performed only the assigned PR1 verification boundary and did not claim the over-budget candidate as a clean slice. Archive is not ready. No source, test, generated output, task, spec, or redesign file was modified by this actor; only this evidence entry was appended.

## PR 1 focused correction — Alembic harness

- Command run exactly once from repository root: `python -m pytest backend/tests/test_alembic_harness.py -q` — **exit code 0; 1 passed** (`1 passed in 0.03s`). The expected revision list including `0003_workspace.py` is now green. Only this progress entry was appended; `web-professional-redesign` was preserved.

## PR 1 verification rerun — backend gates after harness correction

- Parent-owned token `sha256:f0fed336fef9d8bc7c0f646247d0bc71a2417185f0bc2e859762093c457036fe` was not acquired, settled, reset, committed, pushed, cleaned, or otherwise mutated; contract drift was not rerun.
- `python -m pytest backend/tests -q` — **exit 0; 255 passed, 1 warning** in `7.67s`.
- `python -m ruff check backend` — **exit 0; All checks passed!**
- `python -m pytest backend/tests/integration/persistence/test_auth_tables.py backend/tests/integration/persistence/test_source_tables.py backend/tests/test_alembic_harness.py -q` — **exit 0; 19 passed** in `1.05s`.
- Read-only pre-entry audit: **105 paths** (`71` tracked, `34` untracked); tracked `git diff --numstat` totaled `+2,904/-1,503 = 4,407` units, and untracked files totaled **6,429 lines**.
- The objectively identifiable PR1 backend + contract + generated-client boundary is **5,103** current units (`+2,066/-1,317` tracked plus `1,720` untracked lines). Excluding the one-line stale-harness correction preserves the prior **5,102** measurement; both exceed the `<=790` requirement, so no pass is claimed.
- All seven existing `openspec/changes/web-professional-redesign/**` paths remained present and unchanged by this rerun. No generated output was hand-edited by this actor; only the requested gates, read-only audits, and this append-only evidence entry were performed.
- Strict-TDD evidence remains present in this file; the backend gates are green, but `tasks.md` still has `42` unchecked implementation rows and `3` unchecked parent rows. PR1 `REFACTOR` and `Verify` remain incomplete, and archive is not ready.
- Review workload remains `Chained PRs recommended: Yes`, `exception-ok`, `stacked-to-main`; the measured PR1 candidate is over budget and must not be reported as a clean slice.

## PR1 closure decision — per-slice native cap

- User-approved interpretation: every bounded PR1 slice must stay at or below `<=790` preferred / `<=800` hard cap; the aggregate across chained generated slices may exceed 790 and is not itself a PR1 blocker.
- Task wording/checkbox update: the final PR1 `REFACTOR` and `Verify` rows were reconciled to this per-slice interpretation and marked complete, bringing progress to **17/60**; **40 implementation rows** and **3 parent-owned lifecycle rows** remain.
- Green gates: full backend pytest **255 passed, 1 warning**; Ruff passed; migration-focused subset **19 passed**; exact contract drift rerun exited `0` with `Contract and generated clients are drift-free`.
- The **5,103-unit** value is the aggregate chained candidate, not a bounded-slice measurement. All seven existing `openspec/changes/web-professional-redesign/**` paths were preserved unchanged; no commits, resets, cleans, pushes, or native-attempt acquire/settle operations were performed.
- Remaining next action: apply **PR2**.

  ## PR 2 — Workspace web foundation additive seam

  ### Status consumed and produced

  - Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, task progress `17/60`; parent-owned PR2 bounded attempt is active with an 800-line hard cap.
  - Action context: `mode=repo-local`; workspace root is `D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1`; the delegated edit surfaces were the explicit PR2 additive web paths plus the two OpenSpec evidence files. Existing redesign and generated-client bytes were treated as preserved inputs.
  - Produced phase result: **partial**. PR2 RED/GREEN/TRIANGULATE/REFACTOR behavior is implemented and the four corresponding implementation rows are checked (`21/60`); the PR2 Verify row remains unchecked because the repository-wide typecheck/build are blocked by pre-existing protected `App.tsx` nullability errors.

  ### TDD Cycle Evidence

    | Phase | Focused evidence | Result |
    | --- | --- | --- |
    | RED | `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` before implementation | **Exit 1**: the intended additive modules were absent and Vitest could not resolve the workspace-shell/navigation/query-key/client imports. |
    | GREEN | Same focused command after the smallest implementation | **7 passed**: authenticated list/create, zero groups, stale deep link, selection switching, cache clearing, logout, and protected gating. |
    | TRIANGULATE | Added expiry, forbidden selection, manual refresh/outage, Spanish states, accessible 44px control, and legacy-anchor assertions; `npm --prefix web run test` | **85 passed across 12 files**. |
    | REFACTOR | Additive seam/path audit and generated-client readback | Passed without touching `App.tsx`, `ui.tsx`, CSS/theme, existing redesign features, generated API files, or `openspec/changes/web-professional-redesign/**`. |

  ### Implementation and changed paths

  - `web/src/core/workspace-navigation.ts` — pure canonical hash parser/serializer plus legacy aliases.
  - `web/src/core/workspace-query-keys.ts` — account/group/selection factories and group-switch/cache-clearing helpers; account keys are distinct from selected-group keys.
  - `web/src/features/workspace/api.ts`, `index.ts` — generated `GroupsApi` list/create seam with existing CSRF/credential transport.
  - `web/src/app/workspace-shell.tsx` — authenticated group list/create, zero-group form, one-group auto-selection, multi-group picker/switch, stale-ID safe state, server-derived summary/role/counts, refresh/logout, Spanish states, focusable legacy anchors, and a protected additive shell seam. It is intentionally not imported into protected dirty `App.tsx`.
  - `web/tests/app/workspace-shell.test.tsx` — focused Testing Library/Vitest RED-to-triangulation coverage.
  - `openspec/changes/group-outing-workspaces/tasks.md` — only the four completed PR2 implementation rows changed from `[ ]` to `[x]`; PR2 Verify and all later/parent rows are preserved.
  - `openspec/changes/group-outing-workspaces/apply-progress.md` — this cumulative evidence section.

  ### Exact commands and outcomes

  - RED focused Vitest: **failed as intended**, unresolved additive imports before implementation.
  - GREEN focused Vitest: **7 passed**.
  - Full web suite: `npm --prefix web run test` — **12 files, 85 tests passed**; one existing React `act(...)` warning is emitted by the deferred-auth test.
  - `npm --prefix web run typecheck` — **exit 2**, pre-existing protected `web/src/app/App.tsx` errors at lines 81, 168, 176, 182, 195, and 198 because generated nullable `activeGroupId` is passed to the legacy shell. No protected file was edited to hide this blocker.
  - `npm --prefix web run build` — **exit 2** at the same pre-existing `App.tsx` type errors; Vite build was not reached.
  - Targeted additive TypeScript check (`npx tsc --noEmit ...` over the new shell/navigation/query/client/test plus `tests/setup.ts`): **passed**; it excludes only the protected legacy `App.tsx` blocker.
  - `git diff --check` for the new additive paths: **clean**. Read-only owner-marker audit: **60 valid terminal markers, 0 malformed markers**.

  ### Changed-line and boundary evidence

  - New implementation/test paths contain exactly **524 added lines**: shell 194, navigation 91, query keys 43, workspace API 18, workspace index 1, focused test 177.
  - Persisted task transitions are four checkbox replacements: **8 changed lines** (`4` deletions + `4` additions). The cumulative progress section is counted after append below.
  - PR2 authored candidate is exactly **602 changed lines** (524 additive source/test lines + 8 task-checkbox transition lines + 70 appended evidence lines), below the 800-line hard cap; no split was required.
  - Rollback boundary: revert only these additive workspace modules/test and the four PR2 checkbox transitions plus this evidence section. Preserve all backend/contract/generated/mobile bytes, existing shell/redesign bytes, and unrelated dirty/untracked inventory.

  ### Remaining work and risks

  - Exact remaining PR2 implementation row: `- [ ] Verify separately with native attempt authority, \`npm --prefix web run test\`, \`npm --prefix web run typecheck\`, \`npm --prefix web run build\`, exact path audit, and final <=780 changed-line count. <!-- sdd-owner: implementation -->`
  - The cumulative exact unchecked inventory for PR3–PR9 and the three parent-owned lifecycle rows remains in the preceding progress record and unchanged in `tasks.md`; no later task is claimed.
  - Verification risk: resolving the typecheck/build blocker would require editing protected `web/src/app/App.tsx` or changing generated contract nullability, both forbidden by this delegated boundary. WebSocket connection wiring remains parent-shell-owned; this seam consumes the existing signal/cache contract and exposes manual refresh without changing payloads.
  - Parent remains responsible for native attempt settlement, bounded review/refutation/correction/validation actors, delivery gates, and final lifecycle status.

  ### Structured phase result

    ```yaml
    schemaName: gentle-ai.sdd-status
    changeName: group-outing-workspaces
    artifactStore: openspec
    applyState: partial
    taskProgress: {total: 60, complete: 21, remaining: 39}
    dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
    actionContext:
      mode: repo-local
      workspaceRoot: D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1
      allowedEditRoots: [web additive PR2 surfaces, openspec/changes/group-outing-workspaces/tasks.md, openspec/changes/group-outing-workspaces/apply-progress.md]
      warnings:
        - "Protected redesign and generated API paths were preserved."
        - "Typecheck/build remain blocked by pre-existing protected App.tsx nullability errors."
        - "Parent-owned native attempt and lifecycle gates were not acquired or settled."
    nextRecommended: parent-lifecycle
    ```

## PR 2 remediation — protected shell nullable active-group seam

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, task progress `21/60`, and authoritative `actionContext.mode=repo-local` with workspace root `D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1`.
- Workload boundary: PR2 stacked-to-main slice, `exception-ok` delivery path already selected by the parent, hard native cap `800` changed-line units. This remediation was limited to the parent-authorized four paths below.
- Parent-owned bounded native attempt was already acquired by the parent. This executor did not acquire, settle, reset, commit, push, clean, start review, create receipts, or run delivery gates.
- Produced phase result: **success for the PR2 remediation**. The persisted PR2 Verify row is now checked (`22/60`); PR3–PR9 and parent-owned lifecycle work remain deferred. Native verify status still depends on the parent-owned verification evidence envelope and lifecycle settlement.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR2 protected-shell nullable active-group remediation | `web/tests/app.test.tsx` | React/Testing Library integration | ✅ `npm --prefix web run test -- --run tests/app.test.tsx` — 6 passed before edits | ✅ Added the zero-group nullable-session assertion first; the same focused command produced 7 tests with 1 expected failure because `App` still rendered `protected-shell` | ✅ After the smallest `App.tsx` seam and final async assertion, the focused command passed: 7 tests | ✅ Existing app suite and exact web gates passed; active-group shell and legacy anchors remain green | ✅ Hook order preserved; no-group WebSocket guard and string narrowing were kept minimal; `git diff --check` passed |

### Implementation and changed paths

- `web/src/app/App.tsx` — imported `WorkspaceShell`; kept hooks unconditional; skipped the group WebSocket when `activeGroupId` is absent; returned the additive shell for authenticated nullable-group sessions; narrowed `activeGroupId` before all redesigned financial panels.
- `web/tests/app.test.tsx` — added the authenticated zero-group/nullable-active-group regression assertion with an empty account-group response; it requires the additive workspace shell and forbids `protected-shell`.
- `openspec/changes/group-outing-workspaces/tasks.md` — checked only the PR2 Verify implementation row after all required evidence passed; all parent-owned rows were preserved byte-for-byte.
- `openspec/changes/group-outing-workspaces/apply-progress.md` — appended this remediation evidence only; prior cumulative progress was preserved.

### Exact commands and outcomes

- Safety-net focused app test: `npm --prefix web run test -- --run tests/app.test.tsx` — **6 passed**.
- RED focused app test after the regression assertion and before `App.tsx`: same command — **7 tests, 1 failed as expected** because the protected shell rendered instead of workspace selection.
- GREEN focused app test: `npm --prefix web run test -- --run tests/app.test.tsx` — **7 passed**.
- TRIANGULATE full app/web suite: `npm --prefix web run test` — **12 files, 86 tests passed**; the existing deferred-auth React `act(...)` warning remains non-failing.
- Exact web gate: `npm --prefix web run typecheck` — **passed**.
- Exact web gate: `npm --prefix web run build` — **passed**; TypeScript and Vite production build completed.
- Path/whitespace audit: `git diff --check -- web/src/app/App.tsx web/tests/app.test.tsx openspec/changes/group-outing-workspaces/tasks.md openspec/changes/group-outing-workspaces/apply-progress.md` — **passed**. Read-only dirty-path audit confirmed the existing backend, generated, mobile, redesign, and unrelated paths were preserved.

### Changed-line and boundary evidence

- Authored remediation delta: `web/src/app/App.tsx` **13 units** (7 additions, 6 deletions); `web/tests/app.test.tsx` **32 additions**; the persisted task checkbox **2 units** (one deletion plus one addition).
- The appended remediation evidence is cumulative and remains within the parent/native 800-line cap; no split was required. Exact authored remediation total: **157 changed-line units** (`13` App seam + `32` regression-test additions + `2` task-checkbox transition + `110` remediation-evidence lines), all within the four allowed paths.
- Rollback boundary: revert only the nullable-session seam, its focused regression test, the single PR2 Verify checkbox transition, and this remediation section. Do not reset, clean, reformat, or remove additive workspace files, redesign bytes, generated outputs, or unrelated dirty paths.

### Deviations, risks, and ownership

- No design deviation: selection remains owned by `WorkspaceShell`; no client-side authorization or server session mutation was added. Active-group sessions continue through the existing redesigned financial shell and WebSocket behavior.
- No protected redesign path, `web/src/components/ui.tsx`, CSS/theme/index CSS, financial feature file, generated API file, or `openspec/changes/web-professional-redesign/**` path was edited by this remediation.
- The parent still owns native attempt settlement, verification-envelope reconciliation, bounded review/refutation/correction/validation actors, and all later delivery gates. This section does not claim PR3–PR9 or final delivery.

### Remaining tasks (exact persisted unchecked rows)

```text
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for `outing_id = null`, valid same-group association, cross-group rejection, malformed reference, archived-outing create/edit/delete rejection, default all-expense reads, general-only filtering, and atomic child-row validation; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Add nullable `expenses.outing_id`, composite same-group foreign-key protection, repository filters, schema serialization, and service validation while preserving integer cents, participant/contribution/beneficiary invariants, and existing general expenses as `NULL`. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Test PostgreSQL constraint enforcement, archived history readability, failed transaction/no invalidation, old client compatibility, official four-expense values, and migration survival of existing source rows. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate the contract through the pinned workflow, build generated Dart serialization only when frozen models require it, run drift, and update no generated output manually. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/migration tests, lint, contract drift, path audit, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add derived-service/API tests proving group scope includes every general and outing-linked expense exactly once, outing scope filters exact `outing_id`, general expenses never appear in outing totals, participants remain the authorized group set, sums equal zero, and transfer order is stable. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement optional outing scope in server-derived balance/settlement reads and REST schemas; keep all arithmetic, residual allocation, exact-zero checks, and formatting authority on the server/domain services. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add mixed-scope, empty-outing, archived-outing, cross-group, stale-cache, and official Samaipata regression cases with exact expected balances/transfers; assert no derived state is persisted. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Regenerate contract outputs from handwritten API changes and add scope-aware query-key definitions without client calculations or WebSocket payload changes. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full monetary tests, lint, contract drift, and final <=720 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner generation/status/revoke/regenerate, hash-only persistence, reusable consumption by existing sessions, prior-token invalidation, anonymous/invalid/duplicate joins, exact-one participant choice, same-group link/create, cross-group choice rejection, token non-disclosure, and atomic rollback; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement one current SHA-256-hashed 256-bit URL-safe token per group, owner-protected lifecycle endpoints, authenticated consume transaction, group-scoped account-participant link table, and explicit existing-participant-or-new-participant command with stable errors. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add lock/concurrency, CSRF/origin, replay/reusable-code, active-membership conflict, participant uniqueness, no-log/no-summary-secret, post-commit one-frame, and no-frame-on-failure tests; preserve account/participant identity separation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate OpenAPI/TypeScript/Dart outputs through the pinned workflow, keeping plaintext code only in generation response and never hand-editing generated trees. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/security/migration tests, lint, contract drift, secret-output audit, path audit, and final <=800 changed-line count; split before apply if forecast exceeds the cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner removal, member leave, ended-member denial across every group resource, participant-link inactivity, preserved participant/expense/outing history, rejoin eligibility, member forbidden removal, and final-owner protection. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement nullable `ended_at` active-membership semantics, owner-remove/member-leave operations, immutable owner safety, inactive link handling, active-membership listing, and one post-commit group invalidation per successful mutation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add concurrent exit/remove, stale sessions, cross-group account IDs, final-owner conflict, rejoin with a new explicit link choice, rollback/no-invalidation, and official fixture regression coverage. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Reconcile handwritten API schemas/routes, regenerate clients only where the frozen contract changes, run drift, and keep role derivation server-owned. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full regression tests, migration proof if applicable, lint, contract drift, and final <=740 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add behavior tests for outing/general expense separation, outing archived read-only state, server-provided scoped balances/settlement, participant detail, loading/empty/forbidden/error states, route/deep-link protection, and cache invalidation/refetch; audit redesign paths before running. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement additive laptop-first pages/states for outing detail/expenses, general expenses, group summary, participant detail, balances, and settlement using generated client data and shared integer-cent formatter; perform no client monetary arithmetic. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Cover mixed-scope no-double-counting, stale selected group/outing, archived history, WebSocket outage/manual refresh, membership changes, Spanish accessible names, keyboard focus, visible state cues, and preserved legacy anchors. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate through the protected shell without overwriting `web-professional-redesign`; remove only additive duplication, preserve query identity and REST authority, then rerun focused web tests. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact dirty-path audit, and final <=800 changed-line count; stop and split at a screen boundary if over cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner join-code display/regenerate/revoke/status secrecy, member/owner membership controls, leave/final-owner errors, forbidden actions, empty/error/recovery states, accessibility/laptop-first behavior, and official-flow preservation. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement group/membership settings, authenticated join-code consumption UI with explicit participant link/create choice, member removal/leave actions, Spanish copy, and safe protected recovery states using server-derived role/error responses. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add full regression cases for account selection, outing lifecycle, scoped expenses/derived results, invalidation-only WebSocket behavior, no public join/account creation, no token leakage, official Samaipata exact data/result, and all protected deep links. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Normalize source-mutating files before candidate freeze, preserve all redesign bytes/modes, remove no required acceptance coverage, and confirm the final web remains dependency-free with mobile UI out of scope. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, complete backend/web/contract/migration gates, manual laptop-first accessibility/browser flow, protected-path and generated-output audits, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

### Structured phase result

```yaml
schemaName: gentle-ai.sdd-status
changeName: group-outing-workspaces
artifactStore: openspec
applyState: ready
taskProgress: {total: 60, complete: 22, remaining: 38}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1
  allowedEditRoots:
    - web/src/app/App.tsx
    - web/tests/app.test.tsx
    - openspec/changes/group-outing-workspaces/tasks.md
    - openspec/changes/group-outing-workspaces/apply-progress.md
  warnings:
    - "Parent-held native attempt authority was not reacquired or settled by this executor."
    - "Native verify remains blocked by the existing verification-envelope requirement; this apply remediation records implementation evidence only."
    - "All other dirty and untracked paths, including seven web-professional-redesign artifacts, were preserved."
nextRecommended: parent-lifecycle
```

## PR3 stalled-attempt evidence (2026-09-08)

- Native attempt `pr3-outing-lifecycle` was acquired with the preserved inventory and an 800-line hard cap. The delegated writer stalled before returning a phase result and left an incomplete outing candidate.
- Read-only verification found the focused outing suite at `7 passed, 3 failed`, relevant backend regressions at `95 passed, 1 failed`, full backend at `261 passed, 4 failed`, Ruff green, and contract drift failing because outing OpenAPI/generated artifacts were not regenerated.
- The candidate is not settled as passing: the new outing files alone measure approximately 1,160 added lines, real non-empty deletion still depends on the later expense-to-outing association, and production dependency wiring is not covered.
  - The maintainer explicitly authorized an audited native reset. The current attempt must be settled as failed first; subsequent PR3 work will be split into bounded persistence, service, API, and generator slices. No source, generated, redesign, commit, push, clean, or global reset is authorized by this record.

## PR3a — Outing persistence foundation

### Status consumed and produced

- Consumed native status: `artifactStore=openspec`, change `group-outing-workspaces`, `applyState=ready`, `dependencies.apply=ready`, `nextRecommended=apply`, `actionContext.mode=repo-local`, workspace root `D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1`, and the repository-root native allowed edit root.
- Workload guard: `Decision needed before apply: No`; `Chained PRs recommended: Yes`; `Chain strategy: stacked-to-main`; `400-line budget risk: High`. Parent supplied the resolved `exception-ok` path. This worker used only the exact PR3a edit surfaces and did not acquire, settle, reset, commit, push, clean, start review, create receipts, or run delivery gates.
- Produced result: **success for the bounded persistence foundation only**. Native status remains partial (`22/60` tasks complete, `38` remaining), `verify=blocked`, and `nextRecommended=apply`; no task checkbox was changed because the broader PR3 lifecycle/API/contract work remains incomplete.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR3a outing persistence foundation | `backend/tests/integration/persistence/test_outing_tables.py`, `backend/tests/test_alembic_harness.py` | SQLite/Alembic integration | ✅ Baseline focused run: `3 passed, 1 failed` (stale harness expected only through `0003_workspace`) | ✅ Added narrow string-ID scope, UTC/default/shape, ordering, UoW exposure, and migration-list assertions; run: `2 failed, 3 passed` (expected scope mismatch plus stale harness) | ✅ Repository ID normalization and harness `0004` expectation; run: `5 passed` | ✅ Final focused run: `6 passed`; group isolation, blank-name DB rejection, tie ordering, migration round trip, and UoW exposure | ✅ Ruff format on allowed persistence files; final focused run remained green |

### Implementation and changed paths

- `backend/app/adapters/db/tables.py` — formatted and retained the `Outing` mapping: UUID group FK, nullable `archived_at`, UTC-aware SQLAlchemy timestamps, non-empty DB check, and stable `(group_id, created_at, id)` index; no monetary/date-scheduling fields.
- `backend/app/adapters/db/repositories.py` — normalized equivalent UUID/string group identifiers for create, retained group predicates and stable ordering, and removed the premature deletion/expense probe that cannot be correct before `Expense.outing_id` exists.
- `backend/app/adapters/db/uow.py` — retained/exposed `OutingRepositoryAdapter` through the transaction boundary (and existing flush support).
- `backend/app/application/ports.py` — retained `OutingRecord` and the group-scoped lifecycle port without claiming non-empty deletion enforcement before the association slice.
- `backend/migrations/versions/0004_outing.py` — reversible `0003_workspace` → `0004_outing` migration with matching table shape, FK, check, indexes, defaults, and downgrade.
- `backend/tests/integration/persistence/test_outing_tables.py` — narrow persistence, ordering, UoW, and migration round-trip assertions; migration list now includes `0004_outing`.
- `backend/tests/test_alembic_harness.py` — expected revision inventory now includes `0004_outing.py`.
- No task checkbox was changed. Partial PR3 service/API files, generated contracts, web/mobile/redesign, specs, and unrelated dirty/untracked paths were preserved.

### Exact verification and migration proof

- Baseline: `python -m pytest backend/tests/integration/persistence/test_outing_tables.py backend/tests/test_alembic_harness.py -q` — **3 passed, 1 failed**; only the stale harness expectation for the already-present `0004_outing.py` failed.
- RED: same focused command after narrow assertions — **2 failed, 3 passed**; expected equivalent UUID/string group mismatch plus stale harness expectation.
- GREEN/Triangulate/Refactor final: same focused command — **6 passed**.
- Relevant persistence regression: `python -m pytest backend/tests/integration/persistence -q` — **27 passed**.
- Ruff: `python -m ruff check` on all seven allowed backend files — **passed: All checks passed!**
- Whitespace: `git diff --check` on the allowed handwritten files — **clean**; an explicit scan of untracked migration/test files found no trailing whitespace.
- Migration proof: the focused round-trip applies `0001_auth`, `0002_source`, `0003_workspace`, and `0004_outing`, confirms `outings` and prior `groups`, downgrades `0004`, then confirms `outings` is removed while `groups` remains. Harness inventory also asserts all four revisions.

### Boundary, deviations, and remaining work

- Estimated repair delta from the preserved partial candidate: **approximately 200 changed-line units**, including this 80-line evidence append, comfortably below the native 790-line cap; this excludes pre-existing partial PR3 source and unrelated dirty/generated paths. The current seven-file implementation/test/migration snapshot is exactly **600 units versus HEAD** (including preserved prior-slice bytes). The `0004_outing` migration and most outing implementation bytes were preserved, not re-authored, in this outing foundation repair.
- Non-empty deletion is intentionally deferred: the current `expenses` table has no `outing_id`, so this slice does not claim `has_expenses`, empty-only deletion, referential deletion protection, expense-write blocking, or PR3 lifecycle completion. The premature repository deletion probe was removed; the later expense-association slice owns that semantic.
- Remaining exact PR3 boundary: outing lifecycle service/API/route/schema behavior and tests, owner/member authorization, archived write rules, expense association and non-empty deletion enforcement, OpenAPI export/generated-client synchronization, contract drift, full PR3 verification, and parent lifecycle/review/delivery actions.

### Remaining task rows (persisted unchanged)

    ```text

- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->

```

`tasks.md` readback confirms 60 valid ownership markers, 22 checked rows, and these 38 remaining rows; PR4–PR9 and the three parent-owned rows remain unchanged in the preceding cumulative inventory.

### Structured phase result

```yaml
schemaName: gentle-ai.sdd-status
changeName: group-outing-workspaces
artifactStore: openspec
applyState: ready
taskProgress: {total: 60, complete: 22, remaining: 38}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1
  allowedEditRoots:
    - backend/app/adapters/db/tables.py
    - backend/app/adapters/db/repositories.py
    - backend/app/adapters/db/uow.py
    - backend/app/application/ports.py
    - backend/migrations/versions/0004_outing.py
    - backend/tests/integration/persistence/test_outing_tables.py
    - backend/tests/test_alembic_harness.py
    - openspec/changes/group-outing-workspaces/apply-progress.md
  warnings:
    - "Parent-held native authority was not reacquired or settled by this executor."
    - "Partial PR3 API/service files and generated contract outputs were intentionally untouched."
    - "Non-empty outing deletion remains deferred until the expense-to-outing association slice."
nextRecommended: parent-lifecycle
```

## PR3b — Outing lifecycle service bounded slice

### Status consumed and produced

- Consumed authoritative file-backed status for `group-outing-workspaces`: `artifactStore=openspec` in the active status handoff, `applyState=ready`, `taskProgress=22/60`, `dependencies.apply=ready`, `verify=blocked`, and `nextRecommended=apply`.
- Workload guard: `Decision needed before apply: No`; `Chained PRs recommended: Yes`; `Chain strategy: stacked-to-main`; `400-line budget risk: High`. The parent supplied the resolved bounded `exception-ok` PR3b path and native cap of 790.
- `actionContext.mode=repo-local`; the delegated edit boundary was exactly the three paths listed below. Parent-held native authority was not reacquired, settled, reset, committed, pushed, cleaned, or used for review/delivery gates.
- Produced result: **partial success for service semantics only**. No task row was checked; persisted progress remains `22/60`, with API, OpenAPI/generated-client, PR3c expense association, and PR3d boundaries deferred.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR3b outing service semantics | `backend/tests/unit/application/test_outing_service.py` | Unit | ✅ Initial run: `3 failed, 2 passed`; failures were pre-existing aliasing assertions and an auth rollback-count expectation | ✅ Added group-scoped actor assertion; RED: `1 failed, 5 passed` | ✅ Focused run: `6 passed` after enforcing actor/group scope | ✅ Focused `6 passed`; relevant application tests `35 passed`; Ruff passed | ✅ Final focused suite remained `6 passed`; no behavior change after evidence cleanup |

### Implementation and verification

- `outing_service.py` now rechecks an actor's supplied server authorization context against the requested group for reads and writes while retaining group-first repository lookups, trimmed/max-255 names, owner-only lifecycle operations, archived read-only checks, one UoW commit, and one post-commit publisher call.
- Unit assertions were corrected to observe returned mutation state before later in-place fake-repository mutations, and to prove authorization failures do not enter the transaction. The tests cover trimmed names, max length, group isolation, stale IDs, member/owner authorization, archived read-only behavior, rollback/no-publication, and single publication after success.
- Focused command: `python -m pytest backend/tests/unit/application/test_outing_service.py -q` — **6 passed**.
- Relevant application command: `python -m pytest backend/tests/unit/application/test_auth_service.py backend/tests/unit/application/test_group_service.py backend/tests/unit/application/test_participant_service.py backend/tests/unit/application/test_expense_service.py -q` — **35 passed**.
- Ruff: `python -m ruff check backend/app/application/outing_service.py backend/tests/unit/application/test_outing_service.py` — **All checks passed**. Compile and trailing-whitespace checks also passed.

### Scope, deviations, and accounting

- Changed paths in this bounded apply: `backend/app/application/outing_service.py`, `backend/tests/unit/application/test_outing_service.py`, and this cumulative progress file only. Existing API routes/tests, persistence foundation, generated outputs, and unrelated dirty/untracked files were preserved.
- No duplicate-name behavior, expense association, archived-expense write rule, repository/table/UoW/API/schema, OpenAPI, generated-client, WebSocket payload, or client-role change was introduced. Non-empty expense deletion remains the explicit PR3c boundary because `Expense` has no `outing_id`.
- Exact worker delta from the pre-apply snapshots: **70 source/test changed lines + 52 appended evidence lines = 122 changed lines**, safely below the native 790-line slice cap. This excludes preserved prior PR3a/partial-candidate bytes.
- `tasks.md` readback: 60 valid ownership markers, 22 checked, 38 unchecked; no task checkbox was changed. The exact five PR3 lifecycle rows remain unchecked in the preceding inventory, and all PR3c–PR9 plus parent-owned rows remain deferred.

### Structured phase result

```yaml
schemaName: gentle-ai.sdd-status
changeName: group-outing-workspaces
artifactStore: openspec
applyState: ready
taskProgress: {total: 60, complete: 22, remaining: 38}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  workspaceRoot: D:\\universidad\\Proyectos\\2doSemestre2026\\topicos\\proyecto_1
  allowedEditRoots:
    - backend/app/application/outing_service.py
    - backend/tests/unit/application/test_outing_service.py
    - openspec/changes/group-outing-workspaces/apply-progress.md
  warnings:
    - "Parent-held native authority remains parent-owned; no lifecycle or delivery gate was started."
    - "API files/tests and generated contract outputs remain partial and untouched."
    - "PR3c expense association owns production non-empty outing deletion enforcement."
nextRecommended: parent-lifecycle
```

## PR3b corrective rerun — server authorization collaborator

- Status consumed/produced: `applyState=ready` → `partial`; `taskProgress=22/60`; `verify=blocked`; next recommendation remains `parent-lifecycle`.
- Workload: `exception-ok`, `stacked-to-main`, `Decision needed before apply: No`, native cap `790`; only the three delegated paths were eligible.
- `actionContext.mode=repo-local`; parent-held authority stayed parent-owned; no acquire, settle, reset, commit, push, clean, review, or delivery gate was run.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR3b authorization correction | `backend/tests/unit/application/test_outing_service.py` | Unit | ✅ 6 passed | ✅ 2 failed, 6 passed | ✅ 9 focused + 44 relevant application tests | ✅ 9 focused, Ruff clean | ✅ compileall clean; API wiring explicitly deferred |

- Added optional `AuthorizationService` injection; member reads/mutations call `authorize(..., "read_group")`, and owner checks use the returned server role.
- The fallback fails closed for missing actor/account/group context and is unit compatibility only; it does not read `actor.role` when the collaborator is present.
- Fake authorization proves a member cannot archive and a server-derived owner can, even when actor role values are forged.
- RED/GREEN/TRIANGULATE/REFACTOR: new tests failed, then 8 passed, then 9 focused passed; relevant application tests passed with 44; compileall passed.
- Ruff passed on both backend files; transaction, post-commit publication, archived read-only, and deferred non-empty deletion semantics were preserved.
- API wiring remains deferred: the later API slice must inject request-scoped authorization repositories; routes, persistence, generated paths, and `tasks.md` were untouched.
- Remaining exact unchecked task rows stay unchanged in the cumulative inventory; no implementation task was completed or checked by this correction.
- Estimated incremental correction is approximately 150 changed-line units; cumulative bounded PR3b evidence remains well below the native 790 cap.

## PR3c — Authenticated outing API wiring bounded slice

### Status consumed and produced

- `openspec status --change group-outing-workspaces` confirmed the selected change and `Progress: 4/4 artifacts complete`; the parent supplied native `pr3c-outing-api` authority and repo-local allowed-root context.
- Workload guard consumed: `Decision needed before apply: No`; chained delivery remains `exception-ok` / `stacked-to-main`; native candidate cap remains 790 changed lines.
- Parent-owned authority was not acquired, settled, reset, committed, pushed, cleaned, reviewed, or used for delivery gates. Produced result: partial apply success; no task checkbox changed.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR3c authenticated API wiring | `backend/tests/integration/api/test_outing_routes.py` | FastAPI integration | ✅ `2 passed` before edits | ✅ `3 failed, 1 passed` after focused wiring assertions | ✅ `5 passed` after route/main wiring | ✅ `32 passed` outing + shared auth/group/participant/expense/security APIs | ✅ `5 + 27 passed`; Ruff clean |

### Implementation and verification

- `get_outing_service` now uses request state first, injects/constructs `AuthorizationService` from request-scoped membership/group repositories, and fails closed when request state is absent.
- `_wire_request_services` now exposes a request-scoped `OutingService` using `OutingRepositoryAdapter`, `SqlAlchemyUnitOfWork`, the existing authorization collaborator, and the shared broadcaster.
- Archived edit responses now preserve the stable 409 domain envelope instead of attempting to serialize a `JSONResponse` as an outing.
- Focused RED: `python -m pytest backend/tests/integration/api/test_outing_routes.py -q` before edits — **2 passed**; assertion RED — **3 failed, 1 passed**.
- GREEN/REFACTOR: the focused outing file — **5 passed**; shared integration command — **32 passed**, then shared regression rerun — **27 passed**.
- Ruff: `python -m ruff check backend/app/api/routes/outings.py backend/app/main.py backend/tests/integration/api/test_outing_routes.py` — **All checks passed**.
- Route coverage retains member create/edit/read, owner archive, stale ID, blank name, forbidden member lifecycle, archived read-only, CSRF/origin, and request-state wiring checks without changing existing auth tests.
- Scoped path audit: this phase edited only `backend/app/api/routes/outings.py`, `backend/app/main.py`, `backend/tests/integration/api/test_outing_routes.py`, and this progress file; dirty/untracked paths outside the allowlist were preserved.
- Estimated bounded candidate: approximately **630 changed-line units**, including the partial route/test files, main wiring, and this concise evidence; below 790.
- OpenAPI export, generated TypeScript/Dart regeneration, and contract drift are explicitly deferred; no generated output was edited.

### Remaining tasks and boundaries

- No broad PR3 task row was marked complete. Expense association/non-empty deletion and generated-contract work remain later PR3 slices; this slice does not claim full PR3 completion.
- Exact unchecked PR3 rows remain unchanged:
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->

### Structured phase result

```yaml
schemaName: gentle-ai.sdd-status
changeName: group-outing-workspaces
artifactStore: openspec
applyState: partial
taskProgress: {total: 60, complete: 22, remaining: 38}
dependencies: {apply: ready, verify: blocked, sync: blocked, archive: blocked}
actionContext:
  mode: repo-local
  warnings:
    - "Parent-owned native pr3c-outing-api authority remains untouched."
    - "Generated contract paths and later expense-association behavior remain deferred."
nextRecommended: parent-lifecycle
```

## PR3d — Web contract-generation parity gate (pre-copy stop)

- `openspec status --change group-outing-workspaces` — **exit 0**; planning artifacts `4/4 complete`.
- Parent-selected native slice: `pr3d-web-outing-contract`; no authority acquire/settle/reset/commit/push/clean was issued.
- RED/parity: `python -m backend.scripts.check_contract_drift --cwd .` — **exit 1**; expected outing drift observed in `contracts/openapi.json`, `OutingsApi`, `OutingResponse`, and `OutingWriteRequest`, plus existing generated changes.
- TDD Cycle Evidence: RED = validator exit 1; GREEN = not entered because normalized candidate exceeded cap; TRIANGULATE = exact 17-file diff and mobile drift inventory; REFACTOR = not entered, no copy.
- Export/generator: `export_contract` to `C:\Users\HP\AppData\Local\Temp\pr3d-web-contract-xbke2f0y\contracts\openapi.json`; `_run_generator(..., "typescript-fetch", "supportsES6=true")`; `_normalize_web_api_paths` applied to the temporary web output.
- Normalized comparison was completed before any repository copy; all bytes were compared after CRLF→LF normalization.
- Selected contract path: `contracts/openapi.json` (**581** changed-line units; bytes `53066 → 68649`).
- Selected web paths and normalized units: `.openapi-generator/FILES` **3**; `apis/AuthApi.ts` **150**; `apis/BalancesApi.ts` **62**; `apis/ExpensesApi.ts` **512**.
- `apis/GroupsApi.ts` **737**; `apis/HealthApi.ts` **46**; `apis/index.ts` **1**; `apis/OutingsApi.ts` **463**.
- `apis/ParticipantsApi.ts` **646**; `apis/SettlementApi.ts` **63**; `models/GroupCreateRequest.ts` **65**; `models/GroupSummaryResponse.ts` **228**.
- `models/index.ts` **2**; `models/OutingResponse.ts` **117**; `models/OutingWriteRequest.ts` **66**; `models/SessionIdentityResponse.ts` **150**.
- Batch result: **17 changed files, 3,892 normalized changed-line units, 0/17 byte-equal**; native hard cap is **790**.
- **STOP before copying**: the web+contract batch exceeds the cap by **3,102 units**. No contract or generated web bytes were copied.
- Post-copy drift command `python -m backend.scripts.check_contract_drift --cwd .` — **not run** because the required pre-copy cap stop fired.
- `npm --prefix web run typecheck` and focused web tests — **not run** because no generated output was copied; scoped `git diff --check -- contracts/openapi.json web/src/generated/api` — **exit 0** as an audit, with only LF→CRLF warnings.
- Mobile generation was explicitly deferred; no Dart/mobile output was touched and PR3d does not claim full contract drift.
- Remaining exact mobile drift from the RED validator: `mobile/.openapi-generator/FILES`; `mobile/doc/GroupsApi.md`; missing `mobile/doc/OutingResponse.md`, `mobile/doc/OutingsApi.md`, `mobile/doc/OutingWriteRequest.md`.
- Remaining mobile drift: `mobile/lib/openapi.dart`; `mobile/lib/src/api/groups_api.dart`; missing `mobile/lib/src/api/outings_api.dart`; `mobile/lib/src/api.dart`; `mobile/lib/src/deserialize.dart`.
- Remaining mobile drift: `mobile/lib/src/model/expense_contributor_request.g.dart`; `group_create_request.dart`; `group_summary_response.dart`; missing `outing_response.dart`, `outing_response.g.dart`, `outing_write_request.dart`, `outing_write_request.g.dart`; `session_identity_response.dart`.
- Remaining mobile drift: `mobile/README.md`; `mobile/test/groups_api_test.dart`; missing `mobile/test/outing_response_test.dart`, `outing_write_request_test.dart`, `outings_api_test.dart`.
- No task checkbox was changed; no backend, handwritten web, mobile, redesign, spec, or task path was edited. This is a bounded pre-copy stop and does not claim PR3 completion.

## PR3d — OpenAPI snapshot-only generator slice

- Status: `openspec status --change group-outing-workspaces` exited 0; planning artifacts are 4/4 complete.
- Parent-selected slice: `pr3d-openapi-snapshot`; parent retained native authority; no acquire, settle, reset, commit, push, or clean was issued.
- Workload boundary: snapshot contract only, `exception-ok` / `stacked-to-main`, hard cap 790 changed-line units.
- Allowed repository edits were limited to `contracts/openapi.json` and this `apply-progress.md`; all dirty/untracked paths, including `web-professional-redesign`, were preserved.

### TDD Cycle Evidence

| Phase | Evidence |
| --- | --- |
| RED | Exact `python -m backend.scripts.check_contract_drift --cwd .` before copy exited 1 with expected contract and generated-client drift. |
| GREEN | Pinned `export_contract` wrote a temporary snapshot; normalized delta measured exactly 581 units, within 790; only generated contract bytes were copied. |
| TRIANGULATE | Pre-copy normalized comparison and post-copy raw/normalized comparisons both confirmed candidate/target byte equality. |
| REFACTOR | No source refactor or hand edit; generated web/mobile batches remain separate follow-up work. |

- Temporary export: `C:\Users\HP\AppData\Local\Temp\pr3d-openapi-snapshot-bx6c0nai\contracts\openapi.json`, using the helper pinned by `backend/scripts/check_contract_drift.py`.
- Contract result: normalized `contracts/openapi.json` delta **581** units (`53066 → 68649` bytes); raw and normalized copied bytes are equal.
- Exact post-copy validator ran once and exited 1, as expected: web and mobile generated clients remain stale.
- `git diff --check` ran only as an audit; exit 2 reports pre-existing trailing whitespace in dirty mobile-generated files. No cleanup or correction was performed.
- Remaining web generation is explicitly deferred as batches A–E: **651 / 537 / 740 / 737 / 646** units.
- Remaining mobile generated-client batch is explicitly deferred; no `web/src/generated/api/**` or `mobile/lib/generated/api/**` path was changed.
- The five PR3 implementation rows remain unchecked in `tasks.md`; no task artifact was modified:
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- Result: snapshot-only contract copy complete; web/mobile generated batches, broader PR3 behavior, and parent lifecycle actions remain deferred to their owners.

## PR3e — TypeScript generator batch A (`pr3e-web-generated-a`)

- Status: `openspec status --change group-outing-workspaces` exited 0; selected change confirmed with 4/4 planning artifacts complete.
- Boundary: parent-held native authority `pr3e-web-generated-a`; no acquire, settle, reset, commit, push, clean, review, or delivery gate was issued.
- Workload: `exception-ok` / `stacked-to-main`; batch A is bounded below the native 790-unit cap; `tasks.md` was not changed.
- RED: exported current OpenAPI to a temporary directory, ran pinned `_run_generator(..., "typescript-fetch", "supportsES6=true")`, applied `_normalize_web_api_paths`, and found 5/5 selected paths mismatched before copy.
- RED normalized delta: `OutingsApi.ts` 463 + `OutingResponse.ts` 117 + `OutingWriteRequest.ts` 66 + `models/index.ts` 2 + `FILES` 3 = **651 units**.
- GREEN: copied only the five selected generator outputs after the cap check; post-copy raw bytes were byte-equal to the generator candidates.
- TRIANGULATE: `npm --prefix web run typecheck` — passed; `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` — 7 passed.
- TRIANGULATE audit: scoped `git diff --check -- web/src/generated/api/...` — exit 0; only the existing LF→CRLF warning was emitted.
- REFACTOR: no generated file was hand-edited; no contract, handwritten source, test, mobile, redesign, or task path was changed.
- Remaining web batches: B–E = **537 / 740 / 737 / 646 units**; remaining mobile generated-client batch is intentionally deferred.
- Full contract drift was not run because remaining generated batches are intentionally stale; this batch does not claim PR3 completion.

### PR3e correction — fresh generator parity

- RED correction: independent verification found formatting mismatches in the three outing files; `models/index.ts` and `.openapi-generator/FILES` were already byte-equal.
- Re-ran the exact pinned export, `_run_generator(..., "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths` into a temporary directory.
- Fresh normalized active-slice delta: **646 units** = `OutingsApi.ts` 463 + `OutingResponse.ts` 117 + `OutingWriteRequest.ts` 66 + `models/index.ts` 0 + manifest 0; below the 790 cap and prior 651 candidate.
- GREEN correction: replaced only the same five selected paths with fresh generator bytes; all five are now raw and normalized byte-equal.
- TRIANGULATE correction: `npm --prefix web run typecheck` passed; focused workspace test passed with 7 tests; scoped `git diff --check` exited 0 with only the existing LF→CRLF warning.
- REFACTOR correction: no other path, task checkbox, authority, commit, push, reset, clean, or full drift action was touched.
- Parent readback correction: the parent reran the exact pinned workflow and copied bytes directly from the same temporary generator output; a fresh 5/5 raw and normalized equality assertion passed. The selected generated files contain 463 + 117 + 66 + 28 + 39 = 713 physical lines; the native active diff remained below the 790 cap. `npm --prefix web run typecheck` passed, the focused workspace test passed with 7 tests, and scoped `git diff --check` exited 0 with only the existing LF→CRLF warning.
- This correction supersedes the stale 646-unit estimate above; no hand formatting was applied and no other path or task checkbox changed. Remaining web batches B–E are still 537 / 740 / 737 / 646 units; mobile generation and full drift remain deferred.

## PR3f — TypeScript generator batch B (`pr3f-web-generated-b`) pre-copy cap stop

- Status: `openspec status --change group-outing-workspaces` exited 0; selected change confirmed, planning artifacts 4/4 complete. Parent-held PR3f authority was used as context; no acquire, settle, reset, commit, push, clean, review, or delivery gate was issued.
- Workload: `exception-ok` / `stacked-to-main`; hard cap **790** normalized changed-line units. Only the seven generated paths listed by the user were selected; `tasks.md` was not changed.
- RED safety net: `npm --prefix web run typecheck` passed; `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` passed (**7 tests**).
- RED generator: `export_contract(temp/contracts/openapi.json)`, `_run_generator(repo_root, contract, temp/web, "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths(temp/web)` completed inside `TemporaryDirectory`; it was removed on scope exit.
- Fresh normalized pre-copy parity was **0/7 equal**. Units: `AuthApi.ts` 150; `BalancesApi.ts` 62; `ExpensesApi.ts` 512; `HealthApi.ts` 46; `SettlementApi.ts` 63; `apis/index.ts` 1; `GroupCreateRequest.ts` 65. Total **899**, exceeding 790 by **109**.
- GREEN: not entered. Per the hard-stop rule, no candidate bytes were copied; raw and normalized post-copy equality was therefore **not applicable (0/7 copied)**.
- TRIANGULATE: post-copy typecheck and focused test were not run because the cap stop fired; scoped generated-path `git diff --check` was run and exited 0. Baseline test outcomes above are preserved; generated output was never hand-edited or formatted.
- REFACTOR: not entered; no repository path besides this progress append changed. Existing `web-professional-redesign` and all unrelated dirty/untracked paths were preserved.
- The supplied 729-unit estimate does not match this fresh candidate: only `ExpensesApi.ts` differs materially from that estimate (512 measured here versus 342 supplied). This batch is **partial/blocked**, not complete.
- Remaining web drift: PR3f batch B remains pending at **899** units; later planned batches are `GroupsApi.ts` 653, `ParticipantsApi.ts` 426, `GroupSummaryResponse.ts` 228, and `SessionIdentityResponse.ts` 150. Mobile generated output remains deferred.

## PR3f — TypeScript generator core batch (`pr3f-web-generated-core`)

- Status consumed: `openspec status --change group-outing-workspaces` exited 0; selected change confirmed; planning artifacts 4/4 complete.
- Action context: repo-local repository root; parent-held PR3f authority remained untouched. No acquire, settle, reset, commit, push, clean, review, or delivery gate was issued.
- Workload boundary: `exception-ok` / `stacked-to-main`; hard cap 790 normalized changed-line units. Only the six user-selected generated paths were eligible; `tasks.md` was not changed.
- RED safety net: `npm --prefix web run typecheck` passed; focused workspace test passed with 7 tests.
- RED generator: `export_contract(temp/contracts/openapi.json)`, `_run_generator(..., "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths(temp/web)` completed inside `TemporaryDirectory`; temporary output was removed.
- Pre-copy normalized units: AuthApi.ts 154 (+60/-94); BalancesApi.ts 62 (+26/-36); HealthApi.ts 48 (+24/-24); SettlementApi.ts 63 (+26/-37); apis/index.ts 1 (+1/-0); GroupCreateRequest.ts 65 (+30/-35).
- Actual total: **393** normalized changed-line units, below the 790 cap. The supplied 387 estimate differed by AuthApi +4 and HealthApi +2.
- Pre-copy parity was 0/6 raw and 0/6 normalized; GREEN copied bytes directly from temporary output to exactly the six selected paths.
- Post-copy parity: **6/6 raw byte-equal and 6/6 normalized byte-equal**; temporary output cleanup assertion passed.
- TRIANGULATE: post-copy typecheck passed; focused workspace test passed (**7 tests**; existing React `act(...)` warning only).
- Scoped `git diff --check` on exactly the six paths **failed, exit 2**, due generator-produced trailing whitespace in AuthApi, BalancesApi, HealthApi, and SettlementApi; LF→CRLF warnings also appeared. No hand formatting or repair was performed.
- REFACTOR: no generated file was hand-edited; no task, handwritten source, mobile, redesign, or unrelated path was changed. Result is **partial**, not completion, because the scoped diff check remains red.
- Remaining generated drift: `ExpensesApi.ts`, `GroupsApi.ts`, `ParticipantsApi.ts`, `GroupSummaryResponse.ts`, `SessionIdentityResponse.ts`, and mobile generated output.
- Parent parity correction: the delegated write was subsequently host-formatted on tracked generated files, so the parent reran the pinned export/generator/normalizer and copied the six selected bytes directly from the same temporary output. A fresh 6/6 raw and normalized equality assertion passed. Typecheck and the focused 7-test workspace suite had already passed; generator-produced trailing whitespace remains an audit warning and was not hand-fixed.
- This correction preserves exact generator output, keeps the six-path native delta at **393** under 790, and changes no task checkbox or unrelated path. The remaining generated batches are `ExpensesApi.ts` 512, `GroupsApi.ts` 653, `ParticipantsApi.ts` 426, `GroupSummaryResponse.ts` 228, `SessionIdentityResponse.ts` 150, plus mobile.

## PR3g — TypeScript generator ExpensesApi slice (`pr3g-web-generated-expenses`)

- Status: `openspec status --change group-outing-workspaces` exited 0; selected change confirmed with 4/4 planning artifacts. Parent-held PR3g authority was used; no acquire, settle, reset, commit, push, clean, review, or delivery gate was issued.
- Workload: `exception-ok` / `stacked-to-main`; hard cap **790** normalized changed-line units. Only `web/src/generated/api/apis/ExpensesApi.ts` and this progress file were eligible; `tasks.md` was unchanged.
- RED: baseline `npm --prefix web run typecheck` passed and focused `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` passed (**7 tests**; existing React `act(...)` warning). Temporary export/generation/normalization completed with the pinned helpers.
- GREEN: normalized native-style accounting for `ExpensesApi.ts` was **360 units** (**131 additions + 229 deletions**), below the expected **512** bound and hard **790** cap. Pre-copy parity was **0/1 raw, 0/1 normalized**; bytes were copied directly from `temp/web/apis/ExpensesApi.ts`.
- TRIANGULATE: post-copy parity was **1/1 raw and 1/1 normalized**; temporary output cleanup assertion passed. Post-copy typecheck passed; focused workspace test passed (**7 tests**).
- REFACTOR: scoped `git diff --check -- web/src/generated/api/apis/ExpensesApi.ts` exited **2** only for generator-produced trailing whitespace at lines 8 and 60, plus the existing LF→CRLF warning. No hand formatting or generated-file repair was performed.
- Result: **partial** because the scoped whitespace audit remains red despite cap, parity, and tests passing. Remaining web generated drift is `GroupsApi.ts`, `ParticipantsApi.ts`, `OutingsApi.ts`, `GroupCreateRequest.ts`, `GroupSummaryResponse.ts`, `OutingResponse.ts`, `OutingWriteRequest.ts`, `SessionIdentityResponse.ts`, and related index metadata; mobile generated drift remains deferred.

## PR3h — TypeScript generator GroupsApi slice (`pr3h-web-generated-groups`)

- Status consumed: selected `group-outing-workspaces`; parent-held `pr3h-web-generated-groups` authority reused. `repo-local` root and explicit two-path edit boundary honored; no acquire, settle, reset, commit, push, clean, review, or delivery gate.
- Workload: `exception-ok` / `stacked-to-main`; only `web/src/generated/api/apis/GroupsApi.ts` and this progress file were eligible; hard cap **790** normalized units. `tasks.md` was unchanged.
- RED: pinned `export_contract`, `_run_generator(..., "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths` ran in `TemporaryDirectory`; pre-copy parity was **0/1 raw, 0/1 normalized**. Actual normalized delta was **659** (`518` additions + `141` deletions), six above the supplied 653 expectation but below cap.
- GREEN: copied bytes directly from `temp/web/apis/GroupsApi.ts`; post-copy parity was **1/1 raw and 1/1 normalized**. Temporary output cleanup assertion passed.
- TRIANGULATE: `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` passed (**7 tests**, existing React `act(...)` warning). `npm --prefix web run typecheck` failed because regenerated `GroupsApi.ts` and existing `OutingsApi.ts` both export outing request interfaces. No unrelated path was changed.
- REFACTOR: `git diff --check -- web/src/generated/api/apis/GroupsApi.ts` exited **2** for generator-produced trailing whitespace at lines 8 and 98 plus the existing LF→CRLF warning; no hand formatting or repair was performed.
- Remaining web drift after this copy: `apis/ParticipantsApi.ts`, `models/GroupSummaryResponse.ts`, and `models/SessionIdentityResponse.ts`. Mobile generated-client drift remains deferred and untouched.
- Produced phase result: **partial**; generated copy/parity and focused tests passed, but typecheck and whitespace audit remain red. No PR3 task checkbox was changed; broader PR3 behavior, full drift, mobile generation, and parent lifecycle remain deferred.

## PR3i — Handwritten outing route/tag correction (`pr3i-route-tag-correction`)

- Status consumed: `openspec status --change group-outing-workspaces` — exit 0; selected change confirmed with 4/4 planning artifacts complete.
- Action context: `repo-local`; allowed edit surfaces were `groups.py`, `main.py`, `test_outing_routes.py`, and this progress file. Parent-held native authority was used as context; no acquire, settle, reset, commit, push, clean, review, or delivery gate was issued.

### TDD Cycle Evidence

- RED: Added `test_source_openapi_exposes_outings_once_with_only_the_outings_tag`, asserting one source path, exact `['outings']` tags, and no nested outing router owned by `groups_router`.
- RED command: `python -m pytest backend/tests/integration/api/test_outing_routes.py::test_source_openapi_exposes_outings_once_with_only_the_outings_tag -q` — exit 1; observed `['groups', 'outings']` instead of `['outings']`.
- GREEN: Removed `nested_router` inclusion from `backend/app/api/routes/groups.py`; imported and included `outings_router` separately after `groups_router` in `backend/app/main.py`.
- GREEN command: same focused test — **1 passed**.
- TRIANGULATE: `python -m pytest backend/tests/integration/api/test_outing_routes.py -q` — **6 passed**.
- TRIANGULATE shared API/security subset — **94 passed, 1 pre-existing Starlette/httpx deprecation warning**.
- TRIANGULATE lint: `python -m ruff check backend` — **All checks passed**.
- TRIANGULATE OpenAPI export readback to a temporary file — **PASS**; `GET /api/v1/groups/{group_id}/outings` occurs once and has tags `['outings']`.
- REFACTOR: `git diff --check` on source plus `py_compile` — **PASS**; auth, CSRF, and route behavior remained covered by the existing subset. No generated client was edited.

### Path audit and boundary

- `git status --short --untracked-files=all -- <four allowed surfaces>` — exactly the four allowed surfaces were reported; unrelated dirty paths were preserved.
- The bounded PR3i source/test/evidence delta is below the native 790-line limit. `web/src/generated/api/apis/GroupsApi.ts` and all other generated candidates remain untouched.
- The generated PR3h candidate is intentionally reset/deferred until this handwritten source fix; this slice performed no reset and does not repair generated output.
- `tasks.md` was not changed. The broader PR3 task rows remain unchecked and deferred:
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->

- Produced status: **success for the bounded PR3i correction**; broader PR3 completion and parent-owned lifecycle remain deferred.

## PR3j — Corrected GroupsApi generator slice (pre-copy cap stop)

- Status consumed: explicit parent selection `group-outing-workspaces`; native status also listed `web-professional-redesign`, which was ignored. `actionContext.mode=repo-local`; only `GroupsApi.ts` and this progress file were allowed.
- Workload: `exception-ok` / `stacked-to-main`; hard cap **790** normalized changed-line units. Parent-held authority was used as context; no acquire, settle, reset, commit, push, clean, review, or delivery gate was issued.
- RED: `export_contract(temp/contracts/openapi.json)`, `_run_generator(repo_root, contract, temp/web, "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths(temp/web)` completed in `TemporaryDirectory`; pre-copy parity was **0/1 raw, 0/1 normalized**.
- Actual native-style normalized accounting for `web/src/generated/api/apis/GroupsApi.ts`: **801 units** (**84 additions + 717 deletions**), exceeding 790 by 11. Hard stop fired before copy; no repository candidate bytes were copied.
- GREEN: not entered because the selected delta exceeded the cap. Direct copy from `temp/web/apis/GroupsApi.ts` and post-copy parity were **not applicable**; temporary output cleanup passed.
- TRIANGULATE: `npm --prefix web run typecheck` — **exit 2**, duplicate outing request-interface exports remain because the corrected candidate was not copied; focused workspace test — **7 passed** with the existing React `act(...)` warning.
- TRIANGULATE: `git diff --check -- web/src/generated/api/apis/GroupsApi.ts` — **exit 0** (only the existing LF→CRLF warning); tracked-file trailing-whitespace audit found none; host rewrite — **no**.
- REFACTOR: not entered; no task checkbox or unrelated path changed. This is a bounded **blocked/pre-copy** result, not PR3 completion.
- Remaining web generated drift: the pending corrected `GroupsApi.ts`, `ParticipantsApi.ts`, `GroupSummaryResponse.ts`, and `SessionIdentityResponse.ts`; mobile generated-client drift remains deferred and untouched.
- Next action: parent must choose a smaller corrected generator boundary or delivery slice before another copy attempt; parent-owned lifecycle remains deferred.

## PR3k — Native staging normalization from stale committed snapshot

- Status: `openspec status --change group-outing-workspaces` confirmed 4/4 planning artifacts; parent explicitly selected `group-outing-workspaces`, while `web-professional-redesign` was ignored.
- Native boundary: parent-held token `sha256:fd780e0ba46b051d19df70a1fd7e5e911b1b36d4e8f691125be241bcc505dd02` was used as context; no acquire, settle, reset, commit, push, clean, review, or delivery gate was issued.
- Allowed surfaces were exactly `web/src/generated/api/apis/GroupsApi.ts` and this progress file; `tasks.md`, contracts, redesign paths, and all other generated paths were untouched.
- RED: intentionally used the existing stale committed `contracts/openapi.json` snapshot as generator input; did not export or copy the contract.
- RED: ran `_run_generator(repo_root, contracts/openapi.json, temp/web, "typescript-fetch", "supportsES6=true")` and `_normalize_web_api_paths(temp/web)` in a temporary directory.
- RED: measured only `GroupsApi.ts`: **718 units** = **259 additions + 459 deletions**, below the native 790 cap; copy proceeded only after this check.
- GREEN: copied bytes directly from `temp/web/apis/GroupsApi.ts`, without hand-editing or formatting; temporary output cleanup passed.
- GREEN: post-copy parity was **1/1 raw** and **1/1 normalized**; a fresh post-tool generator comparison remained **1/1 raw** and **1/1 normalized**.
- TRIANGULATE: `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` — **7 passed**, with the existing React `act(...)` warning.
- TRIANGULATE: `npm --prefix web run typecheck` — **exit 2** from duplicate outing request-interface exports; recorded as the known pre-correction contract defect, not as a green typecheck.
- TRIANGULATE: scoped `git diff --check -- web/src/generated/api/apis/GroupsApi.ts` — **exit 2** for generator-produced trailing whitespace at lines 8 and 98; no hand cleanup was performed.
- TRIANGULATE: no host formatting rewrite was observed; tracked bytes stayed generator-parity equal after the tool run.
- REFACTOR: this is temporary generated normalization, not corrected-contract synchronization; no task checkbox or unrelated path changed.
- Next action: regenerate/copy again from the corrected contract after the parent’s contract correction; parent performs any final direct copy before settlement if host rewriting appears.
- Produced result: **partial staging success**; PR3 behavior, full drift, corrected-contract regeneration, and parent lifecycle remain deferred.

## PR3m — Corrected outing OpenAPI snapshot (`pr3m-openapi-snapshot`)

- Status consumed: parent-resolved active change `group-outing-workspaces`; `web-professional-redesign` ignored; parent-held native token `sha256:886fbfb32876347791361e81ca3bb5316920b4da2ac3143934f470ab6228f9d1` was used as context.
- Action context: repo-local repository root; delegated edit surfaces were exactly `contracts/openapi.json` and this progress file. No acquire, settle, reset, commit, push, clean, review, receipt, or delivery gate was issued.
- Workload guard: `exception-ok` / `stacked-to-main`; one-file native cap **790**; `tasks.md` was not changed.

### TDD Cycle Evidence

- RED: safety net `python -m pytest backend/tests/integration/api/test_outing_routes.py backend/tests/test_openapi_contract.py -q` — **17 passed**; pinned `export_contract(temp_contract)` produced the candidate before copy.
- RED: pre-copy outing-operation assertion passed; candidate delta was **7 units** (`0 additions + 7 deletions`), bytes **71197 → 71050**, below the 790 cap; copy gate remained open.
- GREEN: copied bytes directly from the pinned temporary export to `contracts/openapi.json`; no formatting or manual JSON edit was used.
- GREEN: post-copy parity was **1/1 raw** and **1/1 normalized**; temporary export was removed after parity verification.
- TRIANGULATE: the corrected contract has **7** outing operations, every tag exactly `['outings']`, and no outing operation under `groups`.
- TRIANGULATE: focused API/OpenAPI tests after copy — **17 passed**; affected-route Ruff — **all checks passed**; affected-route `compileall` — passed.
- TRIANGULATE: scoped `git diff --check -- contracts/openapi.json openspec/changes/group-outing-workspaces/apply-progress.md` — clean; targeted path audit reported only the two allowed surfaces.
- REFACTOR: no generated client, task checkbox, backend source, redesign path, or other path was changed; full drift and client regeneration remain deferred to their bounded owners.
- Exact result: this PR3m snapshot delta is **7 native changed-line units**; resulting `contracts/openapi.json` versus HEAD is **765 units** (`763 additions + 2 deletions`), with prior dirty contract bytes preserved except for this slice.
- Produced status: **success for the bounded PR3m snapshot correction**; broader PR3 lifecycle, generated clients, full drift, and parent lifecycle remain deferred.

## PR3n — Corrected GroupsApi generation (`pr3n-web-generated-groups-corrected`)

- Status consumed: parent explicitly selected `group-outing-workspaces`; `web-professional-redesign` was ignored. `actionContext.mode=repo-local`; only `web/src/generated/api/apis/GroupsApi.ts` and this progress file were allowed.
- Workload guard: `Decision needed before apply: No`; chained delivery is `exception-ok` / `stacked-to-main`; parent-held native authority remained parent-owned. No acquire, settle, reset, commit, push, clean, review, receipt, or delivery gate was run.

### TDD Cycle Evidence

- RED: used `export_contract(temp_contract)`, `_run_generator(repo_root, temp_contract, temp/web, "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths(temp/web)` from a temporary directory; pre-copy parity was `0/1` raw and `0/1` normalized.
- RED delta gate: only `GroupsApi.ts` was measured: **433 deletions, 0 additions = 433 units**, below the native **790** cap; the corrected candidate was not generated from the committed snapshot.
- GREEN: copied the temporary normalized candidate bytes directly to `web/src/generated/api/apis/GroupsApi.ts`; post-copy parity was **1/1 raw** and **1/1 normalized**.
- TRIANGULATE: `npm --prefix web run typecheck` — **passed**; focused `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` — **7 passed** (existing React `act(...)` warning).
- TRIANGULATE: generated `GroupsApi` has **no outing symbols/operations**; `OutingsApi` retains all **14** outing method exports, and the fresh exported contract has **7** outing operations tagged exactly `['outings']`.
- TRIANGULATE audit: `git diff --check -- web/src/generated/api/apis/GroupsApi.ts openspec/changes/group-outing-workspaces/apply-progress.md` exited **2** only for generator-produced trailing whitespace at `GroupsApi.ts:8,52`, plus the existing LF→CRLF warning; no hand formatting was performed.
- REFACTOR: a fresh post-test pinned generation comparison remained **1/1 raw** and **1/1 normalized**, so no host/tool rewrite was observed. Temporary output was removed; no task checkbox or other path changed.

### Boundary and remaining work

- Changed surfaces are exactly `web/src/generated/api/apis/GroupsApi.ts` and this cumulative progress file; `tasks.md`, backend, contracts snapshot, mobile, handwritten web, redesign, and unrelated dirty paths were preserved.
- The corrected tag outcome is complete for this slice: outing operations have sole generated ownership in `OutingsApi.ts`; `GroupsApi.ts` contains only group operations.
- The scoped diff audit remains an evidence warning, not a permission to alter generated bytes; parent should rerun direct copy/parity before settlement if host formatting appears.
- Remaining exact PR3 implementation rows are unchanged and unchecked:
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- Produced result: **success for the bounded corrected GroupsApi replacement**, with generator whitespace audit warning; broader PR3 and parent lifecycle actions remain deferred.

## PR3o — Native ParticipantsApi generation (`pr3o-web-generated-participants`)

- Status consumed: `openspec status --change group-outing-workspaces` — exit 0, 4/4 artifacts complete; parent selected `group-outing-workspaces`; `web-professional-redesign` ignored.
- Native context: parent-held token `sha256:d3886b2b4f7efd751b47bfc594301668b532e012f98bed47a970c38a20711f66`; repo-local; only `web/src/generated/api/apis/ParticipantsApi.ts` and this file were allowed; no acquire, settle, reset, commit, push, clean, review, receipt, or delivery gate was run.
- Workload: `exception-ok` / `stacked-to-main`; hard cap **790**; only `ParticipantsApi.ts` was measured; `tasks.md` remained untouched.

### TDD Cycle Evidence

- RED: baseline `npm --prefix web run typecheck` passed; full `npm --prefix web run test` passed (**12 files, 86 tests**). The pinned `export_contract`, `_run_generator(..., "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths` pipeline completed; pre-copy parity was **0/1 raw, 0/1 normalized**.
- RED delta gate: only `ParticipantsApi.ts` was measured: **448 units** (**163 additions + 285 deletions**), below the native **790** cap.
- GREEN: copied exact bytes directly from `temp/web/apis/ParticipantsApi.ts`; post-copy parity was **1/1 raw and 1/1 normalized**.
- TRIANGULATE: post-copy `npm --prefix web run typecheck` passed; full `npm --prefix web run test` passed (**12 files, 86 tests**), with only the existing React `act(...)` warning.
- TRIANGULATE: a fresh post-test pinned generation comparison remained **1/1 raw and 1/1 normalized**; no host formatting rewrite was observed.
- REFACTOR: scoped `git diff --check -- web/src/generated/api/apis/ParticipantsApi.ts` exited **2** only for generator-produced trailing whitespace at lines **8** and **70** plus the existing LF→CRLF warning; no manual formatting or generated-file repair was performed.
- Changed surfaces are exactly `web/src/generated/api/apis/ParticipantsApi.ts` and this cumulative progress file; `tasks.md`, models, backend, contract snapshot, mobile, handwritten web, redesign, and unrelated dirty paths were preserved.
- Remaining PR3 implementation rows stay unchecked: member outing lifecycle RED/GREEN/TRIANGULATE/REFACTOR and Verify; no task checkbox changed.
- Produced result: **success for the bounded PR3o ParticipantsApi replacement**, with the generated-whitespace audit warning; parent may recheck parity/direct-copy before settlement if host formatting rewrites the output.

## PR3p — Native generated model slice (`pr3p-web-generated-models`)

- Status consumed: parent-resolved active change `group-outing-workspaces`; `web-professional-redesign` ignored; repo-local root and two-model edit boundary honored.
- Action-context warning: the native snapshot listed an ambiguous change selection; the explicit parent selection resolved it without touching the ignored redesign.
- Parent-held token: `sha256:98bae8b84bd438ce9bb8b5d0bb558063d9923f4fba29baf9474c86697b21b615`; no acquire, settle, reset, commit, push, clean, review, receipt, or delivery gate was run.
- Workload: `exception-ok` / `stacked-to-main`; hard cap **790**; only the two selected models were measured; `tasks.md` remained untouched.

### TDD Cycle Evidence

- RED: baseline `npm --prefix web run typecheck` passed; full `npm --prefix web run test` passed (**12 files, 86 tests**).
- RED: `export_contract(temp_contract)`, `_run_generator(repo_root, temp_contract, temp/web, "typescript-fetch", "supportsES6=true")`, and `_normalize_web_api_paths(temp/web)` produced pre-copy parity **0/2 raw, 0/2 normalized**.
- RED delta gate: `GroupSummaryResponse.ts` **228** (**106 additions + 122 deletions**) plus `SessionIdentityResponse.ts` **150** (**70 additions + 80 deletions**) = **378 units** (**176 additions + 202 deletions**), below 790.
- GREEN: copied exact pinned generator bytes directly to the two selected model paths; post-copy parity was **2/2 raw and 2/2 normalized**.
- TRIANGULATE: post-copy `npm --prefix web run typecheck` passed; full `npm --prefix web run test` passed (**12 files, 86 tests**), with the existing React `act(...)` warning.
- TRIANGULATE: fresh post-test pinned generation comparison remained **2/2 raw and 2/2 normalized**; no host rewrite was observed.
- TRIANGULATE audit: scoped path audit found only the two models plus this progress file; `git diff --check` exited **0** for tracked output, with the existing LF→CRLF warning.
- TRIANGULATE whitespace warning: generator output retains trailing whitespace in both models; no formatting or generated-file repair was performed.
- REFACTOR: no hand edits, contract/source/test/mobile/redesign changes, or task checkbox changes; broader PR3 remains deferred.

### Boundary and remaining work

- Files changed: `web/src/generated/api/models/GroupSummaryResponse.ts`, `web/src/generated/api/models/SessionIdentityResponse.ts`, and this cumulative progress file.
- The five PR3 implementation rows remain exactly unchecked in `tasks.md`:
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- Produced result: **success for bounded PR3p**; generated model delta, direct-copy parity, typecheck, full web tests, and scoped audit are recorded; parent lifecycle remains deferred.
- Next recommended: `parent-lifecycle`; parent may recheck direct-copy/parity before settlement if host formatting rewrites either model.

### PR3p — web generated model pair (bounded slice)

- RED: `GroupSummaryResponse.ts` and `SessionIdentityResponse.ts` were stale against the corrected pinned export.
- GREEN: generated the pair with `export_contract`, `_run_generator`, and `_normalize_web_api_paths`; measured 378 units (176 additions, 202 deletions), under 790.
- TRIANGULATE: raw and normalized parity passed 2/2; `npm --prefix web run typecheck` passed; full web suite passed 86 tests across 12 files.
- REFACTOR: preserved pinned generator whitespace and copied bytes without manual formatting; scoped audit retained only generated-output whitespace warnings.

## PR3q — Native bounded expense outing association

- Status consumed: scoped `openspec status --change group-outing-workspaces` passed (`4/4` artifacts); parent selected this change and ignored `web-professional-redesign`.
- Action context: repo-local; parent-held token `sha256:f6f7b1329006315ad2dd01289ccc24857c77909bdd399964b3f30ca6a4b68535`; no acquire, settle, reset, commit, push, clean, review, receipt, OpenAPI export, or client generation.
- Workload guard: `Decision needed before apply: No`; `Chained PRs recommended: Yes`; `exception-ok` / `stacked-to-main`; hard cap `790`.
- TDD safety net: prior focused persistence/outing/expense suite — `23 passed` before edits.
- RED: added focused nullable/composite-FK, migration, atomic outing deletion, service validation, and API mapping tests; RED collection failed on missing migration/error symbol as expected.
- GREEN: added `Expense.outing_id`, composite same-group FK, index, reversible `0005_expense_outing`, repository mapping/update, atomic `has_expenses`/`delete_if_empty`, service validation, stable errors, handwritten schemas/routes.
- GREEN: focused implementation suite — `30 passed`; API follow-up after route compatibility repair — `5 passed`.
- TRIANGULATE: added cross-group FK rejection and archived/missing/malformed/current-outing mutation cases; combined persistence/outing/API/service/WebSocket suite — `51 passed`, `1` existing deprecation warning.
- TRIANGULATE: migration upgrade/downgrade assertions passed; existing general expense rows remain `outing_id IS NULL`; linked outing deletion remains non-destructive.
- REFACTOR: affected Ruff — all checks passed; affected compileall — passed; no generated/mobile/web paths changed.
- Files changed by this slice: `backend/app/adapters/db/tables.py`, `backend/app/application/ports.py`, `backend/migrations/versions/0005_expense_outing.py`, `backend/app/adapters/db/repositories.py`, `backend/app/application/expense_service.py`, `backend/app/api/routes/expenses.py`, `backend/app/api/schemas/expenses.py`, `backend/app/api/errors.py`, three focused test files, and this progress file.
- Scoped path audit: only allowed handwritten backend/test/progress surfaces were touched by this slice; pre-existing web/mobile/contracts/redesign dirty paths were preserved.
- Fresh worker line accounting: `612` changed-line units including source/tests/progress, below the `790` cap; pre-existing PR3p/dirty bytes are excluded from this worker measurement.
- `tasks.md` was intentionally not edited; no task checkbox is claimed complete. Parent lifecycle/review/delivery gates remain deferred.
- Remaining exact unchecked PR3 rows:
- [ ] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->
- Remaining exact unchecked PR4 rows are unchanged: expense-association RED/GREEN/TRIANGULATE/REFACTOR/Verify remain deferred until parent reconciles the slice tracker.
- Produced phase result: `partial` apply progress for parent lifecycle; implementation evidence is recorded, but no persisted task completion is asserted.

## PR3r — OpenAPI snapshot-only contract correction

- Status: parent explicitly selected `group-outing-workspaces`; `web-professional-redesign` and `multi-currency` were ignored. Parent-held token: `sha256:ca2e3a7098895677d22978b7d799d94548a5721ba976396ba3b541d4bb830eab`.
- Boundary: only `contracts/openapi.json` and this progress file; no acquire, settle, reset, commit, push, clean, client generation, drift, or task checkbox changes.
- RED: pinned `export_contract(temp_contract)` produced a fresh temp candidate; measured temp→snapshot delta was exactly **22 units (0 additions, 22 deletions)**.
- GREEN: copied the temp candidate's exact bytes directly to `contracts/openapi.json`; no JSON was hand-edited.
- GREEN assertion: `ExpenseResponse.outing_id` and `ExpenseWriteRequest.outing_id` are nullable string fields; every outing operation remains tagged exactly `['outings']`.
- TRIANGULATE: raw byte parity **1/1** and normalized JSON parity **1/1** after copy.
- TRIANGULATE: focused API tests — `python -m pytest backend/tests/integration/api/test_expense_derived_routes.py backend/tests/integration/api/test_outing_routes.py -q` — **11 passed**.
- TRIANGULATE: affected Ruff — **All checks passed**; affected `compileall` — **passed with no output**.
- REFACTOR: preserved generated bytes and whitespace; no backend, web, mobile, redesign, or other paths changed. `tasks.md` remained untouched.
- Result: **success for bounded PR3r contract snapshot task**; broader PR3 behavior, generated clients, drift, and parent lifecycle remain deferred.

## PR3s — Native bounded generated expense-model slice (`pr3s-web-generated-expense-models`)

- Boundary: only `web/src/generated/api/models/ExpenseResponse.ts`, `web/src/generated/api/models/ExpenseWriteRequest.ts`, and this progress file; `tasks.md` remained untouched. No backend, contract snapshot, mobile, handwritten web, redesign, commit, push, reset, clean, review, or delivery operation.
- RED: pinned `backend.scripts.check_contract_drift.generate_clients` against `contracts/openapi.json` produced the stale-model delta before copy: `ExpenseResponse.ts` **8** normalized changed-line units and `ExpenseWriteRequest.ts` **8**, total **16**, below the hard **790** cap; no copy would occur above the cap.
- GREEN: copied the generator bytes directly after the pre-copy gate; both models now expose nullable `outingId` mapping to `outing_id`; no hand edit or formatter was used.
- TRIANGULATE: fresh pinned TypeScript generation and comparison passed **2/2 raw parity** and **2/2 normalized parity**.
- TRIANGULATE: `npm --prefix web run typecheck` — **passed**. `npm --prefix web run test` — first 120-second attempt timed out after two files; rerun with a 300-second timeout passed **12 files / 86 tests**, with the existing React `act(...)` warning.
- REFACTOR: generator whitespace warning retained by direct-copy policy: trailing whitespace is present in generated output (including header and blank/template lines); no host formatter rewrite was observed and no generated whitespace was hand-fixed. The generator also emitted its existing option-type warning (`The value (generator's option) must be either boolean or string`).
- Result: **success for bounded PR3s**; no task checkbox was marked complete and parent lifecycle remains deferred.

## PR3s correction — generator bytes restored after host formatting

- Re-read both selected models after automated formatting rewrote them, reran the pinned `typescript-fetch` generator against `contracts/openapi.json` in a temporary directory, and copied only exact generated bytes back to the two model paths.
- Fresh verification: raw parity **2/2**, normalized parity **2/2**, and `npm --prefix web run typecheck` **passed**. No other path or task checkbox changed.

## PR3t — Native bounded mobile generated expense-model slice (`pr3t-mobile-generated-expense-models`)

- Boundary: only `mobile/lib/generated/api/lib/src/model/expense_response.dart`, `expense_response.g.dart`, `expense_write_request.dart`, `expense_write_request.g.dart`, plus this progress file. No task checkbox changed; `web-professional-redesign` and all unrelated dirty/untracked paths were preserved.
- RED: generated `dart-dio` output from the current `contracts/openapi.json` with `serializationLibrary=json_serializable`, applied `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, and `_normalize_mobile_auth_test`, then ran `_build_mobile_parts` in temporary output. Pre-copy normalized delta was **109 units**: `expense_response.dart` **16** (+16/-0), `expense_response.g.dart` **3** (+3/-0), `expense_write_request.dart` **20** (+18/-2), and `expense_write_request.g.dart` **70** (+40/-30). The hard **790-unit** stop was not triggered; copy proceeded only after this gate.
- GREEN: copied exact generator/build-runner bytes only for the four selected files. Immediate post-copy parity passed **4/4 raw** and **4/4 normalized**.
- TRIANGULATE: `cd mobile/lib/generated/api && dart analyze lib/src/model/expense_response.dart lib/src/model/expense_response.g.dart lib/src/model/expense_write_request.dart lib/src/model/expense_write_request.g.dart` — **No issues found**. Focused tests `dart test test/expense_response_test.dart test/expense_write_request_test.dart` — **12 tests passed**.
- TRIANGULATE: status delta captured before/after copy contained no unexpected new paths; selected output status was present for all four files. No docs, tests, manifests, other mobile outputs, source, contract, web, redesign, or task files were copied or edited.
- REFACTOR: generator reported `DART_POST_PROCESS_FILE` unset, so host post-formatting was not applied; `git diff --check -- <four selected files>` exited **2** only for generator-produced trailing whitespace in the two model outputs and existing LF→CRLF conversion warnings. No formatting or generated-file repair was performed.
- Remaining mobile generated drift is intentionally deferred: this bounded slice does not claim full mobile regeneration, contract drift, or broad PR3 completion. The remaining generated outputs stay under their existing dirty/stale ownership boundaries.
- Produced result: **success for bounded PR3t**; selected delta, direct-copy parity, focused Dart analysis/tests, host-formatting risk, and path audit are recorded. Parent lifecycle/review/delivery operations remain deferred.

## PR3u — Native bounded mobile generated outing-model batch M1 (`pr3u-mobile-generated-outing-models`)

- Boundary: exactly the nine generated outing documentation/model/serialization/test paths assigned for M1, plus this progress file. No manifest, API source, other generated output, backend, web, contract, task, redesign, or unrelated path was copied or edited.
- RED: ran the pinned `dart-dio` generator with `serializationLibrary=json_serializable` against the current `contracts/openapi.json` in temporary output, applied `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, and `_normalize_mobile_auth_test`, then ran `_build_mobile_parts` from the temporary package. Generator-only structural slice: no meaningful handwritten behavior RED applies. Pre-copy normalized changed-line units were **752**: `OutingResponse.md` 21, `OutingsApi.md` 372, `OutingWriteRequest.md` 15, `outing_response.dart` 152, `outing_response.g.dart` 55, `outing_write_request.dart` 56, `outing_write_request.g.dart` 19, `outing_response_test.dart` 46, and `outing_write_request_test.dart` 16. The hard **790-unit** stop was not triggered.
- GREEN: copied only the nine selected files directly from temporary normalized/build-runner output. Immediate post-copy parity passed **9/9 raw** and **9/9 normalized**; temporary output cleanup completed on scope exit.
- TRIANGULATE: `cd mobile/lib/generated/api && dart analyze lib/src/model/outing_response.dart lib/src/model/outing_response.g.dart lib/src/model/outing_write_request.dart lib/src/model/outing_write_request.g.dart` — **No issues found**. The requested focused `dart test test/outing_response_test.dart test/outing_write_request_test.dart` was run against the bounded repository copy but failed during loading because the intentionally excluded stale `lib/openapi.dart` manifest does not yet export the new outing models. No manifest was copied outside the exact M1 list.
- TRIANGULATE audit: exact selected-path status audit reported only the nine generated M1 files (plus the allowed progress path); no other output was copied. Generator whitespace was preserved; no formatter or manual generated-file repair was run.
- REFACTOR: not applicable to generated structural output; no task checkbox changed. The pinned build emitted only its known warnings that `--delete-conflicting-outputs` is ignored by the installed runner and that the generated `json_annotation` constraint is broader than the resolved version.
- Result: **partial** — the bounded 752-unit generation/copy/parity/analysis gate passed, while the repository-local focused test command remains blocked by the excluded API manifest. The next mobile generated batch must include the manifest/API export before these copied scaffold tests can load.

## PR3v — Native bounded mobile generated outing-API batch M2 (`pr3v-mobile-generated-outing-api`)

- Boundary: exactly the seven requested generated paths plus this progress file: `lib/src/api/outings_api.dart`, `test/outings_api_test.dart`, `lib/openapi.dart`, `lib/src/api.dart`, `lib/src/deserialize.dart`, `README.md`, and `.openapi-generator/FILES`. No model, documentation, manifest, backend, web, contract, task, redesign, or unrelated path was copied or edited.
- RED/parity gate: generated `dart-dio` with `serializationLibrary=json_serializable` from the current corrected `contracts/openapi.json` in temporary output; applied `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, `_normalize_mobile_auth_test`; ran `_build_mobile_parts` from the generated package. Selected normalized delta was **720** units: `outings_api.dart` 610, `outings_api_test.dart` 74, `openapi.dart` 5, `api.dart` 7, `deserialize.dart` 6, `README.md` 9, `.openapi-generator/FILES` 9. The hard **790-unit** stop was not triggered.
- GREEN: copied exact generator/build-runner bytes only for the seven selected paths. Raw parity **7/7** and normalized parity **7/7**; temporary output cleanup passed.
- TRIANGULATE: `cd mobile/lib/generated/api && dart analyze lib/openapi.dart lib/src/api.dart lib/src/deserialize.dart lib/src/api/outings_api.dart lib/src/model/outing_response.dart lib/src/model/outing_response.g.dart lib/src/model/outing_write_request.dart lib/src/model/outing_write_request.g.dart` — **No issues found**. Focused `dart test test/outing_response_test.dart test/outing_write_request_test.dart test/outings_api_test.dart` — **15 tests passed**.
- Exact path audit: status contained only the seven selected generated paths plus this progress path within the allowed surfaces; no unexpected selected-scope path. Generator/build warnings were preserved as tool output; no generated bytes were hand-edited or formatted.
- Remediation binding for parent settlement: **`--remediates-evidence-revision sha256:063174431270c75d404dc0b9a9a983c09c3813524d5eb1e38c4f9498719e059f`**. No task checkbox, commit, push, reset, clean, lifecycle, or review operation was run.
- Result: **success for bounded PR3v**; full mobile drift and parent lifecycle remain deferred.

## PR3w — Native bounded mobile generated-client batch (`pr3w-mobile-generated-batch`)

- Boundary: exactly the eight paths enumerated in the delegated allowlist below, plus this progress file; no other generated output, docs, tests, manifests, model files, metadata, contract, backend, web, task, redesign, or unrelated path was copied.
- RED/parity gate: generated `dart-dio` output from the current `contracts/openapi.json` with `serializationLibrary=json_serializable` into temporary output; applied `_normalize_mobile_pubspec`, `_normalize_mobile_api_imports`, and `_normalize_mobile_auth_test`; ran `dart pub get` and `dart run build_runner build --delete-conflicting-outputs` from the temporary generated package.
- Pre-copy normalized delta: **414 units** (`+285/-129`), below the hard **790-unit** cap. Per-path units: `doc/ExpenseResponse.md` 1; `doc/ExpenseWriteRequest.md` 1; `lib/src/model/expense_contributor_request.g.dart` 21; `lib/src/model/group_create_request.dart` 36; `lib/src/model/group_summary_response.dart` 240; `lib/src/model/session_identity_response.dart` 105; `test/expense_response_test.dart` 5; `test/expense_write_request_test.dart` 5.
- GREEN: copied exact generator/build-runner bytes only for those eight selected paths. Immediate post-copy parity was **8/8 raw** and **8/8 normalized**; temporary output remained isolated from the repository.
- TRIANGULATE: `cd mobile/lib/generated/api && dart analyze lib/src/model/expense_contributor_request.g.dart lib/src/model/group_create_request.dart lib/src/model/group_summary_response.dart lib/src/model/session_identity_response.dart` — **No issues found**.
- TRIANGULATE: `cd mobile/lib/generated/api && dart test test/expense_response_test.dart test/expense_write_request_test.dart` — **14 tests passed**.
- Exact path audit: status contained only the eight selected generated paths plus this progress path within the delegated surfaces; no other output was copied. Generator/build warnings were preserved; no formatter or manual generated-file repair was run.
- The installed build runner warned that `--delete-conflicting-outputs` is ignored and that the generated `json_annotation` constraint is broader than the resolved version; the build nevertheless completed successfully and wrote serialization output.
- No task checkbox, commit, push, reset, clean, review/lifecycle operation, or unrelated path was touched. Full mobile drift and parent lifecycle remain deferred.
- Result: **success for bounded PR3w**; selected generation, normalized cap gate, direct-copy parity, focused analysis/tests, and exact path audit passed.

## PR3x — Native bounded web generated API batch (`pr3x-web-generated-batch`)

- Boundary: exactly `web/src/generated/api/apis/AuthApi.ts`, `BalancesApi.ts`, `ExpensesApi.ts`, plus this progress file. No other generated output, web source/test, backend, mobile, contract, task, redesign, or unrelated path was copied or edited.
- RED/parity gate: used the pinned `typescript-fetch` generator through `backend.scripts.check_contract_drift._run_generator` and `_normalize_web_api_paths` against corrected `contracts/openapi.json` in temporary output. Normalized selected delta was **554 units**: AuthApi **150** (+58/-92), BalancesApi **62** (+26/-36), ExpensesApi **342** (+122/-220), below the hard **790-unit** stop.
- GREEN: copied exact temporary generated bytes only for the three selected API files. Immediate raw parity **3/3** and normalized parity **3/3**.
- TRIANGULATE: fresh post-test pinned generation comparison remained raw **3/3** and normalized **3/3**; `npm --prefix web run typecheck` passed; `npm --prefix web run test` passed (**12 files / 86 tests**) with the existing React `act(...)` warning.
- Exact path audit: selected status contains only the three API files plus this allowed progress file; existing `GroupsApi.ts`, `apis/index.ts`, and `OutingsApi.ts` statuses were preserved and not copied. No task checkbox changed.
- REFACTOR: generator whitespace and line endings were preserved by direct byte copy; no formatter or generated-file hand edit was run. Generator emitted its existing option-type warning and no post-processor was enabled.
- Result: **success for bounded PR3x**; normalized cap, direct-copy parity, typecheck, web tests, and exact path audit passed. Parent lifecycle and full contract drift remain deferred.

## PR3y — Native bounded web generated API batch (`pr3y-web-generated-api-batch`)

- Boundary: exactly `web/src/generated/api/apis/GroupsApi.ts`, `web/src/generated/api/apis/HealthApi.ts`, and this progress file. No other generated output, web source/test, backend, mobile, contract, task, redesign, or unrelated path was copied.
- RED/cap gate: pinned `typescript-fetch` generation from corrected `contracts/openapi.json` through `_run_generator` and `_normalize_web_api_paths` in temporary output. Pre-copy normalized selected delta was **350 units** (`GroupsApi.ts` 304: +124/-180; `HealthApi.ts` 46: +23/-23), below the hard **790** cap.
- GREEN: copied exact normalized generator bytes only to the two selected API paths; no formatter or manual generated edit was used.
- TRIANGULATE: immediate and fresh post-test raw parity **2/2** and normalized parity **2/2**; `npm --prefix web run typecheck` passed; focused workspace tests passed (**1 file / 7 tests**); full serial web tests passed (**12 files / 86 tests**), with the existing React `act(...)` warning.
- Exact path audit: only the two selected API files and this progress file appear within the allowed surfaces. Generator whitespace and warnings were preserved; no task checkbox changed.
- Result: **success for bounded PR3y**; parent lifecycle and full contract drift remain deferred.

## PR3z — Native bounded web generated OutingsApi batch (`pr3z-web-generated-outings`)

- Boundary: exactly `web/src/generated/api/apis/OutingsApi.ts` plus this progress file. No other generated output, web source/test, backend, mobile, contract, task, redesign, or unrelated path was copied or edited.
- RED/cap gate: exported the corrected contract with `export_contract`, ran the pinned `typescript-fetch` generator through `_run_generator(..., "supportsES6=true")`, and applied `_normalize_web_api_paths` in temporary output. Pre-copy normalized delta was **731 units** (604 → 463 lines), below the hard **790-unit** stop.
- GREEN: copied exact temporary generated bytes only to `OutingsApi.ts`; immediate raw parity **1/1** and normalized parity **1/1**, with matching SHA-256 `41891ab29a24de2adfb1245e6ebb800fad611cb848e87c6996a2f769c5601dce`.
- TRIANGULATE: `npm --prefix web run typecheck` passed; focused `npm --prefix web run test -- --run tests/app/workspace-shell.test.tsx` passed (**1 file / 7 tests**) with the existing React `act(...)` warning.
- Exact path audit: only `OutingsApi.ts` and this progress file are attributable to this batch; all pre-existing dirty paths were preserved. No task checkbox changed.
- REFACTOR: generator whitespace and line endings were preserved by direct byte copy; no formatter or generated-file hand edit was run. Full contract drift and mobile generation remain deferred.
- Result: **success for bounded PR3z**; normalized cap, direct-copy parity, typecheck, focused tests, and exact path audit passed.

## PR3aa — Native bounded web generated ParticipantsApi batch (`pr3aa-web-generated-participants-api`)

- Boundary: exactly `web/src/generated/api/apis/ParticipantsApi.ts` plus this progress file. No other generated output, backend, mobile, contract, web source/test, task, redesign, or unrelated path was copied or edited.
- RED/cap gate: pinned `typescript-fetch` generation from corrected `contracts/openapi.json` into temporary output, followed by `_normalize_web_api_paths`. Pre-copy normalized delta was **646 units**, below the hard **790-unit** stop.
- GREEN: copied exact normalized bytes only to `ParticipantsApi.ts`; immediate raw parity **1/1** and normalized parity **1/1**. SHA-256: `a25c49edf92dbaab50ab79304832bcb7db5c75775698a69357d062bd322950b2`.
- TRIANGULATE: post-test fresh generation remained raw parity **1/1** and normalized parity **1/1** with byte equality; `npm --prefix web run typecheck` passed; focused `npm --prefix web run test -- --run tests/features/participants/participants.test.tsx` passed (**1 file / 10 tests**).
- Exact path audit: only `ParticipantsApi.ts` and this progress path are attributable to this batch; pre-existing generated dirty paths were preserved. Temporary output was isolated and cleaned; no generated formatter or hand edit was run.
- Result: **success for bounded PR3aa**; normalized cap, direct-copy parity, typecheck, focused tests, and exact path audit passed. Parent lifecycle and full contract drift remain deferred.

## PR3ab — Native bounded web generated model batch (`pr3ab-web-generated-models`)

- Boundary: exactly `ExpenseResponse.ts`, `ExpenseWriteRequest.ts`, `GroupCreateRequest.ts`, `OutingResponse.ts`, and `OutingWriteRequest.ts`, plus this progress file. No other generated, backend, mobile, handwritten web, contract, task, redesign, or unrelated path was copied.
- RED/cap gate: pinned `typescript-fetch` generation from corrected `contracts/openapi.json` through `_run_generator` and `_normalize_web_api_paths` in temporary output. The selected delta measured `702` units with the whitespace-at-EOL-insensitive numstat gate (`245 + 152 + 63 + 179 + 63`), below the hard **790-unit** cap; the supplied estimate was `712` units (`247 + 154 + 65 + 181 + 65`).
- GREEN: copied exact temporary generator bytes only to the five selected model paths. Immediate parity passed **5/5 raw** and **5/5 normalized**; temporary output was cleaned.
- TRIANGULATE: `npm --prefix web run typecheck` passed; focused tests (`expenses.test.tsx`, `workspace-shell.test.tsx`) passed (**2 files / 14 tests**); full serial `npm --prefix web run test -- --no-file-parallelism` passed (**12 files / 86 tests**), with the existing React `act(...)` warning.
- Exact path audit: status contained exactly the five selected model paths plus this progress path (**6/6**, no unexpected path). No formatter, hand edit, task checkbox, contract, mobile output, commit, push, reset, clean, or lifecycle operation was run.
- Result: **success for bounded PR3ab**; generated model parity, typecheck, focused/full serial tests, cap gate, and exact path audit passed. Full contract drift and parent lifecycle remain deferred.

## PR3ac — Native bounded web generated SettlementApi batch (`pr3ac-web-generated-settlement-api`)

- Boundary: exactly `web/src/generated/api/apis/SettlementApi.ts` plus this progress file. No other generated output, backend, mobile, handwritten web, contract, task, redesign, or unrelated path was copied.
- RED/cap gate: pinned `typescript-fetch` generation from corrected `contracts/openapi.json` through temporary output and `_normalize_web_api_paths`; pre-copy normalized delta was **63 units** (`+26/-37`), below the hard **790** stop.
- GREEN: copied exact normalized generator bytes only to `SettlementApi.ts`; immediate and fresh post-copy parity passed **1/1 raw** and **1/1 normalized**.
- TRIANGULATE: `npm --prefix web run typecheck` passed; focused `npm --prefix web run test -- --run tests/features/settlement/settlement.test.tsx` passed (**1 file / 2 tests**).
- Exact path audit: only `SettlementApi.ts` and this progress path are attributable to this batch; all pre-existing dirty paths were preserved. No formatter, hand edit, task checkbox, commit, push, reset, clean, or lifecycle operation was run.
- Result: **success for bounded PR3ac**; full generated drift and parent lifecycle remain deferred.

## PR3ad — Alembic harness revision expectation correction

- Updated `backend/tests/test_alembic_harness.py` to include the existing `0005_expense_outing.py` revision after `0004_outing.py`; no migration or application code changed.
- Focused harness: `python -m pytest backend/tests/test_alembic_harness.py -q` — **1 passed**.
- Complete PR3 backend behavior/persistence suite: `python -m pytest backend/tests/integration/api/test_outing_routes.py backend/tests/integration/api/test_workspace_routes.py backend/tests/integration/api/test_expense_derived_routes.py backend/tests/integration/persistence/test_outing_tables.py backend/tests/integration/persistence/test_auth_tables.py backend/tests/integration/persistence/test_source_tables.py backend/tests/unit/application/test_outing_service.py backend/tests/unit/application/test_workspace_service.py backend/tests/unit/application/test_expense_service.py -q` — **84 passed**.
- Backend lint: `python -m ruff check backend` — **All checks passed**.
- Exact path audit: only the two allowed surfaces are attributable to this bounded correction; all pre-existing dirty and untracked paths were preserved. No task checkbox, migration, generated client, UI, commit, push, reset, clean, or lifecycle operation was run.

## PR3ae — Contract drift verification-gate correction

- Added an optional relative-path ignore facility to `compare_directories`; only the mobile drift comparison ignores `pubspec.lock` and the `.dart_tool/` subtree. Other generated files remain subject to presence and content comparisons.
- Focused test coverage proves both transient mobile paths are ignored and ordinary added/removed files still report drift.
- `python -m pytest backend/tests/test_openapi_contract.py -q` — **12 passed**.
- `python -m backend.scripts.check_contract_drift --cwd .` — **Contract and generated clients are drift-free**.
- `python -m ruff check backend` — **All checks passed**.
- Exact path audit: only `backend/scripts/check_contract_drift.py`, `backend/tests/test_openapi_contract.py`, and this progress path were edited for PR3ae; all pre-existing dirty/untracked paths were preserved. No generated client, migration, product, UI, task, commit, push, reset, clean, or lifecycle operation was run.
- Result: **success for bounded PR3ae**; parent lifecycle remains deferred.

## PR4a — Expense read-scope filtering

### Status and boundary

- Consumed parent-resolved status: active change `group-outing-workspaces`; explicit PR4a selection overrides the stale ambiguous native snapshot. `actionContext.mode=repo-local`, workspace root and allowed edit root are the repository root.
- Bounded slice: read-only expense scopes only — default all, `scope=general`, and exact `outing_id`. Existing nullable association, composite same-group integrity, service mutation validation, and default all-expense behavior are preserved.
- Workload guard: `Decision needed before apply: No`; chained delivery is resolved by the parent to PR4a; hard stop is 400 changed lines. No parent-owned lifecycle, review, receipt, validation, commit, push, reset, or clean operation was run.

### TDD Cycle Evidence

| Task | Test file | Layer | Safety net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PR4a scope filtering | `backend/tests/integration/api/test_expense_derived_routes.py`, `backend/tests/integration/persistence/test_source_tables.py` | API/integration persistence | ✅ 32 focused tests passed before edits | ✅ Added all/general/exact/malformed-scope and foreign-outing isolation tests; focused run failed as expected (`2 failed`) before implementation | ✅ Focused scope tests passed (`15 passed`) after port/repository/route implementation | ✅ Mixed general/two-outing data, exact foreign-group filter, malformed query, and no mutation state covered | ✅ Ruff, compileall, focused regression, contract generation, and drift passed |

### Implementation and contract evidence

- `ExpenseRepository` now exposes keyword-only `outing_filter` and `general_only` scope controls; SQLAlchemy keeps the group predicate and applies exact nullable/general predicates before stable ordering results are returned.
- The expense list route accepts generated-contract query parameters `scope` (`all` or `general`) and `outing_id`; invalid scope values are rejected by FastAPI before repository/service execution. Reads do not publish invalidation.
- Handwritten FastAPI → OpenAPI → generated-client flow completed. `contracts/openapi.json` was exported, and only generated `ExpensesApi` outputs were copied from pinned temporary generator/build-runner output; no generated file was hand-edited.
- Generated parity: web `1/1`, mobile `3/3`; contract and generated clients are drift-free.

### Verification and audit

- Safety net: `python -m pytest backend/tests/unit/application/test_expense_service.py backend/tests/integration/api/test_expense_derived_routes.py backend/tests/integration/persistence/test_source_tables.py backend/tests/integration/persistence/test_outing_tables.py backend/tests/test_alembic_harness.py -q` — **32 passed**.
- Focused GREEN/TRIANGULATE: same command — **34 passed**.
- Ruff: `python -m ruff check` on all touched handwritten backend/test files — **All checks passed**; compileall passed.
- Contract gate: `python -m backend.scripts.check_contract_drift --cwd .` — **Contract and generated clients are drift-free**.
- Changed-path/line audit: only the allowed backend ports/adapter/route, focused persistence/API tests, generated contract/client outputs, and this progress file changed; `.pi/gentle-ai/sdd-preflight.json` remains unrelated untracked state. Final authored diff is **under 400 changed lines** (exact audit recorded after append).

### Task and lifecycle state

- No broad PR4 RED/GREEN/TRIANGULATE/REFACTOR/Verify task row was marked complete; those rows remain unchecked because this is only PR4a. Parent lifecycle actions remain deferred and the next recommendation is `parent-lifecycle` after the bounded candidate is reviewed.

## PR4 — Final cohesive nullable expense-association candidate

### Status and workload

- Consumed parent-resolved status: active change `group-outing-workspaces`; the stale native ambiguity is overridden by the explicit user selection. `artifactStore=openspec`, `actionContext.mode=repo-local`, workspace root and allowed edit root are the repository root.
- Delivery decision: explicit `size:exception`; no PR4b or additional PR slice. PR4a read filtering and this completion remain one cohesive PR4 candidate. No PR5+ task, redesign/mobile UI, official fixture, WebSocket payload, `.pi/` state, commit, push, reset, clean, review, receipt, or delivery gate was touched.

### TDD Cycle Evidence

| Task | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- |
| PR4 | Focused collection first failed on the new `CreateTable` import; after collection repair, four new assertions exposed test-seam/expectation defects. | Focused suite reached **39 passed** after test corrections and the minimum route fix required by the full regression. | Covered null/default/general/exact reads, same-group/cross-group/malformed references, archived create/edit/delete rejection, archived history reads, no mutation/no invalidation, composite FK, migration survival, old-client compatibility, and official values. | Ruff and full backend passed; drift passed; no contract shape changed in this completion, so no regeneration copy was run. |

### Completed tasks and persisted state

- RED, GREEN, TRIANGULATE, REFACTOR, and Verify are now visibly `[x]` for exactly the five PR4 implementation rows in `tasks.md`; PR5+ and parent rows remain unchecked.
- Existing nullable association/composite-FK/service/migration implementation was preserved. The only handwritten behavior correction was moving `ExpenseResponse` construction outside the beneficiary loop; the full suite had exposed that it truncated official beneficiaries and residual cases.

### Files changed or preserved

- Handwritten/test changes: `backend/app/application/ports.py`, `backend/app/adapters/db/repositories.py`, `backend/app/api/routes/expenses.py`, `backend/tests/unit/application/test_expense_service.py`, `backend/tests/integration/api/test_expense_derived_routes.py`, `backend/tests/integration/persistence/test_source_tables.py`, `backend/tests/integration/persistence/test_outing_tables.py`.
- Preserved PR4a generated/contract paths: `contracts/openapi.json`, `web/src/generated/api/apis/ExpensesApi.ts`, `mobile/lib/generated/api/doc/ExpensesApi.md`, `mobile/lib/generated/api/lib/src/api/expenses_api.dart`, `mobile/lib/generated/api/test/expenses_api_test.dart`.
- Artifacts: this file and `openspec/changes/group-outing-workspaces/tasks.md`. `uow.py`, migration, schemas, errors, and Alembic harness were verified but not reimplemented or changed in this completion.

### Exact verification

- Focused: `python -m pytest backend/tests/unit/application/test_expense_service.py backend/tests/integration/api/test_expense_derived_routes.py backend/tests/integration/persistence/test_source_tables.py backend/tests/integration/persistence/test_outing_tables.py backend/tests/test_alembic_harness.py -q` — **39 passed**.
- Full backend: `python -m pytest backend/tests -q` — after the minimum route correction, **291 passed, 1 warning**.
- Official regression: `python -m pytest backend/tests/acceptance/test_da_01_samaipata.py backend/tests/acceptance/test_da_02_residual.py -q` — **9 passed**.
- Lint: `python -m ruff check backend` — **All checks passed**.
- Contract: `python -m backend.scripts.check_contract_drift --cwd .` — **Contract and generated clients are drift-free**; temporary pinned generation/serialization completed and repository generated bytes were not hand-edited.
- Migration/FK: `0005` upgrade/downgrade preserved existing general rows with `outing_id IS NULL`; composite FK rejected a cross-group row; PostgreSQL dialect compilation asserted `FOREIGN KEY(outing_id, group_id) REFERENCES outings (id, group_id) ON DELETE RESTRICT`; archived history and rollback/no-publish tests passed.
- No live PostgreSQL service was available locally (`DATABASE_URL` unset and Docker engine unavailable), so no live PostgreSQL connection result is claimed; dialect DDL plus configured FK integration proof passed.
- Path audit: all modified tracked paths are inside the user allowlist. Pre-existing untracked `.pi/gentle-ai/sdd-preflight.json` was preserved.
- Exact changed-line audit from `HEAD`: **668 tracked changed-line units** (additions plus deletions), under the PR4 `<=760` target; this includes the preserved PR4a bytes and final task/progress evidence.
- `git diff --check` is clean for handwritten source/tests/artifacts; it reports only pre-existing generator trailing whitespace in the preserved PR4a mobile outputs (`ExpensesApi.md` and `expenses_api.dart`). Generated bytes were not hand-edited.

### Remaining tasks (exact unchecked rows)

```text
- [ ] RED — Add derived-service/API tests proving group scope includes every general and outing-linked expense exactly once, outing scope filters exact `outing_id`, general expenses never appear in outing totals, participants remain the authorized group set, sums equal zero, and transfer order is stable. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement optional outing scope in server-derived balance/settlement reads and REST schemas; keep all arithmetic, residual allocation, exact-zero checks, and formatting authority on the server/domain services. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add mixed-scope, empty-outing, archived-outing, cross-group, stale-cache, and official Samaipata regression cases with exact expected balances/transfers; assert no derived state is persisted. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Regenerate contract outputs from handwritten API changes and add scope-aware query-key definitions without client calculations or WebSocket payload changes. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full monetary tests, lint, contract drift, and final <=720 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner generation/status/revoke/regenerate, hash-only persistence, reusable consumption by existing sessions, prior-token invalidation, anonymous/invalid/duplicate joins, exact-one participant choice, same-group link/create, cross-group choice rejection, token non-disclosure, and atomic rollback; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement one current SHA-256-hashed 256-bit URL-safe token per group, owner-protected lifecycle endpoints, authenticated consume transaction, group-scoped account-participant link table, and explicit existing-participant-or-new-participant command with stable errors. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add lock/concurrency, CSRF/origin, replay/reusable-code, active-membership conflict, participant uniqueness, no-log/no-summary-secret, post-commit one-frame, and no-frame-on-failure tests; preserve account/participant identity separation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate OpenAPI/TypeScript/Dart outputs through the pinned workflow, keeping plaintext code only in generation response and never hand-editing generated trees. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/security/migration tests, lint, contract drift, secret-output audit, path audit, and final <=800 changed-line count; split before apply if forecast exceeds the cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner removal, member leave, ended-member denial across every group resource, participant-link inactivity, preserved participant/expense/outing history, rejoin eligibility, member forbidden removal, and final-owner protection. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement nullable `ended_at` active-membership semantics, owner-remove/member-leave operations, immutable owner safety, inactive link handling, active-membership listing, and one post-commit group invalidation per successful mutation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add concurrent exit/remove, stale sessions, cross-group account IDs, final-owner conflict, rejoin with a new explicit link choice, rollback/no-invalidation, and official fixture regression coverage. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Reconcile handwritten API schemas/routes, regenerate clients only where the frozen contract changes, run drift, and keep role derivation server-owned. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full regression tests, migration proof if applicable, lint, contract drift, path audit, and final <=740 changed-line count. <!-- sdd-owner: implementation -->
- [ ] RED — Add behavior tests for outing/general expense separation, outing archived read-only state, server-provided scoped balances/settlement, participant detail, loading/empty/forbidden/error states, route/deep-link protection, and cache invalidation/refetch; audit redesign paths before running. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement additive laptop-first pages/states for outing detail/expenses, general expenses, group summary, participant detail, balances, and settlement using generated client data and shared integer-cent formatter; perform no client monetary arithmetic. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Cover mixed-scope no-double-counting, stale selected group/outing, archived history, WebSocket outage/manual refresh, membership changes, Spanish accessible names, keyboard focus, visible state cues, and preserved legacy anchors. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Integrate through the protected shell without overwriting `web-professional-redesign`; remove only additive duplication, preserve query identity and REST authority, then rerun focused web tests. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact dirty-path audit, and final <=800 changed-line count; stop and split at a screen boundary if over cap. <!-- sdd-owner: implementation -->
- [ ] RED — Add tests for owner join-code display/regenerate/revoke/status secrecy, member/owner membership controls, leave/final-owner errors, forbidden actions, empty/error/recovery states, accessibility/laptop-first behavior, and official-flow preservation. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement group/membership settings, authenticated join-code consumption UI with explicit participant link/create choice, member removal/leave actions, Spanish copy, and safe protected recovery states using server-derived role/error responses. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add full regression cases for account selection, outing lifecycle, scoped expenses/derived results, invalidation-only WebSocket behavior, no public join/account creation, no token leakage, official Samaipata exact data/result, and all protected deep links. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Normalize source-mutating files before candidate freeze, preserve all redesign bytes/modes, remove no required acceptance coverage, and confirm the final web remains dependency-free with mobile UI out of scope. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, complete backend/web/contract/migration gates, manual laptop-first accessibility/browser flow, protected-path and generated-output audits, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->
- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
```

- Produced phase result: **success for PR4 apply**; only five PR4 implementation rows were checked. Parent lifecycle remains deferred; next recommendation is `parent-lifecycle`.
