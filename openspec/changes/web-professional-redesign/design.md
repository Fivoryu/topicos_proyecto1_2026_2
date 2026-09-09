# Technical design: web professional redesign

## Decision summary

Implement the confirmed `editorial` direction as a presentation-only refinement of the existing React/Vite/TanStack Query/Tailwind-compatible web client. Keep the current light finance palette, handwritten SVG icon vocabulary, hash-based single-dashboard shell, Spanish copy, and server-authoritative data flow. The implementation will consolidate tokens and shared CSS/React presentation primitives first, then make the expense workspace the clear visual anchor, then quiet the summary and administration surfaces.

No router, new runtime dependency, API/client/backend change, generated-client edit, WebSocket change, mobile change, dark mode, or domain logic is required. Existing DOM labels, IDs, roles, query ownership, mutation wiring, and hash anchors remain contracts.

## Constraints and invariants

- `web/src/app/App.tsx` remains the protected composition. `navItems`, `getCurrentNavHash`, `Navigation`, `ProtectedShell`, and the `connectGroupWebSocket` effect keep their current semantics.
- `ProtectedRoute` and `SessionProvider` remain the authentication boundary. Anonymous bootstrap, CSRF, session expiry, logout/query clearing, and server-derived roles are not presentation concerns to redesign.
- `ExpensesPanel`, `ParticipantsPanel`, `BalancesPanel`, `SettlementPanel`, and `GroupSettings` continue to receive the existing clients and use their existing TanStack Query keys, mutations, invalidation, and refetch behavior.
- `formatCents` and `formatSignedCents` remain the only presentation formatters for server-provided money. The redesign does not calculate, round, reorder, or optimistically synthesize money, balances, or settlement.
- The existing anchors remain available: `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo`.
- Generated files under `web/src/generated/api/**`, backend files, mobile files, and WebSocket implementation files are explicitly excluded.
- Existing Spanish wording and accessible names are preserved, including `Inicia sesión`, `Usuario`, `Contraseña`, `Gastos`, `Registrar gasto`, `Crear gasto`, `Actualizar balances`, `Todos están saldados`, and the participant action names used by the tests.
- The hard per-change limit is **800 changed lines**. The project config's historical `review_budget_changed_lines: 600` is not changed; the approved limit is recorded and enforced for this change by task forecasts and native attempt authority.

## Architecture and token layering

### Layer 1: semantic theme tokens (`web/src/core/theme.css`)

Retain the existing token names and light-theme values as the compatibility surface:

- `surface-base` is the page canvas.
- `surface-sidebar` and `surface-sidebar-raised` are the structural navigation surfaces.
- `surface-card` is the primary workspace/auth surface.
- `surface-card-raised` is the quieter summary/management surface.
- `surface-soft` is the inline editor/state surface.
- `surface-input` is the form-control surface.
- `content-*`, `brand-*`, `finance-*`, `state-*`, `border-*`, `focus-ring`, `shadow-*`, `ease-ledger`, and the existing radius scale remain semantic and centralized.

Add only a small number of semantic aliases where repeated CSS currently expresses the same role with raw alpha colors: action-soft, credit-soft, debt-soft, border-subtle, and a restrained workspace shadow. The aliases must map to the existing palette; they are not a second theme. Add a compact spacing/motion role only if it removes repeated values in high-fan-out selectors. Do not rename all existing variables or introduce per-feature colors.

The visual rule is one light system with four surface levels: canvas, primary workspace, quiet summary/management, and inline state/editor. Depth comes from spacing and the existing warm tinted shadows, not from equal cards, gradients, or decorative texture.

### Layer 2: shared primitives (`web/src/index.css`, `web/src/components/ui.tsx`)

Keep the existing primitives and public call sites:

- `Button` keeps `primary`, `secondary`, `danger`, and `ghost` variants; CSS provides hierarchy, hover, pressed, disabled, and focus treatment.
- `Panel` remains a semantic `section` with `aria-labelledby` and the existing `feature-card` seam.
- `PanelHeading` remains the source of stable heading IDs and eyebrow/title/action grouping.
- `StatusBadge` remains for compact status or policy meaning, but ordinary metadata should not become a badge.
- `LoadingCard` and `ErrorCard` become the common query-state surfaces. If an action slot is needed for recovery, extend `ErrorCard` with an optional React node while keeping the existing no-action call sites valid; wire only existing query `refetch` operations and do not add retry policy or new domain behavior.
- `.feature-empty`, `.feature-error`, `.auth-notice`, `.auth-error`, `.feature-state-card`, and `.state-symbol` remain the CSS seams for empty, validation, notice, and failure states. Their hierarchy and contrast are consolidated rather than replaced with a new component library.

