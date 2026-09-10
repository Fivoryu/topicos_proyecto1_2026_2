# Tasks: Group Outing Workspaces

## Review Workload Forecast

| Field | Value |
| ------- | ------- |
| Estimated changed lines | 5,230–7,230 across 10 chained slices; each slice is bounded at 180–800 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 0 → PR 1 → PR 2 → PR 3 → PR 4 → PR 5 → PR 6 → PR 7 → PR 8 → PR 9 |
| Delivery strategy | exception-ok |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

## Delivery and ownership guardrails

- This plan is English technical artifact only; no implementation is complete and no task is pre-checked.
- Each slice is one writer, one bounded candidate, one reviewable PR, and one rollback boundary. The 800 changed-line limit counts additions plus deletions, including generated output; stop and split at the next handwritten API or screen boundary if the forecast rises above 800.
- The stack is `PR 0 → PR 1 → ... → PR 9`; each PR targets its predecessor and only the integrated tracker targets `main`. Do not mix this with `web-professional-redesign`.
- `openspec/project-context.md`, `openspec/specs/groups/spec.md`, `openspec/specs/api/spec.md`, `openspec/specs/persistence/spec.md`, `openspec/specs/expenses/spec.md` or its actual settlement-owning canonical spec, `openspec/specs/clients/spec.md`, and `docs/sdd-evolution.md` are living-policy targets for PR 0 only. Historical artifacts, `AGENTS.md`, and all `openspec/changes/web-professional-redesign/**` files are protected and must remain untouched.
- `contracts/openapi.json`, `web/src/generated/api/**`, and `mobile/lib/generated/api/**` are generated outputs. Change handwritten FastAPI sources first; never hand-edit generated files. Generated Dart changes are contract output only, not mobile UI/domain work.
- Before every web slice, audit paths and stop if a change would overwrite or discard dirty `web-professional-redesign` bytes. No reset, clean, reformat, or replacement of that work is permitted.
- Every runtime-bearing apply/verify unit must acquire and settle native SDD attempt authority with the slice label, evidence goal, and `--max-changed-lines` equal to its hard bound; do not store caller-authored counters in this file.

## PR 0 — Policy/spec synchronization

**Forecast:** 180–340 changed lines; hard maximum 800. **Dependency:** confirmed proposal, six change-local specs, and design. **Rollback:** revert only the new living-policy amendments before product code exists.

- [x] RED — Add acceptance wording/checks in the applicable OpenSpec validation inputs for multi-group creation/selection, authenticated reusable join, outing lifecycle, nullable outing derivation, membership history, laptop-first web scope, and Samaipata preservation; run the narrow artifact validation and record the expected pre-amendment failures. <!-- sdd-owner: implementation -->
- [x] GREEN — Amend only `openspec/project-context.md`, the owning canonical group/API/persistence/expense-settlement/clients specifications, and `docs/sdd-evolution.md` to record the accepted rules, supersession, ownership boundaries, authenticated-only join exception, and 800-line delivery constraint without rewriting history. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE — Validate that the amendments explicitly exclude public registration, email invitations, recovery, OAuth, expiry, approval queues, ownership transfer, mobile parity, new routing dependencies, client-side money/authorization, WebSocket payload changes, and redesign edits. <!-- sdd-owner: implementation -->
- [x] REFACTOR — Normalize the living-policy prose for traceability and confirm no archived path, `AGENTS.md`, official fixture, or redesign path changed; run strict OpenSpec validation. <!-- sdd-owner: implementation -->
- [x] Record the focused validation result, changed-path audit, exact line count, and rollback boundary; do not begin PR 1 if any protected path changed. <!-- sdd-owner: implementation -->

## PR 1 — Workspace backend foundation and account contract

**Forecast:** 620–790 changed-line units per bounded native slice; hard maximum 800 per slice. **Dependency:** PR 0 green. **Paths:** `backend/app/adapters/db/tables.py`, `backend/app/application/ports.py`, `backend/app/adapters/db/repositories.py`, `backend/app/adapters/db/uow.py`, workspace/auth services and schemas/routes under `backend/app/`, a new `backend/migrations/versions/` revision, backend tests, and generated contract outputs. **Rollback:** revert only workspace source/migration/contract files; preserve existing source rows and redesign.

