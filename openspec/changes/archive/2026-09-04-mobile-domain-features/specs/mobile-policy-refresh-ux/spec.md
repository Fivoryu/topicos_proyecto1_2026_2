# Mobile Policy, Refresh, and UX Specification

## Purpose

Expose the supported group settlement-policy mutation and provide consistent authoritative refresh, invalidation, accessibility, and recovery behavior across the mobile domain.

## ADDED Requirements

### Requirement: Supported settlement-policy mutation

The mobile client MUST expose only the existing group policy operation and MUST adapt its affordance to server-derived role and policy state without making authorization decisions authoritative on the client.

#### Scenario: Authorized policy update succeeds

- GIVEN an authenticated user is authorized by the server to change the group's supported settlement policy
- WHEN the user submits a supported policy value
- THEN the client uses the existing generated operation
- AND after success it refreshes group/policy and permission-dependent presentation

#### Scenario: Policy update is forbidden or invalid

- GIVEN the server returns unauthorized, forbidden, or validation failure for a policy update
- WHEN the request completes
- THEN the client presents the corresponding actionable state
- AND it does not change the displayed policy optimistically

#### Scenario: Unsupported policy value is unavailable

- GIVEN a policy value is not part of the existing supported contract
- WHEN the policy controls are rendered
- THEN the value is not offered
- AND the client does not invent a fallback policy rule or operation

### Requirement: Authoritative post-mutation refresh

After a successful mutation, the mobile client MUST refresh every affected authoritative REST resource and MUST use a conservative refresh set when impact is uncertain.

#### Scenario: Participant mutation refreshes affected views

- GIVEN a participant add, rename, archive, reactivate, or delete succeeds
- WHEN post-mutation coordination runs
- THEN participants and affected expenses/history, balances, and settlement are refreshed
- AND the UI presents completion only from refreshed authoritative state

#### Scenario: Expense mutation refreshes affected views

- GIVEN an expense create, edit, or delete succeeds
- WHEN post-mutation coordination runs
- THEN expenses, balances, and settlement are refreshed
- AND participants are refreshed when names, status, or selector state may be affected

#### Scenario: Policy mutation refreshes dependent state

- GIVEN a group policy update succeeds
- WHEN post-mutation coordination runs
- THEN group/policy and permission-dependent state are refreshed
- AND stale policy or role affordances are not retained as authoritative data

### Requirement: WebSocket invalidation-only behavior

WebSocket frames MUST remain invalidation hints that trigger or request REST refresh; they MUST NOT be treated as domain data or used to calculate monetary outcomes.

#### Scenario: Invalidation frame arrives

- GIVEN a WebSocket invalidation frame is received
- WHEN the mobile listener handles it
- THEN it schedules or triggers the applicable REST reload
- AND it does not directly replace repository data with frame contents

### Requirement: Accessible states and interaction quality

Mobile domain screens MUST provide visible labels, inline validation, accessible semantic labels and reading order, safe-area-aware layouts, predictable back navigation, at least 48dp touch targets on Android, sufficient supported-theme contrast, and explicit loading, empty, archived, unauthorized, forbidden, all-settled, and recovery states.

#### Scenario: Form validation is announced near the field

- GIVEN a required form field is invalid after submission
- WHEN the screen renders the validation state
- THEN the field has a visible label and actionable error near it
- AND the error is available to assistive technology

#### Scenario: Loading and empty states are rendered

- GIVEN a domain resource is loading or has no records
- WHEN its screen renders
- THEN it shows a distinguishable loading or helpful empty state
- AND interactive controls expose an appropriate disabled or recovery state

#### Scenario: Recovery state offers retry

- GIVEN an authoritative read or refresh fails
- WHEN the failure is presented
- THEN the message explains the failure and provides a retry or return path
- AND no fabricated local result is displayed

#### Scenario: Destructive and navigation interactions are accessible

- GIVEN a user operates participant or expense actions on a mobile screen
- WHEN controls are rendered and used
- THEN destructive actions require confirmation, controls meet the touch-target requirement, semantic labels describe icon actions, safe areas are respected, and back navigation preserves a predictable route
