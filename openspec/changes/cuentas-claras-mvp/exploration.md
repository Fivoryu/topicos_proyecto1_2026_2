# Exploration: Cuentas Claras / Amigo Duradero MVP

Source: `docs/requerimiento-docente.md` (baseline, v1.0) + `openspec/project-context.md` (approved architecture decisions). This exploration maps the approved initiative onto the smallest coherent MVP and the next SDD phases. It changes no product code and does not modify the baseline document.

## Summary

| Topic | Finding |
| ------- | --------- |
| Problem | Groups traveling together cannot reliably track who paid what, what each person owed, and who must pay whom to settle. |
| Product | One group, participants, equal-split expenses (multiple contributors allowed), balances, deterministic settlement transfers, persistence, validation, demo data. |
| MVP core | Backend is the single source of monetary truth (FastAPI + PostgreSQL); web and mobile are OpenAPI-generated clients that display server-derived results. |
| Biggest delta vs baseline doc | Baseline §13.1 proposed React-only + Zustand + localStorage. Approved decisions supersede it: full-stack FastAPI/PostgreSQL + React + Flutter, WebSocket as invalidation-only. |
| Next phase | `sdd-propose` — resolve the 7 open decisions listed below, then fix Must/Stretch and slice boundaries. |

## 1. User and problem framing

- **Primary user**: a trip/group member (e.g., Ana) who wants to know "how are we left?" without spreadsheet math.
- **Secondary user**: the group owner who keeps the group's data coherent.
- **Core job**: record who paid what → derive each member's balance → produce a clear transfer list so everyone ends even.
- **Acceptance scenario (non-negotiable)**: Samaipata — Ana 960, Beto 400, Carla 240, Diego 0; expected balances +560 / 0 / -160 / -400 and transfers Diego→Ana 400, Carla→Ana 160.
- **Demo constraint**: the full flow must be demonstrable in under 3 minutes, including a page refresh (persistence proof).

## 2. Must vs Stretch boundaries

**Must (MVP)** — derived from FM-01..09 / RF-01..10 and approved decisions:

- One active group with one owner (group entity exists in the data model).
- Participants: add, list, archive/protect referenced ones; unique normalized names.
- Expenses: create, edit, delete; description, amount > 0, contributors (one or more), equal split among selected beneficiaries; all participants selected by default.
- Balances: per-participant, sum exactly 0 cents after every mutation.
- Settlement: deterministic greedy transfer list (debtors → creditors), derived, never stored.
- Persistence: PostgreSQL via server; survives refresh (and is device-independent).
- Validation and clear error messages for every invalid case in the baseline edge-case table.
- Monetary correctness: integer cents everywhere; FastAPI performs all money math.
- Realistic demo history (Samaipata seed, idempotent).
- Automated tests: domain math + API + acceptance datasets DA-01..DA-05.
- OpenAPI contract with generated web and mobile clients.

**Stretch / explicitly out of MVP** (approved non-goals, do not reopen):

- Authentication, invitations, cloud collaboration, real-time editing, multiple currencies, custom splits (percentages/weights), OCR, payments/bank integration, settlement-paid tracking, advanced analytics.
- Global minimum-transfer optimization: the deterministic greedy settlement is the Must; optimization is a documented future idea.
- WebSocket as a source of truth: it only invalidates/refetches REST.

## 3. Business rules (approved; carry into spec unchanged)

