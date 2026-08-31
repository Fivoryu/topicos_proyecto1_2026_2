# Expenses Specification

## Purpose

Define the expense lifecycle inside protected group sessions: create, edit, and delete expenses with full validation, multiple contributors covering the full amount, equal beneficiary split with the confirmed deterministic residual rule (CC-01), all active participants selected by default with referenced archived participants retained on edit (CC-02), and all-or-nothing atomicity so rejected mutations leave the previous state untouched. Session and group-membership protection for every expense operation is defined in the groups and api specifications.

## Requirements

### Requirement: Expense creation validation

The system MUST create an expense only when: the description is non-empty; `amount_cents` is greater than zero; there is at least one contributor; there is at least one beneficiary; every contributor and beneficiary references an existing participant of the group; and the sum of contribution amounts equals `amount_cents` exactly. Any violation MUST reject the request with an explicit error and MUST NOT persist any partial data.

#### Scenario: CB-01 — no participants

- GIVEN a group with zero participants
- WHEN an expense creation is attempted
- THEN the request is rejected with error `no_participants` and a message directing the user to add participants first

#### Scenario: CB-06 — no beneficiaries

- GIVEN an expense form with a valid amount and contributor but zero selected beneficiaries
- WHEN creation is attempted
- THEN the request is rejected with error `no_beneficiaries`

#### Scenario: CB-07 — invalid reference

- GIVEN an expense form referencing a participant id that does not exist in the group
- WHEN creation is attempted
- THEN the request is rejected with error `invalid_participant_reference`

#### Scenario: AO-03 — contribution mismatch

- GIVEN an expense of `10000` cents with contributions Ana `6000` and Beto `3000`
- WHEN creation is attempted
- THEN the request is rejected with error `contribution_mismatch`
- AND no expense or contribution row is persisted

### Requirement: Multiple contributors

The system MUST support one or more contributors per expense, each with an explicit integer-cent contribution amount, and MUST require their sum to equal the expense total exactly. Each contribution MUST reference a valid group participant and MUST be greater than zero.

#### Scenario: Valid multi-contributor expense

- GIVEN an expense of `10000` cents with Ana `6000` and Beto `4000` as contributors
- WHEN creation is attempted
- THEN it succeeds
- AND the expense is persisted with both contributions summing to `10000`

### Requirement: Default beneficiary selection

The system MUST preselect all active participants as beneficiaries in a new expense form; the user MUST be able to exclude any of them. Referenced archived participants MUST remain selectable in an edit form for an expense that references them, so that editing never invalidates the expense (CC-02). Archived participants MUST NOT appear among the defaults (see participants spec, confirmed CC-02). At least one beneficiary MUST remain selected for submission to be valid.

#### Scenario: Excluding a participant

- GIVEN a group with Ana, Beto, Carla, and Diego and a new expense form
- WHEN Diego is excluded from the beneficiaries and the expense of `30000` is submitted
- THEN the expense is persisted with exactly three beneficiaries (DA-03)

### Requirement: Edit expense with atomic recalculation

The system MUST allow editing an existing expense's description, amount, contributors, and beneficiaries. After a successful edit, all balances and settlement derived from the changed expense MUST reflect the new values, and every derived result MUST be recomputed from source data. An invalid edit MUST be rejected with the same validation errors as creation, leaving the expense and all derived results exactly as before.

#### Scenario: CB-10 — changing the payer recalculates everything

- GIVEN an expense of `30000` originally paid by Ana with Ana, Beto, Carla as beneficiaries
- WHEN the edit changes the payer to Beto with the same beneficiaries
- THEN balances show Beto `+20000`-effect and Ana neutral for this expense
- AND balances and settlement reflect the edit immediately

#### Scenario: AO-05 — invalid edit leaves state unchanged

- GIVEN an existing valid expense
- WHEN an edit sets the amount to `0`
- THEN the edit is rejected with error `invalid_amount`
- AND the expense, balances, and settlement are unchanged

### Requirement: Delete expense with full effect withdrawal

The system MUST delete an expense and fully withdraw its monetary effect: every contribution and beneficiary row of the deleted expense MUST be removed, and balances and settlement MUST be recomputed as if the expense never existed. After deletion, the data MUST be internally valid.

#### Scenario: CB-11 — deletion removes the effect

- GIVEN a group whose only expense is a `30000`-cent expense paid by Ana among three beneficiaries
- WHEN the expense is deleted
- THEN every participant balance is `0`
- AND settlement returns the everyone-settled state with no transfers

### Requirement: Expense listing

The system MUST list expenses with description, `amount_cents`, contributors with amounts, beneficiaries, and timestamps, in stable creation order, including expenses that reference archived participants.

#### Scenario: History includes archived references

- GIVEN an expense referencing an archived participant
- WHEN the expense list is read
- THEN the expense appears with the archived participant's name and its archived status visible

#### Scenario: Renamed participant history

- GIVEN an expense whose contributor or beneficiary was renamed after the expense was recorded
- WHEN the expense list is read
- THEN the expense resolves the same participant ID and displays the current name with its archived status
- AND the recorded contribution amounts and split shares are unchanged

## Non-goals

- No percentage, weighted, custom-amount, or other unequal split modes.
- No receipt OCR, smart categories, or notifications on expenses.
- No mobile write parity in the first slice (mobile expense writes are approved Stretch only).
