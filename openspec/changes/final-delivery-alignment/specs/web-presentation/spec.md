## Purpose

Define a clear primarily Spanish web presentation for the final demonstration while preserving the existing responsive design, protected flow, and server-authoritative calculations.

## ADDED Requirements

### Requirement: Main protected web flow is presented in Spanish
The web application MUST present login/session, group, participant, expense, balance, settlement, loading, empty, validation, and primary action text in natural Spanish, including accessible names and document language metadata. Stable protocol error codes MAY remain unchanged, but user-facing explanations in the main flow MUST not depend on English wording.

#### Scenario: User navigates the delivery flow
- **WHEN** a Spanish-speaking user signs in and reviews the protected group
- **THEN** headings, labels, actions, statuses, and accessibility names for the main flow are in Spanish
- **AND** server-derived `owner` and `member` roles and settlement-policy values are shown with Spanish user-facing labels rather than raw English identifiers

### Requirement: Balance positions use natural Spanish concepts
The balance view MUST label positive positions as `Le deben`, negative positions as `Debe`, and zero positions as `Saldado`, while retaining non-color indicators and the server-provided participant order and cent values. Delivery-facing Boliviano amounts MUST use two decimal digits with a decimal comma: positive balances such as `+Bs. 560,00`, debts such as `-Bs. 160,00`, and zero such as `Bs. 0,00`.

#### Scenario: Official balances are displayed
- **WHEN** the official Samaipata balance response renders
- **THEN** Ana shows `+Bs. 560,00` and `Le deben`, Beto shows `Bs. 0,00` and `Saldado`, Carla shows `-Bs. 160,00` and `Debe`, and Diego shows `-Bs. 400,00` and `Debe`
- **AND** the client has not recomputed, rounded, or reordered the server values

### Requirement: Settlement transfers use direct arrow notation
Each settlement transfer MUST be rendered as `<deudor> → <acreedor>: <monto>` using the server-provided names, order, and integer-cent amount formatted in Bolivianos. A settled group MUST show a clear Spanish empty state and no transfer rows.

#### Scenario: Official settlement is displayed
- **WHEN** the official Samaipata settlement response renders
- **THEN** the visible rows are `Diego → Ana: Bs. 400,00` followed by `Carla → Ana: Bs. 160,00`
- **AND** no technical English phrase such as `pays` is displayed

#### Scenario: Group has no pending transfers
- **WHEN** the server reports that everyone is settled
- **THEN** the view displays a natural Spanish settled message and no transfer list

### Requirement: Presentation polish preserves existing functionality
Translation and clarity changes MUST preserve the current responsive visual system and all existing participant, expense, balance, settlement, authentication, refresh-persistence, archived-reference, validation, and invalidation behavior. In particular, backend mutations MUST continue publishing the exact group-scoped post-commit invalidation-only frame through the shared broadcaster, and the web client MUST continue using its existing API-base resolution and WebSocket-triggered REST refetch behavior. The web client MUST continue displaying server-derived money and roles through handwritten integration code without manually modifying generated OpenAPI files.

#### Scenario: Existing interaction suite runs after translation
- **WHEN** web tests and the production build run after the text updates
- **THEN** add/list participants, create/edit/delete expenses, default and excluded beneficiaries, archived references, balances, settlement, session lifecycle, and refresh behavior remain operational
- **AND** existing backend mutation-invalidation, group-isolation, web API-base, and WebSocket tests pass without modification
- **AND** generated client trees contain no manual presentation edits
