# Apply Progress: W1a Authenticated Shell Boundary Hardening

## Status

**Partial bounded continuation.** The requested route/auth boundary behavior is implemented and both focused suites pass. The full mobile suite still has one retained partial-state disposal failure outside the authorized production edit set, so this phase does not claim final verification or readiness for a native verify receipt.

## Recovery context

- The first W1 attempt was interrupted after a `1200000ms` timeout with 735 changed lines and no final apply evidence.
- A later W1a attempt was interrupted and settled at 188 changed lines.
- Those retained files and tests were treated as unverified recovery state, not as completed evidence. They were preserved; W1b refresh coordination and read-screen work were not touched.

## Authorized boundary and consumed status

- Change: `mobile-domain-features`
- Native status consumed: `nextRecommended=apply`, `blockedReasons=[]`.
- Parent work unit: `W1a-authenticated-shell-hardening`.
- Parent attempt authorization: one attempt, maximum 400 changed lines; parent owns settle.
- No `gentle-ai sdd-attempt`, review lifecycle, reset, settle, commit, or push operation was invoked.
- The supplied status did not include an `actionContext` warning; all intentional edits stayed within the supplied allowed files.
- CodeGraph MCP was unavailable, so targeted filesystem reads were used only after project-root and `.codegraph` checks.
- Engram was unavailable at `http://127.0.0.1:7437`; OpenSpec is the persisted evidence source for this phase.

## Completed bounded work

- Inspected the retained `App`, `DomainScope`, `DomainShell`, and session boundary before editing. The inspection task is the only W1a plan checkbox marked complete below because the remaining plan lines include broader composition/disposal work that this narrow authorization did not reimplement.
- Added optional `routeGroupId` and `routeRole` seams to `DomainShell`.
- Added fail-closed route checks against the active server-derived group and role. Conflicting group or role values render an accessible authorization message without constructing the protected shell/navigation.
- Preserved null route values and matching route values as normal authenticated shell entry.
- Fixed nullable `SessionState.copyWith` clearing using an explicit unset sentinel, so `role`, `activeGroupId`, and `errorMessage` can be cleared intentionally.
- Added transition-version guards so a late session restore cannot re-authenticate after logout or expiry. Session expiry clears protected identity and repeated unauthorized notifications do not trigger a retry loop.
- Added focused matching-route and independent group/role-mismatch widget coverage, and extended the existing session lifecycle coverage.
- No `app.dart`, `domain_scope.dart`, read screen, refresh coordinator, repository, transport, generated file, backend, web, README, or other SDD change was intentionally edited.

## Files intentionally changed by this continuation

- `mobile/lib/presentation/domain/domain_shell.dart`
- `mobile/lib/presentation/auth/session_cubit.dart`
- `mobile/test/presentation/domain/domain_shell_test.dart`
- `mobile/test/presentation/auth/session_cubit_test.dart`
- `openspec/changes/mobile-domain-features/tasks.md`
- `openspec/changes/mobile-domain-features/apply-progress.md`

The retained untracked partial files, including `mobile/test/app/domain_scope_test.dart`, remain recovery state and were not intentionally changed by this continuation.

## Persisted task updates

Changed one implementation-owned checkbox only:

- `[x] Inspect the retained partial shell and define the smallest remaining constructor/lifecycle seams in`mobile/lib/app/app.dart`,`mobile/lib/app/domain_scope.dart`, and`mobile/lib/presentation/domain/domain_shell.dart`; do not introduce group switching, a new DI package, or the separate refresh coordinator. <!-- sdd-owner: implementation -->`

The other W1a plan checkboxes remain unchecked because their complete acceptance scope was not authorized or did not pass the available full-suite evidence. Parent-owned checkboxes were preserved byte-for-byte.

## TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1a authenticated route/session boundary hardening (bounded continuation) | `mobile/test/presentation/domain/domain_shell_test.dart`; `mobile/test/presentation/auth/session_cubit_test.dart` | Presentation shell and session lifecycle | Focused pre-edit runs recorded compile failure for missing route constructor parameters and stale identity/late-restore failures | Focused rerun after adding matching/conflicting-route and expiry assertions reproduced the same legitimate failures before production edits | Focused shell: 5 passed; focused session: 6 passed | Focused shell: 6 passed, including null/matching values and independent group/role conflicts; focused session: 6 passed, including late logout/expiry and repeated unauthorized notification | Focused shell: 6 passed; focused session: 6 passed after minimal formatting/cleanup; full suite was rerun and retained one disposal failure documented below |

## Test Summary

### Safety net / RED before production edits

- `cd mobile && flutter test --no-pub test/presentation/domain/domain_shell_test.dart` — **failed as expected**: the route test could not compile because `DomainShell` lacked `routeGroupId` and `routeRole`.
- `cd mobile && flutter test --no-pub test/presentation/auth/session_cubit_test.dart` — **failed**: nullable identity fields were not cleared and late restore overwrote logout/expiry state.
- After adding the authorized focused assertions but before production edits, the same two focused commands reproduced those failures; no test was deleted or weakened.

### GREEN

- `cd mobile && flutter test --no-pub test/presentation/domain/domain_shell_test.dart` — **5 passed**.
- `cd mobile && flutter test --no-pub test/presentation/auth/session_cubit_test.dart` — **6 passed**.

### TRIANGULATE

- `cd mobile && flutter test --no-pub test/presentation/domain/domain_shell_test.dart` — **6 passed**: null routes, matching group/role, independent group mismatch, independent role mismatch, settlement recovery, and adaptive navigation.
- `cd mobile && flutter test --no-pub test/presentation/auth/session_cubit_test.dart` — **6 passed**: direct expiry clearing, logout during restore, expiry during restore, repeated unauthorized notifications without retry, and signed-out failure handling.
- `cd mobile && flutter test --no-pub test/app/domain_scope_test.dart test/app/auth_gate_test.dart` — **4 passed, 1 failed** with the retained disposal failure described below.

### REFACTOR / final available run

- `cd mobile && flutter test --no-pub test/presentation/domain/domain_shell_test.dart` — **6 passed**.
- `cd mobile && flutter test --no-pub test/presentation/auth/session_cubit_test.dart` — **6 passed**.
- `cd mobile && flutter test --no-pub` — **54 passed, 1 failed**. The failure is `test/app/domain_scope_test.dart: does not publish a protected result after logout closes a loading scope`; retained `GroupCubit.load` attempted to emit after close (`Bad state: Cannot emit new states after calling close`). Fixing that requires an unauthorized production file (`mobile/lib/presentation/group/group_cubit.dart`), so it was not changed.
- Runtime/manual harness: `N/A` — no live mobile/server runtime was started; the executor was not authorized to expand beyond the focused local tests.

## Deviations and risks

- No design deviation and no W1b refresh/invalidation work.
- Full-suite verification is not green because of the retained `GroupCubit` disposal failure outside the allowed production files. This remains a risk for the broader W1a shell/disposal acceptance and must not be represented as fixed by this phase.
- The actual parent-enforced boundary remains **400 maximum changed lines**. Because the shell and domain-shell test are retained untracked partial files from earlier attempts, Git cannot isolate their new line delta from the earlier 188-line interrupted candidate. The measurable tracked diff for this continuation is `mobile/lib/presentation/auth/session_cubit.dart: 32 insertions / 10 deletions` and the session test's prior partial diff remains mixed with this continuation; no native line reforecast was requested or performed.

## Remaining W1a tasks

The following exact implementation-owned lines remain unchecked:

