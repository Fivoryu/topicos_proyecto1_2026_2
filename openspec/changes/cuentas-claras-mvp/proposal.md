# Proposal: Cuentas Claras MVP — scope reconciliation

## Decision first

This proposal reconciles the Cuentas Claras MVP after checkpoint T-00. The four confirmation gates are now **confirmed**, not assumptions:

- Multi-contributor residuals use stable participant creation order, preferring the first participant who is both contributor and beneficiary, with the first selected beneficiary as fallback.
- Referenced archived participants remain visible in balances and history, including `Bs. 0.00`; they are excluded from new-expense defaults and retained in editing forms.
- Minimum authentication is part of the MVP: pre-seeded demo accounts, login, logout, protected sessions, and explicit owner/member roles.
- Participant rename is part of the MVP: IDs and historical references remain stable, normalized-name uniqueness is enforced, and rename is name-only and atomic.

This is a **scope reconciliation**, not an implementation. The existing specs, design, and tasks were read as the preserved pre-checkpoint baseline; they still contain the old authentication and rename non-goals and must be regenerated from this proposal before product code starts. `docs/requerimiento-docente.md` remains unchanged.

## Product outcome

An authenticated owner or member can sign into the seeded Cuentas Claras group, record expenses, see trustworthy balances, and follow a deterministic transfer list that brings the group to zero—without spreadsheet math. The session protects group data, logout closes access, and the server—not a client role flag—determines whether the actor is an owner or member.

The first demonstrable outcome remains the Samaipata flow: the app loads or records Ana, Beto, Carla, and Diego and their expenses, shows Ana `+Bs. 560.00`, Beto `Bs. 0.00`, Carla `-Bs. 160.00`, and Diego `-Bs. 400.00`, proposes Diego → Ana `Bs. 400.00` and Carla → Ana `Bs. 160.00`, and reproduces the same result after refresh. The presenter signs in with a seeded account and can sign out at the end. The web flow, including the minimum session path, must remain demonstrable in under three minutes.

Participant names can be corrected or clarified without replacing identity: a rename changes the participant's display name while preserving its ID, expense references, balance history, and settlement attribution. A rename never merges participants, moves a participant between groups, changes archived status, or changes monetary results.

## Intent and reconciliation boundary

Build the smallest coherent full-stack slice of Cuentas Claras / Amigo Duradero for the 48-hour delivery window and three-specialist team. FastAPI remains the sole monetary authority; clients remain thin, generated from OpenAPI, and display server-derived results. The scope is frozen here before dependent specs and implementation are regenerated.

This proposal supersedes the preserved baseline's React-only/localStorage architecture where it conflicts with the approved architecture session. It does not modify `docs/requerimiento-docente.md`.

The previous proposal (Engram observation `2583`) and its dependent artifacts described authentication and participant rename as non-goals. That claim is superseded by the confirmed checkpoint decisions recorded in Engram observation `2587`. The downstream `specs/`, `design.md`, and `tasks.md` artifacts remain traceable historical inputs, but their old scope statements are stale until regenerated.

## Confirmed checkpoint decisions

The following evidence records user choices at checkpoint T-00. These rows are confirmed product decisions, not bounded assumptions.

| Gate | Confirmed decision | Product consequence | Evidence |
| --- | --- | --- | --- |
| **CC-01 — multi-contributor residual** | Assign the complete residual to the first participant in stable creation order who is both a contributor and beneficiary. If the intersection is empty, assign it to the first selected beneficiary in stable order. | Equal beneficiary shares remain exact and deterministic even when an expense has several contributors. Contribution-entry order and round-robin distribution are not used. | Direct user choice in the reconciliation request; preserved in parent Engram observation `2587`. |
| **CC-02 — archived participant at zero** | Keep a referenced archived participant visible in balances and history even when the derived balance is `Bs. 0.00`. Exclude archived participants from new-expense defaults; retain referenced archived participants in edit forms. | Historical attribution remains visible and editable without creating new obligations for inactive participants. | Direct user choice in the reconciliation request; preserved in parent Engram observation `2587`. |
| **CC-03 — minimum authentication and roles** | Include only the minimum seeded-account authentication slice: pre-seeded demo accounts, login/logout, protected sessions, and explicit owner/member roles. | Group data is no longer presented as unauthenticated policy behavior. No public account lifecycle or larger collaboration product is added. | Direct user choice in the reconciliation request; parent record `2587` explicitly records seeded accounts, login/logout, protected sessions, and owner/member roles. |
| **CC-04 — participant rename** | Include participant rename while preserving participant IDs and historical references, enforcing normalized-name uniqueness, and limiting the behavior to a safe name-only update. | Historical expense relationships and derived money remain stable while visible participant names can be corrected. | Direct user choice in the reconciliation request; preserved in parent Engram observation `2587`. |

