# Technical design: Group outing workspaces

## Decision summary

Implement `group-outing-workspaces` as a server-authoritative domain expansion behind the existing FastAPI/PostgreSQL/SQLAlchemy/Alembic architecture. Keep account identity, participant identity, money, settlement, sessions, CSRF/origin checks, OpenAPI generation, and WebSocket invalidation semantics under their existing authorities.

The change is delivered as a stacked sequence of small slices. **Stage 0 is policy/spec synchronization and is a hard prerequisite for all product-code stages.** Every later implementation slice includes its own migration, contract, test, path, rollback, and changed-line budget. No slice may exceed 800 additions plus deletions; generated output is part of that count and is never hand-compressed or hand-edited.

Group selection is navigation state, not an authorization claim or a persisted session preference. The authenticated session proves account identity; an account-scoped group list supplies selectable memberships; every selected-group request independently rechecks active membership and derives the role on the server. The existing `active_group_id` session field remains a compatibility bootstrap value for the first available active membership, but it is not the authoritative selected-group state. A session with no active membership has no selected group and no group role.

Outings are group-owned source records with active/archived lifecycle. Expenses retain group ownership and gain a nullable `outing_id`; group derivations include every expense, while outing derivations filter strictly to that outing. A current reusable join code is stored only as a hash, is consumed only by an already-authenticated account, and completes an explicit participant link-or-create transaction atomically.

The web implementation extends the current React/Vite/TanStack Query client with a small hash-navigation layer and additive workspace features. It does not add a router or another dependency, does not make mobile UI parity a requirement, and does not overwrite any uncommitted `web-professional-redesign` file. Integration with the protected shell is a guarded stacked-branch operation after the redesign boundary is preserved or landed.

## Hard requirements and bounded assumptions

### Hard requirements

| Area | Design requirement |
| --- | --- |
| Groups | Authenticated accounts list only active memberships, create groups, and select a group. A creator is the sole owner and a member. A new group has no participants, outings, or expenses. |
| Authorization | Every group-owned read and mutation is session-protected, group-scoped, and re-authorized from active membership. Client group IDs and roles never grant access. |
| Outings | Any member creates/edits active outings. Only the owner archives/unarchives and deletes empty outings. Archived history is readable and read-only. Non-empty outings are never physically deleted. |
| Expenses | `outing_id` is nullable. `null` means a general group expense. A non-null outing must belong to the same group. Group totals include all expenses; outing totals include only linked expenses. |
| Joining | One current reusable owner-controlled join code per group. It is valid until revoke/regenerate, is hashed at rest, requires an existing authenticated account, and supports an explicit existing-participant link or new-participant choice. |
| Membership | Owners remove members; members leave. The fixed final owner cannot leave or be removed. Participant records and expense/outing history survive membership changes. |
| Authority | FastAPI authorizes and derives monetary results; PostgreSQL stores source truth; clients render server-derived integer cents. |
| Realtime | Successful committed source mutations publish exactly one group-scoped `{"type":"data_changed"}` signal. The frame contains no data and clients refetch REST. Failed transactions publish nothing. |
| Contract | Handwritten FastAPI route/schema changes precede OpenAPI export, pinned TypeScript/Dart generation, consumer changes, and drift verification. Generated trees are never hand-edited. |
| Web | Laptop-first separate workspace states preserve existing anchors and the protected shell, use no new dependency, and keep labels/errors/accessibility names in Spanish. Mobile UI parity is out of scope. |
| Preservation | Official Samaipata, `AGENTS.md`, archived/history artifacts, and the uncommitted `web-professional-redesign` source files remain untouched by this design phase and protected by implementation path audits. |

### Bounded assumptions

