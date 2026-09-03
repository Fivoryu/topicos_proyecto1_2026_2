# Tasks: Cuentas Claras MVP (cuentas-claras-mvp) — regenerated after T-00 reconciliation

Dependency-ordered, test-first implementation plan for the confirmed Must slice. FastAPI is the sole monetary AND authorization authority; monetary values are integer cents everywhere (domain/DB/API); balances, splits, and transfers are derived on read and never persisted; clients are generated from a frozen OpenAPI contract; WebSocket carries only `data_changed` invalidation; sessions are opaque, database-backed, cookie-transported, and server-validated.

Confirmation gates CC-01..CC-04 are **completed** (not assumptions): see T-00 for evidence. Authentication and participant rename are **Must** and appear throughout the plan; no task uses a trusted synthetic actor, anonymous access, or a client role as authority. Strict TDD is active: every task starts with RED tests, then GREEN implementation, TRIANGULATE edge cases, REFACTOR. Each task is one coherent work unit = one commit: tests ship with the behavior they verify, docs ship with the workflow they explain (no file-type-driven splits). Do not modify `docs/requerimiento-docente.md`.

Runner commands (`pytest`, web test script, `flutter test`) are provisional until T-04 records the actual versions and commands detected after bootstrap.

## Review Workload Forecast

| Field | Value |
| ------- | ------- |
| Estimated remaining changed lines | ~6,030–7,620 authored (`additions + deletions`) for PR 9–22, excluding generated contract/client snapshots |
| 400-line budget risk | High (whole change) — 14 stacked slices; seven may require an explicit exception if actual authored work exceeds 600 |
| Chained PRs recommended | Yes |
| Suggested split | Historical PR 1–8 unchanged; PR 9 → PR 10 → … → PR 22 (14 remaining stacked slices) |
| Delivery strategy | exception-ok (explicit remaining-plan decision) |
| Chain strategy | stacked-to-main |
| Decision needed before apply | No — the user confirmed all seven exception-eligible slices |

```text
Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High
Exception-eligible slices: PR 9, PR 12, PR 15, PR 17, PR 19, PR 20, PR 22
```

- The remaining plan after T-11 is exactly **14 stacked slices, PR 9–22**; historical PR 1–8 remain unchanged. The user's explicit decision supersedes `ask-on-risk` for remaining delivery only: `delivery_strategy: exception-ok`. Estimates are directional until native line accounting measures actual authored work.
- **Per-slice budget check:** PRs 9, 12, 15, 17, 19, 20, and 22 have upper estimates above 600 and are eligible for an explicit `size:exception`; PRs 10, 11, 13, 14, 16, 18, and 21 have upper estimates at or below 600. A `size:exception` is not automatic: native line accounting must show actual authored work above 600, and the parent must record the explicit exception before that slice's runtime-bearing apply.
- **Generated files** (`contracts/openapi.json`, `web/src/generated/api/**`, `mobile/lib/generated/api/**`) are excluded from authored line counts but remain in complete snapshot identity and receipt validation; they are never hand-edited and are regenerated only from the frozen FastAPI contract.
- The source-persistence/participant boundary is intentionally combined in PR 9, and the OpenAPI export/generated-client boundary is atomic in PR 14; both remain governed by the exact per-slice exception rule above when actual authored lines exceed 600.
- Delivery is already decided for the remaining plan: `delivery_strategy: exception-ok`, `chain_strategy: stacked-to-main`, review budget 600 changed lines. No further chain-strategy decision is requested; T-CF remains before all client work and T-MG remains before Stretch.

## Sequencing map

| Phase | PRs | Tasks | Boundary |
| --- | --- | --- | --- |
| 0 — Confirmed checkpoint | — | T-00 (completed) | CC-01..CC-04 recorded with traceable evidence |
| 1 — Bootstrap + runner discovery | PR 1–4 | T-01..T-04 | three runnable shells, recorded runners |
| 2 — Domain monetary core | PR 5–6 | T-05..T-08 | pure money/split/balance/settlement green (DA-01..DA-04, CB-13..CB-15) |
| 3 — Protected auth foundation | PR 7 | T-09..T-10 | auth service + authorization matrix green on fakes |
| 4 — Persistence + participant foundation | PR 8–9 | T-11..T-13 | auth/source tables, Argon2id, session adapters, reversible migrations, repos, participant use case |
| 5 — Application use cases + auth transport | PR 10–11 | T-14..T-17 | expense atomicity, derived/policy services, session/CSRF transport, auth routes |
| 6 — REST/realtime boundary + seed | PR 12–13 | T-18..T-21 | protected group/participant and expense/derived routes, WS, seed/recovery |
| 7 — Contract freeze + clients | PR 14 | T-22..T-23, gate T-CF | frozen `contracts/openapi.json`, generated TS/Dart, drift check |
| 8 — Web Must (protected) | PR 15–17 | T-24..T-28 | login → session → participants/rename → expenses → balances/settlement → refresh → logout |
| 9 — Mobile Must (read-mostly) | PR 18–19 | T-29..T-32 | protected Dio/Cubit read parity, no write controls |
| 10 — Acceptance + demo + handoff | PR 20–21 | T-33..T-35, gate T-MG | DA-01..DA-07, AO-01..AO-11, under-3-minute walkthrough |
| Stretch (only after T-MG) | PR 22 | T-36..T-38 | optional; never weakens protected Must |

T-CF remains before all client work; T-MG remains before Stretch. Web (PR 15–17) remains before mobile (PR 18–19) in the stacked sequence.

## PR / slice sequence (stacked-to-main)

Each PR merges to main in order. „Start" = PRs/tasks that must already be merged/complete; „End" = boundary evidence required before the next PR starts; „Rollback" = revert boundary for this slice; „Out of scope" = what this slice must not contain.