## Bounded technical assumptions for downstream design

These are implementation targets that make the confirmed scope actionable. They are **not additional user approvals**. `sdd-spec` and `sdd-design` must either confirm them as technical choices or narrow them further without reopening CC-01 through CC-04.

| Area | Bounded technical assumption | Boundary kept intentionally small |
| --- | --- | --- |
| Seeded accounts | Seed at least one owner account and one member account for the demo group. Demo credentials are supplied through the development seed/runbook and are not production credentials. | No account administration, registration, invitation, recovery, or external identity provider. Exact fixture names and credential handling belong in the API/persistence design. |
| Session transport | Login establishes a server-recognized protected session that survives a page refresh while valid; logout invalidates it. The exact mechanism (for example, an HTTP-only cookie-backed session or an equivalent protected token) is a design choice. | No client-side role flag, localStorage auth secret, or anonymous fallback. Session expiry, CSRF posture, and mobile token storage must be specified before implementation. |
| Role source and policy | The server derives `owner` from the group owner relationship and `member` from authenticated group membership. The existing `owner_only` default / `any_member` setting remains. Bounded target: `owner_only` restricts the existing owner-sensitive group policy operation to the owner; `any_member` permits either authenticated role for that same operation. | No finer-grained permission matrix, user directory, or new settlement-paid workflow is introduced. The exact protected-operation list must be explicit in the regenerated groups/API specs. |
| Existing mutations | All existing group reads and mutations require a valid session and group membership. No client may self-assert a role. Until a narrower matrix is designed, the existing expense workflow remains available to authenticated group actors; group-policy authorization follows the setting above. | This preserves the prior product surface while making it session-protected. It does not authorize cross-group access or add collaboration features. |
| Rename operation | A rename is a single name-only update: trim input, compute the case-insensitive normalized name, reject blank or conflicting names, preserve the participant ID and all foreign keys, and commit atomically. It cannot merge, delete, reassign, archive, reactivate, or move a participant. | The proposal targets a narrow update rather than a participant migration. No alias table or name-history/audit product is required for this MVP. |
| Historical display after rename | Historical expense rows continue to resolve the same participant ID and may display the participant's current name plus archived status. No historical monetary row or membership is rewritten. | Whether a later product needs prior-name snapshots is deferred; the MVP does not invent that feature. |
| Client coverage | Web and mobile clients both honor the protected-session contract. Mobile remains read-mostly for expense writes, but it must not bypass login or use unauthenticated group data. | Authentication integration is Must; mobile expense create/edit/delete remains Stretch. |

## Approved architecture and enduring constraints

The following decisions remain approved and are carried forward unchanged:

- The data model is group-scoped, with one owner per group; the MVP UI exposes one active group only. There is no group switcher, group discovery, or multi-group workflow in the first slice.
- `settlementPolicy` supports `owner_only` (default) and `any_member`, is persisted per group, and is exposed consistently by the API and clients.
- Participants referenced by expenses are archived rather than physically deleted and can be reactivated. Physical deletion is allowed only for a participant never used by an expense.
- Users see money as `Bs. 1,600.00`. The API and domain represent monetary values as integer cents; no floating-point money logic is permitted.
- An expense may have multiple contributors whose contribution amounts cover the full expense. Beneficiaries split the expense equally, with the confirmed deterministic residual rule.
- Realistic, idempotently pre-seeded demo history is required, including the Samaipata acceptance data and the minimum demo accounts.
- The UI uses warm, finance-friendly visual tokens.
- FastAPI owns monetary parsing/validation at the boundary and all split, balance, and settlement calculations.
- TypeScript and Dart clients are generated from the OpenAPI contract.
- WebSocket is invalidation-only: it signals that clients should refetch REST data and carries no monetary truth.
- Strict TDD remains active, with testing discovery refreshed after bootstrap.
- Must work is completed and evidenced before any Stretch work.

## First coherent MVP slice

The slice is complete when a seeded or manually populated active group can be accessed through a protected session and run the full record → calculate → settle → refresh flow through the web client, with the mobile client consuming the same generated contract. The owner/member roles and participant rename must be present in the same contract; they cannot be postponed as untracked follow-up behavior.

### Must

