# Mobile Participant Lifecycle Specification

## Purpose

Allow authorized users to manage participant lifecycle through existing server operations while preserving IDs, history, authorization, and archived-participant rules.

## Requirements

### Requirement: Participant creation

The mobile client MUST provide an add-participant flow that submits a trimmed, non-empty name through the existing generated operation and treats server validation and uniqueness as authoritative.

#### Scenario: Valid participant is added

- GIVEN an authenticated user has permission to add a participant
- WHEN the user submits a non-empty trimmed name
- THEN the client sends the contract-shaped request through the repository boundary
- AND it shows the created participant only after a successful authoritative refresh

#### Scenario: Invalid or duplicate participant name

- GIVEN the server rejects the name as invalid or non-unique across active and archived participants
- WHEN the add request completes
- THEN the client shows an actionable field-level validation error
- AND it does not add an optimistic participant to displayed data

### Requirement: Participant rename preserves identity

The mobile client MUST provide a name-only rename flow that trims input, preserves the participant ID, and delegates normalized uniqueness and authorization to the server.

#### Scenario: Authorized rename succeeds

- GIVEN an authorized user edits an existing participant
- WHEN the user submits a valid trimmed name
- THEN the request identifies the existing participant
- AND after refresh the same participant ID, historical references, and monetary results remain intact

#### Scenario: Rename is unauthorized or conflicts

- GIVEN the server returns unauthorized, forbidden, or uniqueness/validation failure
- WHEN rename completes
- THEN the client presents the corresponding actionable error
- AND it leaves the displayed participant name unchanged until a successful refresh

### Requirement: Participant archive and reactivation

The mobile client MUST expose archive and reactivate actions supported by the existing API and MUST show server-authoritative lifecycle outcomes.

#### Scenario: Authorized participant is archived

- GIVEN an authorized user archives an active participant
- WHEN the server accepts the request
- THEN the client refreshes participants and affected history, balances, and settlement
- AND the participant is excluded from new-expense defaults

#### Scenario: Archived participant is reactivated

- GIVEN an archived participant can be reactivated under server rules
- WHEN an authorized user confirms reactivation
- THEN the client submits the existing operation
- AND after authoritative refresh the participant is available in active selections

#### Scenario: Lifecycle action is forbidden

- GIVEN the server returns 403 for archive or reactivate
- WHEN the action completes
- THEN the client shows a forbidden state with a recovery path
- AND it does not change local lifecycle state optimistically

### Requirement: Participant deletion respects historical references

The mobile client MUST offer destructive deletion only through confirmation and MUST preserve referenced participants when the server reports historical use.

#### Scenario: Never-used participant is deleted

- GIVEN the participant has no historical references and the user confirms deletion
- WHEN the server accepts deletion
- THEN the client removes it only after authoritative participant refresh
- AND it provides completion feedback

#### Scenario: Referenced participant cannot be physically deleted

- GIVEN the participant is referenced by existing domain history
- WHEN deletion is attempted or rejected by the server
- THEN the client explains that the participant is protected and remains available in history and balances
- AND it does not hide or locally remove the participant

### Requirement: Archived participant selection rules

New-expense participant selectors MUST default to active participants, while edit forms MUST retain referenced archived participants needed by the existing expense.

#### Scenario: New form excludes archived participants

- GIVEN active and archived participants exist
- WHEN a new expense form opens
- THEN only active participants are offered by default

#### Scenario: Edit form retains archived references

- GIVEN an existing expense references an archived participant
- WHEN its edit form opens
- THEN the referenced archived participant remains visible and selectable for that expense
- AND unrelated archived participants are not added as new defaults
