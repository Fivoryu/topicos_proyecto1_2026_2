# Project Context: Cuentas Claras / Amigo Duradero

## Product and delivery target

Cuentas Claras is the group-expense application for the Tópicos programming course. The official Grupo 2 delivery and its under-three-minute Samaipata demonstration are web-centered. The protected FastAPI/PostgreSQL backend is the source of authorization, persistence, monetary results, and settlement. A Flutter/Android client also exists as an independently governed extension under `openspec/changes/mobile-domain-features/`; it is not required to run the official web demo.

## Current source-of-truth precedence

When artifacts disagree, use this order:

1. The official assignment/instructor baseline is the preserved statement of the evaluated problem and required scenario.
2. Dated OpenSpec proposals, explorations, checkpoint decisions, apply/verify reports, and `docs/requerimiento-docente.md` are historical decision evidence; they are not automatically current implementation guidance.
3. This project context plus the specs of each currently active OpenSpec change define accepted current scope.
4. Landed implementation, the exported OpenAPI contract, generated-client drift checks, and passing verification commands are conformance evidence.

Never silently rewrite historical artifacts to make them look current. Add an explicit supersession/status map instead. See `docs/sdd-evolution.md`.

## Delivered architecture baseline

- Backend: FastAPI/Python, PostgreSQL, SQLAlchemy, Alembic.
- Web: React, Vite, TanStack Query, Tailwind/CSS.
- Mobile extension: Flutter, Bloc/Cubit, Dio; current domain work remains owned by `mobile-domain-features`.
- FastAPI is the authorization and monetary authority.
- PostgreSQL is the durable store for protected group/session/source data; `localStorage` is not the data authority.
- Authentication is part of the delivered MVP: seeded owner/member accounts, opaque database-backed sessions, login/logout, CSRF/origin checks, and server-derived roles.
- OpenAPI defines client contracts. Generated TypeScript and Dart clients are never hand-edited.
- WebSocket is invalidation-only: clients receive `{"type":"data_changed"}` and refetch authoritative REST data.
- Successful group-policy, participant, and expense mutations already publish the shared group-scoped invalidation after commit. That behavior is owned by `wire-mutation-websocket-invalidation` and must not be reimplemented by final-delivery work.

## Independent change ownership

- `cuentas-claras-mvp`: completed implementation history and the main reconciled MVP decisions; keep its artifacts intact.
- `wire-mutation-websocket-invalidation`: implementation is landed and backend tests are green; its verification report records a strict-TDD evidence-format blocker before archive. Final-delivery treats it as a regression gate, not as implementation scope.
- `mobile-domain-features`: active, independently governed Flutter/Android domain work with substantial landed implementation and remaining acceptance/tasks. Final-delivery may describe/link its current status but does not implement, accept, revert, or archive it.
- `final-delivery-alignment`: web-centered handoff alignment: current guidance, official four-expense fixture, Spanish web presentation, setup/demo documentation, and delivery verification.

## Confirmed domain decisions

- **CC-01 — multi-contributor residual:** the complete residual goes to the first stable-creation-order participant in contributor∩beneficiary; if empty, to the first selected beneficiary in stable order. No entry-order or round-robin distribution.
- **CC-02 — archived zero visibility:** referenced archived participants stay visible in balances/history, including zero balances; they are excluded from new-expense defaults and retained in referencing edit forms.
- **CC-03 — minimum authentication is Must:** seeded demo owner/member accounts, login, logout, protected sessions, and server-derived `owner`/`member` roles. No public registration, recovery, invitations, or OAuth.
- **CC-04 — participant rename is Must:** name-only atomic rename preserves participant ID, historical references, and monetary results, with trim + case-insensitive normalized-name uniqueness.

## Monetary and persistence invariants

- Store and calculate money as integer cents; never use floating point for domain money.
- Derived balances must sum to exactly zero cents.
- Equal-split residual behavior is deterministic per CC-01.
- Expenses may have multiple contributors; submitted contribution totals are validated by the server.
- Settlement transfers are server-derived and deterministic; clients only render them.
- Referenced participants are archived/protected from deletion; never-used participants may be deleted.
- One group owner; participants are domain records, not login accounts.
- Refresh persistence comes from PostgreSQL and the protected server session, not client-side durable state.

## Official Samaipata delivery fixture

All four participants benefit from all four expenses:

1. Ana — Cabaña — `80000` cents.
2. Ana — Entradas a El Fuerte — `16000` cents.
3. Beto — Cena — `40000` cents.
4. Carla — Gasolina — `24000` cents.

Expected balances: Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`. Expected ordered transfers: Diego → Ana `40000`, then Carla → Ana `16000`.

## Constraints and non-goals

- Preserve `docs/requerimiento-docente.md` as historical baseline evidence.
- Do not absorb work owned by another OpenSpec change.
- Do not revive discarded Stretch work solely because generated code contains TODO markers.
- Public registration, password recovery, invitations, external OAuth, multiple currencies, custom splits, OCR, payments, and advanced analytics remain outside the final-delivery scope.
- Do not redesign the web UI during delivery polish; change presentation copy/formatting only as required.
- Do not change API schemas or regenerate clients unless a real handwritten contract change requires it.

## Spec-Driven Development rule

Accepted understanding changes **specs before product code**. For a behavior change: inspect current state → update/validate proposal/spec/design/tasks → add or update acceptance/tests → implement the smallest change → run focused and full regression gates → only then sync/archive the OpenSpec change. A task is complete only when its specified behavior and verification are complete.

## Verification commands

Run from the repository root unless noted:

```bash
python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q
python -m pytest backend/tests -q
python -m ruff check backend
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
python -m backend.scripts.check_contract_drift --cwd .
```

The mobile extension has its own independent gate:

```bash
cd mobile && flutter test --no-pub
```

OpenSpec lifecycle checks for final delivery:

```bash
openspec validate final-delivery-alignment --strict
openspec status --change final-delivery-alignment
```