- [x] Schema/migration foundation — Add nullable `GroupMembership.ended_at`, the `(account_id, ended_at, group_id)` active-membership index, and reversible `0003_workspace` migration from `0002_source`; cover the schema and migration shape with focused persistence assertions. <!-- sdd-owner: implementation -->
- [x] Membership repository/UoW foundation — Add active account membership listing, group-scoped lookup, create/reactivate/end primitives, server-owned owner counting, and transaction exposure; cover the adapters with focused persistence assertions. <!-- sdd-owner: implementation -->
- [x] Workspace service application slice — Implement account-scoped active listing, server-derived roles, selected-group membership recheck, validated names, atomic empty owner creation, and fake rollback coverage; leave API/contract wiring for later slices. <!-- sdd-owner: implementation -->
- [x] GroupRepository create primitive — Extend the group port and concrete SQLAlchemy adapter with a no-commit create that accepts application group records or ORM groups; cover record mapping, ORM preservation, and rollback visibility with focused persistence assertions. <!-- sdd-owner: implementation -->
- [x] Zero-group authenticated session identity — Allow an active account with no active membership to authenticate with an opaque persisted session and nullable compatibility identity (`active_group_id`/`role`), while rejecting malformed non-null membership records and preserving token-safe response behavior; cover login, session validation, and response schema with focused unit tests. <!-- sdd-owner: implementation -->
- [x] Workspace account collection API — Add account-scoped group list/create routes, additive summary schemas, request-scoped service wiring, and post-commit invalidation; cover authentication, CSRF/origin, stable errors, empty owner summaries, and selected-route compatibility. <!-- sdd-owner: implementation -->
- [x] Corrective session wire-contract schema — Replace the arbitrary nullable `SessionIdentityResponse.active_group_id` field with an explicit nullable string while preserving nullable roles and token-safe serialization; cover null/string output and invalid arbitrary values after failed generated-contract evidence. <!-- sdd-owner: implementation -->
- [x] RED — Add focused backend/API tests for account-scoped group listing, authenticated empty-group creation, owner/member derivation, zero child rows, zero-group sessions, cross-group denial, stale selected IDs, and compatibility of `204` anonymous/`200` authenticated/`401` unusable-cookie session behavior; run the affected tests and capture RED. <!-- sdd-owner: implementation -->
- [x] GREEN — Implement membership-aware repositories/services/routes and the additive migration so an account lists only active memberships, creates an empty owner/member group atomically, and every selected-group request rechecks membership and derives role server-side; preserve `active_group_id` only as the documented compatibility bootstrap. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE — Add two-group isolation, client-role-ignored, CSRF/origin, rollback/no-partial-create, owner-membership, refresh, and post-commit single-group invalidation tests; verify the official Samaipata source fixture is unchanged. <!-- sdd-owner: implementation -->
- [x] REFACTOR — Export `contracts/openapi.json`, regenerate TypeScript and Dart clients with the pinned commands, build generated Dart serialization only if required, update no generated file by hand, and run focused backend tests plus contract drift. <!-- sdd-owner: implementation -->
- [x] Verify separately with native attempt authority, `python -m pytest backend/tests -q` where applicable, `python -m ruff check backend`, migration upgrade/downgrade isolation, path audit, and final <=790 changed-line count for each bounded PR1 slice before stacking the next slice or PR 2. <!-- sdd-owner: implementation -->

## PR 2 — Workspace web foundation

**Forecast:** 560–780 changed lines; hard maximum 800. **Dependency:** PR 1 green and generated TypeScript contract available. **Paths:** additive modules under `web/src/` for navigation, query keys, group screens, and protected workspace composition plus focused `web/tests/**`; do not replace dirty redesign files. **Rollback:** revert only additive workspace modules and integration adapter.