Normalize controls to a minimum 44px hit area, preserve visible `:focus-visible`, keep icon stroke sizing consistent with `Icon`, and use only transform/opacity for motion. Existing `prefers-reduced-motion: reduce` rules remain the final override.

### Layer 3: feature and layout composition

Feature classes remain the implementation seam because `index.css` is already coupled to `feature-*`, `dashboard-*`, and `expense-*` selectors. Prefer changing parent layout, surface, spacing, and shared primitive classes over rewriting JSX. New feature-specific selectors are allowed only when an existing seam cannot express the required hierarchy.

## Shell and navigation

The current DOM order already gives the required reading order: expenses; balances and settlement; participants and group administration. Preserve that order in `App.tsx` and use CSS to express hierarchy:

- Desktop keeps the sticky `.app-sidebar`, `Brand`, `.app-nav`, active `aria-current="page"` treatment, and account/role summary. Make the sidebar quieter and more editorial through spacing, typography, and a restrained active marker rather than adding navigation behavior.
- The workspace keeps `.workspace-header`, the secure-session eyebrow, the tested `Tu grupo está protegido` heading, session/role text, logout action, and the mobile brand row. Do not change the hash state mechanism or introduce routes.
- `Navigation` remains the single source of labels and anchors. The mobile `.mobile-nav-scroll` remains a local navigation scroller at widths where the sidebar is hidden; it must not create page-level overflow. Keep the visible label and icon together and preserve focus order.
- `.dashboard-main-column` remains the primary column. `.dashboard-summary-grid` gives balances and settlement enough prominence to scan. `.dashboard-side-column` remains an explicitly labelled secondary administration rail.
- Keep `scroll-behavior`, `scroll-padding-top`, and slot scroll margins; anchor targets must remain identifiable by their existing headings and active-navigation treatment.

## Login presentation

Refine `LoginScreen` without changing `SessionProvider` or `ProtectedRoute`:

- Retain the existing two-column `.auth-layout`: the deep-green showcase communicates trust and server authority, while the light `.auth-card` is the focused form surface. Keep its mobile single-column collapse.
- Preserve the current `StatusBadge`, `Cuentas Claras` lockup, Spanish copy, visible labels, `autoComplete` values, password visibility button, `aria-pressed`, inline notice/error roles, and `aria-busy` submit state.
- Use the editorial type contrast already present: serif display headings and sans-serif body/control text. Increase whitespace and improve alignment before changing font declarations.
- Use the existing deep-green/terracotta tokens, not new imagery, gradients, fonts, or icon dependencies. The showcase should feel like one structural brand surface, not an unrelated dark-mode section.
- Keep all auth error codes and messages intact so `session-provider.test.tsx` and `app.test.tsx` continue to verify behavior by accessible names and text.

## Expense workspace

`ExpensesPanel` is the primary implementation and visual anchor:

- Keep the existing `expenses-card`, `.expenses-heading-bar`, `expense-workspace`, `.expense-editor`, and `.expense-history` structure. Strengthen the primary surface through controlled padding, a clear heading/action relationship, and a quieter history column instead of adding more cards.
- Keep the `Registrar gasto` heading and the tested `Crear gasto` submit label. The submit remains the single primary CTA. `Editar gasto`, `Eliminar gasto`, `Cancelar`, `+ Agregar pagador`, and field labels retain their current names and semantics.
- Preserve every current form contract: `expense-description`, `expense-amount`, contributor IDs, beneficiary labels, `fieldset`/`legend` structure, `aria-invalid`, `aria-describedby`, archived references while editing, focus on invalid amount, and server contribution-mismatch preservation.
- Preserve the two existing queries, `participantsQuery` and `expensesQuery`, their enabled conditions, `newForm`/`editForm` behavior, mutation payloads, and group-wide invalidation after success. Presentation code must not derive totals or balances.
- Replace the plain pending/error sections with `LoadingCard`/`ErrorCard` or the shared equivalent while retaining the existing Spanish messages. Empty participant guidance and the empty expense history remain explicit `.feature-empty` states with a clear next action expressed by the existing participant workflow.
- On wide desktop, the editor is visually dominant and history is a quieter adjacent record. At the existing `82rem` breakpoint, stack history below the editor. At mobile, keep the editor first, make the submit action full width, and retain readable participant/beneficiary controls without introducing nested page scrolling.
- Keep monetary values tabular and unbroken where possible; allow descriptive participant text to wrap rather than forcing horizontal overflow.

