# Web professional redesign

## Intent

Refine the existing authenticated React/Vite/TanStack Query/Tailwind-compatible web client into a calm, spacious, editorial finance workspace for Cuentas Claras. The redesign should make the Samaipata demonstration easier to understand and operate by strengthening hierarchy, spacing, surface treatment, and state communication while preserving the current product behavior, Spanish semantics, accessibility contracts, and server-authoritative architecture.

This is a presentation-focused change. It improves the experience of the existing workflows; it does not introduce a new workflow, route, data contract, or domain rule.

## User and problem framing

The primary users are authenticated group members who need to record expenses, inspect exact balances, and understand the ordered settlement outcome during the normal group-expense workflow and the official under-three-minute demonstration.

The current client is functional and already has a sound finance-oriented visual foundation, but its long dashboard can read as a collection of similarly weighted cards. Loading, empty, and error states are not presented consistently across features, and secondary administration can compete visually with the expense and financial-outcome workflows. Users therefore have to reconstruct the hierarchy instead of immediately seeing what to do, what changed, and where the authoritative result is.

The desired outcome is a more composed workspace: expense recording is the clear primary task, balances and settlement are easy to scan, and participant/group administration remains available but visually quiet. The interface must continue to communicate that money, balances, and settlement are calculated by the server.

## Confirmed visual direction

The confirmed product decision is `editorial`:

- Use a calm, spacious, editorial finance workspace rather than a dense operational console.
- Retain and refine the current light-theme foundation: warm paper-like surfaces, deep green structural navigation, one terracotta action accent, and distinct teal/red financial states.
- Preserve the existing serif-display and sans-serif-body contrast, with readable measures and tabular figures for monetary values.
- Make the expense workspace and the “Registrar gasto” action the visual anchor.
- Establish a restrained surface hierarchy for page background, primary workspace, summary areas, and inline states instead of treating every section as an equal card.
- Use whitespace, grouping, and consistent elevation sparingly; avoid decorative gradients, gratuitous animation, and visual noise.
- Keep the current handwritten outline SVG vocabulary as the icon language unless a narrowly justified semantic gap is found. Do not add an icon library casually.
- Use meaningful, short transitions for state changes only, preserving reduced-motion behavior and avoiding scroll choreography.

The current hash-based single-dashboard structure remains the navigation model. Orientation may be improved through stronger section headings and active-navigation treatment, but this proposal does not add routes or replace hash anchors.

## Scope

### In scope

1. **Shared presentation foundations**
   - Refine existing semantic theme tokens for color, spacing, radius, shadow, and motion where this improves hierarchy without changing the light-theme contract.
   - Polish shared buttons, panels, headings, compact statuses, loading surfaces, error surfaces, and empty-state presentation.
   - Preserve semantic HTML, focus visibility, accessible names, and state communication.

2. **Authenticated workspace and login presentation**
   - Improve the protected shell, navigation, section framing, and responsive reading order.
   - Refine the login page hierarchy and feedback states without changing authentication, session, CSRF, or role behavior.

3. **Existing product workflows**
   - Rebalance the expense editor and history as the primary workspace.
   - Improve the scannability of balances and server-derived settlement results.
   - Keep participant lifecycle actions and group administration available while reducing their visual competition with the financial workflow.
   - Give loading, empty, validation, forbidden, session-expired, and network-error states consistent explanation and recovery affordances using the existing behavior.

4. **Responsive and accessibility polish**
   - Validate the light-theme layout at approximately 375px mobile, tablet, desktop, and landscape widths.
   - Prevent page-level horizontal overflow and keep navigation, forms, monetary values, and primary actions operable at small widths.
   - Preserve keyboard order, visible focus, labels, live-region behavior, non-color state cues, reduced-motion support, and appropriately sized controls.

5. **Small presentation-only metadata work**
   - Metadata/title refinement may be included only if it remains clearly subordinate to the in-app redesign and fits the line budget. Favicon and broader metadata expansion are deferred by default.

## Out of scope

- New workflows, routes, screens, or navigation technology.
- Public registration, password recovery, invitations, OAuth, payments, analytics, OCR, custom split logic, multiple currencies, or other new product capabilities.
- Backend, API, schema, database, generated-client, or OpenAPI changes.
- Changes to authentication or authorization, protected-session behavior, CSRF/origin checks, server-derived roles, or logout/query-clearing behavior.
- Changes to money calculations, rounding, balances, settlement ordering, participant identity/lifecycle rules, expense semantics, or group-policy authorization.
- Changes to WebSocket protocol, connection ownership, invalidation behavior, query keys, REST authority, or client data-fetching behavior.
- Mobile/Flutter redesign, mobile parity, or work owned by another OpenSpec change.
- Dark mode, theme switching, localization changes, or a styling/framework/Tailwind migration.
- New UI, icon, routing, animation, or font dependencies unless separately approved; the first slice should use the existing infrastructure.
- Pixel snapshots as the sole acceptance proof or a broad screenshot-testing system.