| ID | Rule |
| ---- | ------ |
| BR-01 | All money is integer cents. No float money logic anywhere, including client-side formatting. |
| BR-02 | Expense amount > 0 cents; at most 2 decimal places at input. |
| BR-03 | Exactly ≥ 1 contributor and ≥ 1 beneficiary; contributors and beneficiaries are existing participants of the group. |
| BR-04 | All participants selected by default in the expense form; exclusion allowed. |
| BR-05 | Equal split of the total among beneficiaries in whole cents. |
| BR-06 | Residual cents: payer absorbs when payer is a beneficiary; otherwise distribute deterministically from the first selected beneficiary in stable order. |
| BR-07 | Balance = paid − owed share. Positive = creditor, negative = debtor. |
| BR-08 | Sum of balances = exactly 0 cents after every create/edit/delete. |
| BR-09 | Settlement derived from current balances only; never stored as truth. |
| BR-10 | Referenced participants are archived, never hard-deleted; unreferenced deletion policy to be fixed in spec. |
| BR-11 | Duplicate names rejected after normalize (trim + case-insensitive). |
| BR-12 | One owner per group; settlement trigger policy is `owner_only` or `any_member` — **unresolved, proposal decides** (see §5). |

## 4. Data and flow implications of the approved stack

### 4.1 Entities (data model direction, not final)

| Entity | Fields (direction) | Notes |
| -------- | -------------------- | ------- |
| Group | id, name, owner_participant_id, created_at | One active group for MVP UI; model supports group_id from day one. |
| Participant | id, group_id, name, archived_at (nullable), created_at | Archive instead of delete when referenced. |
| Expense | id, group_id, description, amount_cents, created_at, updated_at | amount_cents is authoritative on the backend. |
| ExpenseContribution | expense_id, participant_id, amount_cents | Supports multiple contributors (payer set); contributions sum to amount_cents. |
| ExpenseBeneficiary | expense_id, participant_id | Split set; at least one. |
| Balance / Transfer | derived server-side, not persisted | FastAPI computes on read. |

### 4.2 API surface (direction)

- `POST/GET /groups`, `GET /groups/{id}` (seed or create one group)
- `POST/GET /groups/{id}/participants`, `PATCH .../participants/{pid}` (archive)
- `POST/GET/PATCH/DELETE /groups/{id}/expenses`
- `GET /groups/{id}/balances`, `GET /groups/{id}/settlement`
- OpenAPI → generated TS (web) and Dart (mobile) clients.
- WebSocket channel per group: server pushes `data_changed` → clients invalidate + refetch REST. No monetary payload over WS.

### 4.3 Flow

1. Client mutation (REST) → FastAPI validates and recomputes derived data → persists → WS invalidation → all clients refetch.
2. Money enters as string/decimal at the edge, is converted to cents in FastAPI, returns as `amount_cents` int. Clients format cents → `Bs. X,YZ` in a single shared formatter per client (no float).
3. Demo seed: idempotent migration/seed script that loads the Samaipata dataset and matches DA-01..DA-05.

### 4.4 Testing implications (strict TDD, runner pending)

- Backend: pytest (domain pure functions: split, residual, balances, settlement) + FastAPI TestClient for API contract tests against a test database.
- Web: Vitest + Testing Library; money formatter and query-layer tests.
- Mobile: `flutter test` on Cubit/state logic.
- Runner detection must be refreshed after stack bootstrap (`sdd-init` re-run).

## 5. Unresolved decisions for the proposal (do NOT decide here)

| # | Decision | Options | Why it matters |
| --- | ---------- | --------- | ---------------- |
| D-01 | Settlement policy | `owner_only` vs `any_member` (approved to resolve in proposal/spec) | Determines API authorization on settlement view/trigger; affects mobile parity. |
| D-02 | Group scope in MVP | (a) single seeded group, no group UI; (b) minimal group CRUD | (a) smallest slice for 48h budget; (b) matches multi-group data model. Baseline OQ-01 said "one active trip"; approved decisions introduce groups with owners — needs explicit scope call. |
| D-03 | Residual rule with multiple contributors | (a) first contributor in stable order absorbs; (b) contributors absorb in order round-robin | BR-06 defines "the payer" — ambiguous when several contributors exist. Spec must fix a deterministic rule. |
| D-04 | Archive semantics | (a) archived participants hidden from new expense forms but kept in history/balances; (b) hidden everywhere except admin | Affects balances display, form default-selection, and settlement correctness for historical expenses. |
| D-05 | Mutation authorization | Any member may create/edit/delete expenses vs owner-only writes | No auth in MVP, but "owner" exists; a policy keeps the demo honest. |
| D-06 | Participant name editing | Allowed vs disallowed in MVP | Baseline defines add + protected delete but not rename; renames ripple through historical expenses. |
| D-07 | Currency representation | Hardcoded `Bs.` symbol + fixed "boliviano" assumption vs configurable single currency | Approved: multiple currencies out. Spec should state the single-currency display convention. |

