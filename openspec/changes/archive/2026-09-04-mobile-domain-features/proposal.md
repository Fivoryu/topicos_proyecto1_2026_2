# Proposal: Complete Mobile Domain Features

## Intent

Complete the authenticated Flutter mobile experience for the full group-expense domain. Users should be able to reach the existing server-backed domain views, manage participant lifecycle, create/edit/delete expenses, manage group settlement policy when authorized, and see settlement exactly as returned by the server.

The backend remains the monetary and authorization authority. The mobile client will submit contract-shaped requests, display server-derived results, and refresh authoritative REST resources after mutations without reproducing splits, balances, residuals, or settlement transfers.

## Decision summary

- **Confirmed scope:** full mobile domain.
- **Delivery shape:** a dependency-ordered chain of bounded, independently reviewable work units rather than one mobile rewrite.
- **Review constraint:** target each work unit below the 400 changed-line review budget; the native forecast and `ask-on-risk` strategy determine whether adjacent work is combined or split further.
- **Navigation:** preserve the existing simple visual language and provide a predictable authenticated mobile shell for the one active group.
- **Settlement:** read-only and server-derived. No payment, transfer, settlement-confirmation, or client-synthesized action is included unless an existing API operation and a later product decision explicitly authorize it.
- **Source boundaries:** use existing generated OpenAPI operations without editing generated files; do not change `mobile/README.md`, product code outside this change, or either existing SDD change.

## Scope

### 1. Authenticated composition and navigation

- Compose the existing repositories, read Cubits, mutation Cubits, and refresh coordination only after authenticated session resolution.
- Expose the group/policy, participants, expenses, balances, and settlement areas through a consistent mobile navigation structure.
- Preserve one active group; do not add group discovery, creation, or switching.
- Protect domain routes from missing or expired sessions, dispose feature state on logout, and retain server-derived role information rather than accepting client-supplied authority.
- Make the settlement view reachable and explicit about the all-settled state.

### 2. Participant lifecycle

Add mobile commands and presentation flows for:

- adding participants;
- trimming and renaming participants while preserving IDs and historical references;
- archiving and reactivating participants; and
- deleting only never-used participants, with referenced participants protected from physical deletion.

The server remains authoritative for permissions, uniqueness, lifecycle validity, and historical-reference protection. New-expense selectors default to active participants. Referenced archived participants remain visible in history and balances, and remain selectable when an existing expense is edited.

### 3. Expense create/edit/delete

Add mobile expense mutation flows using the existing generated API surface and non-generated request mappers/repository methods.

- Create and edit forms must collect the contract-required description, amount representation, contributors, beneficiaries, and references.
- Delete must use a clearly destructive affordance and confirmation flow.
- Client validation may protect obvious form-shape and input-representation errors, but it must not calculate or authoritatively derive splits, balances, residuals, or settlement. Server validation remains authoritative for monetary consistency and all monetary outcomes.
- Do not apply optimistic changes to displayed domain data. Show mutation progress, field/action-level failures, unauthorized/forbidden states, recovery errors, and successful results only after authoritative refresh.

### 4. Group settlement policy

Expose the existing group policy operation through the authenticated mobile domain where the server contract supports it. Respect the approved `owner_only`/`any_member` policy matrix and server-derived roles. The client may adapt available affordances to known server state for usability, but the server must enforce authorization and validity.

A successful policy mutation must refresh the group/policy read model and any permission-dependent presentation. No new policy rule or API operation is invented in this change.

### 5. Authoritative refresh and invalidation

Centralize post-mutation refresh behavior around the existing REST repositories and invalidation listener.

- Participant lifecycle mutations refresh participants and any affected expense-history, balance, and settlement views.
- Expense mutations refresh expenses, balances, and settlement; participant data is refreshed when names/status or selector state can be affected.
- Group policy mutations refresh group/policy and permission-dependent state.
- When impact is uncertain, use the conservative refresh set rather than retaining potentially stale derived data.
- WebSocket frames remain invalidation hints only; they never become a second source of domain or monetary truth.
- Refresh failures remain visible with a retry/recovery path and never get replaced by locally calculated values.

### 6. Mobile UX and accessibility quality

Preserve the current warm, finance-friendly visual language and token-based styling while completing interaction quality:

- visible labels, inline validation and actionable error recovery;
- loading and disabled states for async actions;
- safe-area-aware layouts and predictable back navigation;
- touch targets of at least 48dp on Android;
- semantic labels and logical screen-reader order;
- accessible contrast in supported themes;
- explicit empty, archived, all-settled, unauthorized, forbidden, and recovery states; and
- no emoji or ad-hoc visual substitutes for structural icons.

### 7. Strict-TDD acceptance direction

Implementation work must follow the recorded mobile runner and strict-TDD policy. Coverage should include request mapping and repository behavior, mutation state transitions, server error mapping, archived/default selection rules, refresh coordination, authentication/navigation protection, and widget acceptance paths. The recorded mobile commands are:

- focused cycle: `cd mobile && flutter test --no-pub <file>`;
- full cycle: `cd mobile && flutter test --no-pub`.

This proposal does not claim that implementation or verification has occurred.

## Bounded delivery plan

The following work units preserve the full product scope while keeping reviewable changes small. Each unit is intended to be independently testable and revertible; later units depend only on the stable interfaces delivered by earlier units.

