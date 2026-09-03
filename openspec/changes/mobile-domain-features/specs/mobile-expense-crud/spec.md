# Mobile Expense CRUD Specification

## Purpose

Provide mobile create, edit, and delete flows for the existing expense contract while keeping monetary validation and outcomes authoritative on the server.

## ADDED Requirements

### Requirement: Expense forms submit contract-shaped data

The mobile client MUST collect description, amount representation, contributors, beneficiaries, and required references, and MUST submit them through non-generated request mappers and the existing generated API operations.

#### Scenario: Valid expense is created

- GIVEN an authenticated user has a valid group-scoped expense form
- WHEN the user submits a non-empty description, positive amount, selected contributors and beneficiaries, and valid references
- THEN the repository sends the contract-shaped request
- AND displayed domain data changes only after successful server response and authoritative refresh

#### Scenario: Invalid expense form is rejected locally

- GIVEN the form has an empty description, non-positive amount representation, no contributor, no beneficiary, or malformed required input
- WHEN the user submits
- THEN the client identifies the relevant field or action error
- AND it does not send an invalid request or mutate displayed data

#### Scenario: Server rejects monetary consistency

- GIVEN the submitted contributions do not satisfy the server's monetary contract
- WHEN the server rejects the request
- THEN the client displays the server validation outcome
- AND it does not calculate a correction, split, balance, residual, or settlement locally

### Requirement: Expense edit preserves server authority and archived references

The mobile client MUST allow editing existing expenses through the existing operation and MUST retain referenced archived participants in the edit form.

#### Scenario: Existing expense with archived reference is edited

- GIVEN an existing expense references an archived participant
- WHEN the user edits another field or submits valid changes
- THEN the archived referenced participant remains represented in the request as required by the contract
- AND the resulting expense is displayed only from the server after refresh

#### Scenario: Expense edit is forbidden or unauthorized

- GIVEN the server returns 401 or 403 for an edit
- WHEN the edit request completes
- THEN the client shows the appropriate session or forbidden state with recovery guidance
- AND it leaves the displayed expense unchanged

### Requirement: Expense deletion is explicit and destructive

The mobile client MUST require a clear confirmation before sending an expense deletion request and MUST show progress and outcome feedback.

#### Scenario: Confirmed expense deletion succeeds

- GIVEN the user selects delete for an expense
- WHEN the user confirms the destructive action and the server accepts it
- THEN the client refreshes expenses, balances, and settlement before presenting the resulting state
- AND it provides accessible success feedback

#### Scenario: Expense deletion is cancelled or fails

- GIVEN the user cancels deletion, or the server returns validation, authorization, or recovery failure
- WHEN the deletion flow completes
- THEN no deletion request is sent for cancellation, or the error is shown with retry/recovery for failure
- AND the expense remains visible until authoritative data says otherwise

### Requirement: Mutation progress and error states

Create, edit, and delete controls MUST expose loading/disabled states during asynchronous work and MUST map field, action, unauthorized, forbidden, and refresh failures to accessible recovery guidance.

#### Scenario: Duplicate submission is prevented

- GIVEN an expense mutation is in progress
- WHEN the user taps the submit or delete control again
- THEN the control is disabled or otherwise prevents duplicate submission
- AND visible progress remains available

#### Scenario: Mutation succeeds but refresh fails

- GIVEN the server accepts an expense mutation
- WHEN one or more required authoritative refreshes fail
- THEN the client shows a recoverable refresh-failure state
- AND it does not display locally inferred balances, settlement, or residuals