## Balances and settlement

### Balances

`BalancesPanel` already uses `Panel`, `PanelHeading`, `LoadingCard`, `ErrorCard`, `formatCents`, `formatSignedCents`, a semantic table, and a manual REST refetch. Keep that contract.

- Treat balances as a high-priority summary surface, but quieter than expense entry. Use the existing summary surface and a strong heading/value relationship rather than another elevated card.
- Preserve the exact server order and values, including Ana `+Bs. 560,00`, Beto `Bs. 0,00`, Carla `-Bs. 160,00`, and Diego `-Bs. 400,00`.
- Preserve desktop table semantics, mobile `data-label` rendering, `StatusBadge` labels (`Le deben`, `Debe`, `Saldado`), and arrow/neutral symbols. Color is supplementary, never the only meaning.
- Keep the `Actualizar balances` button and `aria-busy` behavior. Any error recovery action must call the existing query refetch only; it must not change cache or authority semantics.

### Settlement

`SettlementPanel` remains a compact outcome surface:

- Preserve `PanelHeading`, the server policy badge, the `settled` branch, `Todos están saldados`, and the ordered `ol`/`transfer-row` structure.
- Preserve server order and exact display: `Diego → Ana: Bs. 400,00`, then `Carla → Ana: Bs. 160,00`. Do not sort or compute transfers in the client.
- Use quiet numbering and whitespace to make the transfer path scannable. Keep the policy label visible as context, not as a competing CTA.
- Use the shared loading/error state treatment and preserve the existing message and accessibility roles.

## Participants and group settings

### Participants

Keep `ParticipantsPanel` as the secondary management rail, with stable server order and all existing lifecycle actions:

- Preserve the add form, `participant-list`, `participant-row`, rename labels/IDs, helper text, archived status, action labels, error keys, focus-on-error behavior, and group-wide invalidation.
- Apply the quiet management surface: separate add/rename/action groups with whitespace and a restrained divider; avoid making every `Activo`/`Archivado` value a visually loud pill.
- Replace its plain query pending/error branches with the shared state primitives while retaining the existing Spanish messages and `role="alert"`/focus behavior.
- At small widths, keep one participant row per line and allow action controls to wrap into full-width touch targets. Do not hide delete, archive, reactivate, or rename actions.

### Group settings

Keep `GroupSettings` as the least prominent protected surface:

- Preserve the server-loaded group name, owner account, policy labels, `canUpdate` role/policy condition, select ID, mutation, invalidation, and inline forbidden error.
- Use existing `group-details`, `feature-form`, `StatusBadge`, `LoadingCard`, and `ErrorCard` seams. Reduce contrast and elevation relative to expenses and balances, but keep the policy affordance obvious to authorized users.
- Do not infer owner/member access from presentation state. The session role and server policy remain the authority.

## Loading, empty, error, and accessibility states

Use one state grammar across features:

| State | Presentation decision | Contract preserved |
| --- | --- | --- |
| Loading | Use `LoadingCard`, `aria-live="polite"`, reserved layout space, and a quiet motion/pulse that is disabled by reduced motion. | Existing Spanish loading messages and query timing. |
| Empty | Use `.feature-empty` with a short explanation and the existing next action/guidance. | No fabricated records or financial values. |
| Validation | Keep inline `.feature-error` beside the field/group, `aria-invalid`, `aria-describedby`, and focus-on-error behavior. | Existing field IDs, error codes, and editable values. |
| Read failure | Use `ErrorCard`/`role="alert"`; preserve Spanish cause/recovery text and optionally expose the affected query's existing refetch action. | REST remains authoritative; no optimistic replacement. |
| Forbidden | Keep the mutation in place and show the current inline forbidden message. | Server-derived role/policy behavior. |
| Session expired | Let `handleProtectedState` route to `LoginScreen`; do not render protected shell/data while signed out. | `SessionProvider` state and query clearing. |
| Success/refresh | Use existing query invalidation/refetch and concise status feedback only where already present. | No new client-side financial success state. |

Accessibility rules are implementation gates, not optional polish: preserve semantic landmarks and heading order, visible focus, keyboard order, form labels, helper/error descriptions, live regions, non-color state cues, 44px targets, readable tabular figures, and reduced-motion behavior. Do not add hover-only meaning, icon-only controls, or decorative animation. A mobile local navigation scroller is acceptable; page-level horizontal overflow is not.

## Responsive model

Use the existing breakpoints rather than adding a competing system:

