# delivery-readiness Specification

## Purpose

Define the reproducible handoff surface that lets an instructor or team member install, run, seed, demonstrate, and verify the delivered project without repository archaeology.

## Requirements

### Requirement: Root delivery README is self-contained

The repository MUST provide a root `README.md` for “Grupo 2 - Spec-Driven Development” that states the project purpose, delivered functionality, real architecture and stack, repository structure, prerequisites, environment variables, installation steps, PostgreSQL startup, Alembic migrations, Samaipata seed, backend startup, web startup, non-secret demo account names and roles, test/build commands, OpenSpec location, `AGENTS.md` location, and a short path to the official demo. It MUST accurately summarize and link the independently governed `wire-mutation-websocket-invalidation` and `mobile-domain-features` changes without making their implementation or acceptance part of final alignment.

#### Scenario: Fresh reviewer runs the project

- **WHEN** a reviewer follows the root README from a fresh checkout with supported prerequisites and locally supplied demo passwords
- **THEN** PostgreSQL starts, migrations apply, the demo seed succeeds, the backend starts, and the web app can access the protected seeded group
- **AND** the reviewer does not need to inspect source files to discover required commands

### Requirement: Setup guidance is safe and internally consistent

Tracked environment examples and setup documentation MUST use compatible origins and paths for browser cookie transport and generated API routes, MUST distinguish destructive database reset commands, and MUST never contain usable secrets. The environment/documentation correction MUST preserve the existing `resolveApiBaseUrl` behavior, Vite proxy, direct-development and production URL semantics, and their tests. Demo passwords MUST be supplied through local environment configuration, while only non-secret account names and roles are documented.

#### Scenario: Web follows the documented API base

- **WHEN** a reviewer configures and starts the web client exactly as documented
- **THEN** generated `/api/v1` operations are not given a duplicated API prefix
- **AND** same-origin session cookies and CSRF transport remain functional
- **AND** the existing API-base resolver and proxy tests pass without modification

#### Scenario: Demo credentials remain private

- **WHEN** setup and demo instructions are reviewed or captured
- **THEN** they expose the `demo.owner` and `demo.member` login names and roles but no password or password hash
- **AND** they direct the reviewer to provide local password values out of band

### Requirement: Delivery verification has an explicit gate

The handoff MUST define commands that verify the affected backend tests, complete backend suite, backend lint, web tests, web type checking, web production build, and backend startup against a migrated database. Existing backend mutation-invalidation and web API-base/WebSocket tests MUST remain unchanged regression gates. Contract drift MUST be checked; generated clients MUST remain untouched when the aligned pinned workflow already reproduces them, and any required regeneration MUST use that workflow rather than manual edits. The official Samaipata acceptance test MUST assert integer-cent values and exact zero-sum behavior.

#### Scenario: Handoff gate passes

- **WHEN** the documented delivery checks run in their stated working directories
- **THEN** the relevant test suites and web build pass, the backend starts successfully, and the seeded protected flow is available
- **AND** the OpenAPI snapshot and generated clients remain synchronized

### Requirement: Delivery debt stays bounded to demonstrated risk

Final-alignment work MUST include an observed issue only when it prevents setup, can break the official demo, fails required tests or builds, contradicts final specifications, or is necessary for accurate handoff. Generated TODOs, broad refactors, unrelated warnings, and work governed by another OpenSpec change, including mobile implementation/acceptance and backend mutation-invalidation publication, MUST remain outside this change.

#### Scenario: Independently governed or unrelated work is encountered

- **WHEN** implementation encounters work owned by another OpenSpec change, or a warning or TODO that does not affect the final-delivery gate
- **THEN** that work remains under its owning scope and MAY be linked for current status but is not implemented, reclassified, accepted, or reverted by final alignment
