# Persistence Specification

## Purpose

Define PostgreSQL persistence through SQLAlchemy/Alembic: every source-of-truth record survives refresh and restart, balances and settlement are derived on read and never stored, the minimum account/session model supports protected sessions and server-derived roles without a general account-management product, participant rename persists as a name-only change that preserves all foreign keys, migrations are reversible, and corrupted persisted state produces an explicit error with a recovery path instead of silent breakage.

## Requirements

### Requirement: PostgreSQL persistence of source data

The system MUST persist groups, participants, expenses, contributions, and beneficiary memberships in PostgreSQL through SQLAlchemy models and Alembic migrations. Monetary columns MUST be integer cents. After a page refresh or service restart, the system MUST return the same participants (including renamed names), expenses, contributions, group settings, and derived balances and settlement as before (DA-05, CB-12).

#### Scenario: DA-05 — refresh persistence

- GIVEN participants (including a renamed participant) and expenses created through the UI
- WHEN the page is refreshed
- THEN the participants' current names, expenses, balances, and settlement match the pre-refresh state exactly

#### Scenario: Restart persistence

- GIVEN the seeded Samaipata history persisted
- WHEN the backend service restarts
- THEN the same source data and derived results are retrievable

### Requirement: Derived results never persisted

The system MUST NOT store balances, per-participant owed/paid totals, or settlement transfers as records. Every balance and settlement response MUST be recomputed from expense source data at read time; persisted state MUST contain only expense source truth.

#### Scenario: Source-only persistence

- GIVEN a group with expenses and derived balances
- WHEN the database is inspected
- THEN no balance or transfer table exists with independently stored values
- AND deleting a source expense changes the derived result on the next read

### Requirement: Minimum account and session persistence

The system MUST persist the minimum account/session model needed for protected sessions and server-derived roles: pre-seeded demo accounts, per-group membership that relates an account to a group and its owner relationship, and session records that can be validated and invalidated (login/logout/expiry). This model MUST be sufficient to derive `owner` and `member` roles and to reject unauthenticated, invalid, expired, or logged-out sessions; it MUST NOT grow into a general account-management product.

#### Scenario: Seeded owner and member accounts are persisted

- GIVEN an empty database
- WHEN migrations and the demo seed run
- THEN at least one owner account and one member account exist for the seeded group
- AND each account's group membership and role relationship are persisted

#### Scenario: Login persists a session and logout invalidates it

- GIVEN the seeded accounts
- WHEN a login succeeds
- THEN a session record is persisted and subsequent protected requests validate against it
- AND after logout the same session record is invalidated

### Requirement: Reversible migrations and idempotent seed

The system MUST ship Alembic migrations that are reversible (each upgrade has a documented downgrade), and the demo seed MUST be idempotent: running it twice MUST produce the same state without duplicate records. The seed MUST load the Samaipata group and history plus the minimum owner/member demo accounts.

#### Scenario: CB-16 — recovery from corrupted state

- GIVEN persisted data that fails integrity checks (e.g., a contribution referencing a missing expense or a violated invariant)
- WHEN the app reads or starts against that state
- THEN the user receives an explicit error message explaining the corruption
- AND a documented reset/recovery path (recreate database and re-run idempotent seed) restores a working state
- AND the UI does not silently break or show fabricated values

#### Scenario: Seed idempotency

- GIVEN an empty database
- WHEN the demo seed runs twice
- THEN the second run leaves the same participant, account, session, and expense records as the first, with no duplicates

### Requirement: Name uniqueness and rename persistence

The system MUST enforce trimmed, case-insensitive normalized-name uniqueness per group across active and archived participants, including on participant rename. A rename MUST persist only the participant's current name and normalized name, atomically, preserving the participant ID and every contribution/beneficiary foreign key; no historical monetary row or membership MUST be rewritten.

#### Scenario: Rename conflict is rejected by the boundary

- GIVEN a participant with a normalized name equal to another participant's (active or archived)
- WHEN a participant creation or rename is attempted with that name
- THEN the request is rejected with `duplicate_participant_name`
- AND no name change is written

#### Scenario: Rename preserves foreign keys

- GIVEN a participant referenced by expense contributions and beneficiary memberships
- WHEN the participant is renamed
- THEN only the participant's `name`/`normalized_name` change
- AND the participant ID and all referencing rows remain unchanged

### Requirement: Invariant enforcement at the boundary

The system MUST enforce the domain invariants (contributions sum to amount, at least one beneficiary, valid references, zero-balance invariant after every mutation) inside the persistence boundary so that invalid state can never be written, not merely reported by clients.

#### Scenario: Corruption cannot be written

- GIVEN an API request with contributions that do not sum to the expense amount
- WHEN it is processed
- THEN it is rejected with `contribution_mismatch`
- AND no row that would violate the invariant is written

## Non-goals

- No localStorage or client-side persistence; PostgreSQL is the only durable store (group data and the session/source model).
- No persisted balance/transfer ledgers independent of expense source data.
- No general account-management tables (public registration, password recovery, invitations, OAuth, external identity providers).
