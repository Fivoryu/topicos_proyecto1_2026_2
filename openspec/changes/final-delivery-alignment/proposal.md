## Why

Cuentas Claras already implements the protected FastAPI/PostgreSQL/React product, but its delivery surface is inconsistent: required root guidance is missing, historical local-only assumptions can be mistaken for current truth, the seed does not preserve the four official Samaipata expenses as separate records, the walkthrough changes the official outcome, and the web presentation remains mostly English. This change closes those gaps for the Grupo 2 Spec-Driven Development handoff without redesigning or reimplementing the application.

## What Changes

- Add root `AGENTS.md` guidance covering the delivered architecture, repository conventions, monetary invariants, generated-code boundaries, tests, and the mandatory specs-before-code workflow.
- Add a root delivery `README.md` with a reproducible PostgreSQL, migration, seed, backend, web, test, OpenSpec, and under-three-minute demo path; document demo login names and environment-provided passwords without exposing credentials.
- Reconcile living project context and delivery documentation with the implemented FastAPI, PostgreSQL, SQLAlchemy, Alembic, protected sessions/roles, React, OpenAPI, and invalidation-only WebSocket architecture. Preserve the instructor baseline and completed MVP artifacts as dated decision history, with explicit precedence and supersession instead of silent rewriting.
- Establish canonical delivery-facing requirements despite the currently empty `openspec/specs/` baseline, reusing the historical `demo-readiness` capability path and adding narrowly scoped governance, operations, and web-presentation capabilities.
- Replace the three aggregated seeded expense records with exactly four stable, separately named official records: Cabaña `80000` paid by Ana, Entradas a El Fuerte `16000` paid by Ana, Cena `40000` paid by Beto, and Gasolina `24000` paid by Carla, with all four participants benefiting from every expense and Diego contributing none.
- Keep the seed idempotent and fail-closed while protecting the exact official balances Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`, zero-sum total, and ordered transfers Diego to Ana `40000` then Carla to Ana `16000`.
- Rewrite the primary under-three-minute walkthrough to inspect the four pre-seeded official expenses, balances, settlement, and refresh persistence directly; remove the additional `Bs. 100.00` expense from the main flow.
- Translate the main web experience and accessibility labels into natural Spanish, including session, role, participants, expenses, balances, state labels (`Le deben`, `Debe`, `Saldado`), and transfer rows rendered clearly as `Diego → Ana: Bs. 400,00`, without a visual redesign or client-side monetary computation.
- Correct only delivery-affecting setup and contract-generation inconsistencies discovered during inspection, including the misleading web API-base example and generator-version/documentation drift when verification confirms it. Do not broaden this into general refactoring.
- Update only tests coupled to the seed shape, official walkthrough, Spanish presentation, setup/configuration, and delivery documentation. Retain all existing mathematical, lifecycle, authorization, persistence, edge-case, and OpenAPI regression coverage.
- Do not hand-edit generated TypeScript/Dart OpenAPI clients or the exported contract. If a handwritten API schema change unexpectedly becomes necessary, use export/regeneration/drift workflows; otherwise leave the contract and generated trees unchanged.

## Capabilities

### New Capabilities

- `documentation-governance`: Defines current source-of-truth precedence, required AI context, preservation of SDD history, architecture consistency, and generated-code rules.
- `delivery-readiness`: Defines the root handoff README, executable setup/configuration instructions, bounded delivery-debt handling, and required verification evidence.
- `demo-readiness`: Reuses the established capability path to define the corrected four-expense official Samaipata seed and the direct under-three-minute demonstration.
- `web-presentation`: Defines the primarily Spanish delivery UI, natural monetary-state labels, and clear settlement notation while preserving server authority and existing interactions.

### Modified Capabilities

None. `openspec/specs/` currently has no canonical capability specs; the completed `cuentas-claras-mvp` artifacts remain historical inputs rather than an in-place baseline to rewrite.

## Impact

- Documentation and SDD context: root `AGENTS.md`, root `README.md`, `openspec/project-context.md`, `openspec/config.yaml`, current operator docs, and explicit links to the preserved instructor baseline and completed MVP change.
- Demo data and verification: `backend/scripts/seed_demo.py`, seed/recovery/acceptance fixtures and assertions that depend on the seeded expense count or IDs, and the Samaipata walkthrough.
- Web presentation and tests: handwritten React shell and feature panels, auth/session messages, HTML language metadata, and text-coupled Vitest assertions. Existing layout and feature behavior remain intact.
- Delivery configuration: environment examples and OpenAPI generation documentation/configuration only where current commands or drift checks would otherwise mislead or fail.
- No planned database migration, API shape change, new dependency, generated-client manual edit, mobile Stretch implementation, account-management expansion, or general technical-debt refactor.