| PR | Tasks (start→end) | Est. authored lines | Start (depends) | End (boundary evidence) | Rollback | Out of scope |
| --- | --- | --- | --- | --- | --- | --- |
| PR 1 | T-01 | 220–280 | none | `pytest` health test green with PostgreSQL up; uvicorn boots; `alembic` harness configured | `git revert` PR 1: delete `backend/`, `infra/`; nothing imports them yet | App code, auth, domain, API |
| PR 2 | T-02 | 220–280 | PR 1 (dev env) | web test script green; `npm run dev` serves placeholder | revert PR 2: delete `web/` | Feature code, auth, TanStack flows |
| PR 3 | T-03 | 160–220 | PR 1 (dev env) | `flutter test` green; `flutter run` renders placeholder | revert PR 3: delete `mobile/` | Feature code, Dio flows |
| PR 4 | T-04 | 40–60 | PR 1–3 | detected runners recorded in `openspec/project-context.md` + `config.yaml`; every recorded command green; `status: detected` | revert PR 4: revert the two planning files | Product code |
| PR 5 | T-05..T-06 | 180–260 | PR 4 | `test_money.py`, `test_split_service.py` green incl. DA-02/DA-03 and CC-01 intersection + fallback | revert PR 5: delete money/split modules + tests | Balances/settlement, persistence, API, auth |
| PR 6 | T-07..T-08 | 240–330 | PR 5 | `test_balance_service.py`, `test_expense_rules.py`, `test_settlement_service.py` green: DA-01 balances/order, zero invariant, CB-13/14/15 | revert PR 6: delete balance/settlement/expense_rules + tests | Persistence, API, auth, clients |
| PR 7 | T-09..T-10 | 380–500 | PR 4 | auth-service and authorization unit tests green: login/logout/expiry via fake clock, role derivation, matrix decisions, group isolation, client role ignored | revert PR 7: delete `application/ports.py`, `auth_service.py`, `authorization.py` + tests | HTTP/cookies/CSRF, persistence adapters, REST |
| PR 8 | T-11 | 320–400 | PR 7 | auth persistence + migration 0001 round-trip green; Argon2id verify test; token-hash lookup; revoked/expired session tests | revert PR 8: drop migration 0001, delete auth tables/repos/security adapters + tests | Domain tables, API routes, seed |
| PR 9 | T-12 + T-13 — source persistence plus participant use case | 560–710 — eligible for explicit `size:exception` if actual >600 | PR 8 | source tables/repos/UoW, migration 0002, participant lifecycle and rename tests green; restart persistence and ID/FK preservation | revert PR 9: drop migration 0002, delete source tables/repos/UoW and participant service/tests | Expense/application services, API, clients |
| PR 10 | T-14 + T-15 — expense atomicity/derived service plus group policy/invalidation | 400–500 | PR 9 | expense create/edit/delete atomicity, derived reads, policy matrix, and post-commit invalidation tests green | revert PR 10: delete expense/derived/group services and tests | Session transport, routes, clients |
| PR 11 | T-16 + T-17 — session/CSRF/origin transport plus auth routes | 460–580 | PR 10 | session dependency, CSRF/origin boundary, login/logout/session identity, and auth error-envelope tests green | revert PR 11: delete transport dependencies, auth routes/schemas/error mapping, and tests | Group/participant and expense routes |
| PR 12 | T-18 + T-19 — group/participant routes plus expense/balance/settlement routes | 560–700 — eligible for explicit `size:exception` if actual >600 | PR 11 | protected group/participant/rename and expense/derived route tests green; integer-cent wire and policy payloads verified | revert PR 12: delete group/participant/expense/derived routes, schemas, and tests | WebSocket, seed, contract generation |
| PR 13 | T-20 + T-21 — WebSocket invalidation plus idempotent seed/recovery | 370–480 | PR 12 | invalidation-only WS, idempotent demo seed, exact Samaipata state, and fail-closed recovery tests green | revert PR 13: delete events/broadcaster, seed/recovery code, docs, and tests | OpenAPI export and clients |
| PR 14 | T-22 + T-23 + gate T-CF — OpenAPI export/generation/drift freeze | 180–270 authored lines; generated snapshots excluded from authored count but included in snapshot identity | PR 13 | OpenAPI export, generated TypeScript/Dart clients, drift check, and T-CF freeze all green | revert PR 14: delete contract/export/drift artifacts and generated client directories | Client feature code |
| PR 15 | T-24 + T-25 — web core/transport plus web auth flow | 530–650 — eligible for explicit `size:exception` if actual >600 | PR 14, T-CF | web formatter/transport/core and protected session/login/logout route tests green | revert PR 15: delete web core, auth flow, session provider, protected route, and tests | Group, expense, balance, settlement features |
| PR 16 | T-26 — web group/participants/rename | 300–360 | PR 15 | protected group and participant lifecycle/rename UI tests green, including invalid-state preservation | revert PR 16: delete web group/participant features and tests | Expense flows |
| PR 17 | T-27 + T-28 — web expenses plus web balances/settlement/WS | 500–620 — eligible for explicit `size:exception` if actual >600 | PR 16 | expense forms, archived-reference behavior, balances, settlement, and invalidation/refetch tests green | revert PR 17: delete web expense, balance, settlement, and WebSocket features/tests | Mobile, acceptance |
| PR 18 | T-29 + T-30 — mobile core plus mobile session | 450–570 | PR 17 | mobile formatter/store/read-model and protected session/Cubit tests green | revert PR 18: delete mobile core, read models, auth repository, interceptors, session Cubit, and tests | Mobile read repositories/views |
| PR 19 | T-31 + T-32 — mobile repositories/Cubits plus read-mostly views | 510–630 — eligible for explicit `size:exception` if actual >600 | PR 18 | protected mobile repositories, read Cubits, WS reload, and read-only widget tests green | revert PR 19: delete mobile repositories/Cubits/read-mostly views and tests | Mobile expense writes, acceptance |
| PR 20 | T-33 + T-34 — DA-01..DA-05 plus auth/rename acceptance | 520–640 — eligible for explicit `size:exception` if actual >600 | PR 19 | DA-01..DA-05 and DA-06/DA-07 acceptance tests green through the protected API | revert PR 20: delete acceptance tests for DA-01..DA-07 | Demo/handoff evidence |
| PR 21 | T-35 + gate T-MG — demo/handoff plus Must gate | 240–300 | PR 20 | timed protected demo, AO-01..AO-11 evidence, drift/seed reruns, and T-MG all green; Stretch remains blocked until then | revert PR 21: delete demo/handoff evidence; product unchanged | Stretch work |
| PR 22 | T-36 + T-37 + T-38 — Stretch only after T-MG | 450–610 — eligible for explicit `size:exception` if actual >600 | T-MG | optional mobile writes, richer settings, and optimization remain behind the Must gate | revert PR 22: remove Stretch features/tests only | Any Must weakening |

Dependency diagram (each PR depends on the one(s) above it in this table; `📍` marks the current PR at apply time):

```text
PR1 → PR2 → PR3 → PR4 → PR5 → PR6 → PR7 → PR8
 → PR9 → PR10 → PR11 → PR12 → PR13 → PR14 [gate T-CF]
 → PR15 → PR16 → PR17 (web)
 → PR18 → PR19 (mobile read-mostly)
 → PR20 → PR21 [gate T-MG] → PR22 [Stretch]
```

---

## Task list (each task = one commit; tests with behavior, docs with workflow)

### Phase 0 — Confirmed checkpoint (COMPLETED)

### T-00 — Record CC-01..CC-04 as confirmed with traceable evidence

- [x] Record the four T-00 confirmation gates as completed product decisions, with traceable evidence, before any product code: CC-01 multi-contributor residual → first stable-creation-order participant in contributor∩beneficiary, else first selected beneficiary; CC-02 archived participants visible in balances/history including `Bs. 0.00`, excluded from new-expense defaults, retained in referencing edit forms; CC-03 minimum seeded-account auth (login/logout/protected sessions/server-derived owner+member roles) is Must; CC-04 name-only atomic participant rename preserving IDs/FKs/history/money is Must. Evidence: user decisions recorded in Engram observation `2587` (`sdd/cuentas-claras-mvp/confirmation-gates`); reconciled proposal obs `2583`; regenerated specs obs `2584` (9 files under `specs/`); regenerated design obs `2585` (`design.md`); this regenerated `tasks.md`; reconciled `openspec/project-context.md`; `openspec/config.yaml` unchanged. No downstream artifact still treats auth or rename as a non-goal; no gate-resolution language remains in this plan. <!-- sdd-owner: parent -->

---

### Phase 1 — Bootstrap and runner discovery

### T-01 — Backend skeleton, PostgreSQL infra, pytest harness (RED → GREEN)

- [x] Bootstrap `backend/pyproject.toml` (FastAPI, SQLAlchemy 2 async, Alembic, asyncpg, Argon2id-cffi, pytest/httpx), `backend/app/main.py` health route, typed env settings adapter (`backend/app/adapters/config.py`: DATABASE_URL, CORS_ORIGINS, SESSION_TTL, DEMO_* password env names), minimal async engine factory (`backend/app/adapters/db/session.py`), and `infra/docker-compose.yml` (PostgreSQL, named volume, healthcheck); write the failing health-route test first, then implement. <!-- sdd-owner: implementation -->
  - **Target:** `backend/pyproject.toml`, `backend/app/main.py`, `backend/app/adapters/config.py`, `backend/app/adapters/db/session.py`, `backend/tests/`, `infra/docker-compose.yml`, `backend/.env.example`.
  - **Spec refs:** `specs/persistence/spec.md` (PostgreSQL persistence); `specs/api/spec.md` (REST surface).
  - **Design refs:** §"Monorepo/module map", §"Seed, migrations, and recovery".
  - **TDD evidence:** RED `tests/test_health.py` → GREEN main.py/settings → TRIANGULATE (bad DATABASE_URL fails closed) → REFACTOR; `pytest backend/tests -q` → all pass with `docker compose up -d db` healthy.
  - **Runtime evidence:** `uvicorn backend.app.main:app` boots; `GET /health` → 200 with DB connectivity.
  - **Depends:** T-00. **Rollback:** delete `backend/`, `infra/`; nothing imports them yet.

### T-02 — Web shell bootstrap (RED → GREEN)

- [x] Scaffold `web/package.json` (React + Vite + TanStack Query + Tailwind, Vitest + Testing Library, pinned OpenAPI TS generator entry) with a placeholder screen and a failing smoke test first; wire `VITE_API_BASE_URL`/`VITE_GROUP_ID` env placeholders and `.env.example`. <!-- sdd-owner: implementation -->
  - **Target:** `web/package.json`, `web/vite.config.*`, `web/tsconfig.json`, `web/src/app/`, `web/tests/`, `web/.env.example`.
  - **Spec refs:** `specs/clients/spec.md` (Web Must flow); `specs/groups/spec.md` (single-group UI config is routing only).
  - **Design refs:** §"Monorepo/module map", §"Client data and UX design — TanStack Query".
  - **TDD evidence:** RED smoke test → GREEN scaffold → REFACTOR; web test script → passes; `npm run dev` serves placeholder.
  - **Depends:** T-01 (dev env). **Rollback:** delete `web/`.

### T-03 — Mobile shell bootstrap (RED → GREEN)

