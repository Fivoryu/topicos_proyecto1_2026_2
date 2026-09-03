# Mobile Domain Features Handoff

## Status

The mobile domain change is **not complete**. This handoff is the starting point for the next implementer. The authoritative task ledger is [`tasks.md`](./tasks.md); checked rows are bounded slices, not broad-workstream completion.

Current verified mobile baseline:

- `cd mobile && flutter test --no-pub`: **163 passed, 0 failed**.
- `cd mobile && flutter analyze`: **no issues**.
- The latest bounded W3b form slice is **399 post-format nonblank authored lines** (243 production + 156 test) and is intentionally kept below the 400-line review limit.
- Runtime/manual evidence is `N/A`: no separate mobile/backend runtime harness is available.
- No native review/receipt exists because clone-local receipt-driven development is disabled.

## Implemented bounded slices

- W1a bounded shell/auth/read-state and disposal continuations.
- W2 participant writer, mutation Cubit, forms/actions, screen composition, authoritative refresh/retry, completion feedback, archived visibility, close, and logout characterizations.
- W3a immutable expense write models, integer-only lexical amount parsing, generated-request adapters, CSRF injection, delete handling, corruption failures, and server-error/reference forwarding characterizations.
- W3b-S1 participant option selection with active-only new forms and referenced-archived edit recovery.
- W3b-S2a expense mutation state and create/edit/delete commands.
- W3b-S2b typed expense failure mapping and one post-success refresh retry.
- W3b-S3a expense write form with local field/group validation and create/edit Cubit invocation.

## Remaining implementation order

### 1. W3b-S3b — Delete confirmation/action

Add a reusable expense delete action that:

- requires explicit confirmation before calling `ExpenseMutationCubit.delete`;
- sends no request when cancelled or dismissed;
- exposes 48dp loading/disabled state and accessible progress/error/success feedback;
- preserves the existing expense until authoritative refresh says it is gone;
- uses the existing Cubit retry path and never computes local monetary or balance data.

Keep this slice separate from integration and add focused widget tests.

### 2. W3b-S3c — Expense composition and authoritative refresh

Extend the transport-backed mobile composition without changing generated files:

- add a nullable `ExpensesWriter` to `DomainReaders` and create `ExpenseMutationCubit` only when the writer exists;
- wire expense mutation success to `RefreshImpact.expense` through the existing `RefreshCoordinator`;
- pass the optional Cubit/action surface through `DomainScope` and `DomainShell` to the expense history/read presentation;
- keep unavailable/custom scopes read-only;
- close expense mutation ownership before refresh/read state on logout or scope disposal;
- retain archived references on edit and never replace read data optimistically.

Test composition, refresh failure/retry, logout during mutation, and no-writer read-only behavior in a separate bounded slice.

### 3. Close W1a/W1b evidence and acceptance

The broad W1a and W1b rows remain unchecked. Reconcile the existing bounded work with fresh evidence for:

- authenticated entry, session expiry/logout during loading, route/group/role rejection, protected disposal, and five-destination navigation;
- refresh impact plans for participant, expense, policy, and unknown invalidation;
- all-required-reload completion, coalescing, partial failure, retry, logout during refresh, and invalidation-only WebSocket payload handling;
- safe areas, semantic labels, 48dp targets, large text, and read-only/all-settled settlement presentation.

Do not fabricate RED or runtime evidence. If the harness remains unavailable, record `N/A` and leave the broad rows unchecked.

### 4. Close W2 participant acceptance

The bounded participant implementation exists, but broad W2 remains open. Independently verify or document the limits of:

- normalized-name uniqueness across active and archived participants;
- add → rename → archive → reactivate → protected-delete as a live end-to-end journey;
- duplicate taps, logout during mutation, never-used deletion, archived history/balance visibility, and refresh recovery.

The server remains the authorization and uniqueness authority. Do not add client-side authorization or local repair.

### 5. Close W3a data-boundary acceptance

The bounded W3a implementation exists, but broad W3a remains open. Reconcile the unchecked rows with evidence for:

- the existing generated operation signatures (read-only inspection; never edit generated output);
- complete lexical amount grammar/boundary coverage;
- no-request-on-invalid-input, malformed references/shape, duplicate calls, corruption/recovery, and exact request strings;
- unchanged forwarding of server monetary-consistency failures without correction, totals, splits, balances, residuals, or settlement calculations.

### 6. W4 — Group policy and cross-feature hardening

W4 has not started. Implement only supported generated operations and policy values (`owner_only`, `any_member`), then add:

- policy repository/Cubit/UI with owner/member usability gating, no client authorization decision;
- 401/403/validation/duplicate-submit/no-optimistic-state handling;
- policy and cross-feature refresh impact coverage;
- WebSocket invalidation-only behavior, protected re-entry, corruption/recovery, archived references, settlement read-only behavior, accessibility, responsive layout, safe areas, and 48dp controls.

Split this work again if the native or authored-line forecast exceeds 400 lines.

## Non-negotiable constraints

- Do not edit or regenerate `mobile/lib/generated/api/**`.
- Keep generated-client calls behind repository/service boundaries.
- The server owns authorization, monetary consistency, balances, residuals, and settlement.
- Preserve integer cents and exact lexical amount text; never use floating-point monetary logic.
- Never replace displayed read data optimistically.
- New expense selectors use active participants only; edits retain only archived participants referenced by the existing expense.
- Keep tests with the behavior they verify and each implementation slice under 400 authored lines.
- Preserve unrelated retained changes in the repository.
- Run the mobile safety net after each bounded slice and record focused, full, analyzer, formatting, diff, and runtime evidence honestly.

## Delivery notes

The working tree contains retained backend, mobile, OpenSpec, and test changes from the full project work. They were intentionally not discarded. Before delivery, inspect the complete status/diff, exclude secrets, commit by logical work unit, and push the requested branch without force-pushing. No commit or push is implied by this handoff itself.