| Area | Chosen assumption | Consequence / deferral |
| --- | --- | --- |
| Selection | Canonical selection lives in the URL/hash and React state. One group may be auto-selected; several groups show a picker; zero groups show a protected empty state. | No server-persisted preferred group or session mutation for selection. |
| Session compatibility | `active_group_id` is a deterministic first-membership bootstrap value for legacy consumers. The selected route can differ. `role` is nullable only when there is no active membership; selected-group responses expose the authoritative role. | Existing single-group consumers remain compatible; generated types must represent the no-group state. |
| Membership history | Add nullable `ended_at` to the existing `(group_id, account_id)` row. `ended_at IS NULL` is active. Rejoining reactivates the row only after a new valid join/link choice. | Membership audit history beyond first creation and last active state is not a product surface. |
| Group names | Creation trims and rejects blank names, keeps the existing maximum length, and does not introduce global name uniqueness. | A later product decision may add scoped uniqueness through a separate spec change. |
| Outing dates | Store optional informational `start_date` and `end_date` only if the API slice needs them; name and lifecycle are the required fields. | No calendar, recurrence, scheduling, reminder, or date-filter behavior. |
| Outing names | Names are required and trimmed; names are not unique within a group in the first version. | Stable IDs and creation order disambiguate same-name history. |
| Outing edits | An archived outing cannot be edited. Owner unarchive is the explicit path back to active editing. | No direct mutation of archived metadata. |
| Archived expense writes | Create/edit/delete operations that add, alter, detach, or remove an expense linked to an archived outing are rejected. Existing history remains readable. | This is stricter than merely blocking new associated expenses and protects the read-only rule. |
| Outing derived participants | Outing balances use the full authorized group participant set plus only that outing's source expenses, so zero rows remain explainable and settlement stays deterministic. | A later participant-subset presentation is not inferred by clients. |
| Join token | Generate returns the plaintext token only in the protected generation/regeneration response for owner display/QR creation. Status reads never return token material. SHA-256 of a cryptographically random URL-safe token is persisted. | No expiry, usage limit, multiple current codes, email delivery, or approval queue. |
| Join re-entry | A prior ended membership may rejoin only through a new authenticated consume request and explicit participant choice. An active membership is a conflict. | Participant merge, aliases, and identity replacement are deferred. |
| Link lifecycle | One group-scoped active account-to-participant link exists per account. Ending membership marks the link inactive; rejoin may select another valid participant in the same group. | Historical expense references never point to account links, so no monetary rewrite is needed. |
| API scope | Existing group routes remain; new account collection and lifecycle routes are additive. Optional `outing_id` filters preserve existing group list/balance/settlement routes. | No versioned API fork is introduced. |
| Navigation | A small parser supports canonical hash paths and aliases existing `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo`. | No React Router migration or browser history framework. |

## Current architecture anchors

The design extends, rather than replaces, these observed seams:

- `backend/app/adapters/db/tables.py` owns `Account`, `Group`, `GroupMembership`, `Participant`, `Expense`, child contribution/beneficiary rows, and hashed `AuthSession` persistence.
- `backend/app/application/ports.py` contains repository protocols and the transaction-bound `UnitOfWork`; `backend/app/adapters/db/repositories.py` supplies SQLAlchemy adapters and `uow.py` wires source repositories.
- `AuthorizationService` and `api/deps.py` currently derive membership/role from the requested group. The membership lookup must become multi-group-aware without accepting client role claims.
- `AuthService` and `api/routes/auth.py` own opaque-cookie session identity, CSRF initialization, logout invalidation, and the browser `204` anonymous probe. The multi-group change must preserve those transport semantics.
- `app/main.py` constructs request-scoped repositories/services and one shared `GroupEventBroadcaster`. New mutation services use the same post-commit publisher seam.
- `DerivedService` currently reads all group expenses and calls the existing balance/settlement domain services. It will receive an explicit group or outing scope and continue to persist no derived results.
- The web protected boundary is `SessionProvider` → `ProtectedRoute` → `ProtectedShell` in `web/src/app`. Existing feature panels use group-aware TanStack Query keys and the generated TypeScript client.
- `web/src/core/websocket.ts` accepts only `data_changed` and invalidates group queries. It remains a signal adapter; the new implementation extends the invalidation key set but does not interpret event data.
- `web-professional-redesign` currently owns uncommitted presentation changes in the protected shell, CSS, auth, expense, participant, balance, settlement, and group-settings surfaces. Those bytes are a protected input, not a base to overwrite.

## Domain and persistence design

### Existing group and membership records

Keep `Group.owner_account_id` as the single immutable owner authority and keep role derivation as `account_id == owner_account_id` for an active membership. Add the following to `GroupMembership`:

- `ended_at: nullable timestamp`, default `NULL`.
- An index on `(account_id, ended_at, group_id)` for account group listing and active authorization.
- Existing primary key `(group_id, account_id)` remains the uniqueness boundary.

The active membership predicate is `ended_at IS NULL` and the account must also be active. Group creation inserts the group and the owner membership in one transaction. The service verifies the owner membership before commit. A database-level foreign key continues to ensure the owner account exists; application tests enforce the owner-membership invariant because a simple foreign key cannot express that cross-row condition.

Ending a membership sets `ended_at` and does not cascade or delete group-owned records. The owner membership is never endable. A rejoin clears `ended_at` only inside the authenticated join transaction after token and participant-choice validation.

### Outings

Add an `outings` source table:

- `id` UUID primary key.
- `group_id` non-null foreign key to `groups` with group index.
- `name` non-empty bounded string.
- Optional `start_date` and `end_date` if included in the frozen API contract.
- `archived_at` nullable timestamp; `NULL` is active.
- `created_at` and `updated_at` timestamps.
- Stable index `(group_id, created_at, id)`.
- Unique constraint `(id, group_id)` to support composite same-group foreign keys.

The service, not the client, enforces that active outings are writable, archived outings are readable-only, and delete is allowed only when no expense references exist. A database foreign key from expenses prevents orphaned outing references even if a service path is bypassed.

### Expense-to-outing integrity

Add nullable `outing_id` to `expenses`. Preserve every existing row as `NULL`, so the official Samaipata records remain general group expenses.

