# Implementation tasks: web professional redesign

## Review Workload Forecast

| Field | Value |
| ------- | ------- |
| Estimated changed lines | 600–680 expected; hard maximum 800 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 → PR 3: shared foundation → primary authenticated workflow → financial summary and secondary administration |
| Delivery strategy | exception-ok |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

The 800-line cap is feasible because the work is limited to existing presentation seams, shared CSS/primitive reuse, and narrow semantic assertions. The expected range is approximately 600–680 changed lines. If the candidate reaches 640 lines, defer optional metadata, icon additions, decorative surface work, and optional recovery-action polish. At 721–800 lines, freeze the core hierarchy and reduce secondary administration to token/primitive application plus required responsive fixes. Anything above 800 changed lines stops immediately and reduces scope; it is not normalized, compressed, or silently exceeded. The configured `openspec/config.yaml` value of 600 remains historical and unchanged. `exception-ok` is recorded because the cohesive change is expected to exceed the 400-line review comfort threshold; stacked slices keep each review focused while the approved per-change cap remains 800.

## Constraints and execution protocol

- Use one writer thread and apply work in the dependency order below; do not run parallel writers.
- Presentation-only files are limited to `web/src/core/theme.css`, `web/src/index.css`, `web/src/components/ui.tsx`, `web/src/app/App.tsx`, `web/src/features/auth/login-screen.tsx`, `web/src/features/expenses/expenses-panel.tsx`, `web/src/features/participants/participants-panel.tsx`, `web/src/features/balances/balances-panel.tsx`, `web/src/features/settlement/settlement-panel.tsx`, `web/src/features/group/group-settings.tsx`, and narrowly targeted tests under `web/tests/**`.
- Do not edit `web/src/generated/**`, backend, mobile, WebSocket implementation, API contracts, or `web/index.html` unless a later budget check explicitly permits subordinate metadata work; metadata is deferred by default.
- Before each apply/remediation actor, use native attempt authority with `--change web-professional-redesign`, the work-unit label, bounded evidence goal, and `--max-changed-lines 800` (or a smaller slice allocation whose total is no more than 800). Launch only on `state: proceed`; retain the opaque token and settle with a distinct request ID. A `blocked` or `complete` result stops the unit.
- Do not add attempt counters to this file, OpenSpec state, prompts, or Pi state. Count additions plus deletions on the final exact candidate after all source-mutating normalization and before freeze.
- Preserve Spanish semantics, tested accessible names, hash anchors, DOM/form contracts, query and mutation wiring, server-authoritative money/roles/balances/settlement, REST/WebSocket invalidation semantics, and existing generated clients.
- Each work unit must record its focused test command/result, runtime scenario or `N/A` with reason, rollback boundary, and conventional commit/PR boundary before moving to the next stacked unit.

## Dependency order

```text
PR 1 shared presentation foundation
  ↓
PR 2 authenticated shell, login, and expense workspace
  ↓
PR 3 financial summary, administration, and final proof/freeze
```

Each PR is independently reviewable, keeps tests with the behavior they verify, targets `main` through the selected stacked-to-main sequence, and is rolled back in reverse order if the whole redesign must be removed.

## PR 1 — Shared presentation foundation

**Start:** existing light-theme web client and current shared CSS/UI primitives. **Finish:** a centralized editorial token/state language and responsive accessibility baseline consumed without changing feature behavior. **Rollback:** revert only the foundation files and their focused assertions; feature data flow and existing layout remain intact.

### RED

- [x] Add focused semantic assertions in `web/tests/app.test.tsx` or the smallest applicable existing feature test for shared loading/error roles, preserved hash navigation/active link names, and visible state text; run the affected Vitest file and record the expected failure. <!-- sdd-owner: implementation -->

### GREEN

