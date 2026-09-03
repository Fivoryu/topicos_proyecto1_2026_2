# Exploration: Mobile domain features

## Scope and evidence

This exploration is for the independent `mobile-domain-features` change. It inspected the approved project context, the closed `cuentas-claras-mvp` proposal/specs/design/tasks, the Flutter application composition root, mobile repositories/read models, presentation screens/Cubits, tests, theme tokens, and the generated Dart API surface. No product source, generated API file, README, or existing OpenSpec change was modified.

The backend remains the monetary authority. The mobile client must consume the existing OpenAPI contract and display server-derived participants, expenses, balances, and settlement; it must not reproduce split, balance, or transfer calculations.

## Current capabilities

- Flutter app shell uses Bloc/Cubit, Dio, cookie-backed protected sessions, CSRF handling, single-401 handling, and server-derived role display.
- Domain read models exist for session identity, group/policy, participants, expenses, balances, and settlement. Monetary fields are integer cents and the shared cents formatter renders `Bs.` values.
- Read repositories exist for group, participants, expenses, balances, and settlement. They map generated DTOs, reject incomplete responses, and expose corruption-recovery failures.
- Read Cubits and screens exist for group/policy, participants, expense history, balances, and settlement, including loading, empty, error, and recovery states. Archived participants and archived zero-balance rows are represented in the read models/views.
- Existing tests cover session/app bootstrap, DTO mapping, repositories, Cubit reload/state behavior, formatter/security boundaries, and read-only widget rendering.
- The generated Dart client already exposes the relevant mutation operations: participant add/archive/delete/reactivate/rename, expense create/edit/delete, and group policy update. The generated files are contract output and must not be hand-edited.

## Gaps for the requested completion

- `App` currently composes the session and only a group read Cubit. The other repositories/Cubits/screens are not composed into an authenticated navigation flow, so the complete domain surface is not reachable from the running app.
- Participant data access is read-only at the repository boundary. There are no mobile mutation commands/forms for adding, renaming, archiving, reactivating, or deleting participants, despite the generated operations and approved participant rules.
- The expense repository currently exposes listing only. There are no request mappers, mutation repository methods, Cubit commands, or UI forms for create/edit/delete.
- The mobile presentation is read-mostly and has an explicit no-write affordance contract from the closed MVP. This change is the natural boundary for the approved Stretch mobile expense-write parity, but the parent must confirm whether participant mutations and group policy mutation are also intended in this first slice.
- No complete mobile navigation/state-refresh strategy is visible for coordinating mutations with participants, expense history, balances, and settlement. Successful mutations must invalidate/reload affected REST resources; WebSocket frames remain invalidation hints only.
- Existing UI is functional but minimal: the app theme uses an inline seed/background setup while token constants exist separately. A completed feature should preserve the warm finance-friendly token system, accessible contrast, safe areas, responsive layouts, semantic labels, and at least 48dp Android touch targets.
- Tests do not yet cover mutation validation/error mapping, optimistic-state avoidance, atomic refresh after mutation, archived-participant form rules, or end-to-end mobile navigation through the domain features.

## Existing contract constraints to preserve

- One active group; no group switcher, group creation, or discovery UI.
- Every request is protected by the existing session and group scope. No anonymous group data and no client-supplied role authority.
- Use generated OpenAPI request/response models and the current Dio transport. Regeneration is required if the contract changes; this exploration does not change the contract.
- Amount input must follow the API's accepted representation and ultimately remain integer cents at the client model boundary. No floating-point money arithmetic, client-side split, balance, residual, or settlement logic.
- Expense creation requires a non-empty description, positive amount, at least one contributor and beneficiary, valid group participant references, and contributions summing exactly to the amount. New forms default to active participants; referenced archived participants remain available when editing.
- Participant rename is name-only, trimmed, case-insensitive unique across active and archived participants, ID-preserving, and must not alter historical references or monetary results.
- Referenced archived participants remain visible in history and balances, including `Bs. 0.00`; never-used participants may be deleted, while referenced participants are protected from physical deletion.
- Settlement is displayed from the server response, including the explicit all-settled state. The client must not trigger or synthesize transfers unless the existing API contract explicitly supports that operation and the parent confirms it is in scope.

## Likely implementation boundaries