Enforce same-group ownership twice:

1. The service loads the requested group and outing in the same unit of work and rejects a mismatch before adding children.
2. PostgreSQL receives a composite foreign key `(outing_id, group_id) → (outings.id, outings.group_id)` backed by the outing unique constraint. Because `outing_id` is nullable, existing general expenses remain valid; a non-null association cannot cross groups.

`ExpenseRecord`, repository methods, schemas, serializers, and generated types expose `outing_id: UUID | null`. Expense history ordering remains stable creation order. The expense repository accepts an optional outing filter for reads and returns all expenses for the default group list.

### Account-participant links

Add `account_participant_links`:

- `group_id`, `account_id` composite primary key.
- `participant_id` non-null.
- `ended_at` nullable; `NULL` is the active link.
- `created_at` and `updated_at`.
- Composite foreign keys to `(group_id, account_id)` membership and `(group_id, participant_id)` participant identity.
- Index `(group_id, participant_id)`.

Add a participant unique constraint `(id, group_id)` to support the composite participant foreign key without changing participant IDs or existing name uniqueness. The link is never used as an authorization role or as a substitute for participant identity. On membership exit/removal, mark the link ended. On rejoin, validate the new choice and replace/reactivate the single active link in the same transaction. Expense child rows continue to reference only `participants.id`; they are never rewritten.

### Current reusable join code

Add `group_join_codes` with one row per group:

- `group_id` primary key and foreign key to `groups`.
- `token_hash` fixed 32-byte binary value.
- `generation` monotonically increasing integer or UUID generation identifier.
- `created_at`, `revoked_at`, and `updated_at` timestamps.
- Index on `token_hash` for consume lookup.

The token source generates at least 256 bits of randomness and returns a URL-safe representation. Persistence stores `sha256(token_bytes)` only. The service must not log raw tokens, place them in unrelated records, or include them in a group summary. Generation creates the row when absent; regeneration replaces the hash, increments generation, clears `revoked_at`, and invalidates the previous token. Revocation marks the row unusable. A status endpoint returns only `has_current_code`, generation, and timestamps. The generation/regeneration response contains the plaintext once so the owner can copy or render a QR code in the protected UI.

### Migrations and downgrade policy

Use additive Alembic revisions with explicit downgrades and data-preserving defaults:

| Revision boundary | Source change | Downgrade policy |
| --- | --- | --- |
| Workspace foundation | Membership `ended_at` and active-list indexes; no existing membership becomes inactive. | Reversible in disposable environments; no source deletion. |
| Outings | `outings` table and constraints. | Drop only when no outing data exists; production rollback prefers forward compatibility. |
| Scoped expenses | Nullable `expenses.outing_id`, outing composite constraint, participant composite uniqueness. | Remove column only after linked data is migrated or in a disposable reset; never silently convert linked expenses to general expenses. |
| Join/membership | Account-participant links and current join-code table; membership/link status fields if not already present. | Revoke codes first; preserve membership/history and use forward migration once durable joins exist. |

Each revision is tested upgrade/downgrade on an isolated database and tested against the official fixture. Existing group, participant, expense, contribution, beneficiary, and session rows must survive upgrades unchanged.

## Application, ports, and service boundaries

### Repository ports

Extend `ports.py` with small interfaces rather than exposing SQLAlchemy to use cases:

- `GroupRepository.list_for_account(account_id, active_only=True)`, `create`, and `find_by_id`.
- `MembershipRepository.list_for_account`, `find_for_account_in_group`, `create_or_reactivate`, `end`, `count_active_owners`, and `find_active_by_group_account`.
- `OutingRepository.list_by_group`, `find_by_id`, `create`, `update_active`, `archive`, `unarchive`, `delete_if_empty`, and `has_expenses`.
- `AccountParticipantLinkRepository.find_active`, `upsert_active`, and `end`.
- `JoinCodeRepository.get_current_for_update`, `create`, `replace_hash`, `revoke`, and `find_by_hash_for_update`.
- `ExpenseRepository` methods accept `outing_id` on records and optional `outing_filter`; child validation remains group-scoped.
- `UnitOfWork` exposes the new repositories and continues to commit once on successful exit, rolling back on any exception.

Repository adapters must normalize UUIDs consistently with existing adapters, use group predicates on every query, and return application records rather than ORM rows where an application port already exists.

### Services

Use one service per domain boundary with explicit transaction ownership:

- `WorkspaceService`: list memberships, create an empty group, and build selected-group summary metadata. Selection itself is not persisted.
- `OutingService`: create/edit active outings for any member; archive/unarchive/delete-empty for owners; reject archived writes and non-empty deletion.
- `ScopedExpenseService` or the existing `ExpenseService` extension: validate nullable outing association, reject archived outing writes, preserve all existing participant/contribution/beneficiary rules, and publish after commit.
- `MembershipService`: owner remove and member leave, final-owner protection, history-preserving end semantics.
- `JoinService`: owner code lifecycle and authenticated token consumption with explicit participant link/create choice in one unit of work.
- `DerivedService`: `get_balances(group_id, outing_id=None)` and `get_settlement(group_id, outing_id=None)`; group scope queries all source expenses, outing scope queries exact matching `outing_id`.