- [x] Refine semantic aliases and light-theme roles in `web/src/core/theme.css` for action-soft, credit-soft, debt-soft, border-subtle, spacing, motion, and restrained workspace elevation without renaming existing tokens or adding dark mode. <!-- sdd-owner: implementation -->
- [x] Consolidate shared button, panel, heading, status, loading, empty, error, focus, control hit-area, overflow, and reduced-motion rules in `web/src/index.css`, preserving existing selector seams and using transform/opacity-only transitions. <!-- sdd-owner: implementation -->
- [x] Keep public primitive call sites stable in `web/src/components/ui.tsx`; add only an optional `ErrorCard` recovery-action slot if the existing state map needs it, with current no-action callers still valid. <!-- sdd-owner: implementation -->

### TRIANGULATE

- [x] Add/re-run edge assertions for loading and error accessibility roles, preserved accessible names, reduced-motion CSS override, and no page-level overflow assumptions in the affected `web/tests/**` files; verify with `npm --prefix web run test`. <!-- sdd-owner: implementation -->

### REFACTOR

- [x] Remove duplicate presentation values only where the new semantic tokens improve consistency, then run `npm --prefix web run test`, `npm --prefix web run typecheck`, and `npm --prefix web run build`; verify no non-web paths changed. <!-- sdd-owner: implementation -->

## PR 2 — Authenticated workflow and expense anchor

**Dependency:** PR 1. **Start:** PR 1 foundation is green. **Finish:** the authenticated shell, login, navigation, and expenses present the editorial hierarchy while preserving all auth/form/query contracts. **Rollback:** revert only PR 2 paths; PR 1 primitives remain usable and server/data behavior is untouched.

### RED

- [x] Add focused semantic assertions in `web/tests/app.test.tsx`, `web/tests/features/auth/session-provider.test.tsx`, and `web/tests/features/expenses/expenses.test.tsx` for primary expense/action priority, preserved login accessible names and state roles, stable hash links, editor-first responsive structure, and shared query-state presentation; run the affected files and record failures. <!-- sdd-owner: implementation -->

### GREEN

- [x] Apply editorial shell and navigation framing in `web/src/app/App.tsx` and `web/src/index.css` without changing `navItems`, `getCurrentNavHash`, hash anchors, `aria-current`, session/role text, logout, `ProtectedShell`, or WebSocket lifecycle. <!-- sdd-owner: implementation -->
- [x] Refine presentation-only wrappers/classes in `web/src/features/auth/login-screen.tsx`, preserving Spanish copy, labels, autocomplete, password visibility, `aria-pressed`, notices/errors, `aria-busy`, and protected-route behavior. <!-- sdd-owner: implementation -->
- [x] Make `web/src/features/expenses/expenses-panel.tsx` the visual anchor: preserve IDs, labels, fieldsets, archived edit references, validation focus, mutation payloads, query keys, invalidation, formatter use, and tested action names while applying shared loading/empty/error surfaces and responsive editor-first layout. <!-- sdd-owner: implementation -->

### TRIANGULATE

- [x] Extend/re-run expense and auth edge coverage for invalid amount focus/value preservation, contribution mismatch, empty participant guidance, anonymous shell exclusion, session expiry, and mobile reading order; run `npm --prefix web run test`. <!-- sdd-owner: implementation -->

### REFACTOR

- [x] Simplify duplicated shell/expense classes without changing DOM semantics, then run `npm --prefix web run test`, `npm --prefix web run typecheck`, and `npm --prefix web run build`; confirm the candidate remains within the native 800-line allocation before stacking PR 3. <!-- sdd-owner: implementation -->

## PR 3 — Financial summary, administration, and final proof

**Dependency:** PR 2. **Start:** primary workflow is green and within budget. **Finish:** balances/settlement are scannable, administration is visually secondary, all state/accessibility/responsive gates pass, and the exact candidate is frozen. **Rollback:** revert the summary/administration presentation slice independently; if needed, revert PR 3, then PR 2, then PR 1.

### RED

