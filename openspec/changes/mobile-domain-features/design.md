# Design: Complete Mobile Domain Features

## Technical approach

Extend the existing Flutter Bloc/Cubit + Dio application in four dependency-ordered logical slices. Keep generated OpenAPI files as the transport contract, repositories as the only generated-client callers, Cubits as mutation/read state owners, and the server as the authority for authorization, money, and settlement. Compose a per-session, per-active-group domain scope that owns all feature state and is disposed on logout or session expiry.

## Architecture decisions

| Decision | Choice and rationale |
| --- | --- |
| Composition | Add a `DomainScope`/composition object in `mobile/lib/app/` that creates repositories, read Cubits, mutation Cubits, the refresh coordinator, and `DataChangedListener`. This extends the current composition root without introducing a new DI package. |
| Navigation | Use one authenticated `DomainShell` with five labeled destinations: Group, Participants, Expenses, Balances, Settlement. Use `NavigationBar` on narrow windows and `NavigationRail` through `LayoutBuilder` on larger windows; this preserves the simple visual language and the one-group model. |
| Writes | Add `ParticipantsWriter`, `ExpensesWriter`, and `GroupWriter` repository contracts beside the existing readers. Mappers create the already-generated request DTOs; CSRF/session details stay inside the transport boundary. |
| Money and authority | Expense write drafts carry contract lexical amount text plus a checked integer-cents boundary value. The boundary rejects malformed, non-positive, overflow, or lossy values without floating-point arithmetic. It never sums contributions or derives splits, balances, residuals, or transfers; the server remains authoritative for monetary consistency and all monetary outcomes. |

## Data flow and contracts

```text
SessionCubit(session resolution)
  → AuthGate
  → DomainScope(authenticated session, activeGroupId)
  → repositories + read/mutation Cubits + RefreshCoordinator
  → DomainShell/screens

mutation Cubit → writer repository → generated operation → server
                   → RefreshCoordinator → authoritative REST read Cubits → UI
WebSocket data_changed → RefreshCoordinator.reloadAll() → REST only
```

`MutationFailure` has `kind` (`validation`, `unauthorized`, `forbidden`, `recovery`, `corruption`), an action message, and field messages keyed by server field names. Map `DioException` status 401 to the existing session boundary with no retry, 403 to forbidden, structured `ErrorResponse.fieldErrors` to inline fields, and network/5xx/incomplete responses to recoverable failure. Never expose raw cookies or treat a successful mutation response as the displayed read model.

`RefreshCoordinator` accepts registered reload callbacks and explicit impact plans. Participant mutations reload participants, expenses, balances, and settlement; expense mutations conservatively reload participants, expenses, balances, and settlement; policy mutations reload group/policy and permission-dependent presentation. Completion is emitted only after all required reloads succeed. A failed reload produces a retryable refresh-failure state and no fabricated derived data. The existing listener continues to ignore frame payloads and invokes this coordinator only for `data_changed`.

### Authentication boundary and protected-state lifecycle

The root router MUST resolve the existing session before constructing or entering the domain route. The route states are:

1. `unknown`/resolving: keep the domain route unavailable while the existing session check runs.
2. `authenticated` with the server-provided active group: construct `DomainScope` and enter `DomainShell`.
3. `signedOut` or `sessionExpired`: do not construct protected repositories, Cubits, screens, or subscriptions; route to the existing authentication boundary with its actionable session state.

The transport continues to own the cookie-backed `cc_session`/`cc_csrf` and CSRF behavior. A 401 from session resolution or a protected request transitions through the existing session boundary exactly once, disposes the protected scope, and routes to authentication without a retry loop. A 403 remains an actionable forbidden state and does not trigger authentication retries. Logout and session expiry cancel the WebSocket subscription, refresh callbacks, in-flight feature ownership where supported, and all protected Cubits/read state before returning to authentication. Re-entry always requires a newly resolved authenticated session.

The active group ID and role are taken from the authenticated/server-derived session and group responses. The client never accepts a route-supplied group or client-supplied role as authorization authority.

### Policy affordance and authorization matrix

The mobile client adapts the visible policy affordance to the server-derived role and current server policy, but the server enforces the matrix. The matrix covers only existing operations; it does not add a settlement trigger or another policy operation.

