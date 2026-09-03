## Context

See `proposal.md` for motivation. The delivered application is already server-backed and protected, while its handoff material is split across current implementation, `openspec/project-context.md`, the completed but unarchived `cuentas-claras-mvp` change, and a preserved pre-code instructor baseline. `openspec/specs/` is empty, so old full-spec artifacts cannot be treated as canonical delta specs or rewritten in place without losing history.

The existing seed creates stable accounts, group, participants, three expenses, contributions, and beneficiaries in one fail-closed transaction. Its `position` currently doubles as payer index, which cannot represent two consecutive Ana-paid expenses. Existing balances and settlement logic already produce the official totals and must not change; only the source-record shape is wrong.

The React UI is handwritten outside generated OpenAPI trees and renders server DTOs through one integer-cent formatter. Static strings, accessible labels, role/policy labels, and server-message fallbacks are mostly English. Generated TypeScript and Dart trees declare themselves generated and are byte-checked by the contract drift command.

Delivery inspection also found two operational inconsistencies: `web/.env.example` points at the backend plus `/api/v1` even though generated operations already include that prefix and the Vite flow requires same-origin cookies; OpenAPI generation is operationally driven from the repository root at version `7.14.0`, matching committed generated metadata, while secondary config/docs claim `7.19.0`.

## Goals / Non-Goals

**Goals:**

- Make current guidance discoverable from the root and give historical documents explicit status and precedence.
- Change only the Samaipata source fixture required to represent the official scenario, retaining existing domain algorithms and persistence schema.
- Localize the demonstrated web surface and monetary display without adding a localization framework or moving authority into the client.
- Make setup and verification commands executable as written from documented working directories.
- Use focused test updates plus full regression gates to show that final polish preserves existing behavior.

**Non-Goals:**

- Retrofitting or deleting the historical `cuentas-claras-mvp` proposal, design, specs, reports, or instructor baseline.
- Introducing a data migration for local demo data, changing database tables, changing API schemas, or recalculating money in clients.
- Wiring unfinished mobile composition, adding mobile writes, implementing generated TODOs, or reviving discarded Stretch work.
- Replacing the visual system, adding runtime i18n, resolving unrelated type/audit/deprecation warnings, or refactoring backend session lifetime unless verification proves one blocks this delivery.

## Decisions

### 1. Publish a precedence map instead of rewriting history

Add `AGENTS.md` and `README.md` as current entry points, update `openspec/project-context.md` and `openspec/config.yaml` where their current claims or command guidance are incomplete, and add a concise SDD evolution/status document under `docs/` if the root documents would otherwise become overloaded. The precedence will be: official assignment as preserved baseline; dated exploration/checkpoint artifacts as decision history; current project context plus active delta specs as accepted scope; implementation and verified contract as conformance evidence.

The instructor baseline and completed MVP change stay intact. Statements such as local-only persistence, no backend, or no auth receive external supersession context and links rather than silent textual replacement. After implementation verification, the normal OpenSpec sync/archive workflow can promote these new delta specs into `openspec/specs/`; apply work will not fabricate canonical copies or mutate historical artifacts.

Alternative considered: edit every stale statement in place. Rejected because it destroys point-in-time SDD evidence and still would not resolve the empty canonical-spec state cleanly.

### 2. Model the seed fixture explicitly rather than by tuple position

Represent each seeded expense with description, amount cents, and payer index explicitly:

| Stable expense | Description | Amount cents | Payer index |
| --- | --- | ---: | ---: |
| existing `...0021` | Cabaña | `80000` | Ana (`0`) |
| existing `...0022` | Entradas a El Fuerte | `16000` | Ana (`0`) |
| existing `...0023` | Cena | `40000` | Beto (`1`) |
| new `...0024` | Gasolina | `24000` | Carla (`2`) |

All receive the same four stable beneficiary IDs. Validation will compare every stable expense's full shape and exact canonical IDs, then derive and verify balances, zero sum, and ordered transfers. Existing transaction, account hash preservation, stable participant order, and fail-closed behavior stay unchanged.

The supported transition from the superseded three-expense local fixture is destructive demo reset, migrate, and reseed. The seed will not rewrite an existing `...0022` from Beto's `40000` expense into Ana's `16000` expense or delete user-created rows. This avoids disguising a demo-fixture replacement as a production migration.

Alternative considered: retain Ana's aggregated `96000` record and only rename it. Rejected because the official assignment explicitly requires two separately demonstrable Ana expenses.

Alternative considered: add only a fourth expense while keeping the aggregate. Rejected because it would duplicate value and produce incorrect totals.

### 3. Keep presentation localization in handwritten web code

Translate static copy and accessible names directly in the existing shell and feature components because the deliverable has one target language and no runtime language selection requirement. Small display mappings will translate stable `owner`/`member`, `owner_only`/`any_member`, and known error codes while retaining protocol identifiers for diagnostics. Unexpected errors receive a generic Spanish fallback.