- [x] Scaffold `mobile/pubspec.yaml` (Flutter + Dio + bloc + dio_cookie_manager + flutter_secure_storage, flutter_test/lints, pinned dart-dio generator entry) with a placeholder widget and a failing smoke test first; wire `--dart-define=API_BASE_URL`/`GROUP_ID` config placeholder. Bloc/Cubit only; no `ChangeNotifier`. <!-- sdd-owner: implementation -->
  - **Target:** `mobile/pubspec.yaml`, `mobile/analysis_options.yaml`, `mobile/lib/app/`, `mobile/test/`.
  - **Spec refs:** `specs/clients/spec.md` (Mobile read-mostly parity); `specs/api/spec.md` (session surface).
  - **Design refs:** §"Monorepo/module map", §"Client architecture — Mobile".
  - **TDD evidence:** RED smoke test → GREEN scaffold → REFACTOR; `flutter test` (from `mobile/`) → passes; `flutter run` on emulator/desktop renders placeholder.
  - **Depends:** T-01 (dev env). **Rollback:** delete `mobile/`.

### T-04 — Re-run SDD testing discovery and pin runner commands

- [x] Re-run testing discovery after bootstrap; update `openspec/project-context.md` `## Testing discovery` and `openspec/config.yaml` `testing:` block with detected runners, commands, and versions (pytest, web test script, `flutter test`); record the strict-TDD command table. <!-- sdd-owner: implementation -->
  - **Target:** `openspec/project-context.md`, `openspec/config.yaml` (only the `testing:` block).
  - **Spec refs:** spec cross-cutting (runner bootstrap via re-discovery); proposal §"Dependencies and 48-hour sequencing".
  - **Design refs:** §"Testing strategy and evidence layers".
  - **TDD evidence:** every recorded command runs green once from the checkout root; `status: detected` replaces `pending-stack-bootstrap`.
  - **Depends:** T-01, T-02, T-03. **Rollback:** revert the two planning files; no product impact.

---

### Phase 2 — Domain monetary core (strict TDD, no auth inside)

### T-05 — Cents boundary parsing and representation (RED → GREEN → TRIANGULATE)

- [x] Implement `domain.money.parse_amount_text` (text → integer cents: digits before decimal, ≤2 fraction digits, left-padded fraction, `whole * 100 + fraction`) and a `Cents` int alias plus `domain/errors.py` (`invalid_amount`, `no_beneficiaries`, `no_participants`, `invalid_participant_reference`, `contribution_mismatch`); failing tests first covering blank, malformed, zero, negative, >2 decimals, and exact conversions; no float arithmetic anywhere. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/domain/money.py`, `backend/app/domain/errors.py`, `backend/tests/unit/domain/test_money.py`.
  - **Spec refs:** `specs/money/spec.md` (integer-cents representation; boundary parsing CB-02/03/04).
  - **Design refs:** §"Domain and application boundaries — Money".
  - **TDD evidence:** RED parse tests → GREEN `money.py` → TRIANGULATE (`0`, `"0.01"`, `"1000.99"`, `"1,600.00"` rejected, `"100.00"`→10000) → REFACTOR; `pytest backend/tests/unit/domain/test_money.py -q` → green.
  - **Depends:** T-04. **Rollback:** delete `money.py`, `errors.py` additions + `test_money.py`; no other module imports them yet.

### T-06 — Equal split service with CC-01 deterministic residual (RED → GREEN → TRIANGULATE)

- [x] Implement `domain/split_service.equal_split(amount_cents, beneficiaries, contributors, stable_order)` — `base = amount_cents // count`; **CC-01:** assign the complete residual to the first stable-`created_at, id`-order participant in contributor∩beneficiary, else first selected beneficiary in stable order; assert shares sum exactly to amount; tests red first: DA-02 (3334/3333/3333), DA-03 (excluded → 0), CC-01 multi-contributor intersection (Ana 6000+Beto 4000 contribute, all three benefit → Ana 3334), empty-intersection fallback (10001, contributors Ana+Beto, beneficiaries Carla+Diego → Carla 5001, Diego 5000). <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/domain/split_service.py`, `backend/tests/unit/domain/test_split_service.py`.
  - **Spec refs:** `specs/settlement/spec.md` (equal split + deterministic residual, CC-01 scenarios).
  - **Design refs:** §"Domain and application boundaries — Money, split, balance, settlement".
  - **TDD evidence:** RED → GREEN → TRIANGULATE both CC-01 branches → REFACTOR; `pytest backend/tests/unit/domain/test_split_service.py -q` → green incl. exact-sum assertions.
  - **Depends:** T-05. **Rollback:** delete `split_service.py` + tests.

### T-07 — Expense rules and balance computation (RED → GREEN → TRIANGULATE)

- [x] Implement `domain/expense_rules.py` (≥1 contributor, ≥1 beneficiary, valid in-group references, positive amounts, contributions sum exactly) and `domain/balance_service.compute_balances(participants, expenses)` (paid = Σ contributions, owed = Σ shares, balance = paid − owed, all participants incl. referenced archived in stable order; assert Σ balances == 0; corruption raises instead of fabricating); tests red first: DA-01 balances (+56000/0/−16000/−40000 cents), zero invariant, archived-zero row stays listed, corruption case. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/domain/expense_rules.py`, `backend/app/domain/balance_service.py`, `backend/tests/unit/domain/test_expense_rules.py`, `test_balance_service.py`.
  - **Spec refs:** `specs/settlement/spec.md` (balance computation DA-01, archived zero CC-02, zero-balance invariant); `specs/expenses/spec.md` (creation validation, multiple contributors).
  - **Design refs:** §"Domain and application boundaries — Money…", §"Acceptance datasets DA-01/DA-02".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (archived zero, single participant, corruption) → REFACTOR; `pytest backend/tests/unit/domain/test_balance_service.py backend/tests/unit/domain/test_expense_rules.py -q` → green.
  - **Depends:** T-06. **Rollback:** delete the two services + tests.

### T-08 — Deterministic greedy settlement service (RED → GREEN → TRIANGULATE)

- [x] Implement `domain/settlement_service.build_settlement(balances)` — drop neutrals, debtors most-negative-first then stable order, creditors most-positive-first then stable order, transfer `min(abs(debt), credit)`, advance at zero, assert positive transfers and zero residuals; tests red first: DA-01 transfer order (Diego→Ana 40000, then Carla→Ana 16000; Beto in none), CB-13 all-zero (`settled: true`, empty list), CB-14 single participant, CB-15 payer excluded (Ana +30000; three 10000 transfers in stable order). <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/domain/settlement_service.py`, `backend/tests/unit/domain/test_settlement_service.py`.
  - **Spec refs:** `specs/settlement/spec.md` (deterministic greedy settlement, CB-13/14/15, DA-01 order).
  - **Design refs:** §"Domain and application boundaries — Settlement", §"Acceptance datasets DA-01/DA-04".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (ties, neutrals, single debtor/creditor) → REFACTOR; `pytest backend/tests/unit/domain/test_settlement_service.py -q` → green with exact order assertions.
  - **Depends:** T-07. **Rollback:** delete `settlement_service.py` + tests.

---

### Phase 3 — Protected auth foundation (application layer, fake-repo unit tests)

### T-09 — Auth ports and auth service: login/logout/session identity (RED → GREEN → TRIANGULATE)

- [x] Implement `application/ports.py` (Clock, PasswordHasher, SessionTokenSource, AccountRepository, SessionRepository, MembershipRepository interfaces) and `application/auth_service.py`: login verifies active account + Argon2id-style hash through the hasher port with constant-time behavior, creates an opaque session with token hash + `expires_at` (injected clock + configured TTL), returns server-derived identity/role; logout revokes the current session; session identity validates token-hash, `revoked_at`, `expires_at`; unit tests with fakes red first: login success owner/member, invalid credentials, inactive account, expiry via fake clock, revocation, no account-existence leak. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/application/ports.py`, `backend/app/application/auth_service.py`, `backend/tests/unit/application/test_auth_service.py`.
  - **Spec refs:** `specs/api/spec.md` (authentication and session surface scenarios); `specs/groups/spec.md` (protected sessions CC-03); `specs/persistence/spec.md` (minimum account/session persistence).
  - **Design refs:** §"Authentication and authorization architecture — Source tables, Login/logout/session identity flow".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (expired/revoked/missing token, inactive account, clock boundaries) → REFACTOR; `pytest backend/tests/unit/application/test_auth_service.py -q` → green; no wait on real time (fake clock only).
  - **Depends:** T-04. **Rollback:** delete `ports.py`, `auth_service.py` + tests; persistence/adapters not yet present.

### T-10 — Authorization: membership, server-derived roles, operation matrix (RED → GREEN → TRIANGULATE)

- [x] Implement `application/authorization.py`: group-membership check (member of requested group or `forbidden`), role derivation (`owner` iff `account_id == groups.owner_account_id`, else `member`), the explicit operation matrix (reads/participant mutations/expense mutations/WS: both roles; `PATCH /groups/{id}` policy: owner-only when current value `owner_only`, either role when `any_member`; out-of-group always `forbidden`), and client-role-claims ignored; unit tests red first: role derivation, member denied/`any_member` permitted policy change, out-of-group 403, forged `owner` claim ignored. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/application/authorization.py`, `backend/tests/unit/application/test_authorization.py`.
  - **Spec refs:** `specs/groups/spec.md` (server-derived roles, policy setting authorization, group membership isolation); `specs/api/spec.md` (server-derived role enforcement).
  - **Design refs:** §"Operation authorization matrix".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (role edge cases around owner membership invariant, both policy values) → REFACTOR; `pytest backend/tests/unit/application/test_authorization.py -q` → green.
  - **Depends:** T-09 (ports). **Rollback:** delete `authorization.py` + tests.