Every mutating service follows: authorize actor → validate group/resource scope → validate domain command → mutate source rows in one UoW → commit → publish one group invalidation. No publisher call occurs before commit or for reads. If publisher delivery fails, the committed REST mutation remains successful according to the existing broadcaster isolation behavior.

### Authorization matrix

| Operation | Any active member | Owner only | Explicit denial |
| --- | ---: | ---: | --- |
| List account groups / read selected group and history | Account/session or member | — | No session; ended membership; other group |
| Create group | Authenticated account | — | No session |
| Create/edit active outing | Yes | — | Archived outing is read-only |
| Archive/unarchive outing | No | Yes | `forbidden` |
| Delete outing | No | Yes, only if no expenses | `forbidden` or `outing_not_empty` |
| Create/edit/delete ordinary group expense | Yes, subject to existing rules | — | Archived-linked expense writes are read-only |
| Create/manage current join code | No | Yes | `forbidden` |
| Consume join code | Authenticated non-active member | — | Anonymous, invalid/revoked, active duplicate |
| Link/create participant during join | Joining account's transaction | — | Cross-group/invalid choice |
| Remove another member | No | Yes | Cannot remove owner |
| Leave group | Yes, except fixed owner | — | `final_owner_exit` |
| Change settlement policy | Existing owner/member policy rules | Existing matrix | Preserve baseline behavior |

`AuthorizationService` should accept operation names for the new matrix, but it must continue ignoring any client role value. `require_group_scoped_access` remains the shared FastAPI dependency for group paths; account-scoped group listing/creation uses current identity plus a service-level account ID and never accepts a group role claim.

## API contract and error design

### Endpoint shape

Use the existing `/api/v1` prefix and preserve existing group routes:

| Surface | Route shape | Notes |
| --- | --- | --- |
| Account group list | `GET /api/v1/groups` | Authenticated account scope; returns active memberships, role, and summary metadata only. |
| Group creation | `POST /api/v1/groups` | Authenticated account; atomically creates owner membership and empty group. |
| Group summary/settings | Existing `GET/PATCH /api/v1/groups/{group_id}` | Membership and role rechecked; selected ID is not trusted. |
| Outings | `GET/POST /groups/{group_id}/outings`, `GET/PATCH/POST archive/unarchive/DELETE /groups/{group_id}/outings/{outing_id}` | Archive/unarchive/delete operations are separately authorized. |
| Group expense history | Existing `/groups/{group_id}/expenses` with optional `outing_id`/scope query | Default returns all group expenses; explicit outing filter returns only linked expenses; general filter returns `outing_id = null`. |
| Expense writes | Existing create/edit/delete routes with nullable `outing_id` | Same-group and archived-outing rules enforced server-side. |
| Derived results | Existing `/groups/{group_id}/balances` and `/settlement` with optional `outing_id` | Server-derived integer cents; no persisted ledgers. |
| Members | `/groups/{group_id}/members`, `/members/{account_id}`, and `/leave` | Read active members; owner remove; member leave. |
| Join-code status/lifecycle | `/groups/{group_id}/join-code`, `/join-code/regenerate`, `DELETE /join-code` | Status excludes plaintext; create/regenerate returns it once. |
| Join consumption | `POST /api/v1/groups/join` | Token resolves the group; authenticated account submits exactly one existing-participant or new-participant choice. |
| Events | Existing `/groups/{group_id}/events` | Frame remains exactly `{"type":"data_changed"}`. |

The selected group is not written to `/auth/session` and there is no selection endpoint. A legacy session response returns a deterministic first active group for compatibility; the web group picker owns subsequent selection. For zero active groups, `active_group_id` and `role` are nullable and the account remains authenticated.

### Schemas

Handwritten Pydantic schemas must use `extra="forbid"` for commands. Important shapes:

- `GroupSummary`: `id`, `name`, `settlement_policy`, `role`, `member_count` if available, and empty-state counts; no unauthorized child data.
- `OutingResponse`: `id`, `group_id`, `name`, optional dates, `archived`, timestamps, and server-derived summary fields only where explicitly specified.
- `ExpenseWriteRequest`: existing fields plus `outing_id: UUID | None`.
- `JoinCodeConsumeRequest`: `code` plus exactly one discriminated choice: `participant_id` or `new_participant_name`; reject both/neither before mutation.
- `JoinCodeResponse`: plaintext `code` only for generation/regeneration; `JoinCodeStatus` never includes it.
- `MemberResponse`: account-safe identity, role, active status, and participant link metadata only when authorized; never password/session/token data.
- `ErrorResponse`: stable `error_code` and human-readable message, preserving the existing envelope.

