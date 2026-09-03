# Mobile Domain Shell Specification

## Purpose

Provide an authenticated Flutter shell that exposes the one active group's server-backed domain views without bypassing session protection or inventing monetary results.

## ADDED Requirements

### Requirement: Authenticated domain composition

The mobile application MUST compose group/policy, participants, expenses, balances, and settlement read capabilities only after the existing session has resolved to an authenticated user.

#### Scenario: Authenticated user enters the domain

- GIVEN the session is authenticated and identifies the active group
- WHEN the domain shell is built
- THEN all five domain areas are reachable through labeled, predictable navigation
- AND each area receives its existing repository/read-state dependencies

#### Scenario: Missing or expired session

- GIVEN the session is unauthenticated or expired
- WHEN a protected domain route is requested
- THEN the application MUST NOT expose group data
- AND it MUST route to the existing authentication boundary with an actionable session state

#### Scenario: Logout disposes protected state

- GIVEN the domain shell has loaded protected data
- WHEN the user logs out
- THEN protected feature state and subscriptions MUST be disposed or cleared
- AND returning to the shell MUST require a newly authenticated session

### Requirement: One active group navigation

The mobile shell MUST preserve the one-active-group model and MUST NOT provide group discovery, creation, or switching controls.

#### Scenario: Domain navigation remains group-scoped

- GIVEN an authenticated user has one active group
- WHEN the user navigates among domain areas
- THEN every read and mutation-capable feature remains scoped to that group
- AND no alternate group selector is presented

### Requirement: Server-derived settlement display

The settlement view MUST display settlement data and the explicit all-settled state exactly from the authoritative server response; it MUST NOT synthesize transfers, balances, residuals, payments, or settlement confirmations.

#### Scenario: Settlement has transfers

- GIVEN the server returns settlement entries
- WHEN the settlement view renders
- THEN it displays the returned entries and amounts using the existing money representation
- AND it offers no payment, transfer, or confirmation action

#### Scenario: Settlement is all settled

- GIVEN the server returns the explicit all-settled result
- WHEN the settlement view renders
- THEN it presents a clear all-settled state
- AND it does not infer additional transfers from balances or participant data

#### Scenario: Settlement response is unavailable

- GIVEN settlement loading or refresh fails
- WHEN the view renders the failure
- THEN it shows an accessible explanation and retry action
- AND it does not replace the missing result with client-calculated data