1. **Authentication, session, and group foundation**
   - At least one pre-seeded owner account and one pre-seeded member account for the active demo group.
   - Login with seeded credentials and logout that invalidates the session.
   - Protected web and mobile sessions: unauthenticated or invalid-session requests cannot read or mutate group data.
   - Server-derived, explicit `owner` and `member` roles tied to the group; clients cannot choose the role.
   - One active seeded group, one owner, group-scoped persistence, and group-scoped API paths.
   - Persisted `settlementPolicy`, defaulting to `owner_only`, with `any_member` supported as the existing group setting and role behavior made observable through the protected API.
2. **Participant lifecycle**
   - Add and list participants with trimmed, case-insensitive normalized-name uniqueness.
   - Rename a participant through the bounded name-only behavior: preserve ID and all historical expense references, reject blank/conflicting normalized names, and leave derived money unchanged.
   - Archive and reactivate participants.
   - Keep referenced archived participants visible in history, balances, settlement, and editing forms even at `Bs. 0.00`; exclude them from new-expense defaults.
   - Reject physical deletion for any participant ever referenced by an expense; allow deletion only for never-used participants.
3. **Expense lifecycle**
   - Create, edit, and delete expenses through authenticated, group-scoped API operations.
   - Require a non-empty description, amount greater than zero, at least one contributor, and at least one beneficiary.
   - Support multiple contributors whose integer-cent contributions sum to the full expense.
   - Split equally among selected beneficiaries; all active participants are selected by default and may be excluded.
   - Apply CC-01's deterministic residual rule and reject invalid references.
4. **Derived monetary results**
   - Compute paid, owed, and balance per participant on the server.
   - Enforce the exact zero-cent balance invariant after every expense mutation and preserve it after participant rename.
   - Generate deterministic greedy transfers from debtors to creditors; never persist balances or transfers as independent truth.
5. **Persistence and integration**
   - PostgreSQL persistence through SQLAlchemy/Alembic; refresh must retrieve the same source data and derived results.
   - Persist the minimum account/group/session model needed for protected sessions without creating a general account-management product.
   - FastAPI REST endpoints for login/logout/session state, the active group, participants, rename, expenses, balances, and settlement.
   - OpenAPI contract with generated TypeScript and Dart clients, including the protected-session and rename operations.
   - WebSocket `data_changed` invalidation per group only; clients refetch REST data and never trust monetary values in a frame.
6. **Clients and presentation**
   - Responsive React web flow for login/logout, protected group access, participants and rename, expenses, balances, and settlement using TanStack Query and warm finance-friendly tokens.
   - Generated Flutter/Dio client and Cubit state for login/session, the same group data, and protected reads. Mobile Must is read-mostly parity for participants, balances, settlement, and expense history; mobile write parity is Stretch if time remains.
   - A shared, tested cents-to-`Bs. X,XXX.XX` formatter per client with no floating-point money operations.
   - Explicit unauthorized/session-expired, empty, validation, and recovery states; no anonymous screen that appears to be protected group access.
7. **Validation, testing, and demo readiness**
   - Clear errors for baseline invalid cases: no participants, empty/invalid amount, more than two decimal places, no beneficiaries, invalid references, duplicate names, protected deletion, and corrupted persistence/recovery where applicable.
   - Authentication coverage for successful owner/member login, rejected invalid credentials, protected access without a valid session, logout invalidation, and server-derived role behavior.
   - Rename coverage for successful ID-preserving updates, historical-reference preservation, normalized-name conflicts, blank names, archived records, and no monetary change.
   - Strict TDD for auth/session and domain math first, followed by API, client, and acceptance coverage after the test runners are bootstrapped and detected.
   - Idempotent realistic demo seed and a reproducible under-three-minute Samaipata walkthrough that includes seeded login and refresh persistence.

### Stretch, only after Must is green

- Mobile expense create/edit/delete parity beyond the read-mostly flow.
- A richer group-settings experience beyond the required settlement policy control.
- Global minimum-transfer optimization; the deterministic greedy algorithm remains the MVP behavior.

Authentication extensions are **not** Stretch. Public registration, password recovery, invitations, external OAuth, and other collaboration/account features remain non-goals. Stretch work must not delay or weaken protected sessions, role enforcement, cents correctness, server authority, generated-contract parity, persistence, validation, rename safety, or the Samaipata demo.

## Explicit non-goals

The MVP will not provide:

- Public registration, self-service account creation, password recovery, invitations, external OAuth, or a broader account-management product. The minimum seeded-account authentication slice is in scope; authentication itself is not a non-goal.
- Cloud collaboration, real-time editing, or WebSocket monetary payloads.
- Multiple groups in the UI, group discovery, group creation, or a group switcher.
- Multiple currencies, exchange rates, or configurable currency symbols.
- Percentage, weighted, custom-amount, or other unequal split modes.
- Receipt OCR, smart categories, notifications, payments, bank/wallet integrations, or settlement-paid tracking.
- Advanced analytics or a globally optimized minimum-transfer algorithm.
- Persisted balance/transfer ledgers independent of the expense source data.
- Mobile expense writes in the Must slice.
- Participant merging, ID replacement, or historical name snapshots/audit as separate product features.

## Acceptance outcomes

These outcomes define product acceptance for the reconciled Must slice.

- **AO-01 — Samaipata:** After a seeded owner or member login, Ana is `+56000`, Beto `0`, Carla `-16000`, and Diego `-40000` cents; transfers are Diego → Ana `40000` and Carla → Ana `16000` cents, in stable order.
- **AO-02 — Exact arithmetic:** A `10000`-cent expense split among three beneficiaries including its payer assigns `3334` cents to the payer and `3333` to each other beneficiary. The sum of balances is exactly zero.
- **AO-03 — Multiple contributors:** Contributions sum exactly to the expense amount, beneficiaries receive equal whole-cent shares, and the complete residual goes to the first stable-order contributor/beneficiary intersection, or to the first selected beneficiary when that intersection is empty. Any mismatch is rejected before persistence.
- **AO-04 — Lifecycle and rename integrity:** Duplicate normalized names are rejected; a participant rename preserves the participant ID, group membership, expense references, historical visibility, and derived balances; referenced participants can be archived/reactivated but cannot be physically deleted; never-used participants can be deleted.
- **AO-05 — Expense mutation:** Authenticated, authorized create, edit, and delete operations atomically recalculate balances and settlement. Invalid mutations leave the previous state unchanged.
- **AO-06 — Empty, invalid, and protected states:** No participants, zero/negative amounts, more than two decimals, no beneficiaries, nonexistent references, duplicate names, invalid rename input, invalid credentials, missing/expired sessions, and all-zero balances produce explicit, understandable outcomes. All-zero settlement says that everyone is settled and contains no transfers.
- **AO-07 — Persistence and session behavior:** After refresh, participants, renamed names, expenses, group settings, balances, and settlement match the pre-refresh state while the protected session remains valid. Logout invalidates access, and a controlled error/recovery path exists for corrupt persisted data where the selected persistence layer can encounter it.
- **AO-08 — Contract parity and authority:** Generated web and mobile clients consume the same OpenAPI contract for login/session, group data, participant rename, and monetary resources. Clients never calculate authoritative money results. A WebSocket notification causes refetch only.
- **AO-09 — Demo readiness:** A fresh environment can seed the group and minimum demo accounts, complete login → core Samaipata flow → refresh → logout in under three minutes, and reproduce the exact balances and transfers.
- **AO-10 — Role behavior:** The session identifies an owner and a member from server-side group membership. Protected group operations reject missing/invalid sessions; the existing `owner_only`/`any_member` policy behavior is enforced by the server according to the regenerated API specification, with no client-supplied role override.
- **AO-11 — Archived zero visibility:** A referenced archived participant remains listed in history and balances with `Bs. 0.00` when that is the derived balance, is absent from new-expense defaults, and remains selectable in an edit form for a referencing expense.

## Affected areas

- **Backend authentication and authorization:** account/user records sufficient for seeded owner/member roles, login/logout/session endpoints, protected-session dependency, group membership checks, role derivation, session invalidation, and auth error mapping.
- **Backend domain and persistence:** FastAPI routes and schemas, participant name normalization/rename service, domain services for cents/split/balance/settlement, SQLAlchemy models, Alembic migrations, PostgreSQL configuration, seed script, and group WebSocket invalidation. Rename must not alter monetary services or historical foreign keys.
- **Web:** React/Vite login/logout/session bootstrap, protected route/query behavior, participant rename UI and errors, TanStack Query data flow, generated TypeScript client, cents formatter, validation/error states, and warm finance-friendly tokens.
- **Mobile:** Flutter/Dio generated auth/session integration, Cubit session state, protected read-mostly group/expense/balance/settlement views, rename display/update behavior as supported by the contract, and cents formatter. No misleading mobile expense-write controls in Must.
- **API and contract:** OpenAPI login/logout/session, role-bearing protected responses or server decisions, participant rename, stable error envelopes, and generated TypeScript/Dart clients. No client is allowed to become a second monetary or authorization authority.
- **Tests:** Python domain/API/auth/persistence tests, web formatter/query/protected-route/component tests, mobile Cubit/session/formatter tests, rename/history tests, and DA-01 through DA-05 plus auth/rename acceptance coverage.
- **Documentation and delivery:** OpenAPI generation instructions, seeded-account/demo/session instructions, rename behavior, recovery notes, implementation tasks, and final acceptance evidence. `docs/requerimiento-docente.md` remains unchanged.