| Order | Work unit | Primary outcome | Review boundary |
| --- | --- | --- | --- |
| 1 | Authenticated domain shell | Compose existing read capabilities, add authenticated navigation, settlement display, lifecycle disposal, and the shared refresh/invalidation boundary. | No new mutation family; establishes routes, dependencies, and server-derived read presentation. |
| 2 | Participant lifecycle | Add participant repository commands, Cubit states, forms, lifecycle affordances, permission/error handling, and affected-resource refresh. | Participant operations only; no expense editor implementation. |
| 3 | Expense CRUD | Add request mapping, repository methods, create/edit/delete Cubit flows, forms, archived-reference behavior, confirmation, and expense/balance/settlement refresh. | Expense operations only; no new policy contract. |
| 4 | Group policy and integration hardening | Add the supported policy mutation flow, reconcile cross-feature refresh behavior, and finish navigation, accessibility, empty/error, and regression coverage. | Policy operation and cross-feature acceptance; polish remains bounded and does not become a redesign. |

The native changed-line forecast is the final sizing authority. Under `ask-on-risk`, if a proposed unit exceeds the review budget or creates reviewer-burnout risk, it must be split at the nearest stable boundary before implementation. If the forecast permits a smaller combination without exceeding the budget, the task plan may combine adjacent units while retaining their acceptance boundaries. No implementation work begins from this proposal alone; specs, design, and tasks must define the exact work-unit boundaries.

## Affected areas

- `mobile/lib` data/repository boundaries, domain/read and mutation state, authenticated composition, navigation, feature presentation, and refresh coordination.
- `mobile/test` or the repository's existing mobile test locations for strict-TDD coverage.
- Existing generated API operations are consumed but not edited or regenerated unless a separately approved contract change later requires it.
- This change's OpenSpec artifacts only. The blocked `wire-mutation-websocket-invalidation` change, the closed `cuentas-claras-mvp` change, backend/web product code, generated files, and `mobile/README.md` remain outside the edit set.

## Non-goals and invariants

- No client-side split, balance, residual, or settlement calculation.
- No client-side payment, transfer, or settlement confirmation action in the first mobile domain delivery.
- No generated API edits, manual generated-code patches, or API-contract invention.
- No public registration, recovery, invitations, OAuth, multiple groups, multiple currencies, custom splits, OCR, cloud collaboration, or advanced analytics.
- No change to the one-active-group model, server authorization rules, session transport, or WebSocket invalidation semantics.
- No `mobile/README.md` changes.
- No edits to either existing SDD change.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Full scope exceeds the 400-line review budget. | Use the four dependency-ordered work units; let the native forecast split any unit further before implementation. |
| Client becomes a competing monetary authority. | Keep monetary values in integer cents at the model boundary, submit user-entered contract data, display server results, and add tests that reject local derivation of monetary outcomes. |
| Mutations leave stale history, balances, or settlement. | Centralize affected-resource refresh, treat WebSocket events as invalidation only, and test refresh completion and recovery failures. |
| Archived participants are mishandled. | Separate active creation defaults from referenced archived edit selections and cover archive, reactivation, deletion protection, history, and zero-balance visibility. |
| Authorization or session regressions expose protected data. | Reuse existing session/transport behavior, fail closed on missing sessions, use server-derived roles, map 401/403 states, and avoid retry loops. |
| UI additions become cramped or inaccessible. | Apply semantic tokens, visible labels, safe areas, 48dp targets, contrast checks, logical focus order, loading feedback, and clear recovery states. |
| API surface differs from assumptions. | Restrict implementation to already exposed generated operations; stop and escalate any missing contract capability rather than editing generated output or inventing a fallback. |

## Rollback

Each work unit should be independently revertible at its delivery boundary. If a unit causes regressions, roll back that unit's mobile composition, route, repository, Cubit, presentation, and tests together while preserving the previously working read surface. Because this proposal introduces no backend migration or contract change, rollback does not require data migration. Server-created records remain governed by existing API behavior; the client must not attempt compensating monetary calculations or destructive cleanup during rollback.

If an API operation is unavailable, authorization behavior is ambiguous, or authoritative refresh cannot be demonstrated, stop that work unit and retain the prior server-backed view. Do not bypass the server, edit generated files, or ship stale optimistic data.

## Success criteria

The change is successful when the implementation and verification artifacts demonstrate that:

1. An authenticated user can navigate to all five domain areas for the one active group, while unauthenticated and logged-out states cannot access protected data.
2. Participant add, trimmed unique rename, archive, reactivate, and permitted delete flows use the existing API, preserve historical references, and present server authorization/validation outcomes.
3. Expense create, edit, and delete flows support the existing contract, handle active versus referenced archived participants correctly, confirm destructive deletion, and never calculate monetary outcomes on the client.
4. Group policy can be changed only through the existing supported operation and server permission matrix; unsupported settlement actions are absent.
5. Settlement is displayed from the server response, including the explicit all-settled state, with no client-synthesized transfers.
6. Successful mutations refresh every affected authoritative resource among participants, expenses, balances, settlement, and group policy; failed refreshes remain recoverable and do not silently show fabricated data.
7. Loading, empty, archived, forbidden, unauthorized, validation, recovery, and error states are visible and actionable, with accessible touch targets, labels, contrast, safe areas, and predictable back behavior.
8. Focused and full mobile strict-TDD cycles pass for the implemented work units, with acceptance evidence recorded by the later apply and verify phases.
