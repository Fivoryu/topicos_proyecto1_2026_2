# Exploration: Web professional redesign

## Executive direction

Redesign the existing authenticated web experience as a focused, professional finance workspace for Cuentas Claras, using the Samaipata demo flow as the primary validation journey. The change should improve hierarchy, visual consistency, density, and state communication without changing domain behavior, routes/anchors, API contracts, or the server-authoritative data model.

`final-delivery-alignment` is archived under `openspec/changes/archive/2026-09-04-final-delivery-alignment/`; this is a separate, web-focused change. The repository currently documents no active OpenSpec change in `docs/sdd-evolution.md`.

## Current-state audit

### Stack and composition

- `web/package.json` confirms React 19, Vite 6, TypeScript, TanStack Query 5, Vitest/Testing Library, and Tailwind 3.4.17. There is no UI component dependency or icon package; icons are handwritten SVG paths in `src/components/icons.tsx`.
- The rendered styling is primarily authored CSS rather than utility classes: `src/index.css` contains the complete layout/component system and `src/core/theme.css` contains semantic tokens. This is consistent with the project context's “Tailwind/CSS” description, but the redesign should not introduce a styling migration.
- `src/app/App.tsx` is a single protected dashboard composition. Navigation uses stable hash anchors for Gastos, Balances, Liquidación, Participantes, and Grupo. Desktop uses a sticky sidebar; smaller widths use a horizontally scrollable navigation row.
- `src/components/ui.tsx` provides the shared Button, Panel, PanelHeading, StatusBadge, LoadingCard, and ErrorCard primitives. These are the highest-leverage redesign seam.

### Visual system

Strengths already present:

- Warm finance-oriented token set: cream surfaces, deep green navigation, terracotta primary, teal credit, muted red debt, semantic borders, focus ring, and tinted shadows.
- Semantic token usage is centralized in `theme.css`; there are no ad-hoc per-component hex colors in the inspected web UI.
- Typography has intentional contrast: serif display headings and a sans-serif body, balanced headings, tabular figures for money, and readable base sizing.
- Interaction foundations exist: visible `:focus-visible`, hover/active/disabled states, 44px-ish controls, reduced-motion media rule, skip link, semantic sections/forms, and accessible labels.
- The current layout already avoids a generic three-card marketing row: Expenses is the dominant workflow, balances/settlement are a summary area, and participants/group administration form a secondary rail.

Problems and polish opportunities:

- The CSS system is large and highly coupled to class names (`feature-*`, `dashboard-*`, `expense-*`). Visual refinement should preserve these seams or consolidate carefully; a broad rewrite would create unnecessary regression risk.
- The visual hierarchy is good in intent but still reads as many equal “cards.” Several secondary panels use the same `feature-card` primitive, so the redesign should distinguish workspace, summary, management, and state surfaces through spacing, grouping, and restrained elevation rather than adding decoration.
- Eyebrows are heavily uppercase and letter-spaced throughout. This is consistent but can make the interface feel template-like; use sentence-case labels or reserve small caps for true metadata.
- Status badges are pill-shaped and used for several meanings. Retain compact status treatment where it communicates state, but avoid making every label a badge and ensure state is also expressed by text/icon.
- Loading and error primitives are present, but most feature-specific pending/error branches in Participants and Expenses render plain `feature-card` sections instead of the shared `LoadingCard`/`ErrorCard`. This produces inconsistent feedback and weaker loading skeleton behavior.
- Empty states are explicit, but they are mostly plain text (`feature-empty`). The redesign can give the key empty states a clearer next action and hierarchy without inventing new workflows.
- The main page is a long dashboard rather than route-separated screens. Preserve the existing anchors and deep-link behavior; improve orientation with stronger section headers and current-navigation treatment rather than adding a router.
- The document metadata is incomplete for a polished web surface: `web/index.html` has `lang="es"`, viewport, theme color, and title, but no description. Metadata work is optional and must remain small and presentation-only.
- The theme declares only `color-scheme: light`; dark mode should not be added in this change unless product explicitly requires it. Adding a second theme would exceed the focused redesign and accessibility verification budget.

### Screens and workflows

