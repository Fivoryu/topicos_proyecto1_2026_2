# Implementation Tasks: Complete Mobile Domain Features

This plan implements the approved full mobile domain in bounded, dependency-ordered work units. All work stays under `mobile/lib/**` and `mobile/test/**`; generated OpenAPI output, `mobile/README.md`, backend/web code, and both existing SDD changes remain untouched. The server remains authoritative for authorization, monetary consistency, balances, residuals, and settlement.

## Review Workload Forecast

| Work unit | Estimated changed lines | Under 400-line budget | Chaining/splitting recommendation | Review boundary |
| --- | ---: | --- | --- | --- |
| W1a — authenticated shell completion and boundary hardening | 180–250 | Yes | Keep as one unit; split again if Native forecasts above 400 | Complete the retained shell, auth boundary, disposal, route rejection, and missing triangulation |
| W1b — authoritative refresh and invalidation | 220–300 | Yes | Keep as one unit; split again if Native forecasts above 400 | RefreshCoordinator, WebSocket invalidation-only wiring, coalescing, failure/retry |
| W2 — participant lifecycle (A1/A2 bounded slices) | 228 + 166 actual (394 total) | Yes, narrowly | Keep A1/A2 separate; split again if any native forecast exceeds 400 | Participant writer, Cubit/forms, lifecycle rules, affected-resource refresh |
| W3a — expense write data boundary | 260–350 | Yes | Split W3 before implementation | Request mappers, lexical amount parser, writer repository, error mapping |
| W3b — expense CRUD interaction | 340–390 | Yes, narrowly | Split W3 before implementation | Create/edit/delete Cubits/forms, archived references, confirmation, refresh |
| W4 — policy and integration hardening | 300–380 | Yes, narrowly | Keep as one unit; split if native forecast exceeds 400 | Policy mutation, cross-feature integration, accessibility/regression coverage |
| Full change | 1,630–2,060 | No | Bounded slices are required; chained PRs are not yet required if each slice remains below budget | Full-domain delivery across six reviewable units |

Decision resolved before apply: **Yes** — the user approved strict slicing after the prior W1 attempt timed out at 735 changed lines. Retain the partial implementation, continue with W1a and W1b as separate bounded units, and never combine them or exceed 400 authored changed lines per unit. If Native forecasts any unit above 400 lines, split it again and ask before continuing. No size exception is authorized, and no chain strategy is selected unless a later Native forecast makes chained delivery necessary.

Decision needed before apply: No for the current forecast
Chained PRs recommended: No
Chain strategy: not selected
400-line budget risk: High in aggregate; each current unit is forecast below 400

### Timed-out attempt recovery

- The first W1 attempt was interrupted after a 1200000ms timeout with 735 changed lines and no final apply evidence.
- The retained W1 files are partial state, not completed task evidence. The next apply must inspect and test them before checking any task complete.
- W1a is limited to shell/auth/disposal/route-boundary completion. W1b is the separate refresh/invalidation unit below; do not implement W1b during W1a.

## Global implementation controls

- Use only existing generated operations discovered in `mobile/lib/generated/api/**`; never edit, regenerate, patch, or wrap missing operations with invented fallbacks. <!-- sdd-owner: implementation -->
- Keep generated-client calls inside repository/service boundaries; expose immutable non-generated domain/write models to Cubits and views. <!-- sdd-owner: implementation -->
- Preserve integer-cents boundaries and the frozen lexical grammar `[0-9]+(?:\.[0-9]{1,2})?`; never use floating-point parsing/formatting or derive splits, contribution totals, balances, residuals, or settlement transfers. <!-- sdd-owner: implementation -->
- For every unit, record strict-TDD RED/GREEN/TRIANGULATE/REFACTOR evidence in the apply/verify artifacts: RED and TRIANGULATE use `cd mobile && flutter test --no-pub <focused-file>`; GREEN and REFACTOR use `cd mobile && flutter test --no-pub`. <!-- sdd-owner: implementation -->
- Keep a safety-net full-suite result for every unit and record runtime-harness evidence, or explicitly record `N/A` with the reason when no separate runtime boundary exists. <!-- sdd-owner: implementation -->