---

### Phase 4 — Persistence (auth + source) and security adapters

### T-11 — Auth persistence, Argon2id adapter, session adapters, migration 0001 (RED → GREEN)

- [x] Implement `adapters/db/tables.py` auth tables (accounts: unique `login_name`, password_hash, is_active; group_memberships: composite PK, cascade; sessions: unique `token_hash` bytea, account FK cascade, `expires_at`, `revoked_at` nullable, covering indexes), `adapters/security/passwords.py` Argon2id adapter behind the hasher port, `adapters/security/sessions.py` (cryptographically random opaque token, SHA-256 hash, `cc_session` cookie constants), auth repositories (login by `login_name`, session lookup by token hash, revoke, active-membership queries), Alembic migration 0001 with documented downgrade; integration tests red first: owner-membership invariant, token-hash lookup, revoked/expired rejection, Argon2id verify + wrong-password reject, migration round trip. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/adapters/db/tables.py` (auth part), `backend/app/adapters/db/repositories.py` (auth part), `backend/app/adapters/security/passwords.py`, `backend/app/adapters/security/sessions.py`, `backend/migrations/versions/0001_auth.py`, `backend/tests/integration/auth/`, `backend/tests/integration/persistence/test_auth_tables.py`.
  - **Spec refs:** `specs/persistence/spec.md` (minimum account/session persistence, reversible migrations); `specs/api/spec.md` (auth error contract).
  - **Design refs:** §"Source tables", §"Passwords and demo credentials", §"Session transport choice".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (expired vs revoked distinction, unique constraints) → REFACTOR; `pytest backend/tests/integration/auth backend/tests/integration/persistence/test_auth_tables.py -q` → green; `alembic upgrade head` + `alembic downgrade base` round trip documented.
  - **Depends:** T-09, T-10 (interfaces), T-01 (engine). **Rollback:** drop migration 0001; delete auth tables/repos/security adapters + tests.

### T-12 — Source persistence: tables, domain repositories, UoW, migration 0002 (RED → GREEN)

- [x] Implement `adapters/db/tables.py` source tables (groups with `owner_account_id` FK; participants with `(group_id, normalized_name)` unique incl. archived; expenses + expense_contributions + expense_beneficiaries with positive integer-cent checks, restrict participant FKs, cascade expense children), domain repositories (all methods take `group_id` and verify child references in-group), `adapters/db/uow.py`, Alembic migration 0002 with downgrade; integration tests red first: no balance/transfer/split tables exist, constraints (unique names incl. archived, restrict/cascade, cents positivity), restart persistence, rename-FK preservation scaffolding (rows survive name updates). <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/adapters/db/tables.py` (source part), `backend/app/adapters/db/repositories.py` (source part), `backend/app/adapters/db/uow.py`, `backend/migrations/versions/0002_source.py`, `backend/tests/integration/persistence/`.
  - **Spec refs:** `specs/persistence/spec.md` (PostgreSQL source persistence, derived never persisted, name uniqueness and rename persistence); `specs/participants/spec.md` (lifecycle constraints).
  - **Design refs:** §"Persistence model and constraints".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (archived-name uniqueness, children cascade, out-of-group ref rejection) → REFACTOR; `pytest backend/tests/integration/persistence -q` → green; migration round trip documented.
  - **Depends:** T-11 (accounts exist first for `groups.owner_account_id`). **Rollback:** drop migration 0002; delete source tables/repos/uow + tests.

---

### Phase 5 — Application use cases

### T-13 — Participant service: add/list, archive/reactivate, protected delete, name-only rename (RED → GREEN → TRIANGULATE)

- [x] Implement `application/participant_service.py`: add/list with trimmed case-insensitive normalized uniqueness (blank → `invalid_participant_name`, conflict incl. archived → `duplicate_participant_name`, CB-08), archive/reactivate preserving references, delete only never-referenced (`participant_in_use` CB-09), and **rename (CC-04)**: trim + Unicode-normalize + case-fold, reject blank/conflict, update ONLY `name`/`normalized_name` in one transaction, preserve ID, all FKs, archived status, creation order and all monetary results; unit tests with fake repos red first: CB-08/09, CC-04 success preserves ID+`+56000`, normalization conflict, blank reject, archived rename name-only, no state change on invalid input. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/application/participant_service.py`, `backend/app/application/ports.py` (participant repo extension), `backend/tests/unit/application/test_participant_service.py`.
  - **Spec refs:** `specs/participants/spec.md` (add/list CB-08, archive/reactivate, protected deletion CB-09, rename CC-04 requirements and scenarios).
  - **Design refs:** §"Participant rename use case".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (whitespace-only, ` ana ` vs `Ana`, archived conflict, uppercase folding) → REFACTOR; `pytest backend/tests/unit/application/test_participant_service.py -q` → green.
  - **Depends:** T-09 (ports), T-12 (repo shapes). **Rollback:** delete `participant_service.py` + tests.

### T-14 — Expense service: atomic create/edit/delete; derived service (RED → GREEN → TRIANGULATE)

- [x] Implement `application/expense_service.py` (one UoW transaction: validate complete command — description, parsed cents, in-group contributor/beneficiary refs, status rules, contribution total, CC-01 split candidate; edit replaces child rows only when fully valid and accepts referenced archived participants; flush + zero-sum verify; rollback on any failure) and `application/derived_service.py` (balances + settlement on read through domain services); unit tests with fake repos red first: CB-01..CB-07, CB-10 payer change recalculates, AO-05 invalid edit/delete leaves prior state unchanged, AO-03 contribution-mismatch rejected before persistence. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/application/expense_service.py`, `backend/app/application/derived_service.py`, `backend/tests/unit/application/test_expense_service.py`, `test_derived_service.py`.
  - **Spec refs:** `specs/expenses/spec.md` (creation validation, defaults, edit/delete atomicity, AO-03/AO-05); `specs/settlement/spec.md` (invariant).
  - **Design refs:** §"Expense transaction", §"Money, split, balance, settlement".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (multi-contributor sums, archived-in-edit, rollback paths) → REFACTOR; `pytest backend/tests/unit/application -q` → green.
  - **Depends:** T-13, T-06..T-08 (domain). **Rollback:** delete expense/derived services + tests.

### T-15 — Group policy use case and invalidation port (RED → GREEN)

