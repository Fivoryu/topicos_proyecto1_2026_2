# Exploration: Group outing workspaces

## Executive summary

`group-outing-workspaces` is a new domain and workspace change, separate from `web-professional-redesign`. The redesign is visual-only, already has 622 modified lines, and must remain untouched. This exploration is planning-only; no product source code, generated client, tests, or existing change artifact was modified.

The requested feature extends the current single-active-group MVP into authenticated multi-group workspaces with multiple outings per group, optional outing association for expenses, laptop-first web screens, and controlled QR/code membership joining for accounts that already exist. It crosses the current API, persistence, authorization, session, generated-client, seed/fixture, and web composition boundaries. It cannot be treated as a presentation-only continuation.

The proposed QR/code joining scope requires a policy/spec amendment. Current CC-03 and the canonical `groups`, `api`, and `clients` specifications explicitly prohibit group discovery/switching and invitations. A revocable code for an already-authenticated account is not an email invitation or public registration, but it still changes how memberships are created and introduces a controlled invitation-like join mechanism. The new change should amend those rules explicitly before implementation.

## Repository and OpenSpec baseline

- Root `AGENTS.md` confirms FastAPI/PostgreSQL/SQLAlchemy/Alembic as the backend authority, React/Vite/TanStack Query as the web stack, generated OpenAPI clients as non-editable output, and WebSocket as invalidation-only (`{"type":"data_changed"}`).
- Monetary authority remains the server: integer cents only, exact zero-sum balances, server-derived balances and settlement, and no client monetary calculations.
- The official Samaipata fixture is authoritative: Ana, Beto, Carla, and Diego; four existing expenses; balances Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`; transfers Diego → Ana `40000`, Carla → Ana `16000`.
- `openspec/project-context.md`, `openspec/specs/`, and `docs/sdd-evolution.md` describe the current MVP as one active seeded group. The canonical groups spec explicitly says there is no group switcher, discovery, creation, or multi-group workflow. The API spec has no group-list or membership-join surface and explicitly excludes invitations. The clients spec describes one protected group and no durable client-side group authority.
- `openspec/config.yaml` is configured for artifact store `both`, automatic execution, strict TDD, `exception-ok`, and a historical 600-line review budget. The orchestrator context states this user-facing work is being kept within an 800-line cap; that cap must be treated as a delivery constraint only after the proposal defines a realistic slice.
- `web-professional-redesign` remains an independent active visual change with existing uncommitted files and pending manual visual verification. This exploration does not edit or overwrite it.

CodeGraph/MCP/CLI was not available in this executor surface. After the project-root and `.codegraph` check, the structural map below uses targeted repository reads and symbol/path searches; no broad implementation change was made.

## Current architecture and ownership map

### Authentication, membership, and authorization

- `backend/app/adapters/db/tables.py` has `Account`, `Group`, `GroupMembership`, and database-backed `AuthSession` tables.
- `Group` has one `owner_account_id`, a name, a settlement policy, and timestamps.
- `GroupMembership` has a composite `(group_id, account_id)` key, but current application abstractions resolve one membership for an account: `MembershipRepository.find_for_account()` returns one `MembershipRecord` and the session identity exposes one `active_group_id`.
- `backend/app/application/authorization.py` derives `owner` versus `member` from server-side membership and group ownership. Client role claims are not trusted.
- `backend/app/api/routes/auth.py` and `api/schemas/auth.py` establish the current session contract: login/session/logout, opaque cookies, CSRF handling, and a single active group ID. The browser anonymous probe is `204`; valid sessions are `200`; protected resources require a valid session and membership.
- Existing route dependencies and group authorization assume a requested group ID is checked against the account's current membership. A group selector therefore needs a server-side list of all memberships and an explicit active-group selection model, not a client-only ID switch.

### Persistence and domain

- `Participant` is group-scoped and identity-stable across rename/archive.
- `Expense` is group-scoped with `description`, `amount_cents`, timestamps, and child contribution/beneficiary rows. Balances and settlement are derived at read time; no ledger tables are used.
- `ExpenseRepository.list_by_group()` and `DerivedService` currently derive all group balances/settlement from all source expenses in that group.
- Migrations are under `backend/migrations/versions/`: `0001_auth.py` creates accounts/groups/memberships/sessions and `0002_source.py` creates participants/expenses/contributions/beneficiaries. Outings, expense-outing linkage, join-code state, and any membership metadata require new Alembic migration(s), ORM tables, repository ports/adapters, service logic, and migration tests.
- The current group owner is an account, while expense participants are deliberately separate domain records. The feature must not conflate authenticated account membership with participant identity.

### API and contract generation

- Current REST paths are group-scoped under `/api/v1/groups/{group_id}` for group settings, participants, expenses, balances, settlement, and events. The API has no authenticated account group-list endpoint, outing endpoint, join-code endpoint, or membership-join endpoint.
- Handwritten FastAPI schemas/routes/services are the contract source. `contracts/openapi.json`, `web/src/generated/api/`, and `mobile/lib/generated/api/` are generated and must not be edited manually.
- Any new endpoint or field must follow the existing workflow: handwritten backend schema/route/service changes → OpenAPI export → TypeScript and Dart generation → contract drift check.
- The request explicitly preserves WebSocket behavior. New source mutations may publish one group-scoped invalidation after commit, but the frame must remain exactly invalidation-only and clients must refetch REST. The change should not add outing, membership, or monetary payloads to WebSocket frames.

### Web architecture

- The current web shell is a single protected React composition in `web/src/app/App.tsx`. It derives one `session.activeGroupId`, passes that ID to feature panels, uses hash anchors, and creates one group WebSocket connection.
- TanStack Query keys are currently group/resource pairs (`[resource, groupId]`) for group, participants, expenses, balances, and settlement. A selected-group workspace can preserve this pattern while adding account-scoped group queries and outing-scoped keys, but cache invalidation and selection transitions must be designed explicitly.
- Existing panels are `ExpensesPanel`, `BalancesPanel`, `SettlementPanel`, `ParticipantsPanel`, and `GroupSettings`. The visual redesign documents the current CSS/theme seams and must remain separate; the new change should not assume the redesign is archived or modify its files as a prerequisite.
- The requested product calls for separate laptop-first screens for groups, outings, expenses, group summary, participant detail, balances, and settlement. This is a structural/navigation change, not merely additional cards in the existing dashboard. The current hash-based dashboard and no-router assumption are likely insufficient for deep links and selection state; the proposal must choose a routing/navigation strategy compatible with React/Vite and preserve protected-shell behavior.
- Mobile ownership remains independent under the mobile change boundary. The new first slice should be explicitly web/laptop-first and must not silently create Flutter parity work, generated Dart edits, or mobile acceptance obligations.

## Proposed domain direction to carry into proposal

1. **Account group workspace:** authenticated accounts can list groups they belong to, select one, and open a group workspace. The server returns only memberships visible to the authenticated account. Selection must be validated server-side and must not be a trust boundary.
2. **Outings:** a group owns zero or more outings/salidas. Outing identity, name, lifecycle/archive behavior, ordering, and ownership permissions are not yet decided. A group-level summary must include all group expenses, while an outing view must define whether it includes only outing expenses and how balances/settlement are calculated.
3. **Expenses:** every expense remains owned by a group and may have a nullable `outing_id`. General expenses contribute to group totals but not to a specific outing. An outing expense must reference an outing belonging to the same group. Existing participant, contributor, beneficiary, residual, archive, and atomic validation rules remain unchanged unless explicitly amended.
4. **Laptop-first screens:** separate navigation surfaces are expected for group selection, outing listing/detail, expense listing/editor, group summary, participant detail, balances, and settlement. The first proposal should define a bounded route/screen slice rather than implement all screen polish at once.
5. **Controlled QR/code join:** a group owner can generate a revocable join artifact/code. It may be used only by an already-authenticated account; it must not register accounts, send email, expose public account creation, or become an anonymous group-data endpoint. The server must validate group, code, account session, expiry/revocation/use policy, and duplicate membership atomically. Code material should not be stored in plaintext if a bearer secret is used; store a hash plus bounded metadata and provide owner-only revoke/regenerate operations.
6. **Authorities:** FastAPI remains the source of authorization, membership, persistence, monetary results, balances, and settlement. PostgreSQL remains the durable source. REST remains the data source; WebSocket remains a post-commit invalidation hint only. Generated clients remain workflow output.

## Contract, migration, and compatibility implications

### Likely new or changed API areas

- Authenticated account group listing, likely outside `/groups/{group_id}` because it is account-scoped.
- Group selection/session representation: either make session identity expose a selected group while listing memberships separately, or keep session identity stateless and make selected group a client navigation concern validated on every request. The choice affects cookies/session schema, bootstrap, and cache invalidation.
- Outing CRUD/list/detail routes under a group, with owner/member authorization rules.
- Expense request/response addition for nullable `outing_id` or a normalized outing relation. Existing clients and fixtures need explicit backward-compatible behavior for general expenses.
- Outing-filtered balances/settlement and group-wide summary endpoints or query parameters. The server must define and enforce the aggregation semantics.
- Owner-only join-code generation, revocation, and possibly status/read endpoints; authenticated join consumption for existing accounts.
- Structured error codes for invalid outing references, closed/archived outings, invalid/revoked/expired code, already-member joins, and forbidden owner actions.

### Database and migration work

- Add an outings table with group foreign key, stable ID, name, timestamps, and the chosen lifecycle fields/indexes.
- Add nullable `outing_id` to expenses with a same-group integrity rule. A plain foreign key alone does not guarantee that an outing belongs to the expense group; service validation and/or a composite-key constraint is required.
- Add join-code/token state with a safe representation: group, creator, hash, created/expiry/revoked/used timestamps, and possibly a generation/version or usage limit. Decide whether codes are reusable until revoked, single-use, or bounded-use.
- Decide whether membership rows need role/status/joined-at/source metadata. Existing owner role is derived from `Group.owner_account_id`; do not add a client-controlled role field.
- Preserve existing Samaipata rows and ensure old general expenses remain valid after migration. The official seed must stay idempotent and must not silently add an outing or test expense unless the product decision explicitly changes the fixture.

### Generated contract and tests

- Add backend unit tests for outing ownership/isolation, nullable association, cross-group outing rejection, filtered derivation, and join-code lifecycle/atomicity.
- Add integration/acceptance coverage for account group listing and switching, protected screens, multiple groups, group-wide versus outing-specific totals, revocation/expiry/duplicate joins, and WebSocket invalidation isolation.
- Extend OpenAPI contract tests and run generation/drift checks. Never hand-edit generated TypeScript or Dart.
- Extend web tests around session bootstrap, group selection, query-key/cache reset on selection, route protection, screen accessible names, and server-provided money. Existing auth, expense, participant, balance, settlement, and invalidation tests are regression gates.
- Strict TDD is enabled in the project context: focused RED, smallest GREEN, edge/invalid-state triangulation, then refactor and full gates.

## Ownership boundaries and non-goals

### Must preserve

- Existing authenticated session, CSRF/origin enforcement, server-derived owner/member role, and protected-resource behavior.
- Integer cents, exact zero-sum, deterministic residual and settlement behavior, participant identity/history, and server-only calculations.
- Exact invalidation-only WebSocket payload and post-commit publication policy.
- Generated-client policy and mobile ownership boundary.
- Official Samaipata fixture and its documented expected outcome.
- Existing `web-professional-redesign` files and artifacts; no source files from that change are a dependency to modify in this exploration.

### Explicit non-goals for this proposal unless separately approved

- Public registration, password recovery, OAuth, email invitations, anonymous group data, or account creation through QR.
- Mobile UI/domain parity in this first laptop-first slice.
- Client-side balances, settlement, split calculations, or optimistic monetary writes.
- Multiple currencies, custom/weighted splits, OCR, payments, notifications, or advanced analytics.
- Treating participant records as login accounts or requiring every participant to have an authenticated account.
- Rewriting the existing visual redesign or merging this feature into its 800-line presentation budget.

## Unresolved product decisions

1. **Group selection and session semantics:** Is the selected group merely URL/client navigation state validated per request, or should the server persist an active group in the session? Should login select the last group, the only group, or show a group picker every time?
2. **Group lifecycle:** Can authenticated users create groups in this change, or only view existing memberships and join by code? If creation is allowed, who becomes owner and what is the initial participant/outings state?
3. **Outing lifecycle:** Are outings editable, archivable, deletable, or closeable? What happens to expenses and deep links after an outing is archived or deleted? Is an outing name unique within a group?
4. **Summary semantics:** Does group summary include all expenses and balances, while outing balances/settlement include only expenses linked to that outing? How should general expenses be represented in an outing view—excluded, distributed, or shown separately without allocation?
5. **Settlement scope:** Can users settle an outing independently, or is settlement only group-wide? If both exist, how are general expenses handled and how are transfers prevented from double-counting?
6. **Join-code policy:** Is the code reusable until revoked, single-use, or limited-use? Must it expire? Can an owner have multiple active codes? Does regeneration revoke prior codes automatically? Is joining immediate or does the owner approve a pending request?
7. **Join authorization:** Does any authenticated account holding a valid code join immediately, or must the code be bound to a target account/login name? The confirmed direction only rules out public registration and email invitations; it does not yet settle bearer-code abuse, replay, or approval semantics.
8. **Membership exit and ownership:** Can members leave a group? Can the owner remove members or transfer ownership? What happens if the owner account is deactivated? These affect roles, join-code administration, and data retention.
9. **Fixture strategy:** Should Samaipata remain a single general-expense group for the official walkthrough, or should the seed add named outings while preserving exact group-wide totals? The safest default is to preserve the current official fixture and add separate focused fixtures/tests for outings.
10. **Screen scope and navigation:** Which laptop-first screens are Must for the first implementation slice, and which are later follow-up work? Is a router acceptable, and what URL/deep-link contract is required?
11. **Line/review budget:** Does the 800-line user-facing cap apply only to the existing redesign, or also to this domain change? Given the backend, schema, generated-client, migration, web, and test surface, this feature likely needs a staged/chained implementation or an explicit exception rather than an artificially compressed diff.
12. **Policy amendment ownership:** Should the new change update `openspec/project-context.md`, canonical `openspec/specs/groups`, `api`, `clients`, and possibly `AGENTS.md`/the evolution map before implementation? The current baseline requires this because the accepted understanding changes materially.

## Recommended next phase

Proceed to `sdd-propose` only after the product decisions above are resolved or explicitly recorded as assumptions. The proposal should first define a bounded web/backend slice, the membership/join security model, group-versus-outing calculation semantics, the migration/contract plan, and the required policy/spec amendments. It should not begin implementation or alter `web-professional-redesign` artifacts.

## Evidence paths inspected

- `AGENTS.md`
- `openspec/project-context.md`
- `openspec/config.yaml`
- `docs/sdd-evolution.md`
- `openspec/specs/groups/spec.md`
- `openspec/specs/expenses/spec.md`
- `openspec/specs/api/spec.md`
- `openspec/specs/clients/spec.md`
- `openspec/changes/web-professional-redesign/exploration.md`
- `openspec/changes/web-professional-redesign/specs/web-presentation/spec.md`
- `backend/app/adapters/db/tables.py`
- `backend/app/application/ports.py`
- `backend/app/api/routes/auth.py`
- `backend/app/api/schemas/auth.py`
- `backend/app/api/schemas/expenses.py`
- `backend/app/application/derived_service.py`
- `backend/migrations/versions/0001_auth.py`
- `backend/migrations/versions/0002_source.py`
- `web/src/app/App.tsx`
- `web/src/core/query-client.ts`
- `web/src/core/websocket.ts`
- relevant backend/web tests and seed references found by targeted searches
