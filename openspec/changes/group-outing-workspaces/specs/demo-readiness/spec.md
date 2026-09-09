# Delta for Demo Readiness

## MODIFIED Requirements

### Requirement: Official Samaipata seed contains four separate expenses

A fresh official demo seed MUST continue to create the same stable Samaipata group, accounts, participants, and exactly four source expenses: `Cabaña` `80000`, `Entradas a El Fuerte` `16000`, `Cena` `40000`, and `Gasolina` `24000` cents, with the existing contributor and beneficiary sets. The new group, outing, join, and membership fixtures MUST be isolated from the official fixture and MUST NOT add outings, join codes, or new expenses to it.

(Previously: The official fixture was protected from later delivery changes but did not explicitly define isolation from multi-group and outing fixtures.)

#### Scenario: Official seed remains unchanged

- WHEN the official seed runs against an empty migrated database
- THEN the same four participants and four expenses exist with the same identities and values
- AND no outing, join-code, or additional general expense is introduced into the official history

#### Scenario: Fresh seed has the official source records

- **WHEN** the demo seed runs against an empty migrated database
- **THEN** the four participants and four separately identifiable expenses exist with the specified descriptions, amounts, contributors, and all-participant beneficiary sets
- **AND** no aggregated `96000` Ana expense or additional `10000` walkthrough expense is part of the seeded official history

### Requirement: Seeded balances and settlement match the official result

The official Samaipata group MUST continue to derive Ana `+56000`, Beto `0`, Carla `-16000`, and Diego `-40000` cents, summing exactly to zero, with transfers Diego to Ana `40000` followed by Carla to Ana `16000`. Group/outing derivation rules MUST NOT reinterpret or allocate these source expenses.

(Previously: Official balances and settlement were defined without the new distinction between general and outing-scoped calculations.)

#### Scenario: Official result is unaffected by new scope rules

- WHEN balances and settlement are requested for the official group
- THEN the existing exact values and transfer order are returned
- AND no expense is treated as an outing expense or repeated in an outing result

#### Scenario: Official balances are derived from four records

- **WHEN** balances are requested for the freshly seeded Samaipata group
- **THEN** Ana is `+56000`, Beto is `0`, Carla is `-16000`, and Diego is `-40000` cents
- **AND** the four balances sum exactly to `0`

#### Scenario: Official settlement is derived

- **WHEN** settlement is requested for the freshly seeded Samaipata group
- **THEN** the transfers are Diego to Ana `40000` and Carla to Ana `16000` cents in that order
- **AND** no transfer includes Beto

### Requirement: Official seed remains deterministic and idempotent

The official seed MUST remain fail-closed and idempotent. New tests MAY create isolated groups, outings, memberships, and join-code state, but they MUST not mutate the official seed as a shortcut. Any reset needed for an inconsistent historical fixture MUST remain a local reset and reseed.

(Previously: Seed idempotency covered the official group and source records without the explicit isolation requirement for new feature fixtures.)

#### Scenario: Isolated feature fixtures do not alter the official seed

- GIVEN tests for groups, outings, joins, or membership exit
- WHEN those tests create and mutate their fixtures
- THEN the official Samaipata source records and derived results remain unchanged

#### Scenario: Seed re-run is a no-op

- **WHEN** the seed runs twice without intervening mutations
- **THEN** the second run creates zero accounts, participants, and expenses
- **AND** exactly four official expenses and the same derived results remain

#### Scenario: Existing seeded source is inconsistent

- **WHEN** stable demo identities contain source data that does not match the canonical four-expense fixture
- **THEN** the seed fails explicitly without silently fabricating results or deleting unrelated data
- **AND** the delivery instructions provide the local reset, migration, and reseed path

## ADDED Requirements

### Requirement: Official preservation is a regression boundary

Acceptance coverage for this change MUST assert official Samaipata source count, descriptions, amounts, contributor/beneficiary relationships, exact zero sum, ordered settlement, session behavior, and invalidation-only WebSocket behavior while separately covering new multi-group and outing cases.

#### Scenario: Regression coverage protects official behavior

- WHEN the affected backend, API, web, contract, and invalidation checks run
- THEN they fail if the official fixture or its derived output changes
- AND new feature cases are evaluated in isolated fixtures
