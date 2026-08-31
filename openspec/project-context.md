# Project Context: Cuentas Claras / Amigo Duradero

## Product

Finance-friendly group expense app for the Tópicos programming course. MVP supports one active trip/group, participants, equal-split expenses, balances, deterministic settlement transfers, validation, and persistence. Delivery priority is Must before Stretch.

## Approved architecture baseline

- Backend: FastAPI/Python, PostgreSQL, SQLAlchemy, Alembic.
- Web: React, Vite, TanStack Query, Tailwind.
- Mobile: Flutter, Bloc/Cubit, Dio.
- FastAPI is the monetary authority.
- OpenAPI generates clients.
- WebSocket only invalidates/refetches REST; it is not a second source of monetary truth.

## Confirmed checkpoint decisions (T-00, recorded in Engram observation 2587)

- **CC-01 — multi-contributor residual:** the complete residual goes to the first stable-creation-order participant in contributor∩beneficiary; if empty, to the first selected beneficiary in stable order. No entry-order or round-robin distribution.
- **CC-02 — archived zero visibility:** referenced archived participants stay visible in balances and history, including `Bs. 0.00`; they are excluded from new-expense defaults and retained in referencing edit forms.
- **CC-03 — minimum authentication is Must:** pre-seeded demo owner/member accounts, login, logout, protected sessions, and server-derived `owner`/`member` roles. No public registration, recovery, invitations, or OAuth.
- **CC-04 — participant rename is Must:** name-only atomic rename that preserves the participant ID, all historical references, and all monetary results, with trim + case-insensitive normalized-name uniqueness.

## Domain decisions

- Store monetary values as integer cents; never use floating-point money logic.
- Equal split with deterministic residual per CC-01.
- Expenses support multiple contributors whose contributions sum exactly to the expense amount.
- Referenced participants are archived/protected from deletion; never-used participants may be deleted (CC-02 visibility rules apply).
- Settlement policy (`owner_only` default, `any_member` optional) is persisted per group; policy changes follow the explicit owner/member operation matrix (owner-sensitive under `owner_only`; either role under `any_member`).
- Sessions are opaque, database-backed, cookie-transported (`cc_session` HttpOnly + `cc_csrf` CSRF/origin boundary), with fixed expiry and explicit revocation.
- One group owner; participants are group records, not login accounts.
- Include realistic demo history plus the minimum demo accounts.
- Must-before-Stretch delivery.

## Constraints and non-goals

- Do not implement product code during initialization.
- Preserve `docs/requerimiento-docente.md` unchanged.
- Public registration, password recovery, invitations, external OAuth, cloud collaboration, multiple currencies, custom splits, OCR, payments, and advanced analytics remain outside the MVP as specified in the reconciled proposal. Minimum seeded-account authentication (CC-03) and name-only participant rename (CC-04) are confirmed MVP scope, not non-goals.

## SDD session configuration

- Artifact store: both (OpenSpec + Engram)
- Execution mode: auto
- Delivery strategy: exception-ok
- Remaining-plan size-exception decision: the user explicitly selected `exception-ok`; PRs 9, 12, 15, 17, 19, 20, and 22 are eligible only when native line accounting shows actual authored work above 600 lines.
- Review budget: 600 changed lines
- Strict TDD: enabled by session policy; repository test runners are detected and recorded in `openspec/config.yaml`.

## Testing discovery

Testing discovery was re-run after the T-01 backend, T-02 web, and T-03 mobile bootstrap. All three repository test entry points are now detected and passed once from the checkout root:

| Area | Detected runner and version | Repository command | T-04 result |
| --- | --- | --- | --- |
| Backend | pytest 9.1.1 on Python 3.14.6 (`backend/pyproject.toml`) | `python -m pytest backend/tests -q` | 10 passed |
| Web | `npm` test script invoking Vitest 3.0.5 on Node v22.23.0 (`web/package.json`) | `npm --prefix web run test` | 1 file, 2 tests passed |
| Mobile | Flutter test runner from Flutter 3.41.8 / Dart 3.11.5 (`mobile/pubspec.yaml`) | `cd mobile && flutter test --no-pub` | 5 tests passed |

### Strict-TDD command table

The focused selector is supplied by the task under test; the unqualified command is the
recorded full-suite command.

| Cycle stage | Backend | Web | Mobile |
| --- | --- | --- | --- |
| RED | `python -m pytest backend/tests -q -k <case>` | `npm --prefix web run test -- <file>` | `cd mobile && flutter test --no-pub <file>` |
| GREEN | `python -m pytest backend/tests -q` | `npm --prefix web run test` | `cd mobile && flutter test --no-pub` |
| TRIANGULATE | `python -m pytest backend/tests -q -k <case>` | `npm --prefix web run test -- <file>` | `cd mobile && flutter test --no-pub <file>` |
| REFACTOR | `python -m pytest backend/tests -q` | `npm --prefix web run test` | `cd mobile && flutter test --no-pub` |

For T-04, RED is not manufactured because this work unit changes runner documentation rather
than behavior. The three unqualified GREEN/REFACTOR commands above are the recorded discovery
commands and each passed once.

T-04 is a runner-discovery and documentation task, so it does not manufacture a RED failure or change product behavior. The recorded GREEN evidence is the one successful run of each command above; the existing T-01/T-02/T-03 RED, GREEN, TRIANGULATE, and REFACTOR evidence remains in `openspec/changes/cuentas-claras-mvp/apply-progress.md`. The testing status in `openspec/config.yaml` is `detected` because all three recorded commands passed.
