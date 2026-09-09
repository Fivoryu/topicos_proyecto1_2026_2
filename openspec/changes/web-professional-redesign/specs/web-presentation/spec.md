# Delta for web-presentation

## ADDED Requirements

### Requirement: Editorial hierarchy makes the authenticated workspace scannable

The authenticated web client MUST present the confirmed `editorial` direction as a calm, spacious, light-theme financial workspace. The expense workspace and `Registrar gasto` action MUST be the primary visual anchor; balances and settlement MUST be immediately scannable; participant and group administration MUST remain available but visually secondary. Page background, workspace, summary, management, and inline-state surfaces MUST form a restrained hierarchy rather than a collection of equally prominent cards. The presentation MUST preserve Spanish product semantics and MUST NOT introduce dark mode or theme switching.

#### Scenario: Authenticated dashboard establishes the intended hierarchy

- **GIVEN** an authenticated user opens the protected web dashboard
- **WHEN** the dashboard renders its existing sections
- **THEN** the expense editor and `Registrar gasto` action have the clearest visual priority
- **AND** balances and settlement are prominent enough to scan without competing with the primary expense task
- **AND** participant and group administration remain reachable but visually quieter
- **AND** the interface uses the existing light-theme finance foundation with restrained spacing, surfaces, and elevation

#### Scenario: Official financial outcome remains visually exact

- **GIVEN** the official Samaipata server responses are loaded
- **WHEN** the balances and settlement sections render
- **THEN** the UI displays Ana `+Bs. 560,00`, Beto `Bs. 0,00`, Carla `-Bs. 160,00`, and Diego `-Bs. 400,00`
- **AND** it displays `Diego → Ana: Bs. 400,00` followed by `Carla → Ana: Bs. 160,00`
- **AND** those values and their order come from the server response and are not client-computed

### Requirement: Shared presentation primitives communicate states consistently

The web client MUST use a shared presentation language for buttons, panels, headings, statuses, loading, empty, validation, forbidden, session-expired, and network-error states. Each state MUST explain its meaning in Spanish and provide an existing or appropriate recovery or next action when recovery is possible. Financial and status meaning MUST NOT depend on color alone. Shared presentation tokens MUST govern color, spacing, radius, elevation, and motion; ad-hoc per-surface visual values MUST NOT create a conflicting language.

#### Scenario: Loading and empty states are understandable

- **GIVEN** an expense, participant, balance, or settlement resource is loading or has no records
- **WHEN** its section renders
- **THEN** the user sees a distinguishable Spanish loading or empty state with the section's existing accessible name
- **AND** the state does not fabricate financial or domain data
- **AND** an empty state provides the relevant existing guidance or action when one exists

#### Scenario: Failure and authorization states offer recovery

- **GIVEN** a protected read or mutation returns validation, `forbidden`, `session_expired`, or network failure
- **WHEN** the corresponding web state renders
- **THEN** the message identifies the state in Spanish near the affected content or control
- **AND** it provides the existing retry, edit, return-to-login, or other applicable recovery path
- **AND** the client does not optimistically replace authoritative data with invented results

### Requirement: Editorial responsive layout preserves reading order and operability

The web presentation MUST remain usable at approximately 375px mobile, tablet, desktop, and landscape widths. It MUST prevent unintended page-level horizontal overflow, preserve access to the existing primary actions and hash navigation, and keep the expense and financial-outcome content ahead of secondary administration in the responsive reading order. Monetary values, forms, navigation, and state messages MUST remain readable and operable without changing their semantics or workflow.

#### Scenario: Small viewport keeps the primary workflow usable

- **GIVEN** the authenticated dashboard is rendered at approximately 375px width
- **WHEN** the user navigates through the expense, balance, and settlement sections
- **THEN** no unintended page-level horizontal overflow occurs
- **AND** `Registrar gasto`, form controls, monetary values, state messages, and navigation remain reachable and readable
- **AND** expense and financial-outcome content precede secondary participant and group administration in the reading order

#### Scenario: Existing anchors remain stable at every supported width

- **GIVEN** a user opens a supported mobile, tablet, desktop, or landscape viewport
- **WHEN** the user follows or refreshes an existing hash deep link
- **THEN** `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo` remain available
- **AND** the corresponding section is identifiable through headings and active-navigation treatment
- **AND** no router, route, or new workflow is required

### Requirement: Presentation remains accessible without changing interaction contracts

The redesigned web presentation MUST preserve semantic HTML, existing tested accessible names, keyboard traversal order, visible focus indicators, form labels and descriptions, live-region behavior, non-color state cues, and reduced-motion behavior. Interactive controls MUST remain operable by keyboard and have appropriately sized hit areas; transitions MUST be limited to meaningful presentation state changes and MUST respect the user's reduced-motion preference.

#### Scenario: Keyboard and assistive-technology contracts survive redesign