1. **Anonymous/session bootstrap and login** (`ProtectedRoute`, `SessionProvider`, `LoginScreen`): login is the only anonymous screen. It has a two-column showcase/form layout that collapses to a single-column mobile view, visible labels, password visibility control, inline auth messages, disabled submitting state, and server-authority messaging.
2. **Record and maintain expenses** (`ExpensesPanel`): primary workflow. It loads participants and expenses with TanStack Query, creates/edits/deletes expenses, supports multiple contributors and beneficiaries, keeps archived references during edit, and binds validation errors to fields.
3. **Review balances** (`BalancesPanel`): renders server-provided paid/owed/balance cents in stable participant order, uses the shared formatter, and exposes Spanish non-color state labels (`Le deben`, `Debe`, `Saldado`).
4. **Settle the group** (`SettlementPanel`): renders server-provided ordered transfers and an all-settled empty state; shows the server-derived settlement policy.
5. **Manage participants** (`ParticipantsPanel`): add, rename, archive/reactivate, and delete actions, with focus/error handling and archived status.
6. **Group administration** (`GroupSettings`): server-owned group details and the owner/member-dependent settlement-policy affordance.
7. **Cross-client freshness** (`connectGroupWebSocket`, query keys): the WebSocket is only an invalidation hint; receipt triggers REST query invalidation/refetch. REST remains authoritative.

Core product journey: sign in → inspect the Samaipata group → record or review expenses → inspect exact balances → inspect ordered settlement → refresh and confirm persistence. Participant maintenance and policy editing are important supporting workflows, but should not visually compete with expense recording and financial outcomes.

## Relevant tests and evidence

The existing web suite gives strong behavioral boundaries:

- `web/tests/app.test.tsx` verifies no anonymous protected shell and authenticated shell rendering.
- `web/tests/features/auth/session-provider.test.tsx` covers anonymous `204`, one-probe bootstrap, CSRF, invalid credentials, loading/password visibility, role authority, expiry, protected `401`, logout, and query clearing.
- `web/tests/features/expenses/expenses.test.tsx` covers active-participant defaults, decimal-string submission, invalid amount, empty group guidance, archived edit references, and contribution mismatch preservation.
- `web/tests/features/participants/participants.test.tsx` covers stable order, invalid/duplicate add, lifecycle, in-use deletion, rename errors/focus, and identity/balance preservation.
- `web/tests/features/balances/balances.test.tsx` covers official Ana/Beto/Carla/Diego values and Spanish state semantics, archived zero visibility, REST startup, and manual refresh.
- `web/tests/features/settlement/settlement.test.tsx` covers no-transfer settled state and ordered formatted transfers.
- `web/tests/features/group/group-settings.test.tsx` covers server-owned details, owner/member policy visibility, and forbidden mutation behavior.

Tests are behavior-oriented rather than pixel-oriented. This is desirable for a visual redesign: preserve accessible names and semantic roles so existing tests remain stable, and add only targeted presentation/accessibility assertions where a new state or responsive contract is intentionally introduced.

## Affected areas and likely files

Primary presentation seams:

- `web/src/core/theme.css` — semantic color, radius, shadow, motion, and spacing tokens.
- `web/src/index.css` — global primitives, auth layout, shell/navigation, dashboard grid, feature layouts, breakpoints, and reduced-motion behavior.
- `web/src/components/ui.tsx` — shared buttons, panels, headings, statuses, and loading/error surfaces.
- `web/src/components/icons.tsx` — only if the existing small SVG vocabulary cannot express a required semantic state; do not add a library casually.
- `web/src/app/App.tsx` — shell hierarchy, navigation labels/structure, and workspace framing, while preserving hash anchors and WebSocket setup.
- `web/src/features/auth/login-screen.tsx` — login visual hierarchy and states, preserving labels, messages, CSRF flow, and accessible controls.
- `web/src/features/expenses/expenses-panel.tsx` — expense editor/history presentation and empty/loading/error surfaces; preserve all form semantics and mutation payloads.
- `web/src/features/participants/participants-panel.tsx` — management density, action grouping, and explicit state presentation.
- `web/src/features/balances/balances-panel.tsx`, `settlement/settlement-panel.tsx`, and `group/group-settings.tsx` — summary, settlement, and administration hierarchy only.
- `web/index.html` — optional title/description metadata polish, only if approved in proposal.

