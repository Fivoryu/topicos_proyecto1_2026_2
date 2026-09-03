## Purpose

Define the authoritative project context and maintenance rules so contributors and AI agents can distinguish the delivered architecture from preserved Spec-Driven Development history.

## ADDED Requirements

### Requirement: Root AI context is mandatory
The repository MUST provide a root `AGENTS.md` that documents the current architecture, repository structure, project conventions, monetary invariants, Spec-Driven Development workflow, test and build commands, security expectations, generated-code boundaries, and ownership boundaries among active changes. It MUST state that any change in accepted understanding or behavior updates the relevant specs before product code, and MUST direct contributors to preserve independently governed mobile and WebSocket work.

#### Scenario: Contributor finds actionable context at the root
- **WHEN** a contributor or AI agent starts work from the repository root
- **THEN** `AGENTS.md` identifies the applicable architecture, invariants, workflow, and verification commands without requiring reconstruction from historical artifacts
- **AND** it directs behavior-changing work to update specs before implementation

### Requirement: Current source-of-truth precedence is explicit
Living project documentation MUST identify the implemented protected architecture as the current baseline: FastAPI is the authorization and monetary authority; PostgreSQL stores source records through SQLAlchemy and Alembic; React is the primary final-delivery web/demo client; Flutter/Android is a current client whose implementation and acceptance are independently governed by `mobile-domain-features`; authentication uses persisted sessions and server-derived roles; and OpenAPI defines client contracts. Successful backend group mutations MUST remain connected to the shared broadcaster so that exactly one group-scoped `data_changed` signal is published after commit, and clients MUST continue treating WebSocket events only as hints to invalidate/refetch authoritative REST data. Documents containing superseded local-only, no-backend, no-auth, missing-invalidation, or absent-mobile-domain assumptions MUST be labeled as historical or explicitly superseded rather than presented as current guidance.

#### Scenario: Historical assumptions conflict with delivered behavior
- **WHEN** a reader encounters an earlier statement that prescribes `localStorage`, no backend, or authentication outside scope
- **THEN** current documentation makes clear that the delivered server-backed architecture takes precedence
- **AND** the historical decision remains traceable as a point-in-time artifact

### Requirement: SDD history is preserved without becoming current guidance
The instructor baseline and artifacts for `cuentas-claras-mvp`, `wire-mutation-websocket-invalidation`, and `mobile-domain-features` MUST remain available under their owning changes. Reconciliation MUST use dated status, supersession notes, or a source map instead of silently deleting or retroactively rewriting material decisions; MUST distinguish landed WebSocket publication from its verification-evidence blocker; MUST recognize implemented mobile domain slices and their independently owned remaining ledger; and MUST identify which current specs govern final-delivery, mobile, and WebSocket acceptance.

#### Scenario: Reviewer follows the decision evolution
- **WHEN** a reviewer traces the project from the instructor baseline through exploration, checkpoint decisions, MVP implementation, WebSocket mutation wiring, mobile domain delivery, and final alignment
- **THEN** the repository shows which initial decisions changed, what each independent change implemented or still owns, why the current baseline supersedes earlier assumptions, and where each scope's acceptance requirements live

### Requirement: Generated artifacts are changed only through their source workflow
Project guidance MUST prohibit manual edits to generated TypeScript and Dart OpenAPI client trees and MUST treat generated TODO markers as generator output rather than pending product scope. API contract changes MUST begin in handwritten backend routes or schemas, then export the OpenAPI snapshot, regenerate affected clients, and pass contract-drift checks.

#### Scenario: A generated client appears to need a change
- **WHEN** a contributor identifies a required client contract adjustment or a TODO inside generated output
- **THEN** guidance directs contract adjustments to handwritten API sources and regeneration
- **AND** the generated file or TODO is not manually edited or automatically promoted into delivery scope