- Base: 320px and up. Use one-column flow where content is constrained, `min-height: 100dvh`, fluid gutters, and wrapping text.
- `max-width: 82rem`: keep the desktop sidebar and dashboard columns, but stack the expense history under the editor and allow the history grid to simplify.
- `max-width: 68rem`: hide the sticky sidebar, show `.mobile-brand-row` and `.mobile-nav-scroll`, and retain a primary column before the administration rail.
- `max-width: 52rem`: stack the auth layout, dashboard columns, and summary sections; keep expenses, balances, and settlement before the administration rail.
- `max-width: 36rem` (including the approximately 375px acceptance viewport): collapse history/participant/balance grids to one column, make primary form actions full width, keep the mobile nav reachable, and avoid forced-width labels or amounts.

Validate portrait and landscape at mobile, tablet, and desktop widths. Any horizontal scrolling must be intentional and confined to the mobile navigation or an explicitly bounded data region; the page itself must remain overflow-free.

## Data-flow preservation

The presentation layer consumes the current flow without introducing a parallel store:

1. `SessionProvider` probes the server session. `ProtectedRoute` renders either the existing login screen or the protected children; no protected query is enabled before authentication.
2. `ProtectedShell` obtains `activeGroupId` and server-derived role, renders existing feature panels, and owns the existing `connectGroupWebSocket` lifecycle.
3. Each feature keeps its existing client/query key and receives server responses. `ExpensesPanel` and `ParticipantsPanel` continue to invalidate `groupQueryKeys(groupId)` after successful mutations; `GroupSettings` invalidates its group query; balances/settlement remain REST reads.
4. A WebSocket `{"type":"data_changed"}` remains only an invalidation hint. `connectGroupWebSocket` continues invalidating the existing group query keys, and REST refetches authoritative values.
5. Money continues through `formatCents`/`formatSignedCents`; roles, policy visibility, participant lifecycle, archived references, and settlement ordering remain server-derived.

No effect, query key, client method, generated type, request payload, response mapping, or WebSocket message handling is changed for visual work.

## File-level change map

| File | Planned change | Boundary |
| --- | --- | --- |
| `web/src/core/theme.css` | Refine/add a small semantic token layer for the existing light palette, surface hierarchy, state-soft backgrounds, spacing roles, and motion/elevation roles. | No dark mode, no token rename migration. |
| `web/src/index.css` | Consolidate global primitives, shell/navigation spacing, workspace grid, feature hierarchy, state surfaces, responsive rules, focus, and reduced-motion behavior. | Preserve existing selector seams; no styling-framework migration. |
| `web/src/components/ui.tsx` | Keep existing primitive APIs; optionally add an optional recovery action slot to `ErrorCard` if required by the final state map. | No new component library or dependency. |
| `web/src/app/App.tsx` | Presentation-only class/landmark adjustments if CSS cannot express the hierarchy. | Preserve `navItems`, hashes, session text, logout, and WebSocket effect. |
| `web/src/features/auth/login-screen.tsx` | Presentation wrappers/classes only if needed. | Preserve labels, copy, auth messages, password control, and submit behavior. |
| `web/src/features/expenses/expenses-panel.tsx` | Switch query pending/error branches to shared primitives and adjust presentation classes only. | Preserve form IDs, state, payloads, focus, and invalidation. |
| `web/src/features/participants/participants-panel.tsx` | Switch query pending/error branches to shared primitives and adjust presentation classes only. | Preserve ordering, lifecycle actions, focus, and errors. |
| `web/src/features/balances/balances-panel.tsx` | Presentation classes or bounded error recovery action only. | Preserve server values, order, formatter, table semantics, and refetch. |
| `web/src/features/settlement/settlement-panel.tsx` | Presentation classes or bounded error recovery action only. | Preserve settled branch, ordered transfers, and policy label. |
| `web/src/features/group/group-settings.tsx` | Presentation classes or bounded error recovery action only. | Preserve role/policy authorization and mutation behavior. |
| `web/src/components/icons.tsx` | No planned change; use the existing `wallet`, `receipt`, `chart`, `settlement`, `users`, `home`, `shield`, and `logout` vocabulary. | Add an icon only if an actual semantic gap is proven and budget remains. |
| `web/index.html` | No planned change in the first slice. | Metadata/favicon polish is deferred by default. |
| `web/tests/app.test.tsx` and existing feature test files | Add only targeted semantic/state assertions required by changed presentation branches; retain behavior tests. | No pixel snapshots as the sole proof. |

## Test seams and verification

Strict TDD is active for the project. Each implementation work unit should add or adjust the smallest focused semantic assertion first, run the affected Vitest file, implement the presentation change, then run the affected suite and the full web gates.

