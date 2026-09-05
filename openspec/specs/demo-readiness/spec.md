# demo-readiness Specification

## Purpose

Define the exact official Samaipata data, outcomes, and short protected walkthrough used as the final reproducible demonstration and acceptance baseline.

## Requirements

### Requirement: Official Samaipata seed contains four separate expenses

A fresh demo seed MUST create participants Ana, Beto, Carla, and Diego in stable order and exactly four official expense records: `Cabaña` for `80000` cents contributed by Ana; `Entradas a El Fuerte` for `16000` cents contributed by Ana; `Cena` for `40000` cents contributed by Beto; and `Gasolina` for `24000` cents contributed by Carla. All four participants MUST be beneficiaries of every expense, and Diego MUST contribute to none.

#### Scenario: Fresh seed has the official source records

- **WHEN** the demo seed runs against an empty migrated database
- **THEN** the four participants and four separately identifiable expenses exist with the specified descriptions, amounts, contributors, and all-participant beneficiary sets
- **AND** no aggregated `96000` Ana expense or additional `10000` walkthrough expense is part of the seeded official history

### Requirement: Seeded balances and settlement match the official result

The canonical seeded history MUST derive balances of Ana `+56000`, Beto `0`, Carla `-16000`, and Diego `-40000` cents, whose sum is exactly zero. Settlement MUST contain exactly two ordered transfers: Diego to Ana for `40000` cents, followed by Carla to Ana for `16000` cents; Beto MUST have no transfer.

#### Scenario: Official balances are derived from four records

- **WHEN** balances are requested for the freshly seeded Samaipata group
- **THEN** Ana is `+56000`, Beto is `0`, Carla is `-16000`, and Diego is `-40000` cents
- **AND** the four balances sum exactly to `0`

#### Scenario: Official settlement is derived

- **WHEN** settlement is requested for the freshly seeded Samaipata group
- **THEN** the transfers are Diego to Ana `40000` and Carla to Ana `16000` cents in that order
- **AND** no transfer includes Beto

### Requirement: Official seed remains deterministic and idempotent

The four official expenses, participants, group, and demo accounts MUST use stable identities and the seed MUST remain fail-closed. Re-running the seed on its unchanged canonical state MUST create no duplicate records, change no password hashes, and preserve the exact official balances and settlement. Recovery from the superseded three-expense demo fixture MUST be documented as a local demo reset and reseed rather than an unrequested production data migration.

#### Scenario: Seed re-run is a no-op

- **WHEN** the seed runs twice without intervening mutations
- **THEN** the second run creates zero accounts, participants, and expenses
- **AND** exactly four official expenses and the same derived results remain

#### Scenario: Existing seeded source is inconsistent

- **WHEN** stable demo identities contain source data that does not match the canonical four-expense fixture
- **THEN** the seed fails explicitly without silently fabricating results or deleting unrelated data
- **AND** the delivery instructions provide the local reset, migration, and reseed path

### Requirement: Under-three-minute demo presents the official state directly

The primary demo script MUST fit within three minutes and guide the presenter through sign-in, the four participants, the four official expenses, official balances, official settlement, and a page refresh that preserves the same source and derived data. The main path MUST NOT add the former `Bs. 100,00` rehearsal expense or otherwise mutate the official result.

#### Scenario: Presenter completes the official walkthrough

- **WHEN** the presenter follows the primary script against a freshly seeded environment
- **THEN** the UI shows Ana, Beto, Carla, and Diego; the four official expenses; balances `+56000`, `0`, `-16000`, and `-40000`; and transfers `40000` and `16000` cents
- **AND** refresh retains the authenticated state, records, balances, and settlement
- **AND** the walkthrough completes in under three minutes without creating another expense

### Requirement: Automated evidence protects the official fixture

Automated seed and acceptance coverage MUST assert all four separate expense shapes, idempotent rerun behavior, exact balances, exact zero sum, and exact ordered transfers while retaining the existing mathematical and edge-case suites.

#### Scenario: Official fixture regression test runs

- **WHEN** the affected backend test suites execute
- **THEN** they fail if any official description, amount, contributor, beneficiary set, participant balance, transfer amount, transfer order, or seeded expense count differs
- **AND** existing residual, exclusion, settled, persistence, authorization, rename, and money tests remain passing