## Dependencies and 48-hour sequencing

Authentication and participant rename are now Must work, so they move ahead of client implementation and contract freeze. The sequence below keeps unstable API/auth contracts out of parallel client work.

1. **Bootstrap and test discovery:** create the approved backend/web/mobile shells, PostgreSQL/Docker Compose setup, migration/test harness, and initial health route. Strict TDD is active; re-run testing discovery as soon as the real runners exist.
2. **Protected group foundation:** implement the smallest account/session model, seeded owner/member identities, login/logout/session validation, group membership and role derivation, and protected-route tests. No public registration, recovery, invitations, or OAuth work may enter this slice.
3. **Backend domain:** implement and test integer-cents parsing, contribution validation, equal beneficiary split, the confirmed CC-01 residual rule, balances, and greedy settlement. In parallel where safe, add participant normalization and the name-only rename domain/application tests; rename must preserve IDs and references.
4. **Persistence and API:** freeze source tables plus the minimal auth/session tables, migrations, protected dependencies, group/participant/rename/expense/derived routes, `owner_only`/`any_member` enforcement, structured errors, idempotent demo seed, and invalidation-only WebSocket behavior. Verify invalid mutations and invalid sessions leave state unchanged.
5. **Contract freeze:** export the authenticated FastAPI OpenAPI document, generate TypeScript and Dart clients, add the drift check, and stop changing schemas while clients are built. The contract must include login/logout/session state, role behavior, and participant rename.
6. **Web Must:** implement the login/session/logout path, protected group shell, participant lifecycle including rename and archived visibility, expense CRUD, balances, settlement, refresh persistence, and WebSocket invalidation/refetch. Rehearse the under-three-minute flow early enough to cut optional polish.
7. **Mobile Must:** integrate the generated Dart client and Cubit session state, then ship protected read-mostly parity for participants, renamed names, expense history, balances, and settlement. Add mobile expense writes only after all web/backend/auth/rename outcomes are green.
8. **Integration and handoff:** run DA-01 through DA-05 plus auth, protected-session, role, rename, archived-zero, corruption/recovery, seed-idempotency, generated-client drift, and responsive/accessibility checks. Capture the login → demo → refresh → logout evidence.

For the three-specialist / 48-hour constraint, the backend/domain path remains the critical path. The first boundary is bootstrap plus protected backend/domain behavior; the second is persistence/API/contract freeze; the third is web Must; the fourth is mobile read-mostly plus acceptance. Web and mobile may parallelize only after the authenticated OpenAPI contract and generated clients are frozen. If time becomes tight, stop after the last green Must boundary and defer mobile writes, rich settings, and optimization—never remove protected sessions, role enforcement, monetary tests, or rename safety without a new scope decision.

The `600`-changed-line review budget remains a delivery constraint. The reconciled scope increases authored work, so the downstream task plan must recalculate its workload forecast and preserve the configured `ask-on-risk` delivery strategy. Chained delivery remains available, but no budget decision is silently inferred by this proposal.

## Risks and mitigations