1. **Client mutation/data boundary:** add non-generated request mapping and repository interfaces around the existing generated operations. Keep API errors mapped into field/action-level presentation failures and keep repositories as the only generated-client callers.
2. **Mutation state boundary:** add Cubit/state models for participant lifecycle, expense editor/create/delete, and any confirmed group-policy action. States should distinguish idle/loading/success/validation/unauthorized/forbidden/recovery/error without mutating displayed data before server success.
3. **Composition/navigation boundary:** compose repositories and Cubits after authenticated session resolution, expose the five domain areas through a predictable mobile navigation structure, and dispose feature Cubits correctly on logout/group changes.
4. **Refresh boundary:** after a successful mutation, reload authoritative affected resources (at minimum participants, expenses, balances, settlement, and group policy where relevant). Reuse the existing invalidation listener rather than treating WebSocket payloads as data.
5. **Presentation boundary:** add forms and mutation affordances only for confirmed scope. Keep labels visible, errors near fields, loading/disabled feedback, confirmation for destructive deletion, explicit empty/recovery states, semantic accessibility labels, safe-area padding, and token-based styling.
6. **Test boundary:** strict TDD for request mapping/repository behavior, Cubit transitions and server-error mapping, archived/default selection rules, refresh coordination, navigation protection, and widget acceptance paths. Use the recorded mobile commands: focused `cd mobile && flutter test --no-pub <file>` for RED/TRIANGULATE and `cd mobile && flutter test --no-pub` for GREEN/REFACTOR.

## Small first slice

The smallest coherent first slice is **mobile expense create parity**, assuming the API contract already supports the generated create operation and the parent confirms it as the primary goal:

- Add an expense form with description, amount, contributors and beneficiaries.
- Default active participants as beneficiaries/contributor options; retain referenced archived participants only in an edit flow if edit is included in the same slice.
- Submit through a repository using the generated client, surface server validation errors, and show no partial local mutation.
- On success, reload expense history, participants if names/status can affect display, balances, and settlement.
- Add focused repository/Cubit/widget tests for valid creation, contribution mismatch, no beneficiaries, no participants, archived visibility, unauthorized/forbidden handling, and exact server-derived refresh.

If the requested outcome explicitly includes the full participant lifecycle and expense edit/delete in one delivery, that is a larger slice and should be split into independently reviewable work units: participant lifecycle first, then expense create/edit/delete, then navigation/polish/integration. The configured 400-line review budget makes an unbounded all-at-once mobile rewrite risky.

## Unresolved product decisions for the parent

1. Does `mobile-domain-features` include only the previously approved Stretch mobile expense create/edit/delete parity, or also participant add/rename/archive/reactivate/delete and settlement-policy mutation?
2. Is expense edit required in the first slice, or may create-only ship first with edit/delete as a follow-up?
3. Should mobile support a single top-level navigation shell (for example, labeled bottom navigation) or a simpler scrollable domain dashboard? The existing requirements mandate one active group but do not prescribe a mobile navigation pattern.
4. Is a mobile settlement action intended at all, or is settlement strictly a server-derived read view? Existing closed specs define settlement computation/display, not a client-side payment/settlement confirmation workflow.
5. Should the change preserve the current minimal visual language and only complete interaction/accessibility gaps, or is a broader visual redesign expected? No new brand/style decision is recorded in the approved requirements.

## Risks and mitigations

| Risk | Level | Mitigation |
| --- | --- | --- |
| Mobile mutation scope exceeds the 400-line review budget | High | Confirm the first slice; split participant lifecycle, expense mutations, and integration into bounded work units; defer polish. |
| Client accidentally becomes a monetary authority | High | Treat generated/server values as authoritative; use integer cents only for input/display conversion; add tests proving no client recalculation. |
| Mutation success leaves stale balances/history | High | Centralize post-mutation REST reloads and test all affected resources; WebSocket remains invalidation-only. |
| Archived participants become uneditable or leak into new defaults | Medium | Model active/default versus referenced-edit selections explicitly and test both paths. |
| Auth/session regressions expose protected data | High | Reuse the existing transport/session Cubit; fail closed on missing/expired sessions and map 401/403 without retry loops. |
| UI work introduces inaccessible or cramped controls | Medium | Apply the loaded Flutter architecture and UI guidance: semantic tokens, safe areas, visible labels/errors, 48dp Android targets, contrast, loading/disabled states, and predictable back navigation. |
| Generated client drift or hand edits | Medium | Keep generated files untouched; use only existing operations unless a separately approved contract regeneration is required. |

## Existing changes and protected files

- `openspec/changes/wire-mutation-websocket-invalidation` was not read for mutation or lifecycle work and remains untouched.
- `openspec/changes/cuentas-claras-mvp` is closed and remains untouched.
- `mobile/lib/generated/api/**`, `mobile/README.md`, and all product source/tests remain untouched by this exploration.
- Only this new artifact, `openspec/changes/mobile-domain-features/exploration.md`, is created.

## Next phase

Proceed to `sdd-propose` after the parent resolves the surfaced scope decisions, with the first proposal centered on a bounded mobile mutation slice and explicit non-goals. `skill_resolution: paths-injected`; CodeGraph was unavailable because this executor has no shell/MCP command surface, so the structural mapping used targeted repository reads after confirming the missing `.codegraph` directory.