Update the shared cents formatter to use Spanish separators without floating point. Keep ordinary amounts unsigned (`Bs. 800,00`) and expose a signed balance variant so only positive balances gain `+` (`+Bs. 560,00`); debts retain `-` and zero has no sign. Settlement rows compose server-provided names and amount as `from → to: amount`. No sorting or arithmetic moves into React.

Translate `web/index.html` language metadata and text-bound tests. Preserve CSS, component structure, responsive behavior, TanStack Query ownership, WebSocket invalidation, protected routing, and generated adapters.

Alternative considered: add an i18n dependency and message catalogs. Rejected as unnecessary scope and delivery risk for a single-language polish pass.

Alternative considered: translate backend error strings. Rejected because it would affect every client and the API contract behavior; the web presentation can map stable codes without changing transport semantics.

### 4. Make the primary demo read-only after login

Rewrite `docs/demo-samaipata.md` to spend the available time on login, participants, four expense rows, balances, settlement, and refresh. Remove expense creation and the logout replay from the primary timed path; retain security/test references outside that path when useful. Target less than three minutes with explicit checkpoints and the exact Spanish-rendered outcomes.

This directly protects the assignment's official state and makes a seed rerun before rehearsal meaningful. Existing expense creation remains demonstrable and tested but is not used to mutate the canonical demo dataset.

Alternative considered: delete and recreate the four expenses live. Rejected because it is too slow, increases demo failure modes, and weakens the persistence demonstration.

### 5. Update only fixture- and text-coupled tests

Extend seed integration and DA-01 acceptance coverage to inspect the four descriptions, amounts, one-contributor mappings, all-four beneficiary sets, exact paid/owed/balance values, zero sum, and two transfers. Update recovery count and acceptance cleanup assertions that currently assume three stable expense IDs. Do not rewrite generic money, split, balance, settlement, lifecycle, authorization, persistence, or rename tests merely because the fixture representation changes.

Update web tests at the same accessibility boundary users rely on: Spanish labels, role/policy display, state labels, direct transfer notation, decimal-comma formatting, session messages, and unchanged interactions. Add one official response rendering case where existing balance/settlement fixtures do not cover the exact handoff output.

Alternative considered: broad snapshot replacement. Rejected because focused semantic queries better protect accessibility and behavior while avoiding layout churn.

### 6. Align operational examples to the commands that actually run

Use the Vite same-origin proxy as the default web setup. `VITE_API_BASE_URL` will be empty or the web origin, never the backend origin and never suffixed with `/api/v1`; document `VITE_GROUP_ID` as non-authoritative/unused by the protected shell unless inspection during implementation proves otherwise.

Treat repository-root `openapitools.json` version `7.14.0` as the current operational pin because the drift script executes the npm generator from the repository root and both committed generated trees report `7.14.0`. Align duplicate metadata and generation documentation to that version, correct working-directory navigation, and run the drift check. Do not edit generated files manually; regenerate only if the aligned command proves committed output is not reproducible.

Alternative considered: upgrade all generated output to `7.19.0` during final polish. Rejected because no product or contract requirement needs a generator upgrade, and it would create avoidable generated churn.

## Risks / Trade-offs

- [Historical docs still contain obsolete statements] → Root guidance and the SDD evolution map will label their status and provide explicit precedence; historical artifacts remain intentionally unchanged.
- [An existing local database contains the old stable expense shapes] → Fail closed and document `docker compose ... down -v`, migrate, and reseed; never rewrite or delete source rows silently.
- [Decimal-comma display differs from decimal-point API input] → Keep wire parsing unchanged, use decimal-point examples/help for editable amount fields where required, and limit comma formatting to displayed Boliviano values.
- [Direct string translation misses a visible or accessible English label] → Search handwritten web sources and test queries for the audited English surface, then perform the timed browser rehearsal in addition to Vitest.
- [Generator config alignment still reveals drift] → Stop manual edits, regenerate through the pinned workflow only if needed, review generated diffs, and require the drift gate to pass.
- [Full regression commands expose unrelated pre-existing failures] → Record the exact pre-existing condition; fix it only if it blocks setup, demo, tests/build, contract conformance, or a final spec requirement.
- [The empty canonical spec directory remains empty until lifecycle completion] → Keep this change's deltas and project context as the active source, validate them strictly, and use the explicit OpenSpec sync/archive workflow after apply verification.

## Migration Plan

1. Update current context and root handoff documents while preserving and linking historical artifacts.
2. Change the seed fixture and focused backend tests; use a fresh local database for rehearsal because old stable demo rows are intentionally incompatible.
3. Translate handwritten web presentation and update focused web tests and formatter coverage.
4. Correct setup/generator documentation and metadata only to the extent needed for reproducible commands.
5. Run focused checks, complete backend/web gates, contract drift, fresh PostgreSQL migrate/seed-twice/startup, and the timed browser walkthrough.
6. If verification fails, revert only this change's fixture/presentation/documentation edits; database rollback is the documented local volume reset because no schema migration is introduced.
7. After apply is accepted, use the separate OpenSpec sync/archive workflow to promote the delta specs and preserve this change as completed history.