## W1a — Authenticated shell completion and boundary hardening

**Start:** a partial authenticated shell, domain scope, five read destinations, and focused tests remain from the timed-out W1 attempt. **Finish:** the retained shell passes fresh strict-TDD coverage for authenticated entry, session expiry/logout disposal, route/group/role rejection, five destinations, server-derived settlement display, and loading/error/recovery behavior, without implementing the separate refresh coordinator. **Depends on:** approved shell spec, existing session/transport and read repositories/Cubits. **Traceability:** `specs/mobile-domain-shell/spec.md` (authenticated composition, one active group, settlement display); `specs/mobile-policy-refresh-ux/spec.md` (accessible states).

### Implementation tasks

- [x] Bounded continuation: guard `GroupCubit.load` against late success/failure emissions after protected scope disposal, with focused domain-scope regression coverage. <!-- sdd-owner: implementation -->
- [x] Bounded continuation: guard `ParticipantsCubit.load`, `ExpensesCubit.load`, `BalancesCubit.load`, and `SettlementCubit.load` against late success/failure emissions after protected scope disposal, with focused domain-scope regression coverage. <!-- sdd-owner: implementation -->
- [x] Bounded continuation: verify retained authenticated App scope disposal on logout/session expiry, including failed logout and forbidden reads, with focused auth-gate/domain-scope coverage. <!-- sdd-owner: implementation -->
- [x] Inspect the retained partial shell and define the smallest remaining constructor/lifecycle seams in `mobile/lib/app/app.dart`, `mobile/lib/app/domain_scope.dart`, and `mobile/lib/presentation/domain/domain_shell.dart`; do not introduce group switching, a new DI package, or the separate refresh coordinator. <!-- sdd-owner: implementation -->
- [x] Bounded continuation: W1a-read-state-ux covers authenticated App navigation across all five read destinations, loading-time session expiry/logout disposal, App-boundary route rejection, distinct 401/403 read messaging, Cubit-provided messages, and safe-area, touch-target, and large-text checks without starting W1b. <!-- sdd-owner: implementation -->
- [x] RED: add focused tests in `mobile/test/app/domain_scope_test.dart`, `mobile/test/presentation/domain/domain_shell_test.dart`, and `mobile/test/app/auth_gate_test.dart` for the still-missing authenticated-entry, logout-during-load, expired-session, route group/role rejection, disposal, and five-destination behaviors; preserve existing tests and record the real pre-edit safety net. <!-- sdd-owner: implementation -->
- [x] GREEN: complete the retained authenticated per-session/per-group composition, nullable session clearing, protected-state disposal, adaptive labeled `NavigationBar`/large-window `NavigationRail`, predictable back behavior, safe areas, semantic labels, and explicit all-settled/read-only settlement presentation. Do not wire W1b refresh coordination here. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE: add focused coverage for logout/session expiry during loading, 401 without retry loops, 403 as forbidden rather than sign-in retry, route-supplied group/role rejection, empty/loading/recovery states, and settlement failure retry without local replacement data. <!-- sdd-owner: implementation -->
- [x] REFACTOR: dispose/cancel protected Cubits, subscriptions, refresh callbacks, and in-flight ownership at logout/session expiry; preserve token-based theme, 48dp targets, readable dynamic text, contrast, and no emoji structural icons without changing `mobile/README.md`. <!-- sdd-owner: implementation -->
- [x] Safety-net: run `cd mobile && flutter test --no-pub` and record the focused and full results plus a manual/runtime scenario covering sign-in → domain → logout → protected-route denial. <!-- sdd-owner: implementation -->

**Rollback boundary:** revert `app.dart`, `app/domain_scope.dart`, `presentation/domain/domain_shell.dart`, shell/read composition changes, and their tests together; retain the prior authenticated group read view and transport/session behavior.

## W1b — Shared authoritative refresh and WebSocket invalidation