| Existing operation or affordance | `owner_only`, owner | `owner_only`, member | `any_member`, owner | `any_member`, member |
| --- | --- | --- | --- | --- |
| Group/policy, participant, expense, balance, and settlement reads | Allowed | Allowed | Allowed | Allowed |
| Participant add/archive/reactivate/rename/delete | Enabled affordance; server-authorized | Enabled affordance; server-authorized | Enabled affordance; server-authorized | Enabled affordance; server-authorized |
| Expense create/edit/delete | Enabled affordance; server-authorized | Enabled affordance; server-authorized | Enabled affordance; server-authorized | Enabled affordance; server-authorized |
| Existing group settlement-policy update (`PATCH /groups/{id}`) | Enabled for supported values only | No enabled mutation affordance; current policy remains readable; a stale/unauthorized request maps to 403 | Enabled for supported values only | Enabled for supported values only |
| Group WebSocket `data_changed` subscription | Allowed for the group | Allowed for the group | Allowed for the group | Allowed for the group |

An unauthenticated caller cannot enter the matrix and is routed to authentication; a non-member receives the existing forbidden behavior for group-scoped requests. For policy mutation, the only values offered are `owner_only` and `any_member` from the existing contract. Settlement itself remains read-only: no payment, transfer, or settlement-confirmation affordance is present.

### Lexical amount input and normalization boundary

The expense form applies the same boundary to the top-level `amount` and every contributor `amount` in the existing `ExpenseWriteRequest`/`ExpenseContributorRequest` contract. These generated request fields remain strings. The accepted lexical representation is exactly the existing server parser contract:

```text
[0-9]+(?:\.[0-9]{1,2})?
```

This means ASCII digits are required, with an optional decimal point followed by one or two ASCII fractional digits. For example, `1`, `1.2`, `1.20`, and `0001.05` are accepted representations. Empty text, whitespace or surrounding whitespace, signs, grouping separators, commas, exponent notation, `.5`, `1.`, and more than two fractional digits are rejected. `0` and zero-valued forms such as `0.00` are rejected as non-positive.

Validation and normalization MUST happen before the generated request is built:

1. Validate the raw field text against the contract grammar without locale substitution, implicit trimming, rounding, truncation, or other lossy cleanup.
2. Split the already-valid text into whole and fractional ASCII digit strings. Use `00` for a missing fraction and right-pad a one-digit fraction with one zero.
3. Parse with integer-only checked arithmetic (`whole * 100 + fraction`). A temporary arbitrary-precision integer or equivalent checked digit accumulation is permitted; convert to the client integer type only after the bound check. Never use `double`, `num` floating-point parsing, or floating-point formatting.
4. Reject non-positive results, values that overflow the client integer type, values above the current server integer-cents storage/contract bound (the current backend `INTEGER` bound is 2,147,483,647 cents), or any conversion that would be lossy. Do not wrap, saturate, silently round, or send an unrepresentable value.
5. Store the checked integer cents in the non-generated client write model while retaining the accepted contract text for the request mapper. The mapper sends only the existing string fields and participant IDs; it does not reconstruct money through floating-point formatting.

This parser validates each amount representation only. It MUST NOT total contributors, calculate an equal split, derive a residual/balance/settlement, or decide whether contributor amounts are consistent. The server parses the submitted lexical values and remains authoritative for contribution equality, persistence, balances, and settlement. Tests must prove that invalid lexical values are rejected before a request and that server monetary-consistency failures are displayed without client correction.

Archived selection is a pure presentation helper: new forms use active participants only; edit forms union active participants with archived IDs present in the existing expense contributors/beneficiaries, labeling archived entries. Deletion protection remains server-authoritative.

## File changes

| File | Action |
| --- | --- |
| `mobile/lib/app/app.dart`, new `app/domain_scope.dart`, `presentation/domain/domain_shell.dart` | Compose/dispose the authenticated scope and provide adaptive navigation. The router/auth gate remains the entry boundary for all protected domain routes. |
| Existing group/participant/expense repositories; new `data/repositories/mutation_support.dart`, `domain/write_models/write_models.dart` | Add writer interfaces, request mappers, CSRF-safe generated adapters, lexical amount validation, and error mapping. |
| New `data/refresh/refresh_coordinator.dart`; existing WebSocket listener tests | Centralize impact plans and REST invalidation. |
| New participant, expense, and policy mutation Cubits/forms; existing domain screens | Add commands, accessible states, confirmations, role-aware affordances, and server-derived presentation. |
| `mobile/test/**` | Add strict-TDD unit, Cubit, coordinator, navigation/auth-boundary, lexical-input, and widget coverage. |

Generated API output, `mobile/README.md`, backend/web code, and existing SDD changes remain untouched.

## Non-goals and invariants

The following boundaries are explicit and apply to every work unit:

- No client monetary calculations or monetary outcomes: no client-side split, balance, residual, contribution-total authority, or settlement calculation. Lexical parsing to a checked integer-cents representation is input validation only.
- No payment, transfer, or settlement-confirmation action. Settlement is a server-derived read view only.
- No generated API edits, manual generated-code patches, or regeneration as part of this change.
- No README changes, including `mobile/README.md`.
- No API invention, new endpoint, new request/response shape, or fallback policy operation. Consume only the existing generated OpenAPI operations.
- No public registration, password recovery, invitations, or OAuth.
- No multiple groups, group discovery/creation/switching, multiple currencies, custom splits, OCR, cloud collaboration, or analytics.
- Preserve one active group and the existing protected session model, including cookie transport and CSRF behavior.
- Preserve server authorization and server-derived roles; client role/policy state controls usability affordances only and never authorizes a request.
- Preserve WebSocket invalidation semantics: `data_changed` is only a hint to refresh authoritative REST resources, never domain or monetary data.
- Preserve authoritative post-mutation refresh, no optimistic displayed domain data, and fail-closed recovery behavior.
- Keep both existing SDD changes untouched: `wire-mutation-websocket-invalidation` and `cuentas-claras-mvp`.

## Testing and delivery sequence

Each unit is independently revertible and must remain below the 400-line review boundary; native forecasting may split a unit further under `ask-on-risk`. The native changed-line forecast is the final sizing authority. If a proposed unit exceeds the budget or creates reviewer-burnout risk, split it at the nearest stable interface before implementation. If the forecast permits a smaller combination without exceeding the budget, adjacent units may be combined while retaining their acceptance boundaries. No implementation work begins from this design alone.

1. **Shell + refresh:** scope lifecycle, explicit authentication gate, five destinations, read loading/empty/recovery states, settlement no-action display, invalidation-only reload, logout disposal, and 401/403 routing. Test with `app/domain_shell_test.dart` and `data/refresh/refresh_coordinator_test.dart`.
2. **Participant lifecycle:** writer mapping, mutation states/errors, add/trim/rename/archive/reactivate/delete, authorization matrix behavior, and archived rules. Test repository/Cubit first, then form widgets.
3. **Expense CRUD:** lexical request mapping, exact local shape/amount validation, create/edit/delete confirmation, archived edit references, and conservative refresh. Test accepted/rejected lexical forms, overflow/lossless conversion, no request on invalid input, server contribution mismatch, and no optimistic or monetary derivation.
4. **Policy + hardening:** supported enum values only, the `owner_only`/`any_member` affordance matrix with server 403 fallback, cross-feature refresh, accessibility and responsive regression coverage.

For every unit: RED/GREEN/TRIANGULATE use `cd mobile && flutter test --no-pub <focused-file>`; GREEN/REFACTOR and final integration use `cd mobile && flutter test --no-pub`. Include duplicate-submit prevention, logout during load, missing/expired session, 401/403 without retry loops, validation, refresh failure, empty/all-settled, archived selection, and corrupted-response cases. The recorded mobile runner and strict-TDD stage mapping remain authoritative: RED and TRIANGULATE are focused commands; GREEN and REFACTOR are full-suite commands.

## Accessibility, rollout, and rollback

Use safe areas, visible labels, semantic live regions for errors, 48dp minimum controls, vector Material icons, semantic color tokens, predictable Navigator back behavior, dynamic text without truncation, and constrained large-screen content. Destructive participant/expense actions require confirmation. No migration or feature flag is required. Revert a slice's scope, routes, repositories, Cubits, screens, and tests together; prior server-backed reads remain usable. Never compensate for a client rollback with monetary cleanup.

## Threat matrix

All rows are **N/A**: documentation-like paths (design only), Git repository selection, commit state, push state, and PR commands are not changed; Flutter navigation is application routing, not shell/VCS automation. Therefore no shell/process RED cases are introduced.

## Risks and unresolved technical choices

Primary risks are stale cross-feature reads, session leakage, archived-reference loss, accidental client monetary logic, and drift between client lexical validation and the frozen contract. The coordinator, per-session disposal, explicit authentication gate, explicit authorization matrix, contract-grammar parser, checked integer-cents model, and server-only consistency validation mitigate them.

The lexical amount grammar is not a product choice deferred to implementation: it is fixed here to the existing server contract (`[0-9]+(?:\.[0-9]{1,2})?`, positive only, no whitespace/signs/separators/exponents/rounding). Tasks must implement and test that boundary for both expense and contributor amounts without editing generated output. The only contract-driven check to re-confirm during tasks is the frozen server's declared integer-cents upper bound; if the approved contract changes, stop and reconcile the contract rather than inventing a mobile rule or API.

If an API operation is unavailable, authorization behavior is ambiguous, or authoritative refresh cannot be demonstrated, stop that work unit and retain the prior server-backed view. Do not bypass the server, edit generated files, ship stale optimistic data, or add a compensating operation.