| Risk | Level | Mitigation |
| --- | --- | --- |
| Minimum authentication expands the 48-hour surface and delays the monetary core | High | Keep auth to seeded owner/member accounts, login/logout, protected sessions, and server-derived roles; build it before contract freeze; defer all account extensions and mobile writes. |
| Session or role enforcement is simulated in the client | High | Protect every group route server-side, derive role from authenticated membership, test missing/expired/logout sessions, and forbid client-supplied role flags. |
| `owner_only` versus `any_member` behavior is ambiguous after auth enters scope | High | Preserve the existing setting and document the bounded operation target; regenerate groups/API specs with an explicit operation matrix before code. Do not add broader permissions or settlement-paid behavior. |
| Rename changes historical meaning or creates duplicate identities | High | Make rename name-only and atomic; preserve IDs and all references; normalize and constrain names across the group, including archived rows; add historical, duplicate, blank, and no-money-change tests. |
| Historical display after rename is misunderstood as a new participant | Medium | Keep the same participant ID visible in expense/history responses and document that no merge or new identity is created. Defer name snapshots/audit. |
| Demo credentials or sessions are mishandled | Medium | Keep seeded credentials development/demo-only, avoid production secrets in the repository, document reset/logout behavior, and test refresh plus invalidation. Exact credential delivery is a downstream technical choice. |
| Two clients plus backend exceed 48 hours | High | Finish protected backend/domain and web Must first; keep mobile read-mostly; defer writes, rich settings, optimization, and all account extensions. |
| Floating-point logic enters a client | High | Use integer-cent wire values, server-derived results, one formatter per client, and formatter tests; prohibit client-side money arithmetic. |
| Generated clients drift from FastAPI | Medium | Freeze the authenticated OpenAPI contract, regenerate both clients, and verify generation in CI or the handoff checklist. |
| PostgreSQL or seed is unavailable during demo | Medium | Use Docker Compose, health checks, reversible migrations, idempotent group/account/history seed, documented reset path, and a fresh-environment rehearsal. |
| Archived participants break historical edits or balances | Medium | Retain references, include referenced archived records at zero, exclude them only from new defaults, and test archive/reactivate/rename/delete rules. |
| WebSocket adds a second source of truth | Low | Send only `data_changed`; every client refetches authoritative REST resources. WebSocket failure never bypasses protected REST or monetary correctness. |

## Rollback and recovery

- **Scope rollback:** Stop at the last green Must boundary and remove only Stretch work. Do not restore an anonymous fallback, localStorage architecture, client-side authorization, or client-side monetary calculations. If the reconciled auth/rename scope cannot be delivered safely, stop and request a new scope decision rather than silently shipping the old non-goals.
- **Authentication rollback:** Use reversible account/session migrations and invalidate active sessions during a controlled rollback. Protected endpoints remain protected; a broken auth UI may be disabled only while the release is held, not by exposing group data anonymously.
- **Data rollback:** Use reversible Alembic migrations and an idempotent demo seed. Recompute balances and settlement from participants and expenses rather than restoring a separately stored ledger. A rename incident is corrected through a controlled name update or database recovery; it never creates a replacement participant that breaks historical IDs.
- **Rename rollback boundary:** Because rename changes only the participant name and no monetary or foreign-key data, the endpoint can be disabled or corrected without altering expenses, balances, or settlement. No automatic merge or identity replacement is allowed.
- **Integration rollback:** If WebSocket invalidation fails, disable the notification path and continue through authenticated REST refetches; monetary correctness, protected access, and refresh persistence remain available.
- **Client rollback:** If mobile scope threatens the schedule, keep generated auth/session support and read-mostly views, and defer mobile expense writes without changing the API contract or weakening protected access.
- **Decision rollback:** If a later review changes a confirmed business rule, update this proposal, the affected specs/design/tasks, and the tests/API contract before implementation. Do not encode a new rule only in code.
- **Baseline protection:** The preserved baseline document is not edited as part of this change.

## Success criteria

The reconciled proposal is successful when:

- CC-01 through CC-04 are visibly marked confirmed with traceable evidence, and no downstream artifact continues to treat authentication or rename as a non-goal after regeneration.
- The Must/Stretch boundary includes only minimum seeded authentication, protected sessions, owner/member roles, and safe participant rename; it does not grow into registration, invitations, recovery, OAuth, or a larger collaboration product.
- The regenerated specs define explicit session, role, rename, archived-zero, residual, and atomicity behavior, and every Must outcome traces to tests and implementation tasks.
- A clean environment can seed owner/member demo accounts and Samaipata history, complete login → record/view → settle → refresh → logout through the web client, and reproduce the same balances and transfers.
- Participant rename preserves IDs and historical references, enforces normalized-name uniqueness, leaves monetary results unchanged, and has an explicit failure/rollback path.
- The backend remains the only monetary authority and authorization authority; generated clients match OpenAPI; WebSocket remains invalidation-only; no balance or transfer is stored as independent truth.
- The team can explain the cents, residual, balance, settlement, protected-session, role, archived-visibility, and rename rules without relying on undocumented behavior.

## Next step

Regenerate the earliest dependent phase: **`sdd-spec`**. It must update the groups, API, participants, clients, persistence, expenses/settlement, and demo-readiness specifications as needed, then `sdd-design` and `sdd-tasks` must reconcile architecture, sequencing, workload, and acceptance evidence before any product code is written.