**Start:** W1a shell exists but mutation/invalidation coordination is not centralized. **Finish:** `RefreshCoordinator` owns explicit impact plans, waits for all required REST reloads, exposes retryable failure, and ignores WebSocket payload data. **Depends on:** W1a scope ownership and existing listener/read Cubits. **Traceability:** `specs/mobile-policy-refresh-ux/spec.md` (authoritative refresh, invalidation-only, recovery).

### Implementation tasks

- [x] RED: add `mobile/test/data/refresh/refresh_coordinator_test.dart` cases for participant, expense, and policy impact plans; all-required-reloads completion; uncertain-impact conservative reload; partial failure; retry; and `data_changed` payloads that never replace REST state. <!-- sdd-owner: implementation -->
- [x] GREEN: implement `mobile/lib/data/refresh/refresh_coordinator.dart` with registered reload callbacks, explicit impact sets, completion-after-success semantics, retryable refresh failure, and integration with the existing WebSocket listener's `data_changed` event only. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE: verify logout during refresh, duplicate invalidation coalescing, incomplete/corrupt REST responses, 401/403 handling, and no fabricated balances/settlement/residuals after refresh failure. <!-- sdd-owner: implementation -->
- [x] REFACTOR: keep coordinator ownership scoped to `DomainScope`, avoid a second domain-data cache, and expose accessible retry/action state to the shell and feature Cubits. <!-- sdd-owner: implementation -->
- [x] Safety-net: run `cd mobile && flutter test --no-pub` and retain existing WebSocket/read-repository tests unchanged except for the required listener seam. <!-- sdd-owner: implementation -->

**Rollback boundary:** revert only `mobile/lib/data/refresh/refresh_coordinator.dart`, listener integration, and coordinator tests; mutations may still be removed independently while existing read reloads remain available.

## W2 — Participant lifecycle

**Start:** participant access is read-only. **Finish:** add, trim/rename, archive, reactivate, and protected delete are available through existing operations with server-derived outcomes and affected-resource refresh. **Depends on:** W1a/W1b scope and refresh interfaces. **Traceability:** `specs/mobile-participant-lifecycle/spec.md` (all requirements); `specs/mobile-policy-refresh-ux/spec.md` (refresh and accessible recovery).

### Implementation tasks

