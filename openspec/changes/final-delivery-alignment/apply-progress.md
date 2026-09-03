# Apply progress: final-delivery-alignment

This file records the implementation state produced from the repository ZIP snapshot after the OpenCode quota interruption. It does not replace `tasks.md`; checkboxes remain authoritative.

## Implemented scope

- Current guidance reconciled in `openspec/project-context.md`, `openspec/config.yaml`, root `AGENTS.md`, and `docs/sdd-evolution.md`.
- Historical `docs/requerimiento-docente.md` and the independently governed `cuentas-claras-mvp`, `wire-mutation-websocket-invalidation`, and `mobile-domain-features` change directories were not edited.
- Samaipata seed changed from three aggregated source rows to four exact official source expenses with stable IDs `...0021`–`...0024` and explicit payer indices.
- Seed/recovery/DA-01..DA-04 tests updated for the four-expense fixture while domain balance/settlement code remains unchanged.
- Handwritten web delivery surface translated to Spanish; integer-only display formatting now uses decimal comma/thousands dot and signed balances; settlement rows use direct arrow notation.
- Root README, official timed demo, environment example, generator metadata/docs, and delivery-facing SDD status were updated.
- Generated TypeScript/Dart OpenAPI client trees were not modified.

## TDD / verification evidence

### Backend fixture RED

The changed seed/DA-01 tests were run against the pre-change source fixture in a clean copy:

```text
python -m pytest backend/tests/integration/persistence/test_seed.py backend/tests/acceptance/test_da_01_samaipata.py -q

F.F
2 failed, 1 passed
```

Observed failures were the intended ones: the old seed contained `3` expenses instead of `4`, and DA-01 returned `Samaipata - Ana` `96000` rather than separate `Cabaña` `80000` plus `Entradas a El Fuerte` `16000`.

### Backend GREEN / regressions

Run from repository root after implementation:

```text
python -m pytest backend/tests/integration/persistence/test_seed.py backend/tests/integration/api/test_recovery.py backend/tests/acceptance -q
14 passed

python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q
5 passed

python -m pytest backend/tests -q
195 passed

python -m compileall -q backend
passed
```

`python -m ruff check backend` could not be executed in this container because Ruff is not installed.

### Web implementation checks

Vitest/Vite dependencies are not bundled in the ZIP. This environment cannot access the npm registry, and its npm cache does not contain the required project packages, so the real web test/typecheck/build commands could not be executed here.

Checks completed without fabricating a green gate:

- All handwritten web `.ts`/`.tsx` and test files were parsed/transpiled with the installed TypeScript compiler: no syntax diagnostics.
- Direct formatter checks passed for `Bs. 0,00`, thousands grouping, negative amounts, `+Bs. 560,00`, zero, and debt output without floating-point conversion.
- Existing `web/src/core/config.ts`, `web/vite.config.ts`, `web/tests/core/config.test.ts`, and `web/tests/core/websocket.test.ts` are byte-identical to the input snapshot.
- `web/src/generated/api/**` is byte-identical to the input snapshot.

Required local commands remain:

```text
npm --prefix web ci
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
```

### Contract / generated clients

A fresh FastAPI OpenAPI export was produced and its parsed JSON is semantically identical to committed `contracts/openapi.json`. Byte comparison in this Linux container differs because the ZIP carries CRLF line endings while the local export uses LF.

The full drift workflow was not run because it requires the unavailable npm generator dependencies and Dart toolchain. Both committed generated client directories are byte-identical to the input snapshot. Required local command:

```text
python -m backend.scripts.check_contract_drift --cwd .
```

### OpenSpec / PostgreSQL / browser gates

This container does not include the OpenSpec CLI, Docker/PostgreSQL binaries, Flutter/Dart, or the installed web dependency tree. Therefore the following gates are intentionally not claimed as complete and their task checkboxes remain open:

```text
openspec validate final-delivery-alignment --strict
openspec status --change final-delivery-alignment
python -m ruff check backend
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
python -m backend.scripts.check_contract_drift --cwd .
# disposable PostgreSQL reset/migrate/seed-twice/startup/health
# timed browser rehearsal
```

## Preservation checks

- `docs/requerimiento-docente.md`: unchanged.
- `openspec/changes/cuentas-claras-mvp/`: unchanged.
- `openspec/changes/wire-mutation-websocket-invalidation/`: unchanged.
- `openspec/changes/mobile-domain-features/`: unchanged.
- Backend mutation-invalidation integration test: unchanged.
- Web API-base and WebSocket tests/config implementation: unchanged.
- Generated TypeScript/Dart API trees: unchanged.