## 6. Risks

| Risk | Severity | Mitigation |
| ------ | ---------- | ------------ |
| 48h / 3 specialists / ~20h each is tight with two clients + backend | High | FastAPI owns all money logic; clients are generated and thin; slice order: backend → web → mobile; mobile may ship read-mostly parity in the first pass. |
| Float creep in TS/Dart formatting | High | Cents-only API; one formatter per client; formatter unit tests; never `Number` math on money. |
| Residual-cent ambiguity with contributors (D-03) | Medium | Decide in spec with a test case; extend DA-02 to a multi-contributor example. |
| OpenAPI client drift vs backend changes | Medium | Contract-first workflow: change OpenAPI → regenerate → implement. Keep generation commands in AGENTS.md. |
| PostgreSQL availability at demo time | Medium | Docker Compose for local DB; seed idempotent; demo script documented. |
| Strict TDD with no runner discovered yet | Medium | Bootstrap test harness (pytest) before first feature task; re-run `sdd-init` discovery after stack setup. |
| Scope creep from the 26-section baseline | Medium | Proposal fixes the Must list; anything outside it requires spec update first (baseline §22 rule). |
| WS invalidation complexity | Low | Single channel per group; server push is a hint, REST is truth. |

## 7. Smallest coherent MVP slice

Ordered dependency chain (each step independently demonstrable):

1. **S-1 Backend domain**: group/participant/expense models, cents split + residual rule, balances, greedy settlement, validation; pytest coverage incl. DA-01..DA-05. (FastAPI is monetary authority — this is the critical path.)
2. **S-2 API + persistence**: REST endpoints, Alembic migrations, PostgreSQL, OpenAPI schema, seed script (Samaipata), WS invalidation stub.
3. **S-3 Web client**: generated TS client; participants/expenses/balances/settlement views; TanStack Query invalidation; Tailwind; Vitest.
4. **S-4 Mobile client**: generated Dart client; Cubit states; read-mostly parity, expenses create/edit for demo.
5. **S-5 Demo readiness**: 3-minute script, seed verification, refresh-persistence demo, acceptance walkthrough.

Parallelization note: S-3 and S-4 can run in parallel once the OpenAPI contract from S-2 is frozen. D-01..D-07 must be resolved at proposal/spec time because several change the API surface (authorization, group endpoints, archive behavior).

## Checklist

- [x] Baseline document read and mapped; approved decisions used as constraints, not reopened.
- [x] Must vs Stretch boundaries stated; non-goals listed verbatim from approved context.
- [x] Business rules carried forward from baseline §8–§9 into BR-01..BR-12.
- [x] Data model and API/flow implications derived from the approved full-stack stack.
- [x] Unresolved decisions isolated (D-01..D-07) for proposal, with the two explicitly deferred items (settlement policy, group scope) surfaced.
- [x] Risks rated and mitigated.
- [x] Smallest MVP slice defined with a dependency chain and parallelization note.
- [ ] (next) Proposal resolves D-01..D-07 and freezes scope before specs.

## Next step

Run `sdd-propose` for `cuentas-claras-mvp` with D-01..D-07 as the question list; the proposal must freeze the Must list, group scope, settlement policy, archive semantics, and residual rule for contributors before `sdd-spec`.