Stable new codes and status mapping:

| Code | HTTP | Meaning |
| --- | ---: | --- |
| `invalid_outing_reference` | 422 | Missing, malformed, or cross-group outing reference. |
| `archived_outing_read_only` | 409 | Mutation targets an archived outing or linked expense history. |
| `outing_not_empty` | 409 | Owner attempted to delete an outing with expenses. |
| `invalid_join_code` / `revoked_join_code` | 422 | Token cannot authorize a join; response does not disclose group membership. |
| `duplicate_membership` | 409 | Account already has active membership in the resolved group. |
| `invalid_participant_link_choice` | 422 | Choice is malformed, cross-group, or points to an unavailable participant. |
| `duplicate_participant_link` | 409 | Account already has an active group participant link. |
| `final_owner_exit` | 409 | Fixed owner membership cannot be ended without ownership transfer. |
| `member_not_found` | 404 | Target member is not an active member in the requested group. |
| `forbidden` | 403 | Role or membership does not permit the operation. |

Existing `401`, `403`, `404`, `409`, and `422` semantics remain authoritative. Error paths must be atomic and must not publish invalidation.

## Data flow and invariants

### Bootstrap and selection

1. `SessionProvider` performs its existing single session probe and preserves `204` signed-out, `200` authenticated, and `401` unusable-cookie behavior.
2. After authenticated `200`, the web enables the account group query. It does not fetch group resources from `active_group_id` before membership list data is available.
3. The group list is the only source for selectable IDs. One result may be auto-selected; multiple results render the picker; zero results render authenticated empty state with create action.
4. A canonical hash route may contain a selected group or outing ID, but route parsing never authorizes it. The group query must contain that ID before the workspace is enabled.
5. The group endpoint independently checks session, active membership, and server-derived role before returning data. A stale/deep-linked ID goes to a safe selection/forbidden state without rendering protected child data.

### Mutation and invalidation

1. Browser unsafe requests keep the current CSRF/origin dependency.
2. The route obtains the current session identity and requested group authorization context.
3. The application service validates all references in the requested group, including same-group outing and participant-link constraints.
4. The UoW commits source rows atomically. Derived balances and settlement are not stored.
5. Exactly one post-commit invalidation is published for the mutated group. Join, membership, outing, expense, and code lifecycle mutations do not add a payload or second frame.
6. Clients invalidate and refetch REST queries. A WebSocket outage does not block manual refresh or successful REST mutation feedback.

### Monetary derivation

- Group scope: participants are the authorized group's participant rows; source expenses are all rows with `expense.group_id = group_id`, including `outing_id IS NULL` and non-null rows.
- Outing scope: participants remain the authorized group set; source expenses are exactly rows with `expense.group_id = group_id AND expense.outing_id = outing_id`.
- General expenses are never copied into an outing view and are never allocated by the client.
- Existing integer-cent split, residual, exact-zero, archived participant, stable order, and greedy settlement algorithms are reused unchanged.
- The client only formats server integers through the existing shared formatter.

### Cache and identity isolation

Use explicit key factories with account and scope dimensions:

```text
["account", accountId, "groups"]
["group", groupId, "summary"]
["group", groupId, "members"]
["group", groupId, "outings"]
["group", groupId, "expenses", "all"]
["group", groupId, "expenses", "general"]
["group", groupId, "expenses", "outing", outingId]
["group", groupId, "balances", outingId ?? "group"]
["group", groupId, "settlement", outingId ?? "group"]
```

On logout/session expiry, clear all protected queries as today. On group switch, remove or disable the prior selected workspace queries before enabling the new group; do not use previous data as placeholder content under the new key. On membership removal/leave, clear the affected group cache and re-fetch the account group list. WebSocket invalidation for selected group invalidates all applicable group/outing keys and the account group list; it never replaces data from the frame.

## Web information architecture

### Navigation model

Add a small pure parser/serializer under an additive workspace module. Canonical route states are:

- `#/groups`
- `#/groups/{groupId}/summary`
- `#/groups/{groupId}/outings`
- `#/groups/{groupId}/outings/{outingId}`
- `#/groups/{groupId}/outings/{outingId}/expenses`
- `#/groups/{groupId}/expenses`
- `#/groups/{groupId}/participants/{participantId}`
- `#/groups/{groupId}/balances`
- `#/groups/{groupId}/settlement`
- `#/groups/{groupId}/settings`

The parser also maps `#gastos`, `#balances`, `#liquidacion`, `#participantes`, and `#grupo` to the currently selected group. Existing anchor IDs remain in the DOM where the redesign and test contracts require them. Back/deep-link behavior is implemented with `window.location.hash` and `hashchange`; no router dependency or replacement of the protected shell is allowed.

### Screen responsibilities