- **GIVEN** a keyboard or assistive-technology user operates the login, expense, participant, balance, settlement, or group sections
- **WHEN** the redesigned presentation is traversed and interacted with
- **THEN** focus follows the visual and semantic order with a visible focus indicator
- **AND** labels, accessible names, roles, descriptions, and live announcements remain available
- **AND** validation and financial states have text or icon cues in addition to color

#### Scenario: Reduced motion is respected

- **GIVEN** the user has enabled a reduced-motion preference
- **WHEN** the web client changes loading, navigation, feedback, or interaction state
- **THEN** nonessential transitions are suppressed or reduced
- **AND** no scroll choreography or animation is required to understand or complete the workflow

### Requirement: Redesign scope is presentation-only and budget-bounded

This change MUST remain limited to the existing web presentation seams and MUST stay at or below 800 changed lines. It MUST NOT add workflows, routes, API or schema changes, generated-client edits, backend or database changes, authentication or authorization changes, WebSocket protocol or invalidation-wiring changes, mobile changes, localization changes, dark mode, styling-framework migration, or new runtime UI dependencies. If the planned work cannot fit the budget, scope MUST be reduced rather than exceeded.

#### Scenario: Protected architecture and domain authority remain unchanged

- **GIVEN** the web redesign is applied
- **WHEN** a user signs in, records or edits an expense, manages participants, views balances or settlement, refreshes, or receives `{"type":"data_changed"}`
- **THEN** FastAPI remains authoritative for session, role, persistence, money, balances, and settlement
- **AND** the client continues to render server-provided values through the existing formatter without calculating, rounding, reordering, or optimistically inventing results
- **AND** WebSocket input remains invalidation-only and authoritative REST refetch behavior remains unchanged
- **AND** generated clients, backend, mobile, and WebSocket implementation files remain untouched

#### Scenario: Scope and line budget are checked before delivery

- **GIVEN** the final web redesign candidate is prepared for verification
- **WHEN** changed paths and changed lines are inspected
- **THEN** only approved web presentation files and narrowly targeted presentation/accessibility tests are changed
- **AND** the total changed-line count is at most 800
- **AND** any optional metadata, decorative, or low-impact polish is deferred when needed to remain within the budget

## MODIFIED Requirements

### Requirement: Presentation polish preserves existing functionality

Translation and presentation changes MUST preserve the current responsive visual system, Spanish product semantics, and all existing participant, expense, balance, settlement, authentication, refresh-persistence, archived-reference, validation, role, and invalidation behavior. Backend mutations MUST continue publishing the exact group-scoped post-commit invalidation-only frame through the shared broadcaster, and the web client MUST continue using its existing API-base resolution and WebSocket-triggered REST refetch behavior. The web client MUST continue displaying server-derived money and roles through handwritten integration code without manually modifying generated OpenAPI files. The protected shell MUST remain inaccessible to anonymous users, existing hash anchors MUST remain available, and no presentation change MAY alter domain authority or authorization.

(Previously: Translation and clarity changes preserved existing responsive behavior, domain interactions, API-base resolution, WebSocket-triggered REST refetch behavior, server-derived money and roles, and generated-client boundaries, but did not define the confirmed editorial hierarchy, responsive reading-order, accessibility-state, and explicit presentation-only budget boundaries.)

#### Scenario: Existing interaction suite runs after translation

- **WHEN** web tests and the production build run after the text and presentation updates
- **THEN** add/list participants, create/edit/delete expenses, default and excluded beneficiaries, archived references, balances, settlement, session lifecycle, and refresh behavior remain operational
- **AND** existing backend mutation-invalidation, group-isolation, web API-base, and WebSocket tests pass without modification
- **AND** generated client trees contain no manual presentation edits

#### Scenario: Session and role behavior remain server-authoritative

- **GIVEN** anonymous, authenticated owner, authenticated member, expired-session, and forbidden-action states
- **WHEN** the redesigned web client renders or handles them
- **THEN** anonymous users see only the login or unauthorized state and no protected data
- **AND** the displayed role and owner/member affordances remain derived from the server session
- **AND** expiry, logout, CSRF/origin enforcement, and forbidden responses retain their existing behavior

#### Scenario: Financial invariants remain unchanged

- **GIVEN** the official Samaipata records and server-derived results
- **WHEN** the user views balances, settlement, and refresh persistence
- **THEN** money remains integer cents on the authority boundary and is rendered with the existing shared formatter
- **AND** balances remain Ana `+Bs. 560,00`, Beto `Bs. 0,00`, Carla `-Bs. 160,00`, and Diego `-Bs. 400,00`
- **AND** ordered settlement remains Diego → Ana `Bs. 400,00`, then Carla → Ana `Bs. 160,00`
- **AND** the client performs no financial calculation or reordering

#### Scenario: WebSocket availability does not become a data dependency

- **GIVEN** the authenticated web client receives `{"type":"data_changed"}` or the socket is unavailable
- **WHEN** freshness coordination runs
- **THEN** the frame causes the existing affected REST queries to invalidate and refetch without being treated as domain data
- **AND** normal page refresh and REST fetching continue to provide authoritative state when the socket is unavailable

## REMOVED Requirements

None.
