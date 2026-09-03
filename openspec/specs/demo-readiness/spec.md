# Demo-Readiness Specification

## Purpose

Define the demo surface: an idempotent realistic seed that loads the Samaipata acceptance history and the minimum owner/member demo accounts, a reproducible under-three-minute protected walkthrough (login → record → balances → settlement → refresh → logout) that proves persistence, and automated acceptance evidence covering DA-01 through DA-05 plus auth and rename cases (DA-06, DA-07) with exact expected results.

## Requirements

### Requirement: Idempotent realistic demo seed with demo accounts

The system MUST provide a seed operation that loads the Samaipata history into a fresh environment: at least one owner account and one member account for the seeded group; participants Ana, Beto, Carla, and Diego in stable creation order; expenses of `96000` paid by Ana, `40000` paid by Beto, and `24000` paid by Carla, each split among all four participants; group settings with `settlementPolicy: owner_only`. Demo credentials MUST be development/demo-only, supplied through the seed/runbook and not production credentials. Running the seed MUST be idempotent and MUST produce exactly the DA-01/AO-01 expected results.

#### Scenario: AO-09 — fresh environment loads the seed

- GIVEN an empty PostgreSQL database and a restarted backend
- WHEN the seed is executed
- THEN the owner and member demo accounts and the three Samaipata expenses exist as specified
- AND an owner or member login succeeds with the seeded demo credentials
- AND balances are Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`
- AND settlement is Diego → Ana `40000`, Carla → Ana `16000` in that order

#### Scenario: Seed re-run is a no-op

- GIVEN a database already seeded once
- WHEN the seed is executed again
- THEN no duplicate accounts, participants, or expenses appear
- AND all derived results are unchanged

### Requirement: Under-three-minute demonstrable protected web flow

A fresh environment MUST let the presenter complete the core demonstration in under three minutes: open the web app, sign in with a seeded owner or member account, view participants, record one additional expense through the form, view balances and settlement, refresh the page, show identical derived results, and sign out (AO-09). A written demo script MUST document the exact steps and timing.

#### Scenario: Login → record → balance → settle → refresh → logout in time

- GIVEN the seeded web app and the demo script
- WHEN the presenter follows the scripted steps, ending with logout
- THEN the walkthrough completes in under three minutes
- AND the post-refresh balances and settlement match the pre-refresh values
- AND after logout, protected group data is no longer accessible with the logged-out session

### Requirement: DA-01..DA-05 acceptance evidence

The automated test suite MUST include acceptance cases named DA-01 through DA-05 with the exact expected behaviors: DA-01 Samaipata balances and transfers; DA-02 rounding with `10000` split three ways (`3334`/`3333`/`3333`) and an exact-zero sum; DA-03 exclusion with `30000` among three of four participants; DA-04 everyone-settled with an empty transfer list; DA-05 persistence across refresh. The suite MUST run the datasets through the API (not only pure functions) and MUST record pass/fail evidence for the demo handoff.

#### Scenario: DA cases pass end to end

- GIVEN the bootstrapped test runners
- WHEN the DA-01..DA-05 acceptance suite runs against the API and seed
- THEN each case asserts its exact expected balances, transfers, or persistence result
- AND all five pass with evidence captured in the handoff report

### Requirement: Auth and rename acceptance evidence

The automated test suite MUST include acceptance cases DA-06 (protected sessions and roles) and DA-07 (participant rename) with exact expected behaviors: DA-06 — seeded owner and member logins succeed, invalid credentials are rejected, protected reads/mutations without a valid session are rejected, logout invalidates the session, and role enforcement follows `owner_only`/`any_member`; DA-07 — a rename preserves the participant ID, all historical references, and all monetary results, while blank and normalized-name-conflict renames are rejected.

#### Scenario: DA-06 — auth and role cases pass end to end

- GIVEN the seeded environment and API
- WHEN the auth acceptance suite runs
- THEN owner login and member login each establish a session with the correct role
- AND invalid credentials, missing/expired/logged-out sessions, and an `owner_only` member policy change are rejected with the documented envelopes
- AND logout invalidates the session

#### Scenario: DA-07 — rename cases pass end to end

- GIVEN the seeded environment and API
- WHEN the rename acceptance suite runs
- THEN renaming Ana preserves her ID, expense references, and `+56000` balance
- AND a blank rename and a rename conflicting with an existing normalized name are rejected without state change
- AND renaming an archived participant changes only the display name

## Non-goals

- No demo data beyond the realistic Samaipata history, the minimum seeded accounts, and the small additional scripted expense; no analytics or metrics over demo runs.
- The three-minute constraint applies to the Must walkthrough; mobile read-mostly parity is shown separately if time permits.