- [x] Add focused semantic assertions in `web/tests/features/balances/balances.test.tsx`, `web/tests/features/settlement/settlement.test.tsx`, `web/tests/features/participants/participants.test.tsx`, and `web/tests/features/group/group-settings.test.tsx` for exact server-rendered values/order, non-color status cues, shared state surfaces, and preserved management affordances; run affected files and record failures. <!-- sdd-owner: implementation -->

### GREEN

- [x] Apply quieter-but-scannable presentation to `web/src/features/balances/balances-panel.tsx` and `web/src/features/settlement/settlement-panel.tsx`, preserving `formatCents`/`formatSignedCents`, server order, `StatusBadge` meanings, table/data-label semantics, `Actualizar balances`, settled state, policy label, ordered transfer list, and existing refetch behavior. <!-- sdd-owner: implementation -->
- [x] Apply secondary management treatment to `web/src/features/participants/participants-panel.tsx` and `web/src/features/group/group-settings.tsx`, preserving stable order, lifecycle labels/IDs, archived behavior, focus/error handling, owner/member policy condition, mutation/invalidation wiring, and server authority. <!-- sdd-owner: implementation -->
- [x] Complete responsive and accessibility presentation rules in `web/src/index.css` for approximately 375px, tablet, desktop, and landscape: no page overflow, wrapped touch-sized controls, preserved reading order, visible focus, live regions, readable tabular amounts, and reduced-motion behavior. <!-- sdd-owner: implementation -->

### TRIANGULATE

- [x] Re-run the official Samaipata semantic coverage and edge cases: Ana `+Bs. 560,00`, Beto `Bs. 0,00`, Carla `-Bs. 160,00`, Diego `-Bs. 400,00`; transfers Diego → Ana `Bs. 400,00`, then Carla → Ana `Bs. 160,00`; verify archived zero visibility, forbidden mutation, settled empty state, and role/policy behavior with `npm --prefix web run test`. <!-- sdd-owner: implementation -->

### REFACTOR

- [x] Defer optional metadata, decorative assets, new icons, and optional recovery polish if the changed-line forecast reaches 640; at 721–800 keep only required secondary responsive/accessibility fixes; stop and reduce scope above 800. <!-- sdd-owner: implementation -->
- [x] Run final source-mutating normalization before verification, then run `npm --prefix web run test`, `npm --prefix web run typecheck`, and `npm --prefix web run build`; record exact outcomes and changed-line count from the final candidate. <!-- sdd-owner: implementation -->

## Final proof and freeze

- [ ] Walk the Samaipata flow manually at approximately 375px mobile, tablet, desktop, and landscape: sign in, inspect the group, record/review expenses, inspect balances and ordered settlement, refresh, and confirm persistence and reachable hash anchors. <!-- sdd-owner: implementation -->
- [x] Inspect keyboard traversal, visible focus, labels/roles/descriptions, live announcements, non-color state cues, reduced-motion behavior, touch-target sizing, and anonymous protected-content exclusion against the final exact HTML/CSS. <!-- sdd-owner: implementation -->
- [x] Run `git diff --name-only`, `git diff --stat`, and a changed-line/path audit; prove only approved web presentation files and targeted tests changed, total additions plus deletions are at most 800, and generated, backend, mobile, API, and WebSocket files are untouched. <!-- sdd-owner: implementation -->
- [ ] Preserve the final candidate bytes and modes after normalization, retain the native attempt/settle evidence for each work unit, and hand the exact frozen candidate to the parent for the bounded lifecycle review gate. <!-- sdd-owner: parent -->

## Parent lifecycle actions

- [ ] Start or reuse the bounded review for the final frozen candidate using the configured `stacked-to-main` delivery strategy and confirm each stacked unit's dependency and rollback boundary. <!-- sdd-owner: parent -->
- [ ] Execute the post-apply lifecycle gate only after implementation proof, native attempt settlement, and final candidate freeze are complete. <!-- sdd-owner: parent -->
