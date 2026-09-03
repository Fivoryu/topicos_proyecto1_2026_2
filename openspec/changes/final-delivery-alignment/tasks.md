## 1. Establish Current Project Guidance

- [ ] 1.1 Update `openspec/project-context.md` and `openspec/config.yaml` with the current source-of-truth precedence, delivered protected architecture, current verification commands, and specs-before-code rule; verify they no longer present local-only/no-backend/no-auth assumptions as current.
- [ ] 1.2 Add a concise SDD evolution/status map under `docs/` that links the preserved instructor baseline, exploration/checkpoint decisions, completed MVP artifacts, this final-alignment change, and eventual canonical specs; verify `docs/requerimiento-docente.md` and `openspec/changes/cuentas-claras-mvp/` have no content edits.
- [ ] 1.3 Create root `AGENTS.md` covering architecture, repository structure, coding and monetary invariants, authentication/role authority, SDD workflow, test/build commands, secrets, migration rules, and generated OpenAPI boundaries; verify every documentation-governance requirement is discoverable from the repository root.

## 2. Correct the Official Samaipata Fixture

- [ ] 2.1 Extend `backend/tests/integration/persistence/test_seed.py` and DA-01 acceptance coverage with the four exact expense descriptions, amounts, explicit contributors, all-four beneficiary sets, expense count, balances, zero sum, and ordered transfers; run the focused tests and record the expected RED failure against the current three-expense seed.
- [ ] 2.2 Refactor `backend/scripts/seed_demo.py` to use explicit payer indices, retain stable IDs `...0021` through `...0023`, add stable ID `...0024`, create the four official records, and validate their full shape plus exact derived outcomes; verify the focused seed and DA-01 tests pass without changing domain balance or settlement code.
- [ ] 2.3 Update seed-dependent recovery and acceptance cleanup/count assertions, including DA-02 through DA-04 fixtures, for four stable expenses; run `python -m pytest backend/tests/integration/persistence/test_seed.py backend/tests/integration/api/test_recovery.py backend/tests/acceptance -q` and verify idempotency, reset recovery, residual, exclusion, settled, persistence, auth, and rename cases pass.

## 3. Localize the Web Delivery Surface

- [ ] 3.1 Update formatter, balance, and settlement tests to require Spanish separators, signed balance output, `Le deben`/`Debe`/`Saldado`, Spanish empty states, and exact official rows `Diego → Ana: Bs. 400,00` and `Carla → Ana: Bs. 160,00`; run the focused Vitest files and record the expected RED failures.
- [ ] 3.2 Implement integer-only Spanish amount formatting plus signed-balance formatting, translate the balance and settlement panels, and render direct arrow transfers in server order; verify `web/tests/core/core.test.ts`, `web/tests/features/balances/balances.test.tsx`, and `web/tests/features/settlement/settlement.test.tsx` pass with no client monetary computation.
- [ ] 3.3 Update shell, auth/session, group, participant, expense, and app tests to query natural Spanish visible and accessible text while retaining every existing interaction assertion; run those focused tests and record the expected RED failures before changing production components.
- [ ] 3.4 Translate the handwritten web shell, login/session notices, group settings, participant and expense panels, known-error presentation, loading/empty/validation states, role/policy labels, and `web/index.html` language metadata; verify all focused tests from task 3.3 pass and no file under `web/src/generated/api/` is manually edited.
- [ ] 3.5 Run `npm --prefix web run test` after localization and verify participant CRUD/archive/rename, expense create/edit/delete and beneficiary defaults/exclusions, auth/session, WebSocket invalidation, balances, settlement, and API adapter regressions remain green.

## 4. Produce the Delivery Handoff

- [ ] 4.1 Rewrite `docs/demo-samaipata.md` as a timed read-only-after-login walkthrough showing four participants, four official expenses, exact Spanish balances/transfers, and refresh persistence without the former `Bs. 100,00` expense; verify the scripted checkpoints total less than three minutes.
- [ ] 4.2 Correct `web/.env.example` and setup guidance to use the Vite same-origin route without duplicating `/api/v1`, explain the non-authoritative status of `VITE_GROUP_ID`, and verify the documented generated login request resolves through the web origin and proxy.
- [ ] 4.3 Align OpenAPI generator metadata and `docs/api-client-generation.md` to the operational `7.14.0` root pin, correct working-directory commands, and verify no generated file changes unless the pinned drift workflow proves regeneration is required.
- [ ] 4.4 Create root `README.md` in Spanish with project purpose, “Grupo 2 - Spec-Driven Development”, features, real architecture/status, structure, prerequisites, environment setup, dependency installation, PostgreSQL, migrations, four-expense seed, backend/web startup, non-secret demo accounts, tests/build, OpenSpec/AGENTS locations, destructive-reset warning, and quick demo instructions; verify every delivery-readiness README item is present and commands identify their working directory.
- [ ] 4.5 Review tracked current-facing documentation and configuration for contradictory architecture, seed-count, demo-result, API-base, credential, or generator-pin statements; verify historical files remain linked and labeled by the precedence map rather than silently rewritten.

## 5. Run Final Delivery Gates

- [ ] 5.1 Run `openspec validate final-delivery-alignment --strict` and `openspec status --change final-delivery-alignment`; verify all proposal capabilities have valid delta specs and every apply-required artifact is complete.
- [ ] 5.2 Run `python -m pytest backend/tests -q` and `python -m ruff check backend`; verify the full mathematical, persistence, API, acceptance, auth, rename, and seed suites pass without unrelated refactors.
- [ ] 5.3 Run `npm --prefix web run test`, `npm --prefix web run typecheck`, and `npm --prefix web run build`; verify all web tests pass and the production build completes.
- [ ] 5.4 Run `python -m backend.scripts.check_contract_drift --cwd .`; verify `contracts/openapi.json` and both generated client trees are reproducible and review the diff to confirm generated TODOs and handwritten generated-client edits are absent.
- [ ] 5.5 From a disposable local demo database, run the documented PostgreSQL reset/start, Alembic upgrade, seed twice, and backend startup/health sequence; verify the second seed creates zero records, exactly four official expenses exist, the backend starts, and protected API results match all exact cent assertions.
- [ ] 5.6 Rehearse the documented browser demo at delivery viewport sizes; verify it completes in under three minutes, uses Spanish primary text, shows the exact four records/balances/transfers, preserves results after refresh, and introduces no functional or responsive regression.
