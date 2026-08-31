# Archive Report: cuentas-claras-mvp

**Archive status**: ✅ PASS — change closed.
**Date**: 2026-08-31
**Change**: `cuentas-claras-mvp`
**Version**: N/A (first delivery; repository has no commits — ledger-based delivery)
**Artifact store**: both (OpenSpec + Engram mirror)

## Closure summary

The Cuentas Claras / Amigo Duradero MVP shipped its full Must slice: a protected, server-authoritative full stack (FastAPI/Python + PostgreSQL/SQLAlchemy/Alembic backend; React/Vite/TanStack Query/Tailwind web; Flutter/Bloc-Cubit/Dio mobile) with integer-cent money everywhere, deterministic equal-split residuals (CC-01), archived-participant zero visibility (CC-02), minimum seeded-account authentication with opaque DB-backed sessions and server-derived owner/member roles (CC-03), and name-only atomic participant rename (CC-04). Clients are generated from a frozen OpenAPI contract; WebSocket is invalidation-only; balances and settlement are derived on read, never persisted.

**Verdict**: PASS WITH WARNINGS — all 50 requirements and 105 scenarios implemented and evidenced; 0 CRITICAL findings; 0 blockers. Native validator admitted the verify report: `gentle-ai sdd-verify-validate --input openspec/changes/cuentas-claras-mvp/verify-report.md --requirements 50 --scenarios 105` → valid:true, verdict pass_with_warnings (requirements 50/50, scenarios 105/105).

## Evidence digest (fresh, 2026-08-31)

| Gate | Result |
| --- | --- |
| Backend suite (`pytest backend/tests -q`) | 188 passed |
| Acceptance DA-01..DA-07 (`pytest backend/tests/acceptance -q`) | 10 passed |
| Seed idempotency (`test_seed.py`) | 2 passed |
| ruff (`ruff check backend`) | All checks passed |
| Contract drift (`check_contract_drift.py`) | Drift-free |
| Web (`npm --prefix web run test` / `typecheck` / `build`) | 46 passed / exit 0 / exit 0 |
| Mobile (`flutter test` / `flutter analyze`) | 37 passed / No issues found |
| pyright (PR 20/21 touched scope) | 0 errors, 0 warnings |

Must gate T-MG: **PASSED** (parent-run, 2026-08-31) — DA-01..DA-07 green, AO-01..AO-11 evidence mapped in `docs/demo-samaipata.md` (2:20 scripted walkthrough, a11y/responsive checklist), contract drift clean, seed idempotent, logout invalidation demonstrated.

## Final state

- **Tasks**: 43/43 complete. No `- [ ]` implementation checkboxes remain in `tasks.md` (re-verified immediately before this archive).
- **Must**: complete and evidenced.
- **Stretch T-36..T-38**: **DECLINED** by explicit user decision 2026-08-31 — annotated strike-through in `tasks.md` documents the decision (mobile expense-write parity, richer group settings, global min-transfer optimization recorded as optional future work). No Stretch content leaked: the mobile read-only test suite asserts no write controls and no "Create expense"/"Edit"/"Delete" copy.
- **Confirmation gates**: CC-01..CC-04 remain as recorded (T-00, Engram obs 2587); protected routes assert 401 envelopes for anonymous access (DA-06); no client-side money or role authority.

## Artifacts read

- `openspec/changes/cuentas-claras-mvp/proposal.md` (227 lines)
- `openspec/changes/cuentas-claras-mvp/specs/{api,clients,demo-readiness,expenses,groups,money,participants,persistence,settlement}/spec.md` (9 domain specs)
- `openspec/changes/cuentas-claras-mvp/design.md` (741 lines)
- `openspec/changes/cuentas-claras-mvp/tasks.md` (509 lines)
- `openspec/changes/cuentas-claras-mvp/apply-progress.md` (1300 lines; final sections: T-33/T-34 closure, T-35 PR 21 closure, T-MG pass)
- `openspec/changes/cuentas-claras-mvp/verify-report.md` (126 lines)
- `docs/demo-samaipata.md` (99 lines)
- `openspec/config.yaml`, `openspec/project-context.md`
- No `sync-report.md` exists in this change.

## Sync and archive move

- **Domains synced**: none. **Sync not applicable** — this repository has no canonical `openspec/specs/` layer (only `openspec/changes/`), and the parent/orchestrator explicitly scoped this close-out to archive-report creation only. `sql` file-backed canonical spec sync is therefore not applicable; no ADDED/MODIFIED/REMOVED requirement merge was performed and none is pending.
- **Archive move**: not performed. Per parent constraint ("Only CREATE the archive-report; do not commit, branch, tag, push, or publish"), the change remains at `openspec/changes/cuentas-claras-mvp/` with `archive-report.md` added in place. Moving the folder to `openspec/changes/archive/YYYY-MM-DD-cuentas-claras-mvp/` remains the orchestrator's call; this report documents the audit trail either way.
- **Active same-domain change warnings**: none — `cuentas-claras-mvp` is the only change under `openspec/changes/`.
- **Destructive merge**: none performed; guard N/A.

## Follow-ups carried forward (non-blocking)

1. **Declare `psycopg2` in `backend/pyproject.toml`** before real delivery — used by `backend/app/main.py` live wiring; installed but undeclared (debt recorded in PR 20 closure).
2. **9 pre-existing pyright errors** in `backend/app/application/auth_service.py` (8) and `backend/app/adapters/db/session.py:68` (1) — T-09/T-11 era, outside PR 20/21 touched scope; touched-scope pyright is 0 errors; resolve in the release pass.
3. **httpx cookie deprecation** — 41 test warnings; migrate test clients to client-instance cookies.
4. **Live demo rehearsal on freed port 5432** — pre-existing `backend-db-1` occupies host port 5432; compose fresh-environment rehearsal (`down -v` → `up db` → alembic → seed ×2 → uvicorn → web dev) and the timed 2:20 walkthrough are documented in `docs/demo-samaipata.md` and re-runnable when the port frees. Hermetic gates are the committed evidence.

## Handoff notes (delivery)

- **Ledger-based delivery**: the repository has no commits (git: no commits yet on `main`); all 30 PR slices were settled through the native SDD attempt ledger with per-slice evidence recorded in `apply-progress.md`. Nothing was merged or published.
- **Bounded review per slice remains due at real delivery time**: the post-apply review gate was closed on that basis (annotated in `tasks.md`); normalized candidates, receipts, and per-slice review must be produced when the change is actually committed and delivered.
- `docs/requerimiento-docente.md` was preserved unchanged.

## Structured status and actionContext

- Native SDD status consumed (parent-supplied): `nextRecommended: archive`, `blockedReasons: []`, dependencies proposal/specs/design/tasks/apply/verify all_done; `taskProgress: 43/43` allComplete.
- `actionContext.mode`: repo-local; project root is the workspace/allow-root (no workspace-planning allowedEditRoots requirement). All writes confined to `openspec/changes/cuentas-claras-mvp/archive-report.md` + the Engram mirror.

## Engram mirror

- `mem_save` mirror persisted under topic key `sdd/cuentas-claras-mvp/archive-report`, project `proyecto_1`, type architecture.
- **Engram observation ID**: `2918` (`sdd/cuentas-claras-mvp/archive-report`).