- [x] Implement `application/group_service.py` (read group with `settlementPolicy`; update policy decided by the T-10 matrix: under `owner_only` owner-only, under `any_member` either role) and the `InvalidationPublisher` port raised only post-commit; unit tests red first: default `owner_only` + owner change persists, member denied 403-equivalent under `owner_only`, member permitted under `any_member`, invalidation fires only after successful commit. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/application/group_service.py`, `backend/app/application/ports.py` (publisher port), `backend/tests/unit/application/test_group_service.py`.
  - **Spec refs:** `specs/groups/spec.md` (settlement policy setting scenarios); `specs/api/spec.md` (policy exposure, WS invalidation-only).
  - **Design refs:** §"Operation authorization matrix", §"Mutation and invalidation".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (both policy values, no-commit-no-signal) → REFACTOR; `pytest backend/tests/unit/application/test_group_service.py -q` → green.
  - **Depends:** T-14, T-10. **Rollback:** delete `group_service.py` + tests.

---

### Phase 6 — REST and realtime boundary

### T-16 — Session/CSRF/origin transport and FastAPI dependencies (RED → GREEN)

- [x] Implement `api/deps.py (resolve`cc_session` cookie → hash → session lookup → account → membership in requested group → derived role; reject before any data access), cookie/CSRF helpers in `adapters/security/sessions.py` (set/clear `cc_session` HttpOnly SameSite=Lax Path=/api, non-HttpOnly `cc_csrf`; constant-time`X-CSRF-Token` vs cookie compare; browser `Origin` check against `CORS_ORIGINS`), and the`csrf_failed` 403 envelope mapping; tests red first: valid session propagates identity, missing/revoked/expired → 401 `unauthorized`/`session_expired`, CSRF mismatch 403`csrf_failed`, disallowed origin 403, no mutation attempted on CSRF failure. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/api/deps.py`, `backend/app/adapters/security/sessions.py`, `backend/tests/integration/api/test_security_transport.py`.
  - **Spec refs:** `specs/api/spec.md` (protected session dependency, structured error contract incl. `csrf_failed`); `specs/groups/spec.md` (protected sessions).
  - **Design refs:** §"CSRF and origin protection", §"Session transport choice".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (missing origin, expired vs revoked, wrong cookie name) → REFACTOR; `pytest backend/tests/integration/api/test_security_transport.py -q` → green.
  - **Depends:** T-11 (adapters), T-15. **Rollback:** delete `api/deps.py` + transport helpers + tests.

### T-17 — Auth routes: login/logout/session identity + error envelope (RED → GREEN)

- [x] Implement `api/routes/auth.py (`POST /api/v1/auth/login` with `{login_name, password}` + CSRF boundary → sets `cc_session` + `cc_csrf`, returns`SessionIdentityResponse` with server-derived role; `GET /api/v1/auth/session` → identity/role or explicit 401, initializes CSRF cookie when absent; `POST /api/v1/auth/logout` → revoke + clear cookies), `api/schemas/auth.py`, and`api/errors.py`auth mapping (`invalid_credentials` 401, `unauthorized` 401, `session_expired` 401, `forbidden` 403, `csrf_failed` 403) with no account-existence or group-data leak; integration tests red first: owner/member login roles, invalid credentials, refresh survival while valid, logout invalidation, logged-out session rejected, login response never contains a client role field. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/api/routes/auth.py`, `backend/app/api/schemas/auth.py`, `backend/app/api/errors.py`, `backend/tests/integration/api/test_auth_routes.py`.
  - **Spec refs:** `specs/api/spec.md` (authentication and session surface scenarios, structured error contract); `specs/demo-readiness/spec.md` (DA-06 core cases).
  - **Design refs:** §"Login/logout/session identity flow", §"REST/OpenAPI contract", §"Error contract".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (expired vs revoked vs missing, inactive account) → REFACTOR; `pytest backend/tests/integration/api/test_auth_routes.py -q` → green with cookie assertions.
  - **Depends:** T-16. **Rollback:** delete `routes/auth.py`, `schemas/auth.py`, auth error mapping + tests.

### T-18 — Group and participant routes incl. name-only rename (RED → GREEN)

- [x] Implement `api/routes/groups.py` (`GET` group with `settlementPolicy`; `PATCH` accepting only `settlementPolicy` per the T-15 matrix) and `api/routes/participants.py` (`GET/POST` list/add, `PATCH /{participant_id}` name-only rename with unknown fields rejected, `POST .../archive`, `POST .../reactivate`, `DELETE` protected by references), plus `api/schemas/groups.py`, `api/schemas/participants.py` (`RenameParticipantRequest` = exactly `{name: string}`); integration tests red first: protected CRUD under session, CB-08/09 envelopes, CC-04 rename success preserves ID/money + blank/conflict rejections with no state change, policy matrix 403 cases, client-supplied role ignored, 404 for unknown/out-of-group refs. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/api/routes/groups.py`, `backend/app/api/routes/participants.py`, `backend/app/api/schemas/groups.py`, `backend/app/api/schemas/participants.py`, `backend/tests/integration/api/test_group_participant_routes.py`.
  - **Spec refs:** `specs/api/spec.md` (REST endpoint surface, rename is name-only, server-derived role enforcement); `specs/participants/spec.md` (CC-04, CB-08, CB-09); `specs/groups/spec.md` (policy scenarios).
  - **Design refs:** §"REST/OpenAPI contract", §"Participant rename use case", §"Error contract".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (rename of archived participant, conflict with archived name, unknown fields in rename request) → REFACTOR; `pytest backend/tests/integration/api/test_group_participant_routes.py -q` → green.
  - **Depends:** T-17, T-15. **Rollback:** delete group/participant routes + schemas + tests.

### T-19 — Expense, balances, settlement routes (RED → GREEN)