- [x] Map the existing generated participant operations by discovery in `mobile/lib/generated/api/**` and implement the non-generated repository writer boundary in `mobile/lib/data/repositories/participants_repository.dart`; all five approved operations were present, so no fallback was added. <!-- sdd-owner: implementation -->
- [x] Bounded W2-A1: implement and test add/rename request trimming, strict blank-name rejection, CSRF injection, and `ParticipantResponse` → `ParticipantReadModel` mapping; keep this slice at 228 authored lines. <!-- sdd-owner: implementation -->
- [x] Bounded W2-A2: implement and test archive/reactivate/delete delegation with group/participant scope, CSRF injection, server response mapping, and void delete handling; keep this slice at 166 authored lines. <!-- sdd-owner: implementation -->
- [x] Bounded W2-B1: add and test an injectable participant mutation writer/Cubit for add, trim/blank validation, rename, archive, reactivate, delete, duplicate-submit protection, server-result-after-completion, typed field/auth/forbidden/protected/recovery/corruption mapping, and close guards; forms/widgets, DomainScope, RefreshCoordinator, logout integration, and broader W2 remain deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W2-B2a: add and test reusable `ParticipantNameForm` add/rename UI using the existing mutation Cubit, with visible labels, trim/blank validation, inline and live errors, loading/disabled/progress states, cancellation, and 48dp controls; lifecycle action widgets remain a separate future bounded B2b slice. <!-- sdd-owner: implementation -->
- [x] Bounded W2-B2b: add and test reusable `ParticipantLifecycleActions` using server archived state for archive/reactivate, 48dp loading/disabled controls, labeled destructive-delete confirmation, cancellation paths with no call, single confirmed delete, and accessible protected/recovery errors. <!-- sdd-owner: implementation -->
- [x] Bounded W2-B2c: integrate an optional `ParticipantsMutationCubit` into `ParticipantsScreen`, preserving read-only behavior when omitted, exposing add/rename/archive/reactivate/delete controls when supplied, preserving empty guidance, rename/cancel, and authoritative read data without optimistic replacement; DomainScope/RefreshCoordinator/logout integration remains deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W2-B3: expose nullable `ParticipantsWriter` through transport-backed `DomainReaders`, create and own the participant mutation Cubit in `DomainScope` only when a writer exists, forward it through `DomainShell`, await participant-impact refresh before mutation success, map refresh failure to recovery, and close mutation ownership before refresh/read state. <!-- sdd-owner: implementation -->
- [x] Bounded W2-C1: add a screen-level participant refresh retry for post-mutation authoritative reload failures; retain the server result, retry only failed RefreshCoordinator targets without repeating the writer, keep close/new-mutation guards, and show one labeled 48dp action only in mutation-enabled layouts; broader W2 remains deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W2-C2: add server-authoritative lifecycle completion feedback for participant add/rename/archive/reactivate/delete, retain feedback through refresh retry including null delete results, and characterize duplicate-name field errors without optimistic read replacement; broader W2 remains deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W2-C3: characterize participant authority and lifecycle safety for scope close during writer/refresh, protected-delete retention, and archived participant visibility across participant/history/balance reads; production behavior remains server-authoritative and broader W2 remains deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W2-C4: keep the participant refresh-retry action visible when post-mutation authoritative reload puts the participant read Cubit into loading/error/recovery, suppress the misleading participant-only retry, and verify retry does not repeat the writer; broader W2 remains deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W2-C5: characterize App-level logout during an in-flight participant mutation; close DomainScope and mutation ownership before late writer completion and ensure no late success/refresh or repeated writer; broader W2 remains deferred. <!-- sdd-owner: implementation -->
- [x] RED: add repository and Cubit tests under `mobile/test/data/repositories/` and `mobile/test/presentation/participants/` for request trimming, add/rename/archive/reactivate/delete commands, immutable displayed state before success, and server field/action error mapping. <!-- sdd-owner: implementation -->
- [x] GREEN: add participant mutation models/Cubits and form/action widgets under `mobile/lib/domain/` and `mobile/lib/presentation/participants/`; preserve IDs/history, require confirmation for destructive actions, and show loading/disabled, validation, 401, 403, protected-reference, and recovery states. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE: cover duplicate normalized names across active/archived participants, whitespace-only names, logout during mutation, duplicate taps, never-used deletion, referenced deletion protection, archive/reactivate transitions, and server-authoritative zero-balance/history visibility. <!-- sdd-owner: implementation -->
- [x] REFACTOR: connect successful lifecycle commands to the participant impact plan (participants, expenses/history, balances, settlement), keep role affordances usability-only, and meet visible-label, semantic-order, safe-area, contrast, and 48dp requirements. <!-- sdd-owner: implementation -->
- [x] Safety-net: run `cd mobile && flutter test --no-pub` plus the focused participant repository/Cubit/widget commands; record a runtime scenario for add → rename → archive → reactivate and protected delete. <!-- sdd-owner: implementation -->

**Rollback boundary:** revert participant writer models/adapters, mutation Cubits/forms/actions, participant integration, and participant tests together; preserve participant read screens and authoritative read data.

## W3a — Expense write data boundary

**Start:** expense repository supports listing only. **Finish:** existing expense create/edit/delete operations can receive contract-shaped requests through non-generated adapters with safe lexical amount validation and typed failures. **Depends on:** W1b refresh contracts and existing generated API surface. **Traceability:** `specs/mobile-expense-crud/spec.md` (contract submission and local/server validation); `specs/mobile-policy-refresh-ux/spec.md` (error mapping).

### Implementation tasks