- [x] RED — Add Testing Library tests for authenticated group list/create, zero-group state, one-group auto-selection, multi-group switching, stale/deep-link protection, query-key identity, cache clearing, and no protected render before session authentication; run affected Vitest files and capture RED. <!-- sdd-owner: implementation -->
- [x] GREEN — Implement the additive hash parser/serializer, protected group picker/create flow, selected-group summary/empty workspace, account/group/selection query keys, and cache reset/refetch transitions using the generated client without adding a router or client authorization. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE — Add session expiry/logout, forbidden selection, WebSocket outage/manual refresh, focus/accessible-name, Spanish empty/error/loading, and preserved `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo` behavior tests. <!-- sdd-owner: implementation -->
- [x] REFACTOR — Integrate only through an additive protected-shell seam after a changed-path audit proves no `web-professional-redesign` file is touched; preserve server-derived roles, CSRF flow, WebSocket signal-only handling, and existing anchors. <!-- sdd-owner: implementation -->
- [x] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact path audit, and final <=780 changed-line count. <!-- sdd-owner: implementation -->

## PR 3 — Outing lifecycle

**Forecast:** 610–790 changed lines; hard maximum 800. **Dependency:** PR 2 green. **Paths:** outing persistence/models/repositories/services/routes/schemas, a new `backend/migrations/versions/` revision, focused backend/API tests, generated contract outputs, and additive web outing list/detail consumers if needed for contract proof. **Rollback:** revert outing source and writes before durable outing data; otherwise hide writes and roll forward.

- [x] RED — Add tests for member create/edit of active outings, required trimmed names, group isolation, owner-only archive/unarchive, archived read-only behavior, owner delete of empty outings, and non-empty deletion conflict with preserved history; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [x] GREEN — Implement the `outings` source table, same-group integrity, lifecycle service/repository/API contract, stable errors, and post-commit invalidation while preserving optional informational dates only if present in the frozen contract. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE — Add cross-group IDs, stale route, duplicate/blank names, member forbidden actions, archived metadata/expense-write denial, rollback/no-invalidation, and migration upgrade/downgrade tests. <!-- sdd-owner: implementation -->
- [x] REFACTOR — Export OpenAPI and regenerate pinned TypeScript/Dart clients; update only handwritten consumers and verify the official fixture remains outing-free and unchanged. <!-- sdd-owner: implementation -->
- [x] Verify separately with native attempt authority, focused/backend/lint tests, migration proof, contract drift, path audit, and final <=790 changed-line count. <!-- sdd-owner: implementation -->

## PR 4 — Nullable expense association

**Forecast:** 560–760 changed lines; hard maximum 800. **Dependency:** PR 3 green. **Paths:** expense ORM/records/repositories/services/routes/schemas, outing composite constraints, a new `backend/migrations/versions/` revision, focused API/domain tests, generated contract outputs. **Rollback:** revert association writes/reads only; never detach linked expenses or silently convert them to general expenses.

- [x] RED — Add tests for `outing_id = null`, valid same-group association, cross-group rejection, malformed reference, archived-outing create/edit/delete rejection, default all-expense reads, general-only filtering, and atomic child-row validation; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [x] GREEN — Add nullable `expenses.outing_id`, composite same-group foreign-key protection, repository filters, schema serialization, and service validation while preserving integer cents, participant/contribution/beneficiary invariants, and existing general expenses as `NULL`. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE — Test PostgreSQL constraint enforcement, archived history readability, failed transaction/no invalidation, old client compatibility, official four-expense values, and migration survival of existing source rows. <!-- sdd-owner: implementation -->
- [x] REFACTOR — Export and regenerate the contract through the pinned workflow, build generated Dart serialization only when frozen models require it, run drift, and update no generated output manually. <!-- sdd-owner: implementation -->
- [x] Verify separately with native attempt authority, focused/backend/migration tests, lint, contract drift, path audit, and final <=760 changed-line count. <!-- sdd-owner: implementation -->

## PR 5 — Scoped derived balances and settlement

**Forecast:** 500–720 changed lines; hard maximum 800. **Dependency:** PR 4 green. **Paths:** `backend/app/application/derived_service.py`, balance/settlement route schemas and repositories, focused monetary tests, generated contract outputs, and additive web query-key seams only. **Rollback:** revert outing-derived reads while retaining source association and group-wide behavior.