- **Groups:** account-scoped list, create form, role/status, and explicit no-groups state.
- **Summary:** group name, active/archived outing counts, group-wide expense total, server-derived balances/settlement entry points, and loading/error/forbidden states.
- **Outings:** active and archived sections, member create/edit, owner lifecycle actions, and empty state.
- **Outing detail:** read-only archived banner, outing expenses, scoped balances/settlement, and no general-expense allocation.
- **General/group expenses:** group-wide history and general-only view; expense editor preserves existing participant form contracts.
- **Participant detail:** group-scoped identity/history without conflating account and participant.
- **Balances/settlement:** existing server order and formatter, with optional outing scope.
- **Settings/membership:** owner join-code lifecycle, member list/removal, leave action, final-owner error, and settlement policy compatibility.

Every screen has explicit loading, empty, forbidden, validation, archived/read-only, and recoverable error states. User-facing labels, actions, and accessibility names remain natural Spanish. Controls keep visible focus and at least the existing 44px interaction target. Laptop-first means wide layouts are optimized first; mobile parity is not added as a hidden requirement.

### Redesign compatibility gate

The uncommitted redesign is not a disposable working tree. The implementation must obey these rules:

1. Stages 0, 1, 3–7 may modify no `web-professional-redesign` source file and no redesign artifact.
2. Additive feature modules, query factories, schemas, and tests may be developed independently, but the protected shell cannot be integrated by overwriting the current `App.tsx` or CSS candidate.
3. The first shell integration slice must run on a branch/worktree whose base includes the exact preserved redesign candidate, or must wait until that change is committed/archived. The integration is additive and reviewed as a three-way change; it is never a reformat or replacement of redesign hunks.
4. Before each web apply, inspect changed paths. A dirty redesign path or a conflict that cannot be resolved without discarding its bytes is a blocker and stops the slice.
5. Rollback of this change reverts only workspace integration and feature files; it does not revert or clean the redesign.

## OpenAPI and generated-client workflow

For every API-affecting stage, use this exact order:

1. Update the owning living specs and stage tests first; Stage 0 must already be complete.
2. Write handwritten FastAPI route, schema, service, and error changes.
3. Export the contract from the backend:

   `python -m backend.scripts.export_openapi`

4. From `web/`, regenerate the pinned TypeScript client:

   `npm exec -- openapi-generator-cli generate -i ../contracts/openapi.json -g typescript-fetch -o src/generated/api --skip-validate-spec --additional-properties=supportsES6=true`

5. From `web/`, regenerate the pinned Dart-Dio client:

   `npm exec -- openapi-generator-cli generate -i ../contracts/openapi.json -g dart-dio -o ../mobile/lib/generated/api --skip-validate-spec --additional-properties=serializationLibrary=json_serializable`

6. Build generated Dart serialization parts with `dart pub get` and `dart run build_runner build --delete-conflicting-outputs` in `mobile/lib/generated/api` when the frozen contract changes generated Dart models.
7. Update handwritten web consumers and test seams only after the generated contract exists.
8. Run `python -m backend.scripts.check_contract_drift --cwd .` as the contract gate. The drift script's temporary export/regeneration path is the final reproducibility proof.

`contracts/openapi.json`, `web/src/generated/api/**`, and `mobile/lib/generated/api/**` are outputs. No stage may fix a generated diff by editing output. If a generated diff approaches or exceeds 800 changed lines, split the preceding handwritten API boundary into smaller endpoint batches before implementation continues; do not omit security or acceptance coverage.

## Strict-TDD test seams and fixtures

Strict TDD remains mandatory: RED focused failure, GREEN smallest implementation, TRIANGULATE invalid/isolation cases, REFACTOR with focused and relevant full gates. This design phase runs no tests; later apply actors own the evidence.

### Backend unit seams

- Workspace service: account group ordering, empty creation, owner/member role, zero child rows, no-group account, and duplicate/invalid names.
- Authorization: active versus ended membership, cross-group ID, client role ignored, owner-only operation matrix, final-owner protection.
- Outing service: member create/edit, archived read-only, owner archive/unarchive, non-empty delete conflict, cross-group outing.
- Join service: hash lookup, revoke/regenerate invalidation, reusable consumption, duplicate membership, exact one-of participant choice, link/create rollback, token non-disclosure.
- Membership service: member leave, owner removal, history preservation, ended member access denial, rejoin semantics.
- Derived service: all-expense group scope, exact outing filter, general exclusion, exact zero sum, stable transfer order.

### Backend integration and acceptance seams

Add isolated database/API fixtures for:

- two accounts and two groups with intentionally asymmetric memberships;
- an authenticated account with zero groups;
- a newly created empty group;
- active and archived outings with and without expenses;
- general and outing-linked expenses in the same group;
- join-code generation, regeneration, revoke, reusable consumption, duplicate and cross-group choices;
- member removal/leave while preserving historical participant and expense rows;
- WebSocket sessions for `g1` and `g2`, asserting one frame only for the mutated group;
- migration upgrade/downgrade and idempotent fixture setup.