Do not edit `web/src/generated/api/**`. Do not modify backend files, contracts, mobile files, WebSocket implementation, or query/API client behavior for this change.

## Proposed design direction and rationale

Use a **calm financial workspace**: warm paper-like base, deep green structural navigation, one terracotta action accent, teal/red semantic financial states, editorial serif display type paired with a practical sans body, and restrained depth. The current palette is already a strong foundation; refine hierarchy instead of replacing the brand.

Recommended first-slice direction:

- Make “Registrar gasto” the unmistakable primary action and make the expense editor/history the visual anchor.
- Establish a small surface hierarchy: page background, primary workspace surface, quiet summary surface, and inline state surface. Avoid uniform cards, excessive borders, and gratuitous gradients.
- Use consistent spacing and max-width rules, with an intentional desktop grid and a clear single-column mobile reading order.
- Replace plain loading branches with layout-matched skeleton/placeholder treatment where useful, while keeping loading announcements accessible and lightweight.
- Compose empty/error states with a short cause, recovery/action, and semantic icon/text; never rely on color alone.
- Keep one icon family/style (the existing handwritten outline SVGs), normalize size/stroke usage, and avoid emoji or decorative icon proliferation.
- Preserve visible focus, keyboard order, minimum touch targets, reduced motion, and no horizontal overflow at approximately 375px, tablet, and desktop widths.
- Keep motion limited to 150–300ms transform/opacity transitions and meaningful state changes; do not add scroll choreography or heavy dependencies.
- Follow React performance guidance: avoid introducing broad re-rendering or new data waterfalls; presentation components should continue receiving existing query data and mutations, and any static UI configuration should remain module-level.

This direction is preferable to a framework migration, dark-mode expansion, or a highly animated “dashboard” because it improves perceived quality with low behavioral risk and fits the existing finance-friendly tokens and under-three-minute demonstration.

## Preserved invariants

- FastAPI remains the authority for authorization, sessions, roles, persistence, money, balances, and settlement.
- Money remains integer cents end to end and is rendered only through the existing shared formatter; no client calculations, rounding, or reordering.
- Generated OpenAPI clients remain untouched and are not regenerated for visual work.
- Existing API paths, request/response shapes, query keys, TanStack Query ownership, API-base resolution, CSRF/origin enforcement, protected-route boundary, logout clearing, and session-expiry behavior remain unchanged.
- WebSocket behavior remains authenticated, group-scoped, invalidation-only with the exact `{"type":"data_changed"}` frame; clients continue to refetch REST and remain functional if the socket is unavailable.
- Participant identity, stable order, rename semantics, archived visibility/default rules, expense contributor/beneficiary semantics, policy authorization, and server-derived role labels remain unchanged.
- Mobile/Flutter and backend scope are explicitly untouched.
- Existing hash anchors (`#gastos`, `#balances`, `#liquidacion`, `#participantes`, `#grupo`) and deep-link navigation remain available.
- The implementation must stay within an 800 changed-line review budget; prefer token/component/layout consolidation over broad screen rewrites.

## Candidate boundaries

### In scope

- Web visual language refinement using existing CSS/Tailwind-compatible infrastructure.
- Shared primitive polish for buttons, panels, headings, badges, loading, error, and empty states.
- Auth page, protected shell/navigation, expense workspace, balances, settlement, participants, and group settings presentation.
- Responsive hierarchy and spacing at mobile, tablet, and desktop widths.
- Accessibility polish directly related to redesigned surfaces: focus, labels, live regions, state text/icons, keyboard order, touch targets, and reduced motion.
- Small metadata/title polish if it does not expand the product scope.
- Focused component tests for newly introduced semantic states plus existing Vitest, typecheck, and build gates.

### Out of scope

- New workflows, routes, registration, recovery, invitations, OAuth, payments, analytics, multi-currency, OCR, custom split logic, or new group management.
- Backend/API/schema/database changes, generated-client edits, money/domain logic, auth/authorization changes, CSRF/origin changes, or WebSocket protocol/wiring changes.
- Mobile redesign or parity work.
- Dark mode, theme switching, localization beyond preserving the current Spanish flow, or replacing the font/toolchain without an explicit product decision.
- New UI libraries, icon packages, animation runtimes, routing migrations, or a Tailwind version/config migration.
- Pixel-snapshot-driven acceptance as the sole proof; behavior and accessibility must remain primary.