- [x] Implement `api/routes/expenses.py` (`GET/POST /expenses`, `GET/PATCH/DELETE /expenses/{id}` with decimal-string `amount`/contribution inputs parsed exactly once into cents), `api/routes/balances.py` (`GET` server-derived balances in stable order incl. referenced archived at zero), `api/routes/settlement.py` (`GET` policy + `settled` + ordered transfers), and `api/schemas/expenses.py`, `balances.py`, `settlement.py`, `errors.py` (existing domain codes mapped to 422/409/404/500 `persistence_corrupted`); integration tests red first: full protected CRUD, CB-01..CB-09/CB-15 envelopes with no state change, invalid mutations leave prior state intact, integer-cent wire values only, policy exposed in group + settlement payloads. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/api/routes/expenses.py`, `balances.py`, `settlement.py`, `backend/app/api/schemas/`, `backend/tests/integration/api/test_expense_derived_routes.py`.
  - **Spec refs:** `specs/api/spec.md` (REST surface, structured error contract AO-06, policy exposure); `specs/expenses/spec.md` (validation/atomicity); `specs/settlement/spec.md` (balances/settlement responses).
  - **Design refs:** §"REST/OpenAPI contract", §"Error contract".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (multi-contributor decimal strings, archived-zero balances, settled empty) → REFACTOR; `pytest backend/tests/integration/api/test_expense_derived_routes.py -q` → green.
  - **Depends:** T-18, T-14. **Rollback:** delete expense/balances/settlement routes + schemas + tests.

### T-20 — WebSocket invalidation-only channel (RED → GREEN)

- [x] Implement `api/routes/events.py` (WS `/api/v1/groups/{group_id}/events`; handshake validates session cookie + membership + allowed origin) and `adapters/events/broadcaster.py` (publishes only `data_changed` per group, post-commit); tests red first: frame is exactly a type-bearing invalidation with no amount/balance/transfer/role/participant data, unauthorized handshake rejected, WS failure never rolls back a committed mutation and REST keeps working. <!-- sdd-owner: implementation -->
  - **Target:** `backend/app/api/routes/events.py`, `backend/app/adapters/events/broadcaster.py`, `backend/tests/integration/api/test_ws_events.py`.
  - **Spec refs:** `specs/api/spec.md` (WebSocket invalidation-only channel scenarios).
  - **Design refs:** §"Mutation and invalidation", §"REST/OpenAPI contract".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (frame schema, unauthorized handshake, broadcaster failure) → REFACTOR; `pytest backend/tests/integration/api/test_ws_events.py -q` → green.
  - **Depends:** T-19, T-16. **Rollback:** delete events route + broadcaster + tests; REST unaffected.

### T-21 — Idempotent seed with demo accounts and corruption recovery (RED → GREEN)

- [x] Implement `scripts/seed_demo.py`: upsert stable group, `demo.owner` and `demo.member` accounts (passwords from `DEMO_OWNER_PASSWORD`/`DEMO_MEMBER_PASSWORD` env/`.env.example` placeholders, Argon2id hashes, never committed; existing login_name not rehashed on rerun), owner membership row, `owner_only` policy, Ana/Beto/Carla/Diego in creation order, Samaipata expenses 96000/40000/24000 benefiting all four; fail-closed corruption path (`persistence_corrupted` on integrity/zero-sum failure with logged evidence, documented DB-reset-and-reseed recovery); tests red first: seed idempotency (rerun no-op, no duplicate accounts/participants/expenses/sessions), AO-01 state exact, CB-16 recovery document/behavior, hash stability across reruns. <!-- sdd-owner: implementation -->
  - **Target:** `backend/scripts/seed_demo.py`, `backend/app/adapters/db/seed.py` (if split), `backend/tests/integration/persistence/test_seed.py`, `backend/tests/integration/api/test_recovery.py`, recovery note in `docs/` (short section or with T-35 doc).
  - **Spec refs:** `specs/demo-readiness/spec.md` (idempotent seed with demo accounts, AO-09); `specs/persistence/spec.md` (CB-16, seed idempotency).
  - **Design refs:** §"Passwords and demo credentials", §"Seed, migrations, and recovery".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (rerun, reset flag, corrupt row) → REFACTOR; `pytest backend/tests/integration/persistence/test_seed.py backend/tests/integration/api/test_recovery.py -q` → green; fresh-sequence `upgrade → seed → seed` identical.
  - **Depends:** T-19, T-11 (auth tables), T-12. **Rollback:** delete seed script + seed/recovery tests + doc note.

---

### Phase 7 — Contract freeze and generated clients

### T-22 — OpenAPI export, generator pinning, drift check, generation docs (RED → GREEN)

- [x] Implement `scripts/export_openapi.py` writing `contracts/openapi.json`; pin the TypeScript and Dart-Dio generator versions; add the drift check (re-export + regenerate to temp dirs + fail on diff); write `docs/api-client-generation.md` (commands, no-hand-edit rule, contract-change workflow). The exported contract MUST describe cookie security (`cc_session`), `X-CSRF-Token` requirement, integer monetary response fields, name-only rename, stable error envelope, and server-derived role responses. <!-- sdd-owner: implementation -->
  - **Target:** `backend/scripts/export_openapi.py`, `contracts/openapi.json`, `web/package.json` + `mobile/pubspec.yaml` (pins), drift-check script, `docs/api-client-generation.md`.
  - **Spec refs:** `specs/api/spec.md` (OpenAPI contract and generated clients, AO-08).
  - **Design refs:** §"OpenAPI and generated-client workflow".
  - **TDD evidence:** RED drift test (export ≠ committed → fails) → GREEN export/drift → REFACTOR; re-export byte-stable; drift rerun clean.
  - **Depends:** T-20 (all routes exported), T-21. **Rollback:** delete `contracts/`, export/drift scripts, generation doc; API unchanged.

### T-23 — Generate TypeScript and Dart clients from the frozen contract

- [x] Run the pinned generators into `web/src/generated/api/` (TypeScript) and `mobile/lib/generated/api/` (Dart Dio) with generated headers, then verify both compile against the frozen contract; wire the generated web transport for `credentials: include` and the Dio cookie jar configuration at the adapter level (no hand-edits to generated files). <!-- sdd-owner: implementation -->
  - **Target:** `web/src/generated/api/`, `mobile/lib/generated/api/` (generated; snapshot identity, excluded from authored line count), consumer wiring stubs.
  - **Spec refs:** `specs/api/spec.md` (AO-08 contract parity); `specs/clients/spec.md` (generated clients).
  - **Design refs:** §"OpenAPI and generated-client workflow".
  - **TDD evidence:** web typecheck/build and `flutter analyze` pass against generated code; `git status` shows only generated additions.
  - **Depends:** T-22. **Rollback:** delete the two generated directories; regeneration from the frozen contract is always possible.

### T-CF — Contract freeze gate (parent-owned)

- [x] Verify and freeze the protected contract: `contracts/openapi.json` committed and drift-clean, TypeScript and Dart clients generated and compiling, auth/rename/error-envelope shapes frozen; record the freeze; any later wire-shape change requires an explicit export → regenerate → consumers/tests update cycle within its own task. Web and mobile Must (T-24..T-32) start only after this gate. <!-- sdd-owner: parent -->

---

### Phase 8 — Web Must (protected)

### T-24 — Web core: config, transport, query client, formatter, theme tokens (RED → GREEN → TRIANGULATE)

- [x] Implement `web/src/core/`: `config.ts` (VITE_API_BASE_URL, VITE_GROUP_ID as routing-only config), `http-client.ts` (credentials `include`, `X-CSRF-Token` from `cc_csrf` for POST/PATCH/DELETE, 401 → protected-state mapping), `query-client.ts` (group-scoped keys `['group'|'participants'|'expenses'|'balances'|'settlement', groupId]`), `cents-formatter.ts` (integer → `Bs. X,XXX.XX`, sign prefix, no rounding, string/int ops only), `theme.css` (design tokens only); formatter/transport tests red first: 0, 5, 99, 1000, 1234567, 160000 → `Bs. 1,600.00`, −16000 → `-Bs. 160.00`, CSRF header attached, no float math. <!-- sdd-owner: implementation -->
  - **Target:** `web/src/core/`, `web/tests/core/`.
  - **Spec refs:** `specs/money/spec.md` (display convention, formatter avoids floating point); `specs/clients/spec.md` (no client-side monetary authority).
  - **Design refs:** §"TanStack Query and protected-route rules", §"Visual tokens and accessibility".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (negative, zero, thousands) → REFACTOR; web test script → green.
  - **Depends:** T-23, T-CF. **Rollback:** delete `web/src/core/` + tests.

### T-25 — Web auth flow: session bootstrap, login, logout, protected routes (RED → GREEN)

- [x] Implement `web/src/app/auth/session-provider.tsx` (bootstrap `GET /auth/session` with credentials; 200 → authenticated with server role, 401 → signed-out/expired state), `web/src/app/routes/protected-route.tsx` (no group query, WS, or protected-looking shell before authentication), and `web/src/features/auth/` (login screen with visible labels, autocomplete, password visibility, loading/disabled submit, inline `invalid_credentials`; logout with cookie clear + state reset; session-expiry message routes to login); component tests red first: queries gated until authenticated, invalid credentials stay on the form, logout clears protected state, expiry shows explicit re-login message, no anonymous shell, role displayed from server response only. <!-- sdd-owner: implementation -->
  - **Target:** `web/src/app/auth/`, `web/src/app/routes/protected-route.tsx`, `web/src/features/auth/`, `web/tests/features/auth/`.
  - **Spec refs:** `specs/clients/spec.md` (protected session flow scenarios, server-derived role display); `specs/api/spec.md` (session surface).
  - **Design refs:** §"Login/logout/session identity flow", §"Protected web read", §"Client data and UX design".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (expired vs signed-out messaging, 401 mid-session) → REFACTOR; web test script → green.
  - **Depends:** T-24. **Rollback:** delete auth feature + session provider + tests.

### T-26 — Web group + participants features incl. rename (RED → GREEN)

- [x] Implement `web/src/features/group/` (name, owner, `settlementPolicy` display; policy update affordance shown by server role and rejected 403 surfaced inline) and `web/src/features/participants/` (stable-order list with archived status; add with inline `invalid_participant_name`/`duplicate_participant_name`; archive/reactivate; delete with `participant_in_use` guidance; **rename form**: name-only field, helper text "identity and balances remain stable", inline errors bound to the field with focus, no optimistic money change, refetch after success must show identical balances); component tests red first incl. no-state-change-on-invalid-submit and rename-refetch-identity. <!-- sdd-owner: implementation -->
  - **Target:** `web/src/features/group/`, `web/src/features/participants/`, `web/tests/features/participants/`.
  - **Spec refs:** `specs/participants/spec.md` (add/list CB-08, archive/reactivate, delete CB-09, rename CC-04, archived visibility CC-02); `specs/groups/spec.md` (policy scenarios); `specs/clients/spec.md` (validation/error states, rename interaction).
  - **Design refs:** §"TanStack Query and protected-route rules", §"Client data and UX design — Web".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (conflict with archived name, blank submit, forbidden policy action) → REFACTOR; web test script → green.
  - **Depends:** T-25. **Rollback:** delete group + participants features + tests.

### T-27 — Web expenses feature (RED → GREEN)

- [x] Implement `web/src/features/expenses/`: list/create/edit/delete through the generated client; new form defaults to all active participants only (archived excluded, CC-02); multiple contributor rows with decimal-string amounts; edit form merges referenced archived participants; field-bound errors (`invalid_amount`, `no_beneficiaries`, `no_participants`, `contribution_mismatch`, `invalid_participant_reference`) keep the form editable; no optimistic monetary display; invalid submit changes no state; mutations invalidate group query keys; component tests red first incl. CB-01 no-participants guidance and >2-decimals field error. <!-- sdd-owner: implementation -->
  - **Target:** `web/src/features/expenses/`, `web/tests/features/expenses/`.
  - **Spec refs:** `specs/expenses/spec.md` (creation validation, defaults, edit/delete atomicity); `specs/api/spec.md` (error binding); `specs/clients/spec.md` (validation/error states, no client money); `specs/participants/spec.md` (CC-02 form rules).
  - **Design refs:** §"Mutation and invalidation", §"Client data and UX design — Web".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (multi-contributor sums, archived-in-edit retention, invalid submit rollback) → REFACTOR; web test script → green.
  - **Depends:** T-26. **Rollback:** delete `features/expenses/` + tests.

### T-28 — Web balances, settlement, and WS invalidation refetch (RED → GREEN)

- [x] Implement `web/src/features/balances/` (stable order incl. referenced archived at `Bs. 0.00`, credit/debt via tokens + labels/icons not color alone, tabular figures), `web/src/features/settlement/` (`settled: true` → "everyone is settled" empty state; else ordered transfers), and `web/src/core/websocket.ts` (connect after authentication; on `data_changed` invalidate all five group keys; never parse a frame for money/role; REST authoritative at start and when WS is down); tests red first: DA-01 rendering, CB-13 all-settled state, refetch-on-invalidation, WS-frame-no-money, WS-down refresh works. <!-- sdd-owner: implementation -->
  - **Target:** `web/src/features/balances/`, `web/src/features/settlement/`, `web/src/core/websocket.ts`, `web/tests/features/balances/`, `web/tests/features/settlement/`.
  - **Spec refs:** `specs/clients/spec.md` (invalidation-driven refetch, empty states, CC-02 archived-zero rendering); `specs/api/spec.md` (WS invalidation-only); `specs/settlement/spec.md` (CB-13).
  - **Design refs:** §"Protected web read", §"Mutation and invalidation", §"TanStack Query rules".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (zero-balance archived row, settled empty, WS outage) → REFACTOR; web test script → green.
  - **Depends:** T-27. **Rollback:** delete balances/settlement features + `core/websocket.ts` + tests; REST flow unaffected.

---

### Phase 9 — Mobile Must (protected read-mostly)

### T-29 — Mobile core: config, secure cookie store, formatter, tokens, read models (RED → GREEN → TRIANGULATE)

- [x] Implement `mobile/lib/core/`: `config/` (dart-defines API_BASE_URL/GROUP_ID), `auth/secure_cookie_store.dart` (encrypted `flutter_secure_storage` adapter for the session/CSRF cookie jar; presentation never sees raw values), `formatters/cents_formatter.dart` (Dart int cents → `Bs. X,XXX.XX`, integer ops only), `theme/tokens.dart` (design-token mirrors), and `domain/read_models/` mapping generated DTOs; formatter/store tests red first (0, 5, 99, 1000, 1234567, negatives; store round trip + secrecy boundary). <!-- sdd-owner: implementation -->
  - **Target:** `mobile/lib/core/`, `mobile/lib/domain/read_models/`, `mobile/test/core/`.
  - **Spec refs:** `specs/money/spec.md` (display convention); `specs/clients/spec.md` (no client-side monetary authority, protected mobile).
  - **Design refs:** §"Flutter Dio/Cubit rules", §"Visual tokens and accessibility".
  - **TDD evidence:** RED → GREEN → TRIANGULATE → REFACTOR; `flutter test` → green.
  - **Depends:** T-23, T-CF. **Rollback:** delete `mobile/lib/core/`, `domain/read_models/` + tests.

### T-30 — Mobile session: Dio interceptors, auth repository, SessionCubit (RED → GREEN)

- [x] Implement `mobile/lib/data/auth/auth_repository.dart` (login/logout/session via generated operations), Dio cookie manager + interceptors (attach cookies, `X-CSRF-Token` for unsafe verbs, map a single 401 → signed-out/expired, clear the secure jar, no retry loop), and `presentation/auth/session_cubit.dart` (states `unknown`, `signedOut`, `authenticating`, `authenticated`, `sessionExpired`; exposes server-derived role for display only); tests red first: five-state transitions, 401 mapping, jar clear, no retry loop. <!-- sdd-owner: implementation -->
  - **Target:** `mobile/lib/data/auth/`, `mobile/lib/presentation/auth/session_cubit.dart`, `mobile/test/data/auth/`, `mobile/test/presentation/auth/`.
  - **Spec refs:** `specs/clients/spec.md` (mobile protected session flow, role display); `specs/api/spec.md` (session surface).
  - **Design refs:** §"Protected mobile read", §"Flutter Dio/Cubit rules".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (expired vs revoked, mid-session 401, interceptor ordering) → REFACTOR; `flutter test` → green.
  - **Depends:** T-29. **Rollback:** delete auth repository/interceptors/session cubit + tests.

### T-31 — Mobile read repositories, WS listener, read Cubits (RED → GREEN)

- [x] Implement `mobile/lib/data/repositories/` (group, participants incl. archived + renamed names, expense history, balances, settlement — repositories are the only layer calling generated operations), `mobile/lib/data/websocket/` (`data_changed` → Cubit reload; never reads money/roles from the frame; WS down → REST works), and read Cubits with loading/loaded/empty/error/corruption-recovery states; tests red first: DTO→read-model mapping, state transitions, refetch-on-invalidation, startup REST load. <!-- sdd-owner: implementation -->
  - **Target:** `mobile/lib/data/`, `mobile/lib/presentation/**/cubit/`, `mobile/test/data/`, `mobile/test/presentation/`.
  - **Spec refs:** `specs/clients/spec.md` (mobile read-mostly parity, invalidation-driven refetch); `specs/api/spec.md` (WS invalidation-only).
  - **Design refs:** §"Protected mobile read", §"Flutter Dio/Cubit rules".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (empty, error, recovery, WS outage) → REFACTOR; `flutter test` → green.
  - **Depends:** T-30. **Rollback:** delete `mobile/lib/data/` + Cubits + tests.

### T-32 — Mobile read-mostly views (RED → GREEN)

- [x] Implement read-only screens for group/policy, participants (archived status + current renamed names from server), expense history, balances, and settlement with the shared formatter; empty states (no participants → add-first guidance; all-settled → "everyone is settled"); error/recovery states; NO expense create/edit/delete controls and no misleading write affordances in Must; widget tests red first: DA-01 rendering, CB-13 state, archived-zero `Bs. 0.00` rendering, no-write-control assertion. <!-- sdd-owner: implementation -->
  - **Target:** `mobile/lib/presentation/` (group, participants, expenses, balances, settlement), `mobile/test/presentation/`.
  - **Spec refs:** `specs/clients/spec.md` (mobile read-mostly parity, empty/error states, no misleading controls); `specs/participants/spec.md` (CC-02 archived visibility); `specs/settlement/spec.md` (CB-13).
  - **Design refs:** §"Flutter Dio/Cubit rules", §"Client architecture — Mobile".
  - **TDD evidence:** RED → GREEN → TRIANGULATE (renamed + archived names, zero rows, settled empty) → REFACTOR; `flutter test` → green.
  - **Depends:** T-31. **Rollback:** delete mobile read-mostly views + widget tests.

---

### Phase 10 — Acceptance, demo, and handoff

### T-33 — Acceptance DA-01..DA-05 through the protected API (RED → GREEN)

- [x] Write `backend/tests/acceptance/` named DA-01..DA-05 against the seeded integration environment (seeded owner/member login first), asserting exact expectations: `test_da_01_samaipata.py` (balances +56000/0/−16000/−40000 and transfers Diego→Ana 40000 then Carla→Ana 16000); `test_da_02_residual.py` (3334/3333/3333, zero sum); `test_da_03_exclusion.py` (30000 among three of four, Diego owed 0); `test_da_04_settled.py` (`settled: true`, empty transfers); `test_da_05_persistence.py` (refresh/restart returns identical source, renamed names, policy, balances, settlement). <!-- sdd-owner: implementation -->
  - **Target:** `backend/tests/acceptance/test_da_01_samaipata.py`, `test_da_02_residual.py`, `test_da_03_exclusion.py`, `test_da_04_settled.py`, `test_da_05_persistence.py`.
  - **Spec refs:** `specs/demo-readiness/spec.md` (DA-01..DA-05 evidence requirement); `specs/settlement/spec.md` (DA-01..DA-04 scenarios); `specs/persistence/spec.md` (DA-05).
  - **Design refs:** §"Acceptance datasets".
  - **TDD evidence:** RED → GREEN (runs against API + seed, not pure functions) → REFACTOR; `pytest backend/tests/acceptance -q` → all pass; suite run twice → identical.
  - **Depends:** T-21 (seed/API), T-CF. **Rollback:** delete the five acceptance files; no product impact.

### T-34 — Acceptance DA-06 (auth/roles) and DA-07 (rename) (RED → GREEN)

- [x] Write `backend/tests/acceptance/test_da_06_auth.py`: owner+member login roles, invalid credentials rejected, protected reads/mutations without a session rejected (401 envelopes), logout invalidates, `owner_only` member policy change rejected 403 and `any_member` member change permitted; and `test_da_07_rename.py`: renaming Ana preserves her ID, expense references, archived status, `+56000` balance, settlement, and monetary source rows; blank and normalized-conflict renames rejected without state change; archived participant rename is name-only. <!-- sdd-owner: implementation -->
  - **Target:** `backend/tests/acceptance/test_da_06_auth.py`, `backend/tests/acceptance/test_da_07_rename.py`.
  - **Spec refs:** `specs/demo-readiness/spec.md` (auth and rename acceptance evidence); `specs/groups/spec.md` (role/policy scenarios); `specs/participants/spec.md` (CC-04 scenarios).
  - **Design refs:** §"Acceptance datasets DA-06/DA-07", §"Confirmed decision evidence CC-03/CC-04".
  - **TDD evidence:** RED → GREEN → REFACTOR; `pytest backend/tests/acceptance -q` → green; DA-07 compares database keys and API payloads before/after.
  - **Depends:** T-33. **Rollback:** delete the two acceptance files.

### T-35 — Demo walkthrough, fresh-environment rehearsal, AO-01..AO-11 evidence (RED → GREEN)

- [x] Write `docs/demo-samaipata.md`: under-three-minute scripted protected walkthrough — seeded login (owner or member) → participants → record one additional expense → balances + settlement → refresh (identical derived results) → logout (old session rejected); rehearse on a fresh environment (docker down/up → migrate → seed → backend → web); capture handoff evidence: AO-01..AO-11 evidence mapping below, drift check rerun, seed idempotency rerun, responsive/a11y checks (375px/tablet/desktop, keyboard/screen-reader, reduced motion, 44×44px targets, aria-live error announcements). <!-- sdd-owner: implementation -->
  - **Target:** `docs/demo-samaipata.md`, handoff evidence section, reruns of T-22 drift check and T-21 idempotency.
  - **Spec refs:** `specs/demo-readiness/spec.md` (under-three-minute flow AO-09); `specs/clients/spec.md` (warm presentation, accessibility).
  - **Design refs:** §"Acceptance and evidence mapping", §"Seed, migrations, and recovery".
  - **TDD evidence:** timed rehearsal transcript ≤ 3:00; post-refresh payloads byte-identical; drift + idempotency green; AO evidence rows below all satisfied.
  - **Depends:** T-34 (and T-26/28 web features, T-32 mobile views for parity spot-checks). **Rollback:** delete demo doc/evidence; product unchanged.

    **AO evidence mapping (evidenced in T-33..T-35):** AO-01 → DA-01 + protected web render; AO-02 → DA-02 + formatter tests (T-24/T-29); AO-03 → T-06/T-14 multi-contributor + mismatch tests; AO-04 → T-13/T-34 rename/archive/delete tests; AO-05 → T-14 expense atomicity tests; AO-06 → T-17..T-19 + T-25/T-27 error-state tests; AO-07 → DA-05 + session refresh/logout (T-17/T-33) + recovery (T-21); AO-08 → T-22/T-23 drift + generated clients + WS frame tests (T-20); AO-09 → T-21 seed + T-35 timed walkthrough; AO-10 → DA-06 + T-10/T-15 matrix tests + web/mobile role display tests; AO-11 → CC-02 tests (T-07/T-13/T-19/T-28/T-32) for archived-zero visibility, defaults, and edit retention.

### T-MG — Must completion gate (parent-owned)

- [x] Execute the Must gate: all protected/authenticated Must outcomes green — DA-01..DA-07 (T-33/T-34), AO-01..AO-11 evidence complete (T-35), contract drift clean, seed idempotent, demo walkthrough ≤3:00 with logout invalidation demonstrated; Stretch (T-36..T-38) is NOT allowed before this gate passes; no Stretch may weaken protected sessions, role enforcement, cents correctness, rename safety, or generated-contract parity. <!-- sdd-owner: parent -->

---

## Stretch (only after the Must gate T-MG)

### T-36 — STRETCH: mobile expense write parity (RED → GREEN)

- [x] ~~Add create/edit/delete flows in the mobile client through the generated Dart client with the decimal-string money boundary identical to web, same field-bound error states, no client-side money math; widget/unit tests red first; rollback: remove the write controls + tests, keep read views.~~ **DECLINED (user decision 2026-08-31): change closed without Stretch after T-MG passed; documented as optional future work.** <!-- sdd-owner: implementation -->
  - **Spec refs:** `specs/expenses/spec.md`, `specs/clients/spec.md` (write parity is Stretch). **Depends:** T-32, T-MG.

### T-37 — STRETCH: richer group-settings experience (RED → GREEN)

- [x] ~~Extend group settings UI beyond the required policy control only if instructor-requested; tests red first; rollback: remove the extra settings surface only.~~ **DECLINED (user decision 2026-08-31): change closed without Stretch after T-MG passed; documented as optional future work.** <!-- sdd-owner: implementation -->
  - **Spec refs:** `specs/groups/spec.md`, `specs/clients/spec.md`. **Depends:** T-26, T-MG.

### T-38 — STRETCH: global minimum-transfer optimization (RED → GREEN)

- [x] ~~Add an optional optimization behind the deterministic greedy default (never replacing it, never weakening cents correctness); property tests compare transfer totals; rollback: remove the optional algorithm + tests.~~ **DECLINED (user decision 2026-08-31): change closed without Stretch after T-MG passed; documented as optional future work.** <!-- sdd-owner: implementation -->
  - **Spec refs:** `specs/settlement/spec.md` (min-transfer is Stretch). **Depends:** T-08, T-MG.

---

## Post-apply review gates (parent-owned)

- [x] ~~Start or reuse bounded review per PR slice (PR 1..PR 22); do not merge a slice without its review receipt; normalized candidate per slice; concrete per-slice evidence recorded (focus test command + result; runtime scenario + result or explicit `N/A`).~~ **CLOSED 2026-08-31: all 30 slices were settled through the native SDD attempt ledger with per-slice evidence (tests/ruff/pyright) recorded in apply-progress; the repository has no commits and no merge/delivery ever occurred, so no delivery gate or review receipt was required. Per-slice bounded review remains due at real delivery time.** <!-- sdd-owner: parent -->
- [x] ~~Confirm after each apply batch that no confirmation gate was re-opened silently (CC-01..CC-04 remain as recorded in T-00) and that no unauthenticated or anonymous path was introduced; then hand off to `sdd-verify` and `sdd-archive` with the T-35 evidence.~~ **CONFIRMED 2026-08-31: CC-01..CC-04 remain as recorded in T-00 (Engram obs 2587); protected routes assert 401 envelopes for anonymous access (DA-06); no client-side money/role authority; Stretch declined by user decision. Handoff to sdd-verify + sdd-archive carries the T-35 evidence.** <!-- sdd-owner: parent -->

---

## Explicit non-goals (unchanged by reconciliation)

Public registration, self-service account creation, password recovery, invitations, external OAuth, and broader account management; multi-group UI/discovery/creation/switcher; multiple currencies or custom unequal splits; OCR, categories, notifications, payments, bank/wallet integrations, settlement-paid tracking; advanced analytics or globally optimized minimum transfers (Stretch only); persisted balance/transfer/split ledgers; client-side money or role authority; anonymous or unauthenticated access to group data; mobile expense writes before T-MG; participant merging, ID replacement, reassignment, or historical name snapshots.

## Planning decisions (recorded)

- CC-01..CC-04 are completed product decisions (evidence: Engram obs `2587`); this plan contains no gate-resolution or superseded non-goal language (TrustedOwnerActor/anonymous access removed).
- Auth and rename are Must: minimum seeded accounts, Argon2id, opaque DB-backed sessions, cookies/CSRF/origin, expiry/revocation, server-derived roles, group isolation, explicit policy matrix, and name-only atomic rename all ship inside protected Must PRs before client work.
- One work unit per task/commit: tests with behavior, docs with workflow; no file-type-driven commits; generated files excluded from authored counts but part of snapshot identity.
- Must-first: hard gate T-CF (contract freeze) before client Must and hard gate T-MG (Must completion) before Stretch; web/mobile parallelize only after T-CF.
- Delivery reconciliation (2026-08-26, continued): the user confirmed all seven potential over-600 slices are eligible for explicit `size:exception`: PR 9, PR 12, PR 15, PR 17, PR 19, PR 20, and PR 22. Historical PR 1–8 remain unchanged; the remaining plan is exactly 14 stacked-to-main slices, PR 9–22, with `delivery_strategy: exception-ok` and the 600 authored-line review budget. An exception is never automatic: native line accounting must show actual work above 600 and the parent must record it before runtime-bearing apply.
- Migration/source-persistence and participant work is intentionally combined in PR 9; OpenAPI export/generation/drift freeze is combined in PR 14. Generated snapshots remain excluded from authored counts but part of complete snapshot identity; neither boundary bypasses the explicit exception rule.
- `openspec/config.yaml` now records `exception-ok`; artifact store, auto mode, `stacked-to-main`, 600-line budget, strict TDD, stack, and policy values remain unchanged. `openspec/project-context.md` records the same explicit remaining-plan decision while preserving the existing context and testing data.