The official Samaipata fixture is never a convenient test factory for feature mutations. It remains four exact source expenses, all-general, with the canonical balances and transfer order. Regression tests assert source count, descriptions, amounts, contributor/beneficiary relationships, session behavior, exact zero sum, and invalidation-only frames separately from new fixtures.

### Web seams

Use Testing Library behavior/structure assertions rather than pixel snapshots:

- session bootstrap and no protected render before authentication;
- group list, create, no-group, one-group auto-selection, multi-group switching, stale deep link, and query cache isolation;
- outing active/archived controls and read-only states;
- general versus outing expense lists and nullable payloads;
- server-derived balance/settlement values and no client calculation;
- join-code owner/member settings, membership removal/leave, and structured error messages;
- existing anchor aliases, keyboard focus, accessible names, Spanish labels, and WebSocket invalidation/refetch behavior.

## Staged delivery plan

The chain remains `stacked-to-main`: each slice targets the preceding slice; only the integrated tracker branch targets main. Forecasts include source, tests, migration, contract, generated output, and task-artifact changes for the slice. They are not permission to consume the full range.

| Stage | Bounded slice | Main touched surfaces | Forecast | Rollback boundary |
| ---: | --- | --- | ---: | --- |
| 0 | Policy/spec synchronization | Living OpenSpec specs, `project-context.md`, `docs/sdd-evolution.md`; no product code | 180–340 | Revert only the new living-policy amendment before code exists. Never touch `AGENTS.md` or archived artifacts. |
| 1 | Workspace backend and account contract | Group/membership ports, repository/service/routes/schemas, auth compatibility, migration, backend tests, generated contract outputs | 620–790 | Revert workspace source/migration/contract slice; preserve existing single-group source rows and redesign. |
| 2 | Workspace web foundation | Additive group query/navigation/workspace modules, protected group picker/create/empty screens, generated TypeScript consumer, web tests; shell integration only behind redesign gate | 560–780 | Revert new workspace UI/query modules and integration adapter; keep backend groups and redesign intact. |
| 3 | Outing lifecycle | Outing table/migration, ports/repository/service/routes/schemas, generated outputs, lifecycle tests | 610–790 | Revert outing migration/code only before durable outing data; otherwise roll forward or hide writes. |
| 4 | Nullable expense association | Expense migration/composite FK, repository/service/schema/client changes, general/outing list tests | 560–760 | Revert only association write/read surface; never convert existing linked data to general expenses. |
| 5 | Scoped derived results | Derived service scope, balance/settlement query contract, isolated monetary tests, query key additions | 500–720 | Revert outing-derived reads while retaining source association and group-wide behavior. |
| 6 | Join-code and participant link | Hashed current code, owner lifecycle, authenticated consume transaction, link/create persistence, API/generated outputs, tests | 650–800 | Revoke/disable code endpoints and preserve existing memberships/history; no data deletion. |
| 7 | Membership lifecycle | Active/ended membership behavior, owner remove/member leave, final-owner protection, invalidation, tests | 520–740 | Disable leave/remove writes or roll back the service slice while preserving inactive/history rows. |
| 8 | Web financial workspace | Outing/general expense screens, scoped summary/balance/settlement/participant states, hash-compatible navigation, web tests | 650–800 | Revert this web slice only; keep backend source and redesign untouched. |
| 9 | Web membership/settings and final integration | Join-code/membership settings, empty/forbidden/read-only recovery, accessibility/laptop-first proof, full regression and contract gate | 500–760 | Revert final web integration/settings slice; preserve all server source history and redesign. |

Before each apply actor, the native SDD attempt authority receives the exact stage label, evidence goal, `--max-changed-lines` bound, and changed-path scope. A `blocked` or `complete` acquisition stops that stage. Counts are taken from the final normalized candidate; caller-authored counters are not stored in this design or tasks artifact.

Stage 0 must be complete and validated before Stage 1. Each API stage freezes its handwritten contract before generation. Each web stage remains dependent on the matching backend and generated output. Stage 9 is not allowed to compensate for omitted backend or authorization tests.

## Verification and rollout gates

At each stage:

1. Confirm the previous stacked stage is green and its rollback boundary is known.
2. Acquire native runtime authority before runtime-bearing apply/verify work.
3. Run strict-TDD focused evidence, migration/contract checks where applicable, and changed-path/changed-line audit.
4. Normalize source-mutating files before candidate freeze; subsequent verification must run against exact frozen bytes.
5. Preserve the official Samaipata and WebSocket invalidation regression gates.
6. Settle the native attempt with bounded evidence before moving to the next stage.

The integrated final gate includes the affected backend tests, complete backend suite, backend lint, web tests, web typecheck, web build, contract drift check, migration startup against PostgreSQL, and laptop-first/manual accessibility checks. Manual browser verification is required for the final web stages; it must not be represented as passed from structural tests alone.

## Rollback and recovery

