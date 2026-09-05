## Why

Cuentas Claras already implements a protected FastAPI/PostgreSQL backend, a React web client, and a current Flutter/Android client with independently governed mobile domain capabilities, but its final-delivery surface is inconsistent: required root guidance is missing, historical local-only assumptions can be mistaken for current truth, the seed does not preserve the four official Samaipata expenses as separate records, the walkthrough changes the official outcome, and the web presentation remains mostly English. This change closes those web-centered Grupo 2 Spec-Driven Development handoff gaps without redesigning or reimplementing the application or absorbing work owned by other active changes.

## What Changes

- Add root `AGENTS.md` guidance covering the delivered architecture, repository conventions, monetary invariants, generated-code boundaries, tests, and the mandatory specs-before-code workflow.
- Add a root delivery `README.md` with a reproducible PostgreSQL, migration, seed, backend, web, test, OpenSpec, and under-three-minute demo path; document demo login names and environment-provided passwords without exposing credentials.
- Reconcile living project context and delivery documentation with the implemented FastAPI, PostgreSQL, SQLAlchemy, Alembic, protected sessions/roles, React, current Flutter/Android capabilities, OpenAPI, and invalidation-only WebSocket architecture. Record that successful backend mutations already publish one shared, group-scoped `data_changed` signal after commit, preserve the independently governed `wire-mutation-websocket-invalidation` and `mobile-domain-features` decisions, and retain the instructor baseline and completed MVP artifacts as dated history instead of silently rewriting them.
- Establish canonical delivery-facing requirements despite the currently empty `openspec/specs/` baseline, reusing the historical `demo-readiness` capability path and adding narrowly scoped governance, operations, and web-presentation capabilities.
- Replace the three aggregated seeded expense records with exactly four stable, separately named official records: Cabaña `80000` paid by Ana, Entradas a El Fuerte `16000` paid by Ana, Cena `40000` paid by Beto, and Gasolina `24000` paid by Carla, with all four participants benefiting from every expense and Diego contributing none.
- Keep the seed idempotent and fail-closed while protecting the exact official balances Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`, zero-sum total, and ordered transfers Diego to Ana `40000` then Carla to Ana `16000`.
- Rewrite the primary under-three-minute walkthrough to inspect the four pre-seeded official expenses, balances, settlement, and refresh persistence directly; remove the additional `Bs. 100.00` expense from the main flow.
- Translate the main web experience and accessibility labels into natural Spanish, including session, role, participants, expenses, balances, state labels (`Le deben`, `Debe`, `Saldado`), and transfer rows rendered clearly as `Diego → Ana: Bs. 400,00`, without a visual redesign or client-side monetary computation.
- Correct only delivery-affecting setup and contract-generation inconsistencies discovered during inspection, including the misleading web API-base example and generator-version/documentation drift when verification confirms it. Do not broaden this into general refactoring.
- Update only tests coupled to the seed shape and Spanish presentation. Retain all existing mathematical, lifecycle, authorization, persistence, edge-case, OpenAPI, backend mutation-invalidation, WebSocket, and web API-base configuration coverage; the recent WebSocket and same-origin suites are unchanged regression gates rather than implementation targets.
- Do not hand-edit generated TypeScript/Dart OpenAPI clients or the exported contract. If a handwritten API schema change unexpectedly becomes necessary, use export/regeneration/drift workflows; otherwise leave the contract and generated trees unchanged.

## Capabilities

### New Capabilities

- `documentation-governance`: Defines current source-of-truth precedence, required AI context, preservation of SDD history, architecture consistency, and generated-code rules.
- `delivery-readiness`: Defines the root handoff README, executable setup/configuration instructions, bounded delivery-debt handling, and required verification evidence.
- `demo-readiness`: Reuses the established capability path to define the corrected four-expense official Samaipata seed and the direct under-three-minute demonstration.
- `web-presentation`: Defines the primarily Spanish delivery UI, natural monetary-state labels, and clear settlement notation while preserving server authority and existing interactions.

### Modified Capabilities

None. `openspec/specs/` currently has no canonical capability specs; `cuentas-claras-mvp`, `wire-mutation-websocket-invalidation`, and `mobile-domain-features` remain independently governed historical or active inputs rather than in-place baselines for this change to rewrite.

## Impact

- Documentation and SDD context: root `AGENTS.md`, root `README.md`, `openspec/project-context.md`, `openspec/config.yaml`, current operator docs, and explicit links to the preserved instructor baseline, completed MVP change, implemented WebSocket-invalidation change, and active mobile-domain change.
- Demo data and verification: `backend/scripts/seed_demo.py`, seed/recovery/acceptance fixtures and assertions that depend on the seeded expense count or IDs, and the Samaipata walkthrough.
- Web presentation and tests: handwritten React shell and feature panels, auth/session messages, HTML language metadata, and text-coupled Vitest assertions. Existing layout and feature behavior remain intact.
- Delivery configuration: `web/.env.example`, setup documentation, and OpenAPI generation documentation/configuration only where current commands or drift checks would otherwise mislead or fail. The existing `web/src/core/config.ts` resolver, Vite proxy, and their tests remain unchanged.
- No planned database migration, API shape change, new dependency, generated-client manual edit, account-management expansion, or general technical-debt refactor. Mobile implementation/acceptance remains owned by `mobile-domain-features`; backend invalidation publication remains owned by `wire-mutation-websocket-invalidation`; neither is modified, reverted, reclassified, or completed by this change.