## Affected areas

The implementation should stay within the existing web presentation seams identified during exploration:

- **Web theme and global styles:** semantic tokens, shared layout primitives, shell/navigation, workspace grid, breakpoints, and reduced-motion rules.
- **Shared UI primitives:** buttons, panels, headings, statuses, loading, error, and empty-state surfaces.
- **Application shell:** workspace framing, stable hash navigation, active section treatment, and responsive structure.
- **Authentication screen:** visual hierarchy and state presentation only.
- **Expenses:** editor/history hierarchy, loading and empty/error presentation, and responsive form layout without changing field or mutation semantics.
- **Participants:** management density, action grouping, and explicit lifecycle/error states.
- **Balances and settlement:** summary hierarchy, exact value presentation, and settled/transfer states.
- **Group settings:** secondary administration hierarchy and role-appropriate presentation.
- **Optional document metadata:** only small title/description polish if the final proposal/spec/task breakdown keeps it within budget.

Do not edit generated client files, backend files, mobile files, or WebSocket implementation for this change.

## Preserved invariants

The redesign must preserve all of the following:

- FastAPI remains authoritative for authorization, sessions, roles, persistence, money, balances, and settlement.
- Money remains integer cents end to end and is rendered through the existing shared formatter; the client must not calculate, round, reorder, or optimistically invent financial results.
- Derived balances continue to sum to exactly zero cents, and server-derived settlement transfers retain their existing deterministic order.
- Existing participant identity, stable ordering, rename behavior, archived visibility/default rules, expense contributor/beneficiary semantics, and policy authorization remain unchanged.
- Existing API paths, request/response shapes, query ownership, query keys, API-base resolution, CSRF/origin enforcement, protected-route boundary, logout clearing, and session-expiry behavior remain unchanged.
- WebSocket behavior remains authenticated, group-scoped, and invalidation-only. The `{"type":"data_changed"}` frame remains a hint that causes REST invalidation/refetch; REST remains authoritative and the client remains usable when the socket is unavailable.
- Generated OpenAPI clients remain untouched and are not regenerated for visual work.
- The existing Spanish product semantics and tested accessible names remain stable unless a later product decision explicitly changes copy.
- The existing hash anchors remain available: `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo`.
- Anonymous users must not see the protected shell or protected data.
- The current light theme remains the baseline; no dark-mode behavior is implied.
- The mobile/Flutter change remains independent and untouched.

## Acceptance and success criteria

The change is successful when all of the following are true:

1. **Editorial hierarchy**
   - The authenticated web client visibly prioritizes expense recording and the “Registrar gasto” action.
   - Balances and settlement are immediately scannable without making participant/group administration equally prominent.
   - Surfaces, spacing, typography, and state treatments form one restrained light-theme system rather than a collection of equal cards.

2. **Behavior preservation**
   - Signed-out, authenticated, expired-session, owner, and member experiences retain their existing behavior and server-derived role authority.
   - Expense creation/edit/delete, participant lifecycle actions, group-policy behavior, balances, settlement, refresh persistence, and WebSocket-triggered refetch continue to behave as before.
   - The official Samaipata result remains exact: Ana `+Bs. 560,00`, Beto `Bs. 0,00`, Carla `-Bs. 160,00`, Diego `-Bs. 400,00`; transfers remain Diego → Ana `Bs. 400,00`, then Carla → Ana `Bs. 160,00`.

3. **State clarity and accessibility**
   - Loading, empty, validation, forbidden, session-expired, and network-error states explain the state and offer an existing or appropriate recovery path without changing product behavior.
   - Controls retain visible labels or accessible names, semantic roles, keyboard operation, visible focus, and non-color cues for financial/status meaning.
   - Reduced-motion preferences continue to suppress or reduce nonessential motion.

4. **Responsive quality**
   - At approximately 375px, tablet, desktop, and landscape widths, the page has no unintended horizontal overflow; primary actions, navigation, forms, monetary values, and state messages remain usable and readable.
   - The mobile reading order keeps the core expense and financial-outcome content ahead of secondary administration without hiding required functionality.

5. **Regression and delivery constraints**
   - Existing behavior-oriented web tests remain green, with only narrowly targeted presentation/accessibility assertions added where necessary.
   - Web typecheck and production build pass.
   - Backend, generated-client, and mobile files remain unchanged.
   - The final diff is at or below the requested **800 changed-line budget**. If the first implementation plan cannot fit, reduce scope rather than exceed the budget.

## Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Shared global styles are coupled across the dashboard, so a local polish may break another feature or breakpoint. | Start with semantic tokens and shared primitives, then make small feature-level adjustments. Verify desktop, tablet, mobile, and landscape after each coherent slice. |
| DOM restructuring can break expense form semantics, archived-reference behavior, or focus-on-error handling. | Preserve existing field IDs, labels, descriptions, roles, mutation wiring, and state branches; prefer wrapper/layout changes over behavioral rewrites. |
| Copy changes can invalidate behavior-oriented tests or Spanish product semantics. | Preserve tested wording and accessible names; treat copy changes as out of scope unless explicitly required for clarity and separately verified. |
| A spacious editorial direction could reduce efficiency for expense entry or hide secondary actions. | Keep the expense editor as the operational anchor, preserve direct access to all existing actions, and validate the complete Samaipata walkthrough at the accepted viewport sizes. |
| Decorative assets, new fonts, or animation could increase bundle size and review cost. | Use the current font/icon/style infrastructure, semantic CSS tokens, transform/opacity transitions, and no new runtime dependencies in the first slice. |
| Visual prominence could imply that client-rendered amounts are authoritative. | Retain server-authority messaging and existing REST/query flow; do not add client-side financial calculations or optimistic result states. |
| A budget overrun could create a broad, difficult-to-review redesign. | Sequence work as token/primitive polish first, then the primary expense workspace, then focused state/responsive fixes. Defer metadata and low-impact decoration first. |

## Rollback

Rollback is presentation-only and should be low risk:

1. Keep the change isolated to the approved web presentation files and do not alter backend, contracts, generated clients, mobile files, or data.
2. If a visual or accessibility regression is found, revert the smallest affected token, primitive, layout, or feature styling change and retain the previous working presentation seam.
3. If the complete redesign is not acceptable, revert the change commit(s) or the stacked feature slice in reverse order. Existing hash navigation, server behavior, and data remain available because they are explicitly outside the change.
4. If the line budget or verification cannot be met, stop and reduce the proposal scope rather than shipping a partial behavior change or silently exceeding the budget.

## Verification approach

Verification should combine existing behavioral proof with proportional visual and accessibility checks:

1. Run the focused web suites covering app shell/authentication, expenses, participants, balances, settlement, and group settings.
2. Run the complete web test suite, typecheck, and production build.
3. Manually walk through the Samaipata flow: sign in, inspect the group, record or review expenses, inspect exact balances, inspect ordered settlement, refresh, and confirm persistence.
4. Check approximately 375px mobile, tablet, desktop, and landscape layouts for overflow, reading order, reachability, readable values, and operable primary actions.
5. Inspect keyboard traversal, visible focus, labels/roles, live-region announcements, non-color state cues, reduced-motion behavior, and touch-target sizing.
6. Confirm no anonymous protected content appears during bootstrap, no generated/API/backend/mobile/WebSocket files changed, and no new client-side authority assumptions were introduced.
7. Read back the final HTML/CSS structure and count changed lines before candidate freeze. Verification must run against the final exact bytes; any source-mutating normalization must happen before final verification.

The proposal does not require brittle pixel snapshots. Existing behavior tests plus targeted semantic/accessibility checks and manual responsive inspection provide the proportional proof for a presentation-only change.

## Delivery posture

Project delivery is configured for automatic execution with the `exception-ok` delivery strategy and `stacked-to-main` chain strategy. These settings govern execution and delivery coordination; they do not authorize expanding the product scope or exceeding the 800-line presentation budget. If delivery is split into stacked slices, each slice must remain within the approved boundaries and preserve the same invariants.

## Line-budget strategy

The hard budget is **800 changed lines**. Work should be ordered by leverage:

1. Consolidate or refine existing theme tokens and shared primitives.
2. Rebalance shell/navigation and the expense workspace, preserving current class seams where practical.
3. Apply focused hierarchy/state treatment to balances, settlement, participants, group settings, and login.
4. Add only the smallest responsive/accessibility corrections required by acceptance.
5. Defer optional metadata, decorative assets, broad copy changes, and low-impact polish if the forecast approaches the limit.

The implementation must not create new product behavior merely to consume the budget. A smaller, coherent redesign is preferable to a broader diff. The task breakdown should include a changed-line forecast and a stop/reduce-scope rule before implementation begins.

## Explicit non-goals

This change is not a product-domain rewrite, data-model change, responsive mobile-app project, routing migration, dark-mode project, component-library migration, or animation showcase. It must not alter how Cuentas Claras authenticates users, stores or calculates money, derives balances or settlement, authorizes actions, invalidates queries, or preserves data across refreshes. It must not absorb work from the backend, generated clients, WebSocket invalidation, or independent mobile OpenSpec changes.