Preserve the existing test seams:

- `web/tests/app.test.tsx` and `web/tests/features/auth/session-provider.test.tsx`: anonymous shell exclusion, authenticated shell, login labels, notices/errors, password visibility, loading disablement, role text, expiry, logout, CSRF, and query clearing.
- `web/tests/features/expenses/expenses.test.tsx`: active defaults, decimal strings, invalid amount focus/value preservation, empty-group guidance, archived edit references, and contribution mismatch preservation.
- `web/tests/features/participants/participants.test.tsx`: stable order, archived status, add/rename lifecycle, focus-bound errors, deletion protection, identity preservation, and balance refetch.
- `web/tests/features/balances/balances.test.tsx`: exact official values/order, Spanish non-color states, archived zero visibility, REST startup, and manual refresh.
- `web/tests/features/settlement/settlement.test.tsx`: settled empty state and ordered formatted transfers.
- `web/tests/features/group/group-settings.test.tsx`: server-owned details, owner/member affordance, and forbidden mutation.

Add only narrow assertions for shared loading/error roles, preserved hash links/active navigation, or newly introduced recovery controls. Prefer Testing Library roles/names and structural readback over snapshots.

Required gates after the final exact bytes:

```text
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
```

Also perform the manual Samaipata walkthrough, responsive checks at approximately 375px/tablet/desktop/landscape, keyboard/focus/live-region/reduced-motion checks, and changed-path/changed-line inspection. Confirm no generated, backend, mobile, or WebSocket files changed.

## Work-unit sequencing and 800-line enforcement

Use one writer thread and the following dependency order:

1. **Foundation:** theme tokens, shared primitives, common loading/error/empty treatment, and global responsive/focus rules.
2. **Primary workflow:** shell/navigation framing, login presentation, and expense workspace hierarchy.
3. **Financial summary:** balances and settlement surface treatment and state consistency.
4. **Secondary administration:** participant and group presentation, with only the required responsive/accessibility adjustments.
5. **Proof and freeze:** focused tests, full web gates, manual responsive/accessibility readback, and changed-line count.

The task breakdown must include a review workload forecast. Because the forecast is above the historical 600 default and likely above the 400-line review comfort threshold, the configured `exception-ok` posture records the approved size exception; `stacked-to-main` may split the slices but does not authorize scope expansion.

Native attempt authority, not task-authored counters, enforces the cap:

- Before each apply or remediation actor, acquire a provider-owned attempt for `web-professional-redesign` with the work-unit label, evidence goal, bounded attempt count, and `--max-changed-lines 800` (or a smaller slice allocation whose sum is at most 800).
- Launch only on `state: proceed`; retain the opaque token and settle it with a distinct request ID and bounded evidence. `blocked` or `complete` stops the work unit.
- Do not write counters into `tasks.md`, prompts, OpenSpec state, or Pi state. Do not modify `openspec/config.yaml` to change its historical 600 value.
- Count additions and deletions against the same candidate before freeze. Any source-mutating normalization happens before final verification and the final count is taken from the exact candidate.

Forecast and scope gates:

| Forecast/result | Action |
| --- | --- |
| Up to 640 changed lines | Continue with all core presentation slices and targeted state/accessibility tests. |
| 641–720 | Freeze the core hierarchy and states; defer `web/index.html`, icon additions, decorative surface work, and optional error-action polish. |
| 721–800 | Reduce secondary administration to token/primitive application and required responsive fixes; add no new test surface beyond acceptance blockers. Reserve the remaining lines for corrections and normalization. |
| Above 800, or a native acquire reports no remaining budget | Stop. Reduce scope and update the task breakdown; never silently exceed the cap or move to a broader rewrite. |

The expected implementation target is approximately 600–680 changed lines, leaving room for focused test corrections and convergent normalization. A smaller coherent redesign is preferred over consuming the full limit.

## Rollout and rollback

Roll out in the same dependency order as the work units. Each slice is independently reviewable and can be checked with the web test suite; the final slice runs the complete web/typecheck/build and manual responsive gates. No feature flag or data migration is needed because the change does not alter runtime contracts or persisted state.

Rollback is a presentation-only revert:

1. Revert the smallest affected token/primitive/layout slice if a regression is localized.
2. If the whole redesign is unsuitable, revert the stacked slices in reverse order, leaving the existing protected shell, queries, API clients, WebSocket invalidation, and data untouched.
3. If a test, accessibility check, or line budget cannot be satisfied, stop before delivery and reduce scope rather than shipping a partial behavioral change or exceeding 800 lines.