- **Policy:** Before product code, revert only Stage 0 living-spec amendments if the product decision is withdrawn. Historical artifacts and `AGENTS.md` remain unchanged.
- **Database:** Alembic downgrades are for disposable environments or pre-data validation. Once new groups, outings, links, or joins exist, prefer a forward corrective migration or release rollback that preserves source data.
- **Workspace:** Hide or revert new list/create/selection affordances while preserving the protected single-group route and existing source rows. Never expose an anonymous fallback.
- **Outings/expenses:** Restore a compatible API/client release or disable new writes while keeping readable source history. Never detach outing expenses automatically.
- **Join:** Revoke all current tokens and disable generation/consumption. Existing memberships, links, participant records, and expense history remain intact.
- **Membership:** Stop new leave/remove requests if needed; do not delete ended membership rows or rewrite participant/expense history.
- **Generated contracts:** Restore handwritten API sources, re-export, regenerate both clients with the pinned workflow, and verify drift. Never hand-edit generated output to simulate rollback.
- **Web:** Revert only this change's additive workspace/integration slices in reverse order. Do not clean, reset, or overwrite `web-professional-redesign` files.

## No-go decisions

The implementation must stop and return to specification review rather than improvise any of the following:

- public registration, account creation through QR, anonymous join, email invitation, password recovery, OAuth, approval queue, notifications, or general account directory;
- ownership transfer, delegated administrators, multiple current join codes, token expiry, usage limits, or plaintext token persistence;
- participant merge, account/participant identity conflation, cross-group aliases, or historical name snapshots;
- client-side authorization, role persistence, balance/split/settlement calculation, optimistic monetary writes, or local durable group truth;
- a new WebSocket payload, WebSocket monetary authority, or a second invalidation for one committed mutation;
- a router/framework/styling dependency, mobile UI/domain parity, or a redesign rewrite;
- editing `AGENTS.md`, archived/history artifacts, official Samaipata records, or generated clients by hand;
- deleting non-empty outings, deleting participant/expense history on membership exit, or converting linked expenses into general expenses during rollback;
- exceeding 800 changed lines in any slice, hiding generated churn, or using the historical 600-line configuration as a substitute for the current limit.

## Risks and mitigations

| Risk | Level | Mitigation |
| --- | --- | --- |
| Group ID, stale route, or cache leaks another group's data | Critical | Account-scoped list, server membership dependency on every route, group-first query keys, no previous-data placeholder on switch, two-group isolation tests. |
| Session compatibility breaks no-group or mobile consumers | High | Keep opaque session transport and legacy bootstrap fields, make nullability explicit in the contract, regenerate both clients, test zero/one/multiple memberships. |
| Join token is exposed or replayed incorrectly | High | Cryptographically random token, hash-only persistence, lock current row, revoke/regenerate generation, authenticated CSRF-protected consume, no logs/plaintext status. |
| Account and participant identities drift | High | Dedicated composite link table, explicit one-of choice, same-group composite FK, independent participant history tests. |
| General expense is double-counted in outings | High | Nullable source field, exact SQL scope predicate, separate group/general/outing query keys, derived-service tests. |
| Archived outing is mutated through a stale route | High | Service/API lifecycle guard on every write, stable conflict code, read-only UI as secondary protection. |
| Generated contract diff exceeds slice budget | High | Freeze API in small endpoint batches, count generator output, hard-stop and split before apply; never edit generated files manually. |
| Uncommitted redesign is overwritten | High | Protected-path audit, additive modules, integration only on preserved redesign base, blocker on unresolved conflict, no reset/clean operation. |
| Migration damages Samaipata | High | Additive defaults, isolated migration tests, unchanged idempotent seed, exact official regression fixture, controlled downgrade policy. |
| Membership exit removes history or owner safety | High | End-state columns rather than cascades, immutable owner invariant, final-owner conflict test, history-preserving acceptance fixtures. |
| Scope expands into mobile delivery | Medium | Generated Dart output only when contract requires it; no mobile UI/domain tasks or mobile change-artifact edits. |

## Completion definition

The design is complete when Stage 0 has synchronized the accepted policy, every implementation stage has a dependency-ready task boundary at or below 800 changed lines, and the final integrated system demonstrates:

- authenticated multi-group list/create/select with no cross-group reads or stale cache rendering;
- empty creator-owned groups and protected selected-group navigation;
- active/archived outing lifecycle with owner-only archive/delete-empty behavior;
- nullable, same-group expense association and distinct group-versus-outing derived results;
- reusable hashed authenticated join with explicit participant link/create atomicity;
- membership removal/leave with fixed-owner protection and preserved history;
- exact FastAPI → OpenAPI → generated TypeScript/Dart workflow and drift proof;
- invalidation-only WebSocket behavior;
- laptop-first Spanish web screens with existing anchors and protected shell preserved;
- unchanged official Samaipata source data and exact balances/settlement;
- no new dependency, no mobile UI parity, no public account/invitation product, and no modification of the independent uncommitted redesign.