- [x] RED — Add derived-service/API tests proving group scope includes every general and outing-linked expense exactly once, outing scope filters exact `outing_id`, general expenses never appear in outing totals, participants remain the authorized group set, sums equal zero, and transfer order is stable. <!-- sdd-owner: implementation -->
- [x] GREEN — Implement optional outing scope in server-derived balance/settlement reads and REST schemas; keep all arithmetic, residual allocation, exact-zero checks, and formatting authority on the server/domain services. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE — Add mixed-scope, empty-outing, archived-outing, cross-group, stale-cache, and official Samaipata regression cases with exact expected balances/transfers; assert no derived state is persisted. <!-- sdd-owner: implementation -->
- [x] REFACTOR — Regenerate contract outputs from handwritten API changes and add scope-aware query-key definitions without client calculations or WebSocket payload changes. <!-- sdd-owner: implementation -->
- [x] Verify separately with native attempt authority, focused/backend/full monetary tests, lint, contract drift, and final <=720 changed-line count. <!-- sdd-owner: implementation -->

## PR 6 — Authenticated join code and participant link

**Forecast:** 650–800 changed lines; hard maximum 800. **Dependency:** PR 5 green. **Paths:** join/link tables and models, repositories/services/routes/schemas, a new `backend/migrations/versions/` revision, cryptographic token utility, focused backend/API tests, generated contract outputs. **Rollback:** revoke/disable code operations while preserving memberships, links, participants, and history.

- [ ] RED — Add tests for owner generation/status/revoke/regenerate, hash-only persistence, reusable consumption by existing sessions, prior-token invalidation, anonymous/invalid/duplicate joins, exact-one participant choice, same-group link/create, cross-group choice rejection, token non-disclosure, and atomic rollback; run focused tests and capture RED. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement one current SHA-256-hashed 256-bit URL-safe token per group, owner-protected lifecycle endpoints, authenticated consume transaction, group-scoped account-participant link table, and explicit existing-participant-or-new-participant command with stable errors. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add lock/concurrency, CSRF/origin, replay/reusable-code, active-membership conflict, participant uniqueness, no-log/no-summary-secret, post-commit one-frame, and no-frame-on-failure tests; preserve account/participant identity separation. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Export and regenerate OpenAPI/TypeScript/Dart outputs through the pinned workflow, keeping plaintext code only in generation response and never hand-editing generated trees. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/security/migration tests, lint, contract drift, secret-output audit, path audit, and final <=800 changed-line count; split before apply if forecast exceeds the cap. <!-- sdd-owner: implementation -->

## PR 7 — Membership lifecycle

**Forecast:** 520–740 changed lines; hard maximum 800. **Dependency:** PR 6 green. **Paths:** membership model/repository/service/routes/schemas, migration only if `ended_at` was not delivered earlier, focused authorization/history/invalidation tests, generated contract outputs as needed. **Rollback:** disable leave/remove writes while preserving ended membership rows and all history.

- [ ] RED — Add tests for owner removal, member leave, ended-member denial across every group resource, participant-link inactivity, preserved participant/expense/outing history, rejoin eligibility, member forbidden removal, and final-owner protection. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement nullable `ended_at` active-membership semantics, owner-remove/member-leave operations, immutable owner safety, inactive link handling, active-membership listing, and one post-commit group invalidation per successful mutation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add concurrent exit/remove, stale sessions, cross-group account IDs, final-owner conflict, rejoin with a new explicit link choice, rollback/no-invalidation, and official fixture regression coverage. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Reconcile handwritten API schemas/routes, regenerate clients only where the frozen contract changes, run drift, and keep role derivation server-owned. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, focused/backend/full regression tests, migration proof if applicable, lint, contract drift, and final <=740 changed-line count. <!-- sdd-owner: implementation -->

## PR 8 — Web financial workspace

**Forecast:** 650–800 changed lines; hard maximum 800. **Dependency:** PRs 4, 5, and 7 green; generated TypeScript contract current. **Paths:** additive modules under `web/src/` and focused `web/tests/**` for outings, expenses, summary, participant detail, balances, and settlement. **Rollback:** revert this web slice only; retain backend source and redesign.