- [ ] RED: add focused tests in `mobile/test/app/domain_scope_test.dart`, `mobile/test/presentation/domain/domain_shell_test.dart`, and `mobile/test/app/auth_gate_test.dart` for the still-missing authenticated-entry, logout-during-load, expired-session, route group/role rejection, disposal, and five-destination behaviors; preserve existing tests and record the real pre-edit safety net. <!-- sdd-owner: implementation -->
- [ ] GREEN: complete the retained authenticated per-session/per-group composition, nullable session clearing, protected-state disposal, adaptive labeled `NavigationBar`/large-window `NavigationRail`, predictable back behavior, safe areas, semantic labels, and explicit all-settled/read-only settlement presentation. Do not wire W1b refresh coordination here. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: add focused coverage for logout/session expiry during loading, 401 without retry loops, 403 as forbidden rather than sign-in retry, route-supplied group/role rejection, empty/loading/recovery states, and settlement failure retry without local replacement data. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: dispose/cancel protected Cubits, subscriptions, refresh callbacks, and in-flight ownership at logout/session expiry; preserve token-based theme, 48dp targets, readable dynamic text, contrast, and no emoji structural icons without changing `mobile/README.md`. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` and record the focused and full results plus a manual/runtime scenario covering sign-in → domain → logout → protected-route denial. <!-- sdd-owner: implementation -->

W1b and all later work units remain deferred. Parent-owned review, line-forecast, and delivery actions remain unchecked and deferred to `parent-lifecycle`.

## Workload and next action

- Review forecast consumed: W1a 180–250 lines; current parent cap 400 lines.
- Delivery decision: no size exception and no chained PR decision for this bounded continuation.
- PR boundary: `W1a-authenticated-shell-hardening` only; W1b refresh/invalidation is a separate boundary.
- No native verify-result envelope or receipt was created.
- `next_recommended: parent-lifecycle` — parent must settle this attempt and decide how to handle the retained disposal failure before any broader W1a work.

## Bounded continuation: W1a-group-cubit-disposal

### Current status

**Completed bounded disposal continuation; broader W1a acceptance remains incomplete.** `GroupCubit.load` now ignores both late success and late failure results after `DomainScope.close()` closes the Cubit. The full mobile safety net is green for the retained candidate. This continuation did not implement W1b refresh coordination or claim the broader W1a RED/GREEN/TRIANGULATE/REFACTOR tasks.

### Structured status and authority consumed

- Native status: `artifactStore=openspec`, `nextRecommended=apply`, `applyState=ready`, `blockedReasons=[]`.
- `actionContext.mode=repo-local`; the only authoritative allowed edit root is the project root. No action-context warning was present.
- Required proposal, all four specs, design, tasks, and prior apply-progress were read before editing.
- Review workload gate consumed: current W1a forecast 180–250 lines, `Decision needed before apply: No`, `Chained PRs recommended: No`, aggregate risk `High`; the parent-selected path remains strict slices with no size exception.
- The parent-owned native attempt token remained active; this continuation did not run `sdd-attempt acquire` or `settle`, review lifecycle commands, commit, or push.

### Completed bounded work

- Added a closed-state guard before the initial loading emission in `mobile/lib/presentation/group/group_cubit.dart`.
- Awaited the repository result before emitting and guarded the late success path with `isClosed`.
- Guarded the late failure path before mapping/emitting the existing error or corruption-recovery state.
- Preserved the repository call, server-derived read model, failure mapping, and all non-disposal read semantics.
- Added one focused regression test in `mobile/test/app/domain_scope_test.dart` for a repository failure completing after logout/session-scope disposal. The retained late-success regression remains unchanged.
- No W1b refresh/invalidation, backend, web, generated API, README, participant/expense/policy, or prior SDD change was touched by this continuation.

### Persisted task updates

- Added and checked the exact bounded implementation row in `openspec/changes/mobile-domain-features/tasks.md`: `Bounded continuation: guard GroupCubit.load against late success/failure emissions after protected scope disposal, with focused domain-scope regression coverage.`
- The broader W1a RED, GREEN, TRIANGULATE, REFACTOR, and Safety-net rows remain unchecked because this continuation does not satisfy their full acceptance scope. Parent-owned rows remain unchanged.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1a-group-cubit-disposal | `mobile/test/app/domain_scope_test.dart` | Unit/lifecycle integration | `flutter test --no-pub test/app/domain_scope_test.dart`: 2 passed, 1 known retained disposal failure | Added late-failure regression; focused run: 2 passed, 2 failed with the expected `Cannot emit new states after calling close` at `GroupCubit.load` | Focused run: 4 passed | Focused run for `domain_scope_test.dart` plus `read_cubits_test.dart`: 7 passed, covering late success, late failure, scope close, and unchanged read states | `dart format --output=none --set-exit-if-changed` reported 2 files, 0 changed; focused rerun: 4 passed |

### Test summary

- Tests written in this continuation: 1 regression test.
- Focused GREEN: 4 passed.
- Focused TRIANGULATE: 7 passed across domain-scope disposal and read-Cubit semantics.
- Focused REFACTOR rerun: 4 passed.
- Full safety net: `cd mobile && flutter test --no-pub` — 56 passed, 0 failed.
- Runtime/manual harness: `N/A` — no live mobile/server runtime was started.
- Approval tests: None; this was a targeted behavior fix, not a refactor of existing semantics.
- Pure functions created: 0.

### Files changed in this bounded continuation

- `mobile/lib/presentation/group/group_cubit.dart`
- `mobile/test/app/domain_scope_test.dart`
- `openspec/changes/mobile-domain-features/tasks.md`
- `openspec/changes/mobile-domain-features/apply-progress.md`

Previously retained partial files and unrelated working-tree changes were preserved and not broadly reverted.

### Deviations, risks, and remaining work

- No design deviation for the disposal guard; the only added behavior is suppressing emissions after closure.
- Broader W1a remains incomplete and must not be reported as fully accepted from this continuation. Native verify remains unavailable until every implementation task is complete.
- The exact unchecked task lines remaining in the persisted tasks artifact are:

- [ ] RED: add focused tests in `mobile/test/app/domain_scope_test.dart`, `mobile/test/presentation/domain/domain_shell_test.dart`, and `mobile/test/app/auth_gate_test.dart` for the still-missing authenticated-entry, logout-during-load, expired-session, route group/role rejection, disposal, and five-destination behaviors; preserve existing tests and record the real pre-edit safety net. <!-- sdd-owner: implementation -->
- [ ] GREEN: complete the retained authenticated per-session/per-group composition, nullable session clearing, protected-state disposal, adaptive labeled `NavigationBar`/large-window `NavigationRail`, predictable back behavior, safe areas, semantic labels, and explicit all-settled/read-only settlement presentation. Do not wire W1b refresh coordination here. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: add focused coverage for logout/session expiry during loading, 401 without retry loops, 403 as forbidden rather than sign-in retry, route-supplied group/role rejection, empty/loading/recovery states, and settlement failure retry without local replacement data. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: dispose/cancel protected Cubits, subscriptions, refresh callbacks, and in-flight ownership at logout/session expiry; preserve token-based theme, 48dp targets, readable dynamic text, contrast, and no emoji structural icons without changing `mobile/README.md`. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` and record the focused and full results plus a manual/runtime scenario covering sign-in → domain → logout → protected-route denial. <!-- sdd-owner: implementation -->
- [ ] RED: add `mobile/test/data/refresh/refresh_coordinator_test.dart` cases for participant, expense, and policy impact plans; all-required-reloads completion; uncertain-impact conservative reload; partial failure; retry; and `data_changed` payloads that never replace REST state. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement `mobile/lib/data/refresh/refresh_coordinator.dart` with registered reload callbacks, explicit impact sets, completion-after-success semantics, retryable refresh failure, and integration with the existing WebSocket listener's `data_changed` event only. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: verify logout during refresh, duplicate invalidation coalescing, incomplete/corrupt REST responses, 401/403 handling, and no fabricated balances/settlement/residuals after refresh failure. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: keep coordinator ownership scoped to `DomainScope`, avoid a second domain-data cache, and expose accessible retry/action state to the shell and feature Cubits. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` and retain existing WebSocket/read-repository tests unchanged except for the required listener seam. <!-- sdd-owner: implementation -->
- [ ] Map the existing generated participant operations by discovery in `mobile/lib/generated/api/**` and implement non-generated writer contracts/adapters in `mobile/lib/data/repositories/mutation_support.dart` or a focused participant writer file; stop and escalate if any approved operation is absent. <!-- sdd-owner: implementation -->
- [ ] RED: add repository and Cubit tests under `mobile/test/data/repositories/` and `mobile/test/presentation/participants/` for request trimming, add/rename/archive/reactivate/delete commands, immutable displayed state before success, and server field/action error mapping. <!-- sdd-owner: implementation -->
- [ ] GREEN: add participant mutation models/Cubits and form/action widgets under `mobile/lib/domain/` and `mobile/lib/presentation/participants/`; preserve IDs/history, require confirmation for destructive actions, and show loading/disabled, validation, 401, 403, protected-reference, and recovery states. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: cover duplicate normalized names across active/archived participants, whitespace-only names, logout during mutation, duplicate taps, never-used deletion, referenced deletion protection, archive/reactivate transitions, and server-authoritative zero-balance/history visibility. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: connect successful lifecycle commands to the participant impact plan (participants, expenses/history, balances, settlement), keep role affordances usability-only, and meet visible-label, semantic-order, safe-area, contrast, and 48dp requirements. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` plus the focused participant repository/Cubit/widget commands; record a runtime scenario for add → rename → archive → reactivate and protected delete. <!-- sdd-owner: implementation -->
- [ ] Confirm the existing generated `ExpenseWriteRequest`, contributor request, and create/edit/delete operation signatures in `mobile/lib/generated/api/**`; consume only those signatures and leave every generated file untouched. <!-- sdd-owner: implementation -->
- [ ] RED: add focused tests in `mobile/test/domain/write_models/expense_amount_test.dart` and `mobile/test/data/repositories/expense_writer_test.dart` for accepted `1`, `1.2`, `1.20`, `0001.05`; rejection of whitespace/signs/separators/exponents/`.5`/`1.`/over-precision/zero; overflow/lossless bounds; no request on invalid input; and server monetary-consistency errors without client correction. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement non-generated write models/mappers under `mobile/lib/domain/write_models/` and `mobile/lib/data/repositories/`; validate top-level and contributor lexical text with checked integer-only arithmetic, retain accepted request text, map 401/403/field/action/network/5xx/incomplete responses, and never total contributions or calculate monetary outcomes. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: test malformed references, missing description/contributor/beneficiary, overflow at the confirmed server integer bound, duplicate calls, corruption/recovery responses, and exact generated request strings. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: keep generated DTO calls isolated, make models immutable, and ensure no floating-point (`double`/`num`) monetary parsing or formatting enters the write boundary. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` and record focused mapper/repository results. <!-- sdd-owner: implementation -->
- [ ] RED: add Cubit/widget tests under `mobile/test/presentation/expenses/` for valid create/edit/delete, invalid shape, archived referenced edit selection, unrelated archived exclusion, cancellation, duplicate submit/delete prevention, server 401/403/validation, and refresh failure. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement expense mutation Cubits/forms/actions under `mobile/lib/presentation/expenses/`; collect description, contract amount text, contributors, beneficiaries, and references; default new forms to active participants; retain only referenced archived participants in edits; and confirm destructive deletion. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: verify displayed expenses remain unchanged until successful REST refresh, server contribution mismatch is shown without correction, logout during submit, disabled progress states, empty/history/all-settled transitions, field errors near labeled fields, semantic announcements, and predictable back/cancel paths. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: connect create/edit/delete to the conservative expense impact plan (expenses, balances, settlement, and participants when selector/name/status impact is possible); keep settlement read-only and server-derived. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` plus focused expense Cubit/widget commands; record a runtime scenario for create → refreshed history/balance/settlement, edit with archived reference, and cancelled/confirmed delete. <!-- sdd-owner: implementation -->
- [ ] Confirm the existing generated group update operation and supported policy enum values (`owner_only`, `any_member`) in `mobile/lib/generated/api/**`; do not add a policy operation or unsupported value. <!-- sdd-owner: implementation -->
- [ ] RED: add policy repository/Cubit/widget tests under `mobile/test/data/repositories/group_writer_test.dart` and `mobile/test/presentation/group/` for owner/member × policy matrix, supported-value filtering, 401/403/validation, duplicate submit, no optimistic policy, and post-success refresh. <!-- sdd-owner: implementation -->
- [ ] GREEN: implement the policy writer/Cubit and role-aware affordance in `mobile/lib/data/`, `mobile/lib/domain/`, and `mobile/lib/presentation/group/`; server-derived role/policy controls usability only, while successful updates refresh group/policy and dependent presentation. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: add cross-feature tests for each mutation impact set, WebSocket invalidation-only behavior, refresh failure/retry, protected-route re-entry, corrupt responses, archived history/balances, and explicit all-settled/read-only settlement. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: perform accessibility and responsive regression hardening across `mobile/lib/presentation/**`: visible labels, inline/actionable errors, semantic icon labels, safe areas, predictable back navigation, 48dp targets, token colors/contrast, dynamic text, and no redesign or emoji icons. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` and record focused policy/integration results plus a manual/runtime matrix for owner/member policy attempts and mutation-to-refresh recovery. <!-- sdd-owner: implementation -->
- [ ] Start or reuse one bounded native review for the completed candidate after all source-mutating normalization and before delivery; preserve the exact receipt and review boundary. <!-- sdd-owner: parent -->
- [ ] Confirm the native changed-line forecast before each unit; if any unit exceeds 400 authored changed lines, stop and decide whether to split again or select a permitted delivery exception/chain strategy. <!-- sdd-owner: parent -->

### Workload / PR boundary and next action

- Bounded PR boundary: `W1a-group-cubit-disposal` only; W1b remains separate.
- No size exception, chained PR, review, receipt, or delivery gate was created by this executor.
- `next_recommended: parent-lifecycle`; the parent owns native attempt settlement and subsequent lifecycle decisions. Do not report `Ready for verify` because the broader change still has unchecked implementation tasks.

## Bounded continuation: W1a-read-cubit-disposal

### Current status

**Completed bounded read-Cubit disposal continuation; broader W1a acceptance remains incomplete.** `ParticipantsCubit`, `ExpensesCubit`, `BalancesCubit`, and `SettlementCubit` now suppress initial, late-success, and late-failure emissions once their protected scope has been closed. Existing read semantics and error/corruption mapping remain unchanged. The focused disposal coverage and the full mobile safety net pass.

### Structured status and authority consumed

- Native status: `artifactStore=openspec`, `nextRecommended=apply`, `applyState=ready`, `blockedReasons=[]`.
- `actionContext.mode=repo-local`; no action-context warning or edit-root violation was reported.
- Required proposal, all four specs, design, tasks, and cumulative apply-progress were read before editing.
- The current parent-owned attempt was already acquired for `W1a-read-cubit-disposal`; this executor did not run acquire, settle, review lifecycle, commit, or push operations.
- CodeGraph MCP remained unavailable. The project root was resolved to `proyecto_1`, its existing `.codegraph` directory was checked, and targeted filesystem reads were used only after the CodeGraph attempt failed.

### Completed bounded work

- Added an `isClosed` guard before the initial loading emission in each of the four remaining read Cubits.
- Added an `isClosed` guard immediately after each repository await, preventing late success and failure/corruption emissions after logout or `DomainScope.close()`.
- Added one focused success regression and one focused failure regression covering all four read Cubits completing after the protected scope closes.
- Added focused coverage that calling any of the four read loads after scope closure is a no-op.
- Preserved server-derived read values, empty/loaded branching, existing error messages, corruption recovery mapping, and reload behavior.
- Did not touch W1b refresh coordination, participant/expense/policy mutation work, backend, web, generated API output, `mobile/README.md`, or the prior SDD change.

### Persisted task updates

- Added and checked this implementation-owned task in `openspec/changes/mobile-domain-features/tasks.md`:

  `- [x] Bounded continuation: guard \`ParticipantsCubit.load\`, \`ExpensesCubit.load\`, \`BalancesCubit.load\`, and \`SettlementCubit.load\` against late success/failure emissions after protected scope disposal, with focused domain-scope regression coverage. <!-- sdd-owner: implementation -->`

- The broader W1a RED, GREEN, TRIANGULATE, REFACTOR, and Safety-net rows remain unchecked because this continuation does not satisfy their full authenticated-shell acceptance scope. Parent-owned rows remain unchanged.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1a-read-cubit-disposal | `mobile/test/app/domain_scope_test.dart`; `mobile/test/presentation/read_cubits_test.dart` | Unit/lifecycle integration | `domain_scope_test.dart`: 4 passed; `read_cubits_test.dart`: 3 passed before edits | Added late-success and late-failure scope-close tests first; focused run failed as expected with `Cannot emit new states after calling close` from `ParticipantsCubit.load` | `cd mobile && flutter test --no-pub test/app/domain_scope_test.dart`: 6 passed after the four guards | Added post-close no-op coverage for all four Cubits and reran `cd mobile && flutter test --no-pub test/app/domain_scope_test.dart test/presentation/read_cubits_test.dart`: 10 passed | Formatted the five changed Dart files; reran the same focused command: 10 passed |

### Test Summary

- **Tests written in this continuation**: 3 focused lifecycle regressions (two late-completion cases plus one post-close invocation case), covering all four affected Cubits.
- **Focused RED**: `cd mobile && flutter test --no-pub test/app/domain_scope_test.dart` — 4 existing tests passed and 2 new tests failed with the expected post-close emission error.
- **Focused GREEN**: `cd mobile && flutter test --no-pub test/app/domain_scope_test.dart` — 6 passed.
- **Focused TRIANGULATE**: `cd mobile && flutter test --no-pub test/app/domain_scope_test.dart test/presentation/read_cubits_test.dart` — 10 passed.
- **Focused REFACTOR rerun**: the same focused command after `dart format` — 10 passed.
- **Full safety net**: `cd mobile && flutter test --no-pub` — 60 passed, 0 failed (`+59 ... All tests passed`).
- **Runtime/manual harness**: `N/A` — no live mobile/server runtime was started; this slice has no separate runtime boundary.
- **Approval tests**: None — this was a targeted lifecycle guard, not a behavior-preserving refactor of existing implementation.
- **Pure functions created**: 0.

### Files changed in this bounded continuation

- `mobile/lib/presentation/participants/participants_cubit.dart`
- `mobile/lib/presentation/expenses/expenses_cubit.dart`
- `mobile/lib/presentation/balances/balances_cubit.dart`
- `mobile/lib/presentation/settlement/settlement_cubit.dart`
- `mobile/test/app/domain_scope_test.dart`
- `openspec/changes/mobile-domain-features/tasks.md`
- `openspec/changes/mobile-domain-features/apply-progress.md`

### Deviations, risks, and remaining work

- No design deviation: the only production behavior added is suppressing emissions after Cubit closure.
- The broader W1a shell/authenticated-entry/disposal acceptance remains incomplete; this continuation does not mark its broad RED/GREEN/TRIANGULATE/REFACTOR/Safety-net rows complete and does not authorize verification.
- No separate runtime/manual harness was run.
- Workload gate consumed for the bounded route: `Decision needed before apply: No`; `Chained PRs recommended: No`; `Chain strategy: not selected`; `400-line budget risk: High` in aggregate only. The current slice stayed strictly bounded with no size exception; the parent owns native cap/settlement.

The following exact implementation-owned W1a lines remain unchecked:

- [ ] RED: add focused tests in `mobile/test/app/domain_scope_test.dart`, `mobile/test/presentation/domain/domain_shell_test.dart`, and `mobile/test/app/auth_gate_test.dart` for the still-missing authenticated-entry, logout-during-load, expired-session, route group/role rejection, disposal, and five-destination behaviors; preserve existing tests and record the real pre-edit safety net. <!-- sdd-owner: implementation -->
- [ ] GREEN: complete the retained authenticated per-session/per-group composition, nullable session clearing, protected-state disposal, adaptive labeled `NavigationBar`/large-window `NavigationRail`, predictable back behavior, safe areas, semantic labels, and explicit all-settled/read-only settlement presentation. Do not wire W1b refresh coordination here. <!-- sdd-owner: implementation -->
- [ ] TRIANGULATE: add focused coverage for logout/session expiry during loading, 401 without retry loops, 403 as forbidden rather than sign-in retry, route-supplied group/role rejection, empty/loading/recovery states, and settlement failure retry without local replacement data. <!-- sdd-owner: implementation -->
- [ ] REFACTOR: dispose/cancel protected Cubits, subscriptions, refresh callbacks, and in-flight ownership at logout/session expiry; preserve token-based theme, 48dp targets, readable dynamic text, contrast, and no emoji structural icons without changing `mobile/README.md`. <!-- sdd-owner: implementation -->
- [ ] Safety-net: run `cd mobile && flutter test --no-pub` and record the focused and full results plus a manual/runtime scenario covering sign-in → domain → logout → protected-route denial. <!-- sdd-owner: implementation -->

W1b and all later work-unit rows remain deferred. Parent-owned review, forecast, and delivery rows remain unchecked and deferred to `parent-lifecycle`.

### Workload / PR boundary and next action

- Bounded PR boundary: `W1a-read-cubit-disposal` only; W1b remains separate.
- No size exception, chained PR, review, receipt, or delivery gate was created by this executor.
- `next_recommended: parent-lifecycle`; the parent owns native attempt settlement and subsequent lifecycle decisions. Do not report `Ready for verify` because the broader change still has unchecked implementation tasks.

## Bounded continuation: W1a-authenticated-entry-lifecycle (recovery verification)

### Current status

**Fresh verification of retained authenticated-entry work.** The interrupted worker's retained logout/session-expiry tests were inspected and verified from the repository root with absolute paths. No production or test edits were made during this verification retry; the broad W1a acceptance remains incomplete.

### Verification evidence

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/app/auth_gate_test.dart test/app/domain_scope_test.dart` — **12 passed**.
- Full safety net: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **62 passed**.
- Formatting check: `dart format --output=none --set-exit-if-changed` over the five authenticated-entry Dart files — **5 files, 0 changed**.
- Runtime/manual harness: `N/A` — no live mobile/server runtime was run.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1a-authenticated-entry-lifecycle (retained recovery) | `mobile/test/app/auth_gate_test.dart`; `mobile/test/app/domain_scope_test.dart` | App composition and protected-scope lifecycle | Retained tests were unverified after the worker timeout | `N/A` — no test or production edit was made in this retry; the prior timeout's RED is not reused as fresh evidence | Fresh focused command: 12 passed | Fresh full safety net: 62 passed | Formatting check: 5 files, 0 changed; no source mutation |

### Scope and remaining work

- Verified the retained `App` boundary, server-derived `SessionState.activeGroupId` routing, protected scope disposal on logout/session expiry, failed logout disposal, and forbidden reads remaining in-domain.
- No W1b refresh/invalidation, participant/expense/policy mutation, backend, web, generated API, README, or prior SDD change was touched.
- Broad W1a RED, GREEN, TRIANGULATE, REFACTOR, and Safety-net rows remain unchecked; this recovery verification does not authorize final verify.
- Bounded PR boundary: `W1a-authenticated-entry-lifecycle` recovery verification only; W1b remains separate.
- `next_recommended: parent-lifecycle`; the parent owns native attempt settlement and subsequent lifecycle decisions.

## Bounded continuation: W1b-A-refresh-coordinator-core

### Current status

**Completed bounded core slice; WebSocket integration remains deferred.** Added explicit participant/expense/policy/unknown plans, all-required REST reload completion, conservative unknown reload, duplicate/queued-impact coalescing, and retryable failure state. Source plus focused test files are 285 lines total, below the 300-line slice boundary.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1b-A-refresh-coordinator-core | `mobile/test/data/refresh/refresh_coordinator_test.dart` | Refresh coordination core | Full mobile suite after implementation: 78 passed | Initial focused run: 3 passed, 1 failed because duplicate impacts reran active targets | Focused run after active-target fix: 5 passed | Tests cover explicit plans, unknown all-target reload, all-required completion, duplicate coalescing, queued policy impact, partial failure, and retry; full suite: 78 passed | `dart format --output=none --set-exit-if-changed`: 2 files, 0 changed; `flutter analyze`: No issues found |

### Verification evidence and scope

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/data/refresh/refresh_coordinator_test.dart` — **5 passed**.
- Full command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **78 passed**.
- No WebSocket listener/composition integration, mutations, policy writer, group switching, generated API, README, backend, or other SDD change was touched. No Native/reset/review, commit, or push was run.
- Bounded PR boundary: `W1b-A-refresh-coordinator-core`; parent owns native attempt settlement and subsequent lifecycle decisions.
- `next_recommended: parent-lifecycle`.

## Bounded continuation: W1b-B1-websocket-invalidation-adapter

### Current status

**Completed bounded listener integration; W1b-B2 remains deferred.** The existing `DataChangedListener` now forwards only valid `data_changed` frame notifications to `RefreshCoordinator` with the conservative `RefreshImpact.unknown` impact. WebSocket payload fields remain non-authoritative and are never passed to REST reloaders or used as domain data.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1b-B1-websocket-invalidation-adapter | `mobile/test/data/websocket/data_changed_listener_test.dart` | WebSocket invalidation adapter and refresh coordination seam | Full mobile suite: 82 passed | No test-run evidence was recorded before implementation; pre-implementation diagnostics exposed the missing `onDataChanged` seam with 8 named-parameter errors. This is not presented as a test result. | Focused listener test: 6 passed after implementing `onDataChanged` | Full mobile suite: 82 passed; covers coordinator/listener integration, ignored malformed/nonmatching frames, payload exclusion, duplicate coalescing, and REST fallback | `dart format --output=none --set-exit-if-changed` on 2 files: 2 files, 0 changed; `flutter analyze`: No issues found; scoped diagnostics clean; `git diff --check`: clean |

### Verification evidence and scope

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/data/websocket/data_changed_listener_test.dart` — **6 passed**.
- Full command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **82 passed**.
- Formatting: `dart format --output=none --set-exit-if-changed` over `mobile/lib/data/websocket/data_changed_listener.dart` and `mobile/test/data/websocket/data_changed_listener_test.dart` — **2 files, 0 changed**.
- Runtime/manual harness: **N/A** — no live mobile/server/WebSocket runtime was run for this adapter-only slice.
- Direct slice accounting: listener 87 lines plus focused test 155 lines = **242 physical lines**; authored direct diff **120 lines**. Retained W1/W1a/W1b-A changes are excluded.
- No logout-during-refresh, 401/403, malformed REST lifecycle, composition integration, mutations, policy writer, group switching, generated API, README, backend, other SDD change, Native/reset/review, commit, or push was touched.
- Bounded PR boundary: `W1b-B1-websocket-invalidation-adapter`; parent owns subsequent lifecycle decisions.
- `next_recommended: W1b-B2`.

## Bounded continuation: W1b-B2-A-refresh-lifecycle-composition

### Current status

**Completed bounded composition/lifecycle slice; W1b-B2-B remains deferred.** `DomainScope` owns one `RefreshCoordinator`, binds and starts the invalidation-only `DataChangedListener`, and closes the listener, coordinator, and five read Cubits during protected-scope teardown. The coordinator ignores refresh/retry after close, resets to idle, and suppresses late in-flight reload results.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1b-B2-A-refresh-lifecycle-composition | `mobile/test/app/domain_scope_test.dart`; `mobile/test/data/refresh/refresh_coordinator_test.dart`; `mobile/test/data/websocket/data_changed_listener_test.dart` | DomainScope composition, listener lifecycle, and refresh ownership | Full mobile suite: 84 passed | No pre-implementation test run was recorded; diagnostics exposed a missing getter and one post-implementation assertion failed because unconfigured Cubit readers absorb errors. These are not presented as test-run results. | Focused composition/coordinator/listener run: 20 passed | Full mobile suite: 84 passed; covers five-Cubit teardown, listener/coordinator teardown, late success/failure suppression, and post-close invalidation | `flutter analyze`: No issues found; `dart format --output=none --set-exit-if-changed` on 4 files: 4 files, 0 changed; `git diff --check`: clean |

### Verification evidence and scope

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/app/domain_scope_test.dart test/data/refresh/refresh_coordinator_test.dart test/data/websocket/data_changed_listener_test.dart` — **20 passed**.
- Full command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **84 passed**.
- Analyzer: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter analyze` — **No issues found**.
- Formatting: `dart format --output=none --set-exit-if-changed` over `mobile/lib/app/domain_scope.dart`, `mobile/lib/data/refresh/refresh_coordinator.dart`, `mobile/lib/data/websocket/data_changed_listener.dart`, and `mobile/test/app/domain_scope_test.dart` — **4 files, 0 changed**.
- Runtime/manual harness: **N/A** — no live mobile/WebSocket runtime was run.
- Direct incremental growth reported for B2-A: approximately **100 authored lines**; current file lengths include retained work and are not slice accounting (`domain_scope.dart` 160, coordinator 154, listener 91, domain-scope tests 361).
- No 401/403 or malformed/incomplete REST failure UX, mutations, policy writer, group switching, generated API, README, backend, other SDD change, Native/reset/review, commit, or push was touched.
- Bounded PR boundary: `W1b-B2-A-refresh-lifecycle-composition`; parent owns subsequent lifecycle decisions.
- `next_recommended: W1b-B2-B`.

## Bounded continuation: W1b-B2-B1-refresh-failure-aggregation

### Current status

**Completed bounded failure-aggregation slice; W1b-B2-B2 remains deferred.** Refresh batches now wait for every required reloader, preserve only the targets that actually failed, retain the first failure for diagnosis/retry, and retry only those failed targets without replacing authoritative data.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1b-B2-B1-refresh-failure-aggregation | `mobile/test/data/refresh/refresh_coordinator_test.dart` | Refresh failure aggregation and targeted retry | Full mobile suite: 85 passed | Focused RED: 4 passed, 2 failed. The coordinator exposed all impact targets instead of only failed targets, and the batch completed before every failure settled; the test's error handler also required a typed `void` callback. The intermediate expected map incorrectly included `group` for an expense impact and was corrected because that impact plan excludes `group`. | Focused command after production/test corrections: 6 passed | Full mobile suite: 85 passed; verifies all-target waiting, failed-target reporting, targeted retry, duplicate coalescing, queued impacts, and close behavior | `flutter analyze`: No issues found; `dart format --output=none --set-exit-if-changed` on 2 files: 2 files, 0 changed; `git diff --check`: clean; scoped lens diagnostics clean |

### Verification evidence and scope

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/data/refresh/refresh_coordinator_test.dart` — **6 passed**.
- Full command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **85 passed**.
- Analyzer: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter analyze` — **No issues found**.
- Formatting: `dart format --output=none --set-exit-if-changed` over `mobile/lib/data/refresh/refresh_coordinator.dart` and `mobile/test/data/refresh/refresh_coordinator_test.dart` — **2 files, 0 changed**.
- Runtime/manual harness: **N/A** — no live mobile/WebSocket runtime was run.
- Direct incremental accounting: approximately **62 authored lines** for this B2-B1 continuation (about 11 in the coordinator and 51 in its focused tests, measured against the recorded W1b-A baseline); cumulative untracked file lengths include retained W1b-A/B2-A work and are not attributed to this slice.
- No 401/403 or malformed/incomplete REST UX, mutations, policy writer, group switching, generated API, README, backend, other SDD change, Native/reset/review, commit, or push was touched.
- Bounded PR boundary: `W1b-B2-B1-refresh-failure-aggregation`; parent owns subsequent lifecycle decisions.
- `next_recommended: W1b-B2-B2`.

## Bounded continuation: W1b-B2-B2-refresh-failure-ux

### Current status

**Completed bounded refresh-failure UX slice; the broad W1b task remains deferred.** Refresh-specific Cubit reload callbacks now propagate the original REST failure to the coordinator only after recording the user-facing error or corruption-recovery state. Existing screen `load()`/`reload()` paths remain safe and continue to expose accessible retry actions.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1b-B2-B2-refresh-failure-ux | `mobile/test/app/domain_scope_test.dart`; `mobile/test/presentation/read_screens_test.dart`; `mobile/test/presentation/read_cubits_test.dart` | Refresh failure propagation, read error mapping, and accessible recovery | Full mobile suite: 87 passed | Focused DomainScope run: 9 passed, 2 failed because Cubit reload callbacks swallowed Dio/ReadRepository failures, so the coordinator saw success instead of retryable failure. | Focused DomainScope run after `reloadForRefresh` seam and fixture corrections: 11 passed | Focused read screens/Cubits: 14 passed; full suite: 87 passed; verifies distinct 401/403 messaging, corrupt/incomplete recovery, retry, no local replacement, live regions, and 48dp action targets | `flutter analyze`: No issues found; `dart format --output=none --set-exit-if-changed` on 7 B2-B2 files: 0 changed; `git diff --check`: clean; duplicate-code findings were deferred as intentional typed/test fixtures |

### Verification evidence and scope

- Focused refresh/composition command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/app/domain_scope_test.dart test/data/refresh/refresh_coordinator_test.dart` — **17 passed**.
- Focused read UX command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/presentation/read_screens_test.dart test/presentation/read_cubits_test.dart` — **14 passed**.
- Full command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **87 passed**.
- Analyzer: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter analyze` — **No issues found**.
- Formatting: `dart format --output=none --set-exit-if-changed` over the seven B2-B2 Dart files — **0 changed**.
- Runtime/manual harness: **N/A** — no live mobile/server/WebSocket runtime was run.
- Direct incremental accounting: **98 authored/physical lines reported** for the B2-B2 seam (20 production seam lines plus 78 integration-test lines); retained Cubit and DomainScope file contents are excluded.
- No mutations, policy writer, group switching, generated API, README, backend, other SDD change, Native/reset/review, commit, or push was touched.
- Bounded PR boundary: `W1b-B2-B2-refresh-failure-ux`; parent owns subsequent lifecycle decisions.
- `next_recommended: W2`.

## Bounded continuation: W1a-read-state-ux

### Current status

**Completed bounded slice; broader W1a remains incomplete.** This continuation preserves the retained authenticated shell and adds App-boundary navigation/disposal coverage, distinct protected-read authorization messaging, Cubit message propagation, and minimal accessibility assertions. W1b refresh coordination, mutations, group switching, generated API files, backend, web, and `mobile/README.md` remain out of scope.

### Verification evidence

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/app_test.dart test/app/auth_gate_test.dart test/presentation/read_screens_test.dart test/presentation/domain/domain_shell_test.dart` — **34 passed**.
- Full safety net: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **73 passed**.
- Analyzer: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter analyze` — **No issues found**.
- Formatting: `dart format --output=none --set-exit-if-changed` over the 12 changed mobile Dart files — **12 files, 0 changed**.
- Runtime/manual harness: **N/A** — no live mobile/server runtime was run.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W1a-read-state-ux (bounded continuation) | `mobile/test/app_test.dart`; `mobile/test/app/auth_gate_test.dart`; `mobile/test/presentation/read_screens_test.dart`; `mobile/test/presentation/domain/domain_shell_test.dart` | App boundary, read-state presentation, responsive/accessibility widgets | Fresh combined focused run after retained work: 34 passed | The initial read-state run exposed that `ReadStateMessage` ignored Cubit-provided messages; the initial authorization/disposal assertions also exposed the need for explicit App/domain-shell seams. No failing output is reused as a PASS claim. | Focused GREEN run: 34 passed; full safety net: 73 passed | Covers five-destination App navigation, App route rejection, logout/expiry during loading, 401 vs 403 presentation, empty/loading/error/recovery states, settlement retry, dynamic text, safe areas, live regions, and 48dp targets | Source normalization ran before verification; final format check: 12 files, 0 changed; `flutter analyze`: clean |

### Scope and remaining work

- Updated `App` forwarding and protected-scope disposal behavior, read failure/status presentation, all five read screens, and the focused widget tests needed for this slice.
- `ReadRepositoryException` and Dio 401/403 failures now retain distinct user-facing messages; forbidden reads remain in-domain and do not trigger sign-in retry behavior.
- Broad W1a RED, GREEN, TRIANGULATE, REFACTOR, and Safety-net rows remain unchecked because refresh coordination and other W1a work are still pending.
- Project-wide lens output still carries pre-existing backend Pyright import findings caused by the backend package-root configuration; those findings were marked false-positive and are unrelated to this mobile slice. `flutter analyze` for `mobile` is clean.
- No Native operation, commit, push, review receipt, or delivery gate was created by this executor.
- Bounded PR boundary: `W1a-read-state-ux`; W1b remains separate.
- `next_recommended: parent-lifecycle`; the parent owns native attempt settlement and subsequent lifecycle decisions.

## Bounded continuation: W2-A1-participant-create-rename-boundary

### Current status

**Completed bounded data-boundary slice; broader W2 remains incomplete.** The existing generated add and rename operations are now exposed through the non-generated participant repository boundary. Names are trimmed and blank values fail before an operation call; CSRF is supplied through an injected provider, and successful server responses map to `ParticipantReadModel`. Cubit/forms, lifecycle actions, refresh integration, and participant UX remain deferred.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W2-A1 participant create/rename boundary | `mobile/test/data/repositories/participant_writer_test.dart`; `mobile/test/data/repositories/read_repositories_test.dart` | Repository writer adapter and server-response mapping | Existing read-repository safety net was preserved; writer test initially failed to compile because the repository constructor, add/rename methods, and write exception did not yet exist | Added add/rename and blank-name tests before completing the boundary; the expected missing-symbol diagnostics were retained as RED evidence, not PASS | Focused writer/read command: 7 passed; full mobile suite: 89 passed | `flutter analyze`: No issues found; `dart format --output=none --set-exit-if-changed` over 3 files: 0 changed; `git diff --check`: clean |

### Verification evidence and scope

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/data/repositories/participant_writer_test.dart test/data/repositories/read_repositories_test.dart` — **7 passed**.
- Full command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **89 passed**.
- Analyzer: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter analyze` — **No issues found**.
- Formatting: `dart format --output=none --set-exit-if-changed` over `mobile/lib/data/repositories/participants_repository.dart`, `mobile/test/data/repositories/participant_writer_test.dart`, and `mobile/test/data/repositories/read_repositories_test.dart` — **3 files, 0 changed**.
- Runtime/manual harness: **N/A** — no live mobile/server runtime was started; this repository-only boundary has no separate runtime scenario.
- Direct slice accounting: **228 authored lines** (`110` additions and `1` deletion in the tracked repository, `115` additions in the new writer test, and `3` compatibility lines); below the 400-line maximum.
- Generated API files, `mobile/README.md`, backend, web, Cubits, forms/widgets, refresh integration, and unrelated SDD changes were not edited for this slice.

### Delivery boundary

- A1 was delivered as a distinct local commit: `fe90fd3` (`feat(mobile): add participant create and rename boundary`); no push was performed. The repository, writer test, and 3-line compatibility seam remain its review boundary.
- RDD status remains `clone-local: off`; no native review, reset, or recovery operation was started.
- Bounded PR boundary: `W2-A1-participant-create-rename-boundary`; parent owns later lifecycle delivery.

## Bounded continuation: W2-A2-participant-lifecycle-boundary

### Current status

**Completed bounded lifecycle adapter slice; broader W2 remains incomplete.** Archive, reactivate, and protected delete now delegate to the corresponding existing generated operations with group/participant scope and CSRF. Archive/reactivate map server responses; delete awaits the generated void response and does not synthesize local state or authorization.

### TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
| --- | --- | --- | --- | --- | --- | --- | --- |
| W2-A2 participant archive/reactivate/delete boundary | `mobile/test/data/repositories/participant_writer_test.dart` | Repository lifecycle adapter | A1 focused writer/read safety net: 7 passed | Added lifecycle delegation test first; the focused compile run reported the three expected missing repository methods | Focused writer command: 3 passed | Full mobile suite: 90 passed; lifecycle assertions cover group/participant IDs, CSRF, server archived state, and void delete | `flutter analyze`: No issues found; `dart format --output=none --set-exit-if-changed` over 3 files: 0 changed; `git diff --check`: clean |

### Verification evidence and scope

- Focused command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub test/data/repositories/participant_writer_test.dart` — **3 passed**.
- Full command: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter test --no-pub` — **90 passed**.
- Analyzer: `cd "D:/Universidad/Proyectos/2doSemestre2026/topicos/proyecto_1/mobile" && flutter analyze` — **No issues found**.
- Formatting: `dart format --output=none --set-exit-if-changed` over the same 3 Dart files — **3 files, 0 changed**.
- Runtime/manual harness: **N/A** — no live mobile/server runtime was started; repository operations were verified with fakes.
- Direct slice accounting against the staged A1 boundary: **166 authored lines** (`91` additions in `participants_repository.dart` and `75` additions in `participant_writer_test.dart`); below the 400-line maximum.
- No generated/API, backend, web, README, Cubit/form/widget, refresh, policy, monetary, authorization, or settlement logic was added.

### Delivery boundary and remaining W2 work

- A2 was delivered as a distinct local commit: `5364f2e` (`feat(mobile): add participant lifecycle`); no push was performed. The two A slices remain mechanically separated.
- The broad W2 RED/GREEN/TRIANGULATE/REFACTOR/Safety-net rows remain unchecked: participant forms/widgets, immutable pre-success UI state, confirmation, logout/duplicate-tap integration, and mutation-to-refresh integration are not complete.
- Bounded PR boundary: `W2-A2-participant-lifecycle-boundary`; parent owns later lifecycle delivery.
- `next_recommended: W2-B1`; the A slices are delivered locally and the next bounded work is participant mutation state.

## Bounded continuation: W2-B1-participant-mutation-state

### Current status

**Bounded mutation-state/data-contract slice completed; broader W2 remains incomplete.**

### Scope/files

- `mobile/lib/data/repositories/participants_repository.dart` (ParticipantsWriter contract and implementation declaration)
- `mobile/lib/presentation/participants/participants_mutation_cubit.dart`
- `mobile/test/presentation/participants/participants_mutation_cubit_test.dart`
- These are the only files in scope. No forms/widgets/actions, DomainScope composition, RefreshCoordinator wiring, logout/session integration beyond close guards, generated files, backend/web, README, or other SDD changes were included.

### Behavior

- All five existing writer commands are covered: add, rename, archive, reactivate, and delete.
- Trim/blank validation runs before the writer; one in-flight guard prevents duplicate submission; loading/disabled state is exposed.
- The read list is not optimistically replaced. The server result is emitted only after completion, and late success/failure is suppressed after close.
- Typed failures map validation, 401, 403, structured field errors, `participant_in_use`, network/5xx, and incomplete/malformed/corrupt responses.

### TDD Cycle Evidence

| Stage | Evidence |
| --- | --- |
| RED | Unavailable because the first implementation worker timed out before returning command evidence; no RED result is fabricated. |
| GREEN/full safety-net | Fresh verifier: `cd mobile && flutter test --no-pub` — **97 passed, 0 failed**. |
| TRIANGULATE | Focused: `cd mobile && flutter test --no-pub test/presentation/participants/participants_mutation_cubit_test.dart test/data/repositories/participant_writer_test.dart test/data/repositories/read_repositories_test.dart` — **15 passed, 0 failed**. |
| REFACTOR | Check-only: `cd mobile && dart format --output=none --set-exit-if-changed lib/data/repositories/participants_repository.dart lib/presentation/participants/participants_mutation_cubit.dart test/presentation/participants/participants_mutation_cubit_test.dart` — **0 changed**; `flutter analyze` — **no issues**. `git diff --check` clean except existing LF/CRLF warnings. |

### Accounting

- Repository tracked diff: **+24/-1**.
- New production file: **184 physical lines**.
- New test file: **188 physical lines**.
- Estimated authored additions: **396**, strictly below 400.
- Documentation changes are evidence updates and are not part of the three-file code candidate accounting.

### Runtime, review, and delivery

- Runtime/manual harness: **N/A** — no live mobile/server runtime was started.
- No native review/receipt or commit/push was created because clone-local RDD is disabled.

### Remaining W2 rows and next action

- Participant forms/widgets/actions and later authoritative refresh/composition/integration remain unchecked.
- The broad W2 RED/GREEN/TRIANGULATE/REFACTOR/Safety-net rows remain unchecked; do not claim W2-B or W2 complete.

## Bounded continuation: W2-B2a-participant-name-form

### Current status

**Bounded form-widget slice completed; broader W2 and lifecycle-action/screen/composition/refresh integration remain incomplete.**

### Scope and behavior

- Only `mobile/lib/presentation/participants/participants_mutation_widgets.dart` and `mobile/test/presentation/participants/participants_mutation_widgets_test.dart` belong to this slice.
- The separate `participant_lifecycle_actions.dart` and `participant_lifecycle_actions_test.dart` files are retained future B2b files and are not attributed here.
- Behavior covered: reusable add/rename form using the existing mutation Cubit, visible labels, trim/blank validation through the Cubit, inline name error, live non-field error, loading/disabled/progress states, cancellation, and minimum 48dp controls.
- The widget does not own optimistic read-list state; authoritative list ownership remains outside this slice.

### Strict-TDD evidence

| Stage | Evidence |
| --- | --- |
| RED | Unavailable because the implementation worker timed out before returning command evidence; no RED result is fabricated. |
| GREEN/full safety-net | Fresh verifier: `cd mobile && flutter test --no-pub` — **104 passed, 0 failed**. |
| TRIANGULATE | Focused: `cd mobile && flutter test --no-pub test/presentation/participants/participants_mutation_widgets_test.dart test/presentation/participants/participants_mutation_cubit_test.dart test/data/repositories/participant_writer_test.dart` — **12 passed, 0 failed**. |
| REFACTOR | `cd mobile && flutter analyze` — **no issues**; `dart format --output=none --set-exit-if-changed mobile/lib/presentation/participants/participants_mutation_widgets.dart mobile/test/presentation/participants/participants_mutation_widgets_test.dart` — **0 changed**; `git diff --check` clean except unrelated LF/CRLF warnings. |

### Accounting and delivery

- Authored additions: **131 production lines + 129 test lines = 260 lines**, under 400. These are untracked files, so no tracked numstat applies.
- Runtime/manual: **N/A**.
- No native review/receipt/commit/push was performed because clone-local RDD is disabled.
- Next action: a separate bounded **W2-B2b lifecycle-action** slice. Do not claim W2-B2 or W2 complete.


## Bounded continuation: W2-B2b-participant-lifecycle-actions

### Current status

**Bounded lifecycle-action widget slice completed; W2-B2a is separate prior work and broader W2 remains incomplete.**

### Scope and behavior

- Only `mobile/lib/presentation/participants/participant_lifecycle_actions.dart` and `mobile/test/presentation/participants/participant_lifecycle_actions_test.dart` belong to this slice.
- Archive/reactivate follows the server-derived `ParticipantReadModel.archived` flag; controls are visibly labeled, at least 48dp, and disabled with progress while loading.
- Delete uses a labeled confirmation dialog. Button, barrier, and back dismissal never call the writer; confirmed deletion invokes the Cubit exactly once.
- Protected-reference and recovery failures remain visible through accessible live-region messages.
- Screen integration, DomainScope/DomainShell composition, RefreshCoordinator wiring, logout ownership, repository/generated files, backend/web, README, and other SDD changes were not included.

### TDD Cycle Evidence

| Stage | Evidence |
| --- | --- |
| RED | Unavailable because the implementation worker timed out before returning command evidence; no RED result is fabricated. |
| GREEN/full safety-net | Fresh verifier: `cd mobile && flutter test --no-pub` — **104 passed, 0 failed**. |
| TRIANGULATE | Focused: `cd mobile && flutter test --no-pub test/presentation/participants/participant_lifecycle_actions_test.dart test/presentation/participants/participants_mutation_cubit_test.dart test/data/repositories/participant_writer_test.dart` — **13 passed, 0 failed**. |
| REFACTOR | `cd mobile && flutter analyze` — **no issues**; `dart format --output=none --set-exit-if-changed lib/presentation/participants/participant_lifecycle_actions.dart test/presentation/participants/participant_lifecycle_actions_test.dart` — **0 changed**; `git diff --check` clean except unrelated LF/CRLF warnings. |

### Accounting and delivery

- Authored additions: **118 production lines + 179 test lines = 297 lines**, below 400. These are untracked files, so no tracked numstat applies.
- Runtime/manual: **N/A** — no live mobile/server runtime was started.
- No native review/receipt/commit/push was performed because clone-local RDD is disabled.
- Next action: integrate the form/actions into `ParticipantsScreen` in another bounded slice, then handle DomainScope composition and authoritative RefreshCoordinator integration. Do not claim W2-B2 or W2 complete.


## Bounded continuation: W2-B2c-participant-screen-integration

### Status

**Bounded screen-integration slice completed; W2-B1/B2a/B2b are separate prior slices; broader W2 remains incomplete.**

### Changed paths

- `mobile/lib/presentation/participants/participants_screen.dart`
- New/changed participant integration coverage in `mobile/test/presentation/read_screens_test.dart`; this file also contains retained W1a read-state tests that are not attributed to this slice.

### Behavior

- An optional `mutationCubit` keeps the default read-only mode unchanged.
- When supplied, the screen adds the participant form in loaded and empty states, per-participant rename selection with a populated form and cancel, and archive/reactivate/delete actions.
- Read Cubit data remains authoritative, with no optimistic replacement.
- DomainScope/DomainShell composition, RefreshCoordinator/post-success refresh, logout ownership, and other W2 concerns remain deferred.

### Strict-TDD evidence

| Stage | Evidence |
| --- | --- |
| RED | Unavailable because the implementation worker timed out before returning command evidence; no RED result is fabricated. |
| GREEN/full safety-net | Fresh verifier: `cd mobile && flutter test --no-pub` — **109 passed, 0 failed**. |
| TRIANGULATE | Focused: `cd mobile && flutter test --no-pub test/presentation/read_screens_test.dart test/presentation/participants/participants_mutation_widgets_test.dart test/presentation/participants/participant_lifecycle_actions_test.dart test/presentation/participants/participants_mutation_cubit_test.dart test/data/repositories/participant_writer_test.dart` — **33 passed, 0 failed**. |
| REFACTOR | `cd mobile && flutter analyze` — **no issues**; `dart format --output=none --set-exit-if-changed lib/presentation/participants/participants_screen.dart test/presentation/read_screens_test.dart` — **0 changed**; `git diff --check` clean except existing LF/CRLF warnings. |

### Accounting and delivery

- Conservative incremental estimate: **~350 authored lines**, below 400, excluding retained W1a read-state content in the test file; no material formatting-only churn remains.
- Runtime/manual: **N/A**.
- No native review/receipt/commit/push was performed because clone-local RDD is disabled.
- Next action: a separate bounded slice for DomainScope mutation-writer composition and authoritative RefreshCoordinator/post-success integration, then logout/session ownership; do not claim W2-B or W2 complete.


## Bounded continuation: W2-B3-participant-composition-refresh

### Status

**Bounded composition/authoritative post-success refresh slice completed; W2-B1/B2a/B2b/B2c are separate prior slices; broader W2 remains incomplete.**

### Paths

- `mobile/lib/app/domain_scope.dart`
- `mobile/lib/presentation/domain/domain_shell.dart`
- `mobile/lib/presentation/participants/participants_mutation_cubit.dart`
- Focused additions in `mobile/test/app/domain_scope_test.dart`, `mobile/test/presentation/domain/domain_shell_test.dart`, and `mobile/test/presentation/participants/participants_mutation_cubit_test.dart`.
- These files contain retained prior W1a/W1b/content excluded from this slice.

### Behavior

- One transport-created `ParticipantsRepository` serves both reader and writer boundaries.
- Unavailable/custom readers without a writer remain read-only.
- `DomainScope` creates the optional mutation Cubit after `RefreshCoordinator`, forwards it through `DomainShell`, awaits all `RefreshImpact.participant` reloaders before mutation success, wraps refresh errors as recovery with no success, and closes mutation ownership before coordinator/read Cubits.
- No optimistic read replacement is used.

### Strict-TDD evidence

| Stage | Evidence |
| --- | --- |
| RED | Unavailable because the implementation worker timed out before returning command evidence, so do not fabricate. |
| GREEN/full safety-net | Fresh verifier: `cd mobile && flutter test --no-pub` = **115 passed, 0 failed**. |
| TRIANGULATE | Focused: `cd mobile && flutter test --no-pub test/presentation/participants/participants_mutation_cubit_test.dart test/app/domain_scope_test.dart test/presentation/domain/domain_shell_test.dart test/presentation/read_screens_test.dart test/presentation/participants/participants_mutation_widgets_test.dart test/presentation/participants/participant_lifecycle_actions_test.dart test/data/refresh/refresh_coordinator_test.dart` = **60 passed, 0 failed**. |
| REFACTOR | `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the six allowed files = **0 changed**; `git diff --check` has no whitespace errors apart from existing LF/CRLF warnings. |

### Accounting and delivery

- Conservative incremental estimate: **approximately 240 authored lines**, capped below 300 and under 400, excluding retained W1a/W1b content in untracked files.
- No formatter churn remains in the six authorized files.
- Runtime/manual: **N/A**.
- No native review/receipt/commit/push was performed because clone-local RDD is disabled.

### Next action

- A separate bounded slice for remaining W2 participant triangulation/refresh recovery UX and broader acceptance; do not claim W2-B or W2 complete.

## Bounded continuation: W2-C1-participant-refresh-retry

### Status

**Bounded participant post-mutation refresh retry UX completed; B1/B2a/B2b/B2c/B3 remain separate completed slices; broad W2 remains incomplete.**

### Paths

- `mobile/lib/presentation/participants/participants_mutation_cubit.dart`
- `mobile/lib/app/domain_scope.dart`
- `mobile/lib/presentation/participants/participants_mutation_widgets.dart`
- `mobile/lib/presentation/participants/participants_screen.dart`
- Focused additions in `mobile/test/presentation/participants/participants_mutation_cubit_test.dart`, `mobile/test/presentation/read_screens_test.dart`, and `mobile/test/app/domain_scope_test.dart`.
- These untracked files contain retained prior W1a/W1b content excluded from this slice.

### Behavior

- A separate `onPostMutationRefreshRetry` callback handles retry from the screen boundary.
- A successful writer result is retained even for null delete results when the initial authoritative refresh fails.
- Retry invokes only `RefreshCoordinator.retry()`/the failed-target callback and never repeats the writer; success emits the original server result.
- Retry failure stays recovery/retryable. Close suppresses late emissions, and a new actual mutation clears stale retry state.
- One `ParticipantRefreshRetry` screen-level `Retry refresh` action is labeled and accessibly rendered, has a minimum 48dp target, is disabled while loading, appears only with the mutation Cubit in loaded/empty layouts, and is absent in read-only mode.
- No optimistic read replacement is used.

### Strict-TDD evidence

| Stage | Evidence |
| --- | --- |
| RED | Unavailable because the implementation worker timed out after writing tests/implementation and returned no command evidence; no RED is fabricated. |
| GREEN/full safety-net | Fresh verifier: `cd mobile && flutter test --no-pub` = **124 passed, 0 failed**. |
| TRIANGULATE | Fresh verifier focused command: `cd mobile && flutter test --no-pub test/presentation/participants/participants_mutation_cubit_test.dart test/presentation/read_screens_test.dart test/app/domain_scope_test.dart test/presentation/participants/participants_mutation_widgets_test.dart test/presentation/participants/participant_lifecycle_actions_test.dart test/data/refresh/refresh_coordinator_test.dart` = **60 passed, 0 failed**. |
| REFACTOR | Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the seven allowed files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings. |

### Accounting and delivery

- Conservative incremental estimate: **approximately 200 authored lines**, excluding retained untracked content and formatter churn; under 350 and 400.
- Runtime/manual: **N/A**.
- No native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

- Separate bounded slice for duplicate normalized-name/history visibility and any remaining W2 triangulation; expense CRUD/selectors, policy, broad W2 acceptance, and final runtime remain deferred. Do not mark broad W2 rows complete.

## Bounded continuation: W2-C2-participant-completion-feedback

### Status

**Bounded participant completion-feedback and duplicate-name characterization slice completed; B1/B2a/B2b/B2c/B3/C1 remain separate completed slices; broad W2 remains incomplete.**

### Paths

- `mobile/lib/presentation/participants/participants_mutation_cubit.dart`
- `mobile/lib/presentation/participants/participants_mutation_widgets.dart`
- `mobile/lib/presentation/participants/participants_screen.dart`
- Focused additions in `mobile/test/presentation/participants/participants_mutation_cubit_test.dart` and `mobile/test/presentation/read_screens_test.dart`; these untracked files include retained W1a/W1b/prior W2 content excluded from this slice.

### Behavior

- Cubit emits `successMessage` only after configured authoritative refresh succeeds.
- Messages are `Participant added.`, `Participant renamed.`, `Participant archived.`, `Participant reactivated.`, and `Participant deleted.`
- Pending message is retained through post-refresh retry, including a null delete result.
- Screen-level `ParticipantMutationFeedback` is accessible/live and shown once only in mutation-enabled loaded/empty layouts; it is absent in read-only mode.
- Explicit `duplicate_participant_name` with a field error maps to validation/field-level state.
- No optimistic read replacement.

### Strict-TDD evidence

| Stage | Evidence |
| --- | --- |
| RED | Unavailable because the implementation worker timed out after writing changes and returned no command evidence; no RED is fabricated. |
| GREEN/full safety-net | Fresh verifier: `cd mobile && flutter test --no-pub` = **127 passed, 0 failed**. |
| TRIANGULATE | Fresh verifier focused command: `cd mobile && flutter test --no-pub test/presentation/participants/participants_mutation_cubit_test.dart test/presentation/read_screens_test.dart test/presentation/participants/participants_mutation_widgets_test.dart test/presentation/participants/participant_lifecycle_actions_test.dart` = **44 passed, 0 failed**. |
| REFACTOR | Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the five allowed files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings. |

### Accounting and delivery

- Conservative incremental estimate: **approximately 150–200 authored lines**, excluding retained untracked content and formatter churn; under 300 and 400.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

- Separate bounded slice for archived/history visibility and logout-during-mutation/refresh triangulation; expense CRUD/selectors, policy, broad W2 acceptance, and final runtime remain deferred. Do not mark broad W2 rows complete.

## Bounded continuation: W2-C3-participant-authority-triangulation

### Status

Bounded participant authority/lifecycle characterization coverage completed; B1/B2a/B2b/B2c/B3/C1/C2 remain separate completed slices; broad W2 remains incomplete.

### Paths

- `mobile/test/app/domain_scope_test.dart`
- `mobile/test/presentation/read_screens_test.dart`
- Production behavior was intentionally unchanged, and these untracked tests contain retained W1a/W1b/prior W2 content excluded from this slice.

### Behavior

- Scope close during writer completion or post-mutation refresh suppresses late success/failure, mutation closes before coordinator/read state, and coordinator reaches closed/idle.
- Protected delete keeps participant/read data visible and shows protected-reference/archive guidance without optimistic removal.
- Archived participant remains visible in participant/history/balance-facing reads, including archived zero-balance.

### Strict-TDD evidence

- RED: unavailable because this was characterization-only coverage and no pre-edit failure was claimed.
- GREEN/full safety-net: fresh verifier `cd mobile && flutter test --no-pub` = **132 passed, 0 failed**.
- TRIANGULATE: fresh verifier `cd mobile && flutter test --no-pub test/app/domain_scope_test.dart test/presentation/read_screens_test.dart` = **38 passed, 0 failed**.
- REFACTOR: fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the two allowed test files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative incremental estimate: **approximately 100–180 test/helper lines**, excluding retained W1a/W1b/prior W2 content in untracked files; under 400.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Perform a final read-only W2 acceptance gap audit before any broad checkbox changes; expense CRUD/selectors, policy, and final runtime remain deferred. Do not mark broad W2 rows complete from this slice.

## Bounded continuation: W2-C4-participant-refresh-recovery-view

### Status

Bounded participant refresh-recovery rendering fix completed; B1/B2a/B2b/B2c/B3/C1/C2/C3 remain separate completed slices; broad W2 remains incomplete.

### Paths

- `mobile/lib/presentation/participants/participants_screen.dart`
- Focused additions/helpers in `mobile/test/presentation/read_screens_test.dart`; retained untracked W1a/W1b/prior W2 content is excluded.

### Behavior

When a post-mutation authoritative refresh fails and participant read state is non-loaded, the mutation-enabled screen keeps the current read error/recovery message plus the existing single `Retry refresh` action, omits the misleading participant-only retry, and on successful retry returns to loaded mutation layout/feedback without repeating the writer; loaded/empty/read-only behavior remains unchanged and no optimistic data is introduced.

### Strict-TDD evidence

- **RED:** Actual focused widget test failed before the screen fix with **0 `Retry refresh` widgets** in the failed post-mutation refresh path; no fabricated RED.
- **GREEN/full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **133 passed, 0 failed**.
- **TRIANGULATE:** Fresh verifier focused command over read screens, participant mutation Cubit, DomainScope, widget/action, and refresh coordinator tests = **70 passed, 0 failed**.

  Exact command: `cd mobile && flutter test --no-pub test/presentation/read_screens_test.dart test/presentation/participants/participants_mutation_cubit_test.dart test/app/domain_scope_test.dart test/presentation/participants/participants_mutation_widgets_test.dart test/presentation/participants/participant_lifecycle_actions_test.dart test/data/refresh/refresh_coordinator_test.dart`
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the seven candidate files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative incremental estimate: **approximately 60–90 authored lines**, excluding retained untracked content and formatter churn; under 150 and 400.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Keep broad W2 rows unchecked; if continuing W2, only a bounded contract/runtime evidence slice for active+archived duplicate uniqueness and final add→rename→archive→reactivate→protected-delete scenario remains. Expense selectors/CRUD, policy, and overall W2 acceptance remain deferred.

## Bounded continuation: W2-C5-logout-during-participant-mutation

### Status

Bounded App-level logout/mutation teardown characterization completed; B1/B2a/B2b/B2c/B3/C1/C2/C3/C4 remain separate completed slices; broad W2 remains incomplete.

### Paths

- `mobile/test/app/auth_gate_test.dart`; production unchanged.
- The test uses a pending `ParticipantsWriter` through `DomainReaders` and App's injected `DomainScopeFactory`.

### Behavior

A participant mutation is in loading while logout begins; App immediately transitions to sign-in, disposes the protected DomainScope and closes the mutation Cubit before the pending writer completes; late writer completion produces no success/refresh and the writer call count remains exactly one. Existing read/scope/auth teardown behavior remains intact.

### Strict-TDD evidence

- **RED:** Unavailable because this is characterization-only and no pre-edit product failure was claimed. An initial test-harness attempt used `Future.delayed(Duration.zero)` under Flutter FakeAsync and hung; it was corrected to `tester.pump()` before final verification and is not counted as RED evidence.
- **GREEN/full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **134 passed, 0 failed**.
- **TRIANGULATE:** Fresh verifier `cd mobile && flutter test --no-pub test/app/auth_gate_test.dart test/app/domain_scope_test.dart test/presentation/participants/participants_mutation_cubit_test.dart` = **42 passed, 0 failed**.
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format for `test/app/auth_gate_test.dart` = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative incremental estimate: **approximately 40–60 authored test lines**, excluding retained test content and formatter churn; under 150 and 400.
- Runtime/manual: **N/A**; no live mobile/backend runtime journey, native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Keep broad W2 rows unchecked. The remaining W2 evidence gap is a live add→rename→archive→reactivate→protected-delete journey and mobile-to-backend duplicate active/archived contract; do not invent either. Expense selectors/CRUD and policy remain W3b/deferred. Backend contract audit found precheck plus DB uniqueness, but any concurrency/field-error contract hardening is outside this mobile-only bounded slice.

## Bounded continuation: W3a-A1-expense-amount-write-models

### Status

Bounded W3a-A1 expense amount/write-model boundary completed; W2 C1–C5 remain separate completed slices; broader W3a remains incomplete.

### Paths

- `mobile/lib/domain/write_models/write_models.dart`
- `mobile/test/domain/write_models/expense_amount_test.dart`
- Generated/API, backend, web, UI, existing expense reader, and unrelated artifacts were untouched.

### Behavior

- Immutable `ExpenseAmount`, `ExpenseContributorDraft`, and `ExpenseWriteDraft` were added.
- The parser matches `[0-9]+(?:\\.[0-9]{1,2})?` with ASCII digits, rejects surrounding whitespace, signs, separators, exponents, malformed decimals, and non-positive values, and retains the exact accepted lexical text.
- Integer-only checked cents conversion accepts `21474836.47` as 2,147,483,647 cents and rejects above-bound values.
- Draft lists are defensively copied and unmodifiable.
- No floating-point parsing, totals, splits, balances, settlement, or client monetary correction was added.

### Strict-TDD evidence

- **RED:** Actual initial focused test run failed at compile/import because the new production write-model file was not yet present; no fabricated behavioral RED.
- **GREEN:** Fresh verifier `cd mobile && flutter test --no-pub test/domain/write_models/expense_amount_test.dart` = **3 passed, 0 failed**.
- **TRIANGULATE/full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **137 passed, 0 failed**; focused tests cover accepted/rejected grammar, exact text/cents, max bound, and collection immutability.
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the two files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative estimate: **approximately 140 authored lines**, under 180 and 400.
- Runtime/manual: N/A; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Implement bounded W3a-A2 generated operation interface, request mapper, CSRF/error/incomplete-response handling, and `ExpenseRepository` writer tests; do not begin forms/Cubit/UI or check the broad W3a row yet. The server currently has no explicit application upper-bound check; the client parser follows the frozen documented bound without modifying backend.

## Bounded continuation: W3a-A2a-expense-create-edit-mapping

### Status

Bounded create/edit operation/mapping slice completed; W3a-A1 and W2 C1–C5 are separate completed slices; broader W3a remains incomplete.

### Paths

- `mobile/lib/data/repositories/expenses_repository.dart`
- `mobile/test/data/repositories/expense_writer_test.dart`
- A1 write-model dependency.
- Existing `listExpenses` and list-only operation fakes remain compatible; no generated/API/backend/web/UI/OpenSpec-unrelated files changed.

### Behavior

- Added `ExpensesWriteOperations` and `ExpensesWriter`.
- `GeneratedExpensesOperations` delegates exact generated create/edit methods.
- `ExpenseWriteDraft` maps to exact generated fields/JSON using preserved lexical amount/contributor text, IDs, description, beneficiaries, and CSRF.
- Valid server responses become `ExpenseReadModel`.
- No cents reconstruction, floating point, totals, splits, balances, settlement, or client correction.

### Strict-TDD evidence

- **RED:** Unavailable for this implementation worker because it timed out after making changes; no pre-edit RED result is fabricated.
- **GREEN/verification:** Parent direct writer test = **6 passed, 0 failed**.
- Fresh verifier combined focused adapter/model/read compatibility command = **15 passed, 0 failed**.
- Full Flutter suite = **143 passed, 0 failed**.
- Analyzer: **no issues**.
- Four-file format check: **0 changed**.
- Diff-check: no whitespace errors apart from existing LF/CRLF warnings.
- The combined evidence covers A2a/A2b and is not duplicated as separate runs.

### Accounting and delivery

- Conservative A2a allocation: **approximately 300–360 authored lines**, under 400; the combined candidate was not treated as a single review unit.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Finish W3a validation/triangulation only through bounded tests; do not begin forms/Cubit/UI or check broad W3a rows.

## Bounded continuation: W3a-A2b-expense-delete-errors

### Status

Bounded delete/error/incomplete-response slice completed; A2a/A1 and W2 C1–C5 remain separate completed slices; broader W3a remains incomplete.

### Paths

- `mobile/lib/data/repositories/expenses_repository.dart`
- `mobile/test/data/repositories/expense_writer_test.dart`
- Production read listing remains intact; no generated/API/backend/web/UI files changed.

### Behavior

- Delete passes group/expense IDs and CSRF, accepts a null 204 body without `requireReadData`.
- Missing CSRF and list-only operation fail before calls.
- Null/malformed create/edit success responses become typed corruption.
- Dio server/network failures are rethrown unchanged for future presentation mapping.

### Strict-TDD evidence

- **RED:** Unavailable because the implementation worker timed out; no fabricated RED result.
- Same fresh combined evidence: **15 focused, 143 full, analyzer clean, format 0 changed, diff-check clean except existing LF/CRLF warnings**.
- This is shared combined evidence covering A2a/A2b, not a duplicated separate run.

### Accounting and delivery

- Conservative A2b allocation: **approximately 100–150 authored lines**, under 400; the combined candidate was not treated as a single review unit.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Keep broad W3a rows unchecked; the next bounded slice may add any missing repository contract edge cases, then later W3b forms/Cubit/UI. Do not claim mobile live runtime or backend upper-bound/field-error hardening here.

## Bounded continuation: W3a-A3-server-monetary-error-forwarding

### Status

Bounded server-monetary-error forwarding characterization completed; W3a-A1/A2a/A2b and W2 C1–C5 remain separate completed slices; broader W3a remains incomplete.

### Paths

- `mobile/test/data/repositories/expense_writer_test.dart`; production unchanged in this slice. The test reuses the W3a-A2 adapter and A1 write models.

### Behavior

- A server `contribution_mismatch` `DioException` is rethrown unchanged.
- The generated request retains exact submitted top-level and contributor lexical amount strings.
- No client total, correction, split, balance, residual, or settlement computation occurs.

### Strict-TDD evidence

- **RED:** Unavailable because this is characterization-only and no pre-edit product failure was claimed; do not fabricate RED.
- **GREEN/TRIANGULATE:** Fresh verifier focused command over writer and amount-model tests = **11 passed, 0 failed**: `cd mobile && flutter test --no-pub test/data/repositories/expense_writer_test.dart test/domain/write_models/expense_amount_test.dart`.
- **Full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **144 passed, 0 failed**.
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the four W3a files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative incremental estimate: **under 40 authored lines**, under 400.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Keep broad W3a rows unchecked; remaining W3a validation gaps include malformed reference/empty-shape characterization and final contract accounting, while W3b forms/Cubit/UI remain deferred. Do not add client monetary logic or invent live runtime evidence.

## Bounded continuation: W3a-A4-expense-shape-forwarding

### Status

Bounded server-owned expense shape/reference forwarding characterization completed; W3a-A1/A2a/A2b/A3 and W2 C1–C5 remain separate completed slices; broader W3a remains incomplete.

### Paths

- `mobile/test/data/repositories/expense_writer_test.dart`
- Production unchanged in this slice. It reuses the existing W3a adapter/write models.

### Behavior

- A server `invalid_participant_reference` `DioException` is rethrown unchanged.
- A foreign participant ID and empty beneficiary list are forwarded exactly in the generated request.
- No local reference authorization, repair, contribution total, split, balance, residual, settlement, or monetary correction is introduced.
- W3b form-level required-field validation remains separate.

### Strict-TDD evidence

- **RED:** Unavailable because this is characterization-only and no pre-edit product failure was claimed; do not fabricate RED.
- **GREEN/TRIANGULATE:** Fresh verifier focused command = **11 passed, 0 failed** (8 writer + 3 amount-model tests): `cd mobile && flutter test --no-pub test/data/repositories/expense_writer_test.dart test/domain/write_models/expense_amount_test.dart`.
- **Full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **144 passed, 0 failed**.
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the four W3a files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative incremental estimate: **under 45 authored lines**, under 400.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Keep broad W3a rows unchecked; the remaining W3a requirement work is process-level RED/GREEN/TRIANGULATE/refactor accounting and a decision about whether form-level shape validation belongs in W3b. Do not add client monetary logic or invent live runtime evidence.

## Bounded continuation: W3b-S1-expense-participant-selection

### Status

Bounded W3b participant selection-helper slice completed; W3a-A1/A2a/A2b/A3/A4 and W2 C1–C5 remain separate completed slices; broader W3b remains incomplete.

### Paths

- `mobile/lib/presentation/expenses/expense_participant_selection.dart`
- `mobile/test/presentation/expenses/expense_participant_selection_test.dart`; existing screens, Cubits, generated/API, backend, web, README, and unrelated artifacts untouched.

### Behavior

- Immutable `ExpenseParticipantOption`; new expense returns active participants only in input/server order.
- Edit returns all active plus only archived IDs referenced by existing expense contributors/beneficiaries.
- Current participant rows/names win; absent archived references are reconstructed only from nested server metadata.
- Duplicate IDs are removed, order is deterministic, output is unmodifiable, and inputs are untouched.
- No money, authorization, optimistic state, or UI mutation.

### Strict-TDD evidence

- **RED:** Actual focused test compile/import failure before the new production file existed; no fabricated behavioral RED.
- **GREEN/TRIANGULATE:** Fresh verifier focused command over selection and W3a model/writer tests = **17 passed, 0 failed**.
- Exact command: `cd mobile && flutter test --no-pub test/presentation/expenses/expense_participant_selection_test.dart test/domain/write_models/expense_amount_test.dart test/data/repositories/expense_writer_test.dart`
- **Full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **150 passed, 0 failed**.
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the two S1 files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative estimate: **179 nonblank authored lines**, under 180 and 400.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Implement the next bounded W3b mutation-state slice (create/edit/delete validation, server result then refresh/retry, duplicate/close guards, Dio error mapping) without forms/UI/composition yet; keep broad W3b rows unchecked.

## Bounded continuation: W3b-S2a-expense-mutation-core

### Status

Bounded W3b expense mutation-core slice completed; W3b-S1, W3a-A1/A2a/A2b/A3/A4, and W2 C1–C5 remain separate completed slices; broader W3b remains incomplete.

### Paths

- `mobile/lib/presentation/expenses/expense_mutation_cubit.dart`
- `mobile/test/presentation/expenses/expense_mutation_cubit_test.dart`
- No forms/screens/composition yet; generated/API, backend, web, README, and unrelated artifacts untouched.

### Behavior

- Feature-local immutable mutation status/failure/state is exposed.
- Valid create/edit/delete calls are single-writer operations and remain loading until `onMutationSuccess` completes; completion then shows `Expense created.`, `Expense updated.`, or `Expense deleted.`, with the server result or null delete result retained.
- Local validation rejects blank trimmed descriptions, empty contributors/beneficiaries, and blank contributor IDs before invoking the writer.
- Duplicate calls are ignored, and close suppresses late completions.
- No local amount reparse/reconstruction, contribution totals, correction, split, balance, settlement, authorization, or optimistic displayed data was added.
- Detailed Dio 401/403/field/action/network/5xx mapping and post-refresh retry are deliberately deferred to S2b.

### Strict-TDD evidence

- **RED:** Unavailable because the implementation worker timed out after making changes; no pre-edit RED evidence is fabricated.
- **GREEN/TRIANGULATE:** Fresh verifier focused command = **20 passed, 0 failed**: `cd mobile && flutter test --no-pub test/presentation/expenses/expense_mutation_cubit_test.dart test/presentation/expenses/expense_participant_selection_test.dart test/data/repositories/expense_writer_test.dart test/domain/write_models/expense_amount_test.dart`.
- **Full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **153 passed, 0 failed**.
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the four expense mutation/selection files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Approximately **220 nonblank authored lines**, under 230 and 400.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Implement bounded W3b-S2b detailed Dio/error mapping plus post-success refresh retry without forms/composition; keep broad W3b rows unchecked.

## Bounded continuation: W3b-S2b-expense-mutation-recovery

### Status

**Bounded W3b expense mutation recovery/error slice completed; W3b-S1/S2a and W3a-A1/A2a/A2b/A3/A4 and W2 C1–C5 remain separate completed slices; broader W3b remains incomplete.**

### Paths

- `mobile/lib/presentation/expenses/expense_mutation_cubit.dart`
- `mobile/test/presentation/expenses/expense_mutation_cubit_test.dart`
- No forms/screens/composition yet; generated/API, backend, web, README, and unrelated artifacts were untouched.

### Behavior

- Dio 401 maps to unauthorized, 403 to forbidden, and network/no-response/5xx failures to recovery.
- A valid generated `ErrorResponse` or map payload preserves its message and field errors as validation; malformed payloads and corruption exceptions map to corruption. Unknown or noncorruption repository/write exceptions map to recovery without leaking details.
- Writer failure is not retryable. A post-success refresh failure retains the server result and exact success message, exposes one retry only when a callback exists, never repeats the writer, and preserves a null delete result. Retry failure remains retryable; busy/close guards suppress late state, and a new non-busy mutation clears stale retry state.
- No monetary, authorization-decision, optimistic, form, screen, or composition logic was added.

### Strict-TDD evidence

- **RED:** Unavailable because the implementation worker timed out after making changes; no fabricated pre-edit RED evidence.
- **GREEN/TRIANGULATE:** Fresh verifier focused command = **26 passed, 0 failed**; exact command: `cd mobile && flutter test --no-pub test/presentation/expenses/expense_mutation_cubit_test.dart test/presentation/expenses/expense_participant_selection_test.dart test/data/repositories/expense_writer_test.dart test/domain/write_models/expense_amount_test.dart`.
- **Full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **160 passed, 0 failed**.
- **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the four expense mutation/selection files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

### Accounting and delivery

- Conservative estimate: **approximately 300 nonblank authored lines for the S2b incremental addition**, under the 400-line bounded-slice limit.
- The shared untracked S2a+S2b files total about **547 physical lines**, but they are documented as two independently verified bounded slices; the combined untracked candidate is not claimed as one sub-400 slice.
- Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

### Next action

Implement the next bounded W3b expense form/action slice (field validation, active/reference archived options, cancellation/confirmation, and Cubit invocation) without DomainScope/read-screen composition; keep broad W3b rows unchecked.


    ## Bounded continuation: W3b-S3a-expense-write-form

    ### Status

    **Bounded W3b write-form slice completed;** W3b-S1/S2a/S2b, W3a-A1/A2a/A2b/A3/A4, and W2 C1–C5 remain separate completed slices; broader W3b remains incomplete.

    ### Paths

    - `mobile/lib/presentation/expenses/expense_mutation_widgets.dart`
    - `mobile/test/presentation/expenses/expense_mutation_widgets_test.dart`
    - No delete action, DomainScope/read-screen composition, generated/API, backend, web, README, or unrelated artifacts changed.

    ### Behavior

    - `ExpenseWriteForm` consumes the S1 filtered options. New forms default the first contributor with blank contribution and all supplied active beneficiaries; edit forms initialize server cents as two-decimal lexical text and retain contributor/beneficiary IDs, including supplied archived references.
    - The form collects labeled description, amount, contributor IDs/contribution amounts, and beneficiaries with 48dp actions. Local Form/group validation blocks blank description, malformed amount/contribution, and missing contributors/beneficiaries/IDs before Cubit/writer invocation. Valid create/edit forwards raw lexical values.
    - `StreamBuilder` loading disables submit/add/remove/select/toggle/cancel and prevents duplicate submit. Cancel invokes its callback, and server feedback is accessible.
    - No monetary totals/corrections/splits/balances/settlement, authorization, optimistic read replacement, or delete confirmation was added.

    ### Strict-TDD evidence

    - **RED:** Unavailable because the implementation worker timed out during the form work/compaction; no fabricated pre-edit RED evidence. The later compaction was behavior-preserving.
    - **GREEN/TRIANGULATE:** Fresh verifier focused command = **30 passed, 0 failed**; exact command: `cd mobile && flutter test --no-pub test/presentation/expenses/expense_mutation_widgets_test.dart test/presentation/expenses/expense_mutation_cubit_test.dart test/presentation/expenses/expense_participant_selection_test.dart test/data/repositories/expense_writer_test.dart test/domain/write_models/expense_amount_test.dart`.
    - **Full safety-net:** Fresh verifier `cd mobile && flutter test --no-pub` = **163 passed, 0 failed**.
    - **REFACTOR:** Fresh verifier `cd mobile && flutter analyze` = **no issues**; check-only Dart format over the six expense form/mutation/selection files = **0 changed**; `git diff --check` = no whitespace errors apart from existing LF/CRLF warnings.

    ### Accounting and delivery

    - Post-format nonblank counts: **243 production + 156 test = 399 total**, under the 400-line bounded slice limit by one line; no larger allowance is claimed.
    - Runtime/manual: **N/A**; no native review/receipt/commit/push because clone-local RDD is disabled.

    ### Next action

    Implement bounded W3b-S3b delete confirmation/action and its tests without DomainScope/read-screen composition; keep broad W3b rows unchecked.

## Final continuation: mobile-domain-features completion audit

### Status

All implementation-owned tasks 1–59 are complete. The remaining parent-owned rows are intentionally open because receipt-driven development is disabled for this clone and no native review or native changed-line forecast was authorized or run.

### Completed implementation and evidence

- W1a authenticated shell, protected-scope disposal, route/group/role rejection, five read destinations, distinct authorization messaging, recovery states, safe areas, semantic labels, adaptive navigation, and all-settled read-only settlement are implemented and covered by focused characterization tests.
- W1b `RefreshCoordinator` owns explicit participant/expense/policy/unknown impact plans, waits for all required REST reloads, coalesces invalidations, retries only failed targets, and keeps WebSocket frames invalidation-only.
- W2 participant lifecycle supports add, trim/rename, archive, reactivate, protected delete, server errors, refresh/retry, archived visibility, and close/logout guards.
- W3a preserves lexical money text at an integer-cent boundary, uses existing generated expense operations through non-generated adapters, forwards server validation/corruption/auth failures, and performs no client monetary derivation.
- W3b supports archived-reference selection, create/edit/delete mutation state, confirmation/cancellation, loading and duplicate guards, authoritative refresh/retry, null delete results, and optional read-screen composition.
- W4 uses only the generated group PATCH operation and `owner_only`/`any_member`, provides role-aware policy affordances without making client authorization authoritative, refreshes server state, and preserves accessible recovery behavior.

### Verification evidence

- Full mobile safety net after final normalization: `cd mobile && flutter test --no-pub` — **211 passed, 0 failed**.
- Static analysis: `cd mobile && flutter analyze` — **No issues found**.
- Check-only normalization: `dart format --output=none --set-exit-if-changed` over 23 changed non-generated Dart files — **0 changed**.
- Repository hygiene: `git diff --check` passed; generated API output and `mobile/README.md` are unchanged; pre-existing untracked `INICIO_LOCAL.md` was preserved.
- Runtime/manual harness: **N/A** — no live mobile/backend runtime or emulator boundary was available; no runtime evidence is fabricated.

### Parent-owned deferred actions

- `[ ] Start or reuse one bounded native review ...` remains unchecked because clone-local receipt-driven development is disabled; ordinary repository policy remains the delivery path.
- `[ ] Confirm the native changed-line forecast ...` remains unchecked because no native review/forecast operation was run; each implementation unit was kept below the documented 400-line boundary by explicit slice scope and recorded worker estimates.

The change is implementation-complete and OpenSpec-valid. If strict native receipt evidence is required before archive/delivery, explicitly enable receipt-driven development and run its native lifecycle; this continuation does not enable it implicitly.
