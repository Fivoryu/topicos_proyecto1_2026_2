# Participants Specification

## Purpose

Define the participant lifecycle: add and list participants with normalized-name uniqueness, name-only atomic rename (CC-04 confirmed), archive and reactivate referenced participants, allow physical deletion only for never-used participants, and keep referenced archived participants visible at zero balance while managing their visibility in current forms and views (CC-02 confirmed).

## Requirements

### Requirement: Add and list participants

The system MUST allow adding participants to the active group with a non-empty, trimmed name and MUST reject blank/whitespace-only names with error `invalid_participant_name` and duplicate names after normalization (trim whitespace and compare case-insensitively) with error `duplicate_participant_name`. The participant list MUST return active and archived participants with their status, in stable creation order.

#### Scenario: CB-08 — duplicate normalized name rejected

- GIVEN a group with participant `Ana`
- WHEN a participant named ` ana ` is added
- THEN the request is rejected with error `duplicate_participant_name`
- AND the participant list is unchanged

#### Scenario: Blank name rejected

- GIVEN a group
- WHEN a participant name of only whitespace is submitted
- THEN the request is rejected with error `invalid_participant_name`
- AND no participant is created

#### Scenario: List with status

- GIVEN a group with one active participant and one archived participant
- WHEN the participant list is read
- THEN both participants appear in creation order, each with an explicit `archived` status flag

### Requirement: Archive and reactivate

The system MUST archive a participant without deleting any expense reference; archived participants MUST remain available for historical queries and MUST be reactivatable. Reactivation MUST restore normal selection in expense forms.

#### Scenario: Archive keeps history intact

- GIVEN an expense referencing participants Ana and Beto
- WHEN Beto is archived and balances are computed
- THEN the expense remains valid and unchanged
- AND balances still include Beto's derived values

#### Scenario: Reactivation restores defaults

- GIVEN an archived participant
- WHEN the participant is reactivated
- THEN the participant is selectable and included in new-expense beneficiary defaults again

### Requirement: Protected physical deletion

The system MUST reject physical deletion of any participant ever referenced by an expense, returning an explicit dependency error, and MUST allow physical deletion only for a participant that has never been used by any expense.

#### Scenario: CB-09 — referenced participant cannot be deleted

- GIVEN a participant referenced by an expense
- WHEN a physical delete is attempted
- THEN the request is rejected with error `participant_in_use` and an explanatory message about the dependencies
- AND the participant still exists

#### Scenario: Never-used participant can be deleted

- GIVEN a participant with no expense contributions or beneficiary membership
- WHEN a physical delete is attempted
- THEN the deletion succeeds
- AND the participant no longer appears in the list

### Requirement: Archived visibility including zero-balance rows

The system MUST hide archived participants from the default beneficiary/contributor selections of new expense forms, MUST keep them visible in expense history, balances, and settlement whenever they are referenced by an expense, MUST keep them selectable when editing an existing expense that references them, and MUST NOT drop referenced archived participants from the balances view merely because their derived balance is zero.

> **Confirmed decision (CC-02):** Referenced archived participants remain visible in balances and history, including `Bs. 0.00`. They are excluded from new-expense defaults and retained in edit forms. Recorded in the reconciled proposal and Engram observation `2587` (`sdd/cuentas-claras-mvp/confirmation-gates`).

#### Scenario: CC-02 — archived participant with zero balance stays visible in balances

- GIVEN an archived participant whose derived balance is `0` but who is referenced by a historical expense
- WHEN the balances view is read
- THEN the participant is listed with `Bs. 0.00`, alongside active participants

#### Scenario: Hidden from new-expense defaults

- GIVEN a group with archived participant Carla
- WHEN a new expense form opens
- THEN Carla is not among the default-selected beneficiaries or contributor options
- AND a new expense can be created without referencing Carla

#### Scenario: Editable when referenced

- GIVEN an expense that references archived participant Carla
- WHEN the expense is edited
- THEN Carla remains selectable in that form so the expense stays valid

### Requirement: Participant rename (name-only, atomic)

The system MUST allow renaming a participant through a single name-only update: trim and normalize the new name, reject blank/whitespace-only names with error `invalid_participant_name` and normalized-name conflicts with any other participant in the group (including archived ones) with error `duplicate_participant_name`, and commit the rename atomically. A rename MUST preserve the participant ID and ALL historical references and monetary results: no expense contribution, beneficiary membership, derived balance, or settlement transfer MAY change as a result of a rename.

> **Confirmed decision (CC-04):** Participant rename is part of the MVP: name-only atomic update that preserves the participant ID and all historical references/monetary results, enforces trim + case-insensitive uniqueness, and has no merge, reassignment, or archive side effects. Recorded in the reconciled proposal and Engram observation `2587` (`sdd/cuentas-claras-mvp/confirmation-gates`).

#### Scenario: Rename preserves identity and monetary results

- GIVEN participant `Ana` (`id p1`) with historical expenses and balances `+56000`
- WHEN the participant is renamed to `Ana L.`
- THEN the participant with `id p1` now displays `Ana L.`
- AND the participant ID `p1`, all expense references, and the derived balance `+56000` are unchanged

#### Scenario: Rename with normalized-name conflict is rejected

- GIVEN a group with participants `Ana` and `Beto`
- WHEN `Beto` is renamed to ` ana `
- THEN the request is rejected with error `duplicate_participant_name`
- AND `Beto`'s name is unchanged

#### Scenario: Blank rename is rejected

- GIVEN participant `Ana`
- WHEN `Ana` is renamed to a whitespace-only name
- THEN the request is rejected with error `invalid_participant_name`
- AND the name is unchanged

#### Scenario: Rename of an archived participant is name-only

- GIVEN an archived participant referenced by an expense
- WHEN the participant is renamed to a valid, non-conflicting name
- THEN the rename succeeds and only the display name changes
- AND the archived status, expense references, and derived balances are unchanged

#### Scenario: Rename does not change history attribution

- GIVEN historical expense rows that reference participant `id p1`
- WHEN participant `p1` is renamed
- THEN every historical row still resolves to `id p1` and displays the current name
- AND no historical monetary row or membership is rewritten

## Non-goals

- No participant merging, identity replacement, reassignment between groups, or historical name snapshots/audit as separate product features.
- No user accounts or identity for participants; participants are group records, not login accounts (seeded accounts are separate; see auth requirement in the groups and api specifications).