## Acceptance hypotheses for proposal phase

1. A signed-out user sees only the login experience; a valid session still reveals the same protected shell and server-derived role.
2. The Samaipata journey remains demonstrable in under three minutes, with expenses as the primary action and balances/settlement immediately scannable.
3. Existing accessible names used by the current tests remain available, while redesigned controls retain visible labels and semantic roles.
4. Official values remain exact: Ana `+Bs. 560,00`, Beto `Bs. 0,00`, Carla `-Bs. 160,00`, Diego `-Bs. 400,00`; settlement remains Diego → Ana `Bs. 400,00`, then Carla → Ana `Bs. 160,00`.
5. Loading, empty, validation, forbidden, session-expired, and network-error states explain what happened and provide a clear recovery path without mutating data.
6. At approximately 375px width there is no horizontal page overflow, primary actions remain operable, navigation remains reachable, and balance/expense content remains readable.
7. Existing web tests, typecheck, and production build pass without changes to generated clients or backend regression suites.
8. The final diff remains within 800 changed lines; if implementation cannot fit, the proposal must reduce scope rather than silently exceed the budget.

## Implementation risks

- The large shared `index.css` means a local-looking visual change may affect several feature layouts or breakpoints. Mitigate with token/primitive-first edits and focused responsive checks.
- Existing tests query visible text and accessible names. Changing copy while styling can create unnecessary test churn; preserve wording unless a product decision explicitly changes it.
- Expense forms have unusually rich states and archived-reference rules. Any DOM restructuring must preserve field IDs, labels, `aria-describedby`, focus-on-error, and edit behavior.
- CSS `:has()` and container queries are already used; browser support and test DOM behavior should be checked before relying on additional advanced selectors.
- More decorative assets, fonts, or animation could increase bundle/performance risk and exceed the line budget. Prefer existing CSS/SVG primitives.
- A redesign could accidentally imply client-side financial authority through visual prominence or optimistic states. Keep “calculated by the server” messaging and REST refresh behavior clear.
- Existing project context still has historical references to a prior delivery change and config defaults that differ from the requested OpenSpec mode; proposal should treat the active request and current project context as authority and not rewrite historical records.

## Verification implications

- Before implementation, proposal/spec/design/tasks should define the visual contract and explicitly map each preserved behavior to existing tests.
- Run the focused web suite for auth, app shell, expenses, participants, balances, settlement, and group settings; then run `npm --prefix web run test`, `typecheck`, and `build`.
- Validate responsive behavior at 375px, tablet, desktop, and landscape; inspect keyboard traversal, visible focus, screen-reader names/live regions, reduced-motion behavior, contrast, and touch target sizes.
- Confirm no protected data appears during anonymous bootstrap, no API or generated-client files changed, and no WebSocket payload assumptions were introduced.
- Use structural readback of the final HTML/CSS and a manual Samaipata walkthrough as proportional visual verification; avoid introducing brittle screenshot tests unless the proposal establishes a narrowly justified visual regression need.
- Count changed lines before candidate freeze. Keep any normalization/formatting convergent and ensure verification is run against the final exact bytes.

## Unresolved product decisions for proposal

- Is the redesign intended for the current light theme only, or is dark mode a separately approved future change?
- Should navigation remain the current hash-based single dashboard, or may the proposal improve orientation only within those anchors (no router/routes)?
- Which visual identity is preferred within the existing palette: more editorial/quiet, or slightly more operational/data-dense for frequent expense entry?
- Should the group/participant administration rail stay visible on desktop, or collapse behind an explicit secondary affordance at medium widths?
- Is adding a short document description/favicon/metadata polish part of this change, or should the change remain strictly in-app?
- Which loading states need true layout skeletons versus simpler accessible progress placeholders to stay within 800 changed lines?
- Are user-facing Spanish labels currently accepted as the product copy baseline, or may proposal revise wording where it materially improves clarity while preserving test semantics?
- What concrete viewport/browser matrix will serve as the acceptance baseline for the course demonstration?