- [x] Bounded W3a-A1: add immutable non-generated expense write drafts and an integer-only lexical amount parser that preserves accepted text, enforces the frozen positive grammar and 2,147,483,647-cent bound, and defensively copies draft collections; repository mapping remains deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W3a-A2a: extend the non-generated expense operation boundary with exact generated create/edit contracts, map immutable drafts to lexical `ExpenseWriteRequest` DTOs, inject CSRF, and map valid server responses without local monetary derivation; delete/error coverage remains a separate A2b slice. <!-- sdd-owner: implementation -->
- [x] Bounded W3a-A2b: add expense delete delegation accepting null 204 bodies, typed missing-CSRF/list-only/incomplete-response failures, and unchanged propagation of 401/403/field/action/network/5xx errors; forms/Cubit/UI remain deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W3a-A3: characterize server-authoritative contribution-mismatch forwarding and prove submitted lexical amount strings remain unchanged without client-side monetary correction; broader W3a remains deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W3a-A4: characterize server-owned malformed participant references and empty beneficiary shape forwarding without local repair; broad W3a remains deferred. <!-- sdd-owner: implementation -->
- [x] Confirm the existing generated `ExpenseWriteRequest`, contributor request, and create/edit/delete operation signatures in `mobile/lib/generated/api/**`; consume only those signatures and leave every generated file untouched. <!-- sdd-owner: implementation -->
- [x] RED: add focused tests in `mobile/test/domain/write_models/expense_amount_test.dart` and `mobile/test/data/repositories/expense_writer_test.dart` for accepted `1`, `1.2`, `1.20`, `0001.05`; rejection of whitespace/signs/separators/exponents/`.5`/`1.`/over-precision/zero; overflow/lossless bounds; no request on invalid input; and server monetary-consistency errors without client correction. <!-- sdd-owner: implementation -->
- [x] GREEN: implement non-generated write models/mappers under `mobile/lib/domain/write_models/` and `mobile/lib/data/repositories/`; validate top-level and contributor lexical text with checked integer-only arithmetic, retain accepted request text, map 401/403/field/action/network/5xx/incomplete responses, and never total contributions or calculate monetary outcomes. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE: test malformed references, missing description/contributor/beneficiary, overflow at the confirmed server integer bound, duplicate calls, corruption/recovery responses, and exact generated request strings. <!-- sdd-owner: implementation -->
- [x] REFACTOR: keep generated DTO calls isolated, make models immutable, and ensure no floating-point (`double`/`num`) monetary parsing or formatting enters the write boundary. <!-- sdd-owner: implementation -->
- [x] Safety-net: run `cd mobile && flutter test --no-pub` and record focused mapper/repository results. <!-- sdd-owner: implementation -->

**Rollback boundary:** revert only expense write models, parser, mappers, writer adapters, and their tests; leave expense listing/read presentation intact.

## W3b — Expense CRUD interaction

**Start:** W3a writer boundary is stable; expense history is read-only. **Finish:** create/edit/delete forms and mutation states use server responses followed by authoritative refresh, with archived-reference rules and destructive confirmation. **Depends on:** W1a/W1b, W2 participant read models, and W3a. **Traceability:** `specs/mobile-expense-crud/spec.md` (all requirements); `specs/mobile-participant-lifecycle/spec.md` (archived selection); `specs/mobile-policy-refresh-ux/spec.md` (UX/recovery).

### Implementation tasks

- [x] Bounded W3b-S1: add pure immutable expense participant selection options that use active participants for new expenses and retain only referenced archived participants for edits, including server-provided nested metadata fallback and stable deduplication; mutation/forms remain deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W3b-S2a: add feature-local expense mutation state and create/edit/delete commands with description/participant-shape validation, loading/duplicate/close guards, awaited authoritative-refresh callback, server result capture, and exact completion feedback; detailed Dio mapping/retry and forms remain deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W3b-S2b: add typed expense mutation failure mapping for authorization, validation, transport, and corruption responses plus one post-success refresh retry that retains server results/null delete and never repeats the writer; forms/UI/composition remain deferred. <!-- sdd-owner: implementation -->
- [x] Bounded W3b-S3a: add the expense write form for description, lexical contract/contribution amounts, participant and beneficiary selection, active/reference-archived options, local field/group validation, loading/cancel controls, and create/edit Cubit invocation; deletion confirmation and read-screen composition remain deferred. <!-- sdd-owner: implementation -->
- [x] RED: add Cubit/widget tests under `mobile/test/presentation/expenses/` for valid create/edit/delete, invalid shape, archived referenced edit selection, unrelated archived exclusion, cancellation, duplicate submit/delete prevention, server 401/403/validation, and refresh failure. <!-- sdd-owner: implementation -->
- [x] GREEN: implement expense mutation Cubits/forms/actions under `mobile/lib/presentation/expenses/`; collect description, contract amount text, contributors, beneficiaries, and references; default new forms to active participants; retain only referenced archived participants in edits; and confirm destructive deletion. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE: verify displayed expenses remain unchanged until successful REST refresh, server contribution mismatch is shown without correction, logout during submit, disabled progress states, empty/history/all-settled transitions, field errors near labeled fields, semantic announcements, and predictable back/cancel paths. <!-- sdd-owner: implementation -->
- [x] REFACTOR: connect create/edit/delete to the conservative expense impact plan (expenses, balances, settlement, and participants when selector/name/status impact is possible); keep settlement read-only and server-derived. <!-- sdd-owner: implementation -->
- [x] Safety-net: run `cd mobile && flutter test --no-pub` plus focused expense Cubit/widget commands; record a runtime scenario for create → refreshed history/balance/settlement, edit with archived reference, and cancelled/confirmed delete. <!-- sdd-owner: implementation -->

