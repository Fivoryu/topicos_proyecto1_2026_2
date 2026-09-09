# Delta for Web Presentation

## ADDED Requirements

### Requirement: Laptop-first workspace information architecture

The web MUST present the confirmed workspace destinations as separate, understandable pages or route states: groups, selected-group summary, outings, outing detail and expenses, general expenses, participant detail, balances, settlement, and group/membership settings. The presentation MUST include explicit loading, empty, forbidden, archived/read-only, and error states. Mobile parity is not required by this delta.

#### Scenario: Empty and protected states are explicit

- GIVEN an authenticated account with no groups, or a selected group with no outings or expenses
- WHEN the relevant page renders
- THEN it explains the empty state and available next action
- AND an unauthenticated or unauthorized user sees no protected content

#### Scenario: Archived history is visibly read-only

- GIVEN an archived outing with expenses
- WHEN its detail page renders
- THEN the outing and expense history remain visible
- AND the page communicates that associated writes are unavailable

### Requirement: Accessible navigation and preserved anchors

The laptop-first web navigation MUST preserve applicable existing hash anchors and provide predictable back/deep-link behavior inside the protected shell. Interactive actions MUST have accessible names, visible focus states, and clear error recovery. New visual work MUST not overwrite `web-professional-redesign` or introduce a dependency.

#### Scenario: Deep link validates before rendering

- GIVEN a direct URL/hash for a selected group or outing
- WHEN the protected app loads
- THEN session and membership are validated before protected data renders
- AND invalid selection returns to a safe protected state

## MODIFIED Requirements

### Requirement: Main protected web flow is presented in Spanish

The web application MUST present the new group, outing, membership, general-expense, and workspace settings labels, actions, errors, empty states, and accessibility names in natural Spanish while retaining the existing Spanish treatment for login, participants, expenses, balances, settlement, and roles. Stable protocol error codes MAY remain unchanged.

(Previously: Spanish presentation covered the single-group participant, expense, balance, settlement, login, and primary action flow.)

#### Scenario: Workspace labels are Spanish and understandable

- GIVEN a Spanish-speaking authenticated user
- WHEN the user navigates groups, outings, join-code settings, balances, and settlement
- THEN headings, actions, status labels, and accessible names are natural Spanish
- AND raw machine identifiers are not the primary user-facing copy

#### Scenario: User navigates the delivery flow

- **WHEN** a Spanish-speaking user signs in and reviews the protected group
- **THEN** headings, labels, actions, statuses, and accessibility names for the main flow are in Spanish
- **AND** server-derived `owner` and `member` roles and settlement-policy values are shown with Spanish user-facing labels rather than raw English identifiers

### Requirement: Presentation polish preserves existing functionality

The web application MUST preserve the current responsive visual system, protected session flow, server-derived money and roles, membership authorization, exact-zero balances, structured errors, participant and expense behavior, archived-reference behavior, refresh persistence, and invalidation-only WebSocket behavior. The web MUST remain a thin generated-client consumer and MUST preserve official fixture presentation. Backend mutations MUST continue publishing the exact group-scoped post-commit invalidation-only frame through the shared broadcaster, and the web client MUST continue using its existing API-base resolution and WebSocket-triggered REST refetch behavior. The web client MUST continue displaying server-derived money and roles through handwritten integration code without manually modifying generated OpenAPI files.

(Previously: Presentation preservation covered the delivered single-group flow and the official fixture.)

#### Scenario: Existing interaction suite runs after translation

- **WHEN** web tests and the production build run after the text updates
- **THEN** add/list participants, create/edit/delete expenses, default and excluded beneficiaries, archived references, balances, settlement, session lifecycle, and refresh behavior remain operational
- **AND** existing backend mutation-invalidation, group-isolation, web API-base, and WebSocket tests pass without modification
- **AND** generated client trees contain no manual presentation edits

#### Scenario: Official Samaipata presentation remains unchanged

- GIVEN the official Samaipata seed and its four expenses
- WHEN the existing protected flow is opened
- THEN the four expenses, Spanish balances, settlement order, and refresh behavior remain unchanged
- AND no new outing or general-expense allocation changes the official result
