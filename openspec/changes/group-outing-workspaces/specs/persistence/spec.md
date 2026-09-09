# Delta for Persistence

## ADDED Requirements

### Requirement: Durable outing and membership source records

PostgreSQL MUST persist groups, account memberships, outings, account-to-participant links, join-code lifecycle state, and nullable expense-to-outing associations as source data. Every new migration MUST be reversible, preserve existing source history, and enforce group ownership and referential integrity at the persistence boundary.

#### Scenario: New group starts empty

- GIVEN an account creates a group
- WHEN the transaction commits
- THEN the group has one owner membership and no outing, participant, or expense rows

#### Scenario: Cross-group foreign key cannot be persisted

- GIVEN an expense in `g1` and an outing in `g2`
- WHEN persistence receives the association
- THEN the transaction is rejected
- AND no expense or partial association is written

### Requirement: One current hashed reusable join code per group

Persistence MUST support at most one current join-code generation per group, storing only a non-reversible token representation or hash. Revocation and regeneration MUST make the previous representation unusable. Token plaintext MUST NOT be stored in durable logs or unrelated records.

#### Scenario: Regeneration invalidates stored code state

- GIVEN a current code generation for `g1`
- WHEN regeneration commits
- THEN the prior generation is marked unusable or replaced
- AND consuming its token cannot create membership

#### Scenario: Repeated consume is safe for membership uniqueness

- GIVEN an account already has active membership in `g1`
- WHEN the account consumes the current code again
- THEN the uniqueness constraint rejects a duplicate membership
- AND no participant-link or other partial row is created

### Requirement: Group-scoped account-participant links

Persistence MUST store the relationship between an account and participant separately from either identity and enforce group-scoped uniqueness and foreign-key integrity. Ending membership MUST preserve participants and all historical expense references; link removal or inactivity MUST not rewrite monetary source rows.

#### Scenario: Link preserves independent identities

- GIVEN account `a1` is linked to participant `p1` in `g1`
- WHEN the participant is renamed or the account leaves
- THEN `a1` and `p1` retain distinct identities
- AND expense contributions and beneficiaries still reference `p1`

#### Scenario: Link to another group is rejected

- GIVEN account membership in `g1` and participant `p2` in `g2`
- WHEN a link row for `a1` and `p2` is attempted
- THEN the persistence boundary rejects it
- AND no link is stored

### Requirement: Outing lifecycle persistence preserves history

An outing MUST carry a stable group association and lifecycle state sufficient to distinguish active from archived. Deletion MUST be permitted only when no expenses reference the outing. Archived outings and their expenses MUST remain readable. Optional date fields, if implemented, are informational and MUST NOT add scheduling semantics.

#### Scenario: Non-empty outing cannot be deleted

- GIVEN an outing referenced by an expense
- WHEN deletion is attempted
- THEN referential integrity or domain validation rejects it
- AND the outing and expense remain available

#### Scenario: Archived source remains readable

- GIVEN an archived outing with associated expenses
- WHEN the database is read through authorized services
- THEN the outing and expense history are returned
- AND new associated expense source rows are not accepted

### Requirement: Nullable outing source and derived calculations

Every expense MUST remain owned by one group and MAY have `outing_id = null` for a general expense or a non-null outing reference within that same group. Balances and settlement MUST be derived from source expenses at read time: group calculations include null and non-null expenses, while outing calculations include only matching non-null references. No derived result is persisted.

#### Scenario: Group derivation includes both scopes

- GIVEN one general expense and one expense linked to an outing in `g1`
- WHEN group balances or settlement are derived
- THEN both source expenses contribute exactly once

#### Scenario: Outing derivation excludes general expenses

- GIVEN a general expense and an expense linked to outing `o1`
- WHEN `o1` balances or settlement are derived
- THEN only the expense linked to `o1` contributes
- AND the general expense is not implicitly allocated or repeated

## MODIFIED Requirements

### Requirement: PostgreSQL persistence of source data

The system MUST persist groups, memberships, participants, outings, expenses, contributions, beneficiary memberships, account-participant links, join-code state, and group settings in PostgreSQL through SQLAlchemy models and reversible Alembic migrations. Monetary columns MUST remain integer cents. Refresh and restart MUST reproduce the same authorized source data and server-derived group or outing results.

(Previously: Persistence covered one seeded group, participants, expenses, contributions, beneficiary memberships, settings, and sessions but not multi-group, outing, membership-link, join-code, or nullable outing source data.)

#### Scenario: Refresh preserves selected workspace source state

- GIVEN authorized groups, outings, links, and expenses persisted
- WHEN the web client refreshes
- THEN the same source records and scoped derived results are returned

#### Scenario: DA-05 — refresh persistence

- GIVEN participants (including a renamed participant) and expenses created through the UI
- WHEN the page is refreshed
- THEN the participants' current names, expenses, balances, and settlement match the pre-refresh state exactly

#### Scenario: Restart persistence

- GIVEN the seeded Samaipata history persisted
- WHEN the backend service restarts
- THEN the same source data and derived results are retrievable

### Requirement: Minimum account and session persistence

The minimum account/session model MUST support multiple active group memberships, server-derived owner/member roles, authenticated join consumption, member removal, member leave, and final-owner protection while remaining outside general account management. Sessions MUST be validated before every protected group operation.

(Previously: The model supported seeded accounts and one group's membership/roles without group discovery or authenticated join.)

#### Scenario: Removed member cannot read after membership ends

- GIVEN an account whose membership in `g1` has been ended
- WHEN its existing session requests `g1`
- THEN the request is rejected
- AND participant, outing, expense, balance, and settlement data are not returned

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

## REMOVED Requirements

### Requirement: No general account-management tables as a prohibition on links

(Reason: This delta adds only the narrow account-to-participant link needed after an authenticated group join; it does not add registration, recovery, OAuth, or a general directory.)
(Migration: Preserve the existing account/session model and add only group-scoped membership/link records.)