- [x] RED — Add behavior tests for outing/general expense separation, outing archived read-only state, server-provided scoped balances/settlement, participant detail, loading/empty/forbidden/error states, route/deep-link protection, and cache invalidation/refetch; audit redesign paths before running. <!-- sdd-owner: implementation -->
- [x] GREEN — Implement additive laptop-first pages/states for outing detail/expenses, general expenses, group summary, participant detail, balances, and settlement using generated client data and shared integer-cent formatter; perform no client monetary arithmetic. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE — Cover mixed-scope no-double-counting, stale selected group/outing, archived history, WebSocket outage/manual refresh, membership changes, Spanish accessible names, keyboard focus, visible state cues, and preserved legacy anchors. <!-- sdd-owner: implementation -->
- [x] REFACTOR — Integrate through the protected shell without overwriting `web-professional-redesign`; remove only additive duplication, preserve query identity and REST authority, then rerun focused web tests. <!-- sdd-owner: implementation -->
- [x] Verify separately with native attempt authority, `npm --prefix web run test`, `npm --prefix web run typecheck`, `npm --prefix web run build`, exact dirty-path audit, and final <=800 changed-line count; stop and split at a screen boundary if over cap. <!-- sdd-owner: implementation -->

## PR 9 — Web membership/settings and final integration

**Forecast:** 500–760 changed lines; hard maximum 800. **Dependency:** PR 8 green and redesign boundary preserved or explicitly landed on the integration base. **Paths:** additive web settings/membership/join-code screens and tests, final integration adapters, no `AGENTS.md`, historical artifact, or redesign overwrite. **Rollback:** revert final settings/integration files only; preserve server source/history and redesign.

- [ ] RED — Add tests for owner join-code display/regenerate/revoke/status secrecy, member/owner membership controls, leave/final-owner errors, forbidden actions, empty/error/recovery states, accessibility/laptop-first behavior, and official-flow preservation. <!-- sdd-owner: implementation -->
- [ ] GREEN — Implement group/membership settings, authenticated join-code consumption UI with explicit participant link/create choice, member removal/leave actions, Spanish copy, and safe protected recovery states using server-derived role/error responses. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE — Add full regression cases for account selection, outing lifecycle, scoped expenses/derived results, invalidation-only WebSocket behavior, no public join/account creation, no token leakage, official Samaipata exact data/result, and all protected deep links. <!-- sdd-owner: implementation -->
- [ ] REFACTOR — Normalize source-mutating files before candidate freeze, preserve all redesign bytes/modes, remove no required acceptance coverage, and confirm the final web remains dependency-free with mobile UI out of scope. <!-- sdd-owner: implementation -->
- [ ] Verify separately with native attempt authority, complete backend/web/contract/migration gates, manual laptop-first accessibility/browser flow, protected-path and generated-output audits, and final <=760 changed-line count. <!-- sdd-owner: implementation -->
- [ ] Preserve the exact normalized candidate and evidence for every slice, then hand the frozen stack to the parent for bounded lifecycle review and delivery gates; do not mark this task complete from planning alone. <!-- sdd-owner: parent -->

## Explicit decision gates and completion criteria

- A product decision is required before implementation if any frozen contract needs behavior outside the confirmed rules or bounded assumptions: token expiry/usage/multiple codes, ownership transfer, public/email invitation, participant merge, calendar semantics, router dependency, mobile UI/domain work, a new WebSocket payload, or destructive history rewrite. Stop at the affected slice; do not invent a substitute.
- A slice is complete only when its RED/GREEN/TRIANGULATE/REFACTOR evidence, focused and relevant full verification, migration/contract generation proof where applicable, changed-path audit, rollback boundary, native attempt settlement, and <=800 changed-line result are recorded. Only then may its checkbox be checked by the implementation actor.
- The integrated feature is complete only when all confirmed requirements are demonstrated without changing `AGENTS.md`, archived/historical artifacts, the official Samaipata fixture, generated files by hand, or any `web-professional-redesign` file, and when final verification proves server authorization, integer-cent monetary derivation, exact-zero settlement, protected sessions/CSRF, and invalidation-only WebSocket behavior.

## Parent-owned lifecycle actions

- [ ] Start or reuse the bounded review for the final frozen stacked candidate using `exception-ok` and `stacked-to-main`; confirm each slice has an independent dependency, verification, and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute post-apply lifecycle gates only after all implementation evidence, native attempt settlements, path/line audits, and final candidate freeze are available. <!-- sdd-owner: parent -->