**Rollback boundary:** revert expense mutation Cubits/forms/actions, expense navigation affordances, integration, and tests; retain W3a writer code only if no unsupported API behavior was discovered, otherwise revert W3a with this unit.

## W4 — Group policy and integration hardening

**Start:** shell, refresh boundary, participants, and expense CRUD are independently usable. **Finish:** supported policy mutation and cross-feature acceptance are integrated without stale state, accessibility regressions, or unsupported actions. **Depends on:** W1b, W2, W3a, and W3b. **Traceability:** `specs/mobile-policy-refresh-ux/spec.md` (policy, refresh, WebSocket, UX); `specs/mobile-domain-shell/spec.md` (domain reachability and settlement read-only).

### Implementation tasks

- [x] Confirm the existing generated group update operation and supported policy enum values (`owner_only`, `any_member`) in `mobile/lib/generated/api/**`; do not add a policy operation or unsupported value. <!-- sdd-owner: implementation -->
- [x] RED: add policy repository/Cubit/widget tests under `mobile/test/data/repositories/group_writer_test.dart` and `mobile/test/presentation/group/` for owner/member × policy matrix, supported-value filtering, 401/403/validation, duplicate submit, no optimistic policy, and post-success refresh. <!-- sdd-owner: implementation -->
- [x] GREEN: implement the policy writer/Cubit and role-aware affordance in `mobile/lib/data/`, `mobile/lib/domain/`, and `mobile/lib/presentation/group/`; server-derived role/policy controls usability only, while successful updates refresh group/policy and dependent presentation. <!-- sdd-owner: implementation -->
- [x] TRIANGULATE: add cross-feature tests for each mutation impact set, WebSocket invalidation-only behavior, refresh failure/retry, protected-route re-entry, corrupt responses, archived history/balances, and explicit all-settled/read-only settlement. <!-- sdd-owner: implementation -->
- [x] REFACTOR: perform accessibility and responsive regression hardening across `mobile/lib/presentation/**`: visible labels, inline/actionable errors, semantic icon labels, safe areas, predictable back navigation, 48dp targets, token colors/contrast, dynamic text, and no redesign or emoji icons. <!-- sdd-owner: implementation -->
- [x] Safety-net: run `cd mobile && flutter test --no-pub` and record focused policy/integration results plus a manual/runtime matrix for owner/member policy attempts and mutation-to-refresh recovery. <!-- sdd-owner: implementation -->

**Rollback boundary:** revert policy writer/Cubit/UI and integration-hardening changes together; preserve the previously working shell, read repositories, and server-derived settlement display.

## Parent-owned post-apply actions

- [ ] Start or reuse one bounded native review for the completed candidate after all source-mutating normalization and before delivery; preserve the exact receipt and review boundary. <!-- sdd-owner: parent -->
- [ ] Confirm the native changed-line forecast before each unit; if any unit exceeds 400 authored changed lines, stop and decide whether to split again or select a permitted delivery exception/chain strategy. <!-- sdd-owner: parent -->
