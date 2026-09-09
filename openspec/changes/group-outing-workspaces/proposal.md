# Proposal: Group Outing Workspaces

## Decision first

Create `group-outing-workspaces` as a new domain change, independent from `web-professional-redesign`. It extends the current single-active-group MVP into authenticated multi-group workspaces with outings, scoped expenses, controlled authenticated joining, membership lifecycle, and a laptop-first web information architecture.

The complete backend, persistence, OpenAPI, generated-client, web, and test surface is too large for one delivery change. Delivery MUST therefore use a staged, chained sequence. Every implementation slice is a separately reviewable change/PR with a hard limit of **800 changed lines** (additions plus deletions). The historical `openspec/config.yaml` value of `600` is not the governing limit for this proposal; it is historical configuration and MUST NOT be used silently in place of the current user-facing 800-line constraint. If a slice forecasts more than 800 changed lines, it MUST be split before implementation starts.

The first coherent product slice is the authenticated workspace foundation: an account can list groups, create an empty group, select a group, and open a protected selected-group workspace. Outings, join codes, and scoped expense behavior follow in dependent slices; they are not silently removed from the change.

This proposal is planning-only. It does not modify product code, tests, generated clients, baseline or historical artifacts, `AGENTS.md`, or the uncommitted `web-professional-redesign` change.

## Product outcome

An existing account can work in more than one group without exposing data across group boundaries:

1. The account signs in through the existing protected session flow.
2. The account sees only groups in which it is a member, can create a group, and can select a group.
3. A created group makes its creator both owner and member and starts with no outings, participants, or expenses.
4. A selected group opens a separate workspace with group summary, outings, expenses, participants, balances, settlement, and settings surfaces as the dependent slices land.
5. The owner can generate a reusable QR/join code for other already-authenticated accounts. The code remains valid until revoked or regenerated; regeneration invalidates the previous code.
6. After joining, the account holder explicitly chooses either an existing participant in that group or a new participant. The account identity and participant identity remain separate.
7. Members can create and edit outings. Owners control outing archive/unarchive and can delete only an empty outing. Archived outings remain historical and read-only.
8. Expenses can be general group expenses or associated with exactly one outing. Group totals include both kinds; an outing total includes only its associated expenses, so general expenses are never repeated in an outing result.
9. Owners can remove members and members can leave. Ownership transfer is not part of the first version.

FastAPI remains the authorization and monetary authority, PostgreSQL remains the durable source of truth, and clients continue to render server-derived integer-cent results.

## Intent and current-state gap

The current MVP assumes one active seeded group. Its canonical groups, API, and clients specifications explicitly prohibit group discovery, group creation, group switching, multi-group workflows, and invitation-like membership flows. The current web shell is also a single protected composition organized around one active group and hash anchors.

That model is now insufficient for users who manage multiple trips or outings. It makes group selection implicit, gives no lifecycle for outings, mixes general and outing-specific expense meaning, and has no controlled path for an existing account to join another group. The desired change is a domain and workspace expansion, not a continuation of the visual redesign.

## Baseline amendment and supersession record

The following current living rules are deliberately superseded or amended by this new change:

| Baseline rule | New rule for this change | Boundary that remains unchanged |
| --- | --- | --- |
| The groups specification exposes one active group and forbids group discovery, creation, switching, and multi-group workflows. | Authenticated accounts can list memberships, create groups, and select a group. | Every read and mutation remains membership-scoped and server-authorized. |
| The API specification has no account-scoped group-list/create surface or membership-join surface. | Add account-scoped group listing/creation/selection semantics, outing and membership endpoints, and protected join-code operations. | No anonymous group endpoint is introduced. |
| The API, clients, and persistence specifications exclude invitations and broader account management. | Add a narrow bearer join-code mechanism for accounts that already have valid sessions. | No public registration, account creation, email invitation, password recovery, OAuth, or anonymous join flow is introduced. |
| The clients specification assumes one protected group and no group selector. | Add laptop-first group selection and selected-group workspace navigation. | Mobile UI/domain parity remains outside this change's first version and remains under mobile ownership. |
| Expenses have only group scope. | Add nullable outing association and group-versus-outing derivation rules. | Existing participant identity, integer cents, exact zero-sum, and server-derived settlement rules remain authoritative. |

The implementation planning phases MUST amend the **canonical living** specifications and evolution map before product code:

- `openspec/project-context.md` for the active-change boundary and the controlled authenticated join exception.
- `openspec/specs/groups/spec.md` for multi-group membership, group creation, selection, outing lifecycle, and membership lifecycle.
- `openspec/specs/api/spec.md` for the new protected endpoint and error contract.
- `openspec/specs/persistence/spec.md` for outings, nullable expense association, join-code state, and account-participant links.
- `openspec/specs/expenses/spec.md` and the settlement-related specification for general versus outing-scoped derivation.
- `openspec/specs/clients/spec.md` for web workspace responsibilities and the explicit mobile boundary.
- `docs/sdd-evolution.md` to register this active change and explain which MVP clauses it supersedes.

Archived change artifacts and preserved historical baseline documents MUST remain untouched. `AGENTS.md` MUST remain untouched; its final-delivery boundary still excludes invitations and this separate change does not reopen or modify final-delivery work. The amendment is specifically a controlled, authenticated join capability in this new change, not a general invitation or account-management product.

## Bounded first implementation slice

### Workspace foundation (first user-visible slice)

The first slice includes only the protected multi-group foundation:

- An authenticated account can list groups for which the server confirms membership.
- An authenticated account can create a group. The creator is persisted as owner and member, and the group has no outings, participants, or expenses.
- A selected group is carried by explicit web navigation state and validated by the server on every group-scoped request.
- The account/session response remains account-scoped; selection is not a client-trusted authorization claim and does not weaken the existing cookie, CSRF, origin, or session rules.
- The web client has a protected group-selection screen and a selected-group summary/empty workspace screen.
- Existing single-group Samaipata behavior remains available and unchanged while the new foundation is added.
- OpenAPI is regenerated from handwritten FastAPI sources, and generated TypeScript/Dart outputs are produced only through the pinned generation workflow.
- Focused backend/API/web tests cover group isolation, creation, empty-state behavior, selection transitions, session expiry, and cache reset/refetch on selection.

The first slice explicitly does **not** include outings, join codes, participant linking, membership removal/leave, expense association, new balance semantics, or the complete screen set. Those are dependent slices below, not omitted requirements.

## Domain rules for the complete change

### Groups and memberships

- Accounts can list groups they belong to, create a group, and select a group.
- The creator becomes owner and member automatically.
- A new group starts empty: no outings, no participants, and no expenses.
- The server returns only memberships visible to the authenticated account and rechecks membership for every selected-group resource.
- Owner/member roles remain server-derived. No client-supplied group ID or role can grant access.
- The owner can remove members, and a member can leave. Ownership transfer is out of the first version.
- Membership removal or leaving does not delete participant records or historical expenses. The account-participant link is removed or made inactive according to the final persistence design; group history remains intact.

### Controlled authenticated joining

- Only an already-authenticated account can consume a join code.
- The owner can generate, revoke, and regenerate the current group code.
- The code is reusable until revoked or regenerated. Regeneration invalidates the previous token. No time expiry or email delivery is added to this version.
- The code is treated as a bearer secret: token material is not stored in plaintext, is not emitted in logs, and is never accepted through an anonymous group-data endpoint.
- A valid join creates membership atomically and rejects cross-group references, duplicate membership, and invalid participant-link choices without partial mutation.
- After joining, the account holder chooses to link to an existing participant in that group or create a new participant. The account and participant remain separate identities.
- No public registration, account creation through QR, password recovery, OAuth, email invitation, pending approval product, or general account directory is introduced.

### Outings

- An outing belongs to exactly one group and has a stable identity.
- The outing name is required. Optional start/end dates are an implementation assumption for this version and are informational only; date filtering and scheduling are out of scope.
- Any group member can create or edit an outing.
- Only the owner can archive or unarchive an outing.
- An active outing accepts associated expenses. An archived outing is read-only, but its expenses remain in history and group totals.
- An empty outing can be deleted by the owner. An outing with expenses is retained and cannot be deleted as a shortcut for history removal.
- Archive/unarchive and delete operations are server-authorized and group-scoped; the web client may hide unavailable actions but cannot be the authorization boundary.

### Expenses and derived results

- Every expense remains owned by one group and has a nullable outing association.
- `outing_id = null` means a general group expense.
- A non-null outing reference must belong to the same group. Cross-group outing references are rejected atomically.
- Group summary, balance, and settlement include all general and outing-associated expenses.
- An outing summary, balance, and settlement include only that outing's associated expenses. General expenses are never repeated or implicitly allocated to an outing.
- Active outings accept associated expense writes. Archived outings are read-only; the implementation assumption is that creating or editing an expense associated with an archived outing is rejected while existing history remains readable. General group expenses remain governed by the group's normal active workflow.
- Existing participant, contributor, beneficiary, residual, archive, validation, integer-cent, exact-zero, and server-derived settlement rules remain unchanged unless a later specification explicitly amends them.

## Laptop-first web experience

The web experience is a set of separate screens/pages rather than one expanded dashboard:

- group list, creation, and selection;
- selected-group summary;
- outings list and outing detail;
- outing expenses;
- general expenses;
- participant detail;
- balances;
- settlement;
- group and membership settings, including owner join-code and membership actions.

The implementation assumption is to extend the existing hash-based navigation with stable route state rather than add a routing dependency. Existing anchors remain reachable where applicable (including the current expense, balance, settlement, participant, and group anchors). Deep links must still go through the protected shell and server membership validation. The first version is laptop-first; mobile UI parity is out of scope and remains independently owned.

The web implementation MUST avoid overwriting the uncommitted `web-professional-redesign` work. New screens should use additive seams or a separately isolated delivery branch. A conflict with those uncommitted files is a delivery blocker, not permission to replace or reformat the redesign.

## Assumptions and deferred low-risk details

These assumptions make the confirmed handoff implementable without inventing broader product scope. They must be made explicit in the downstream spec/design and can be narrowed there without reopening the confirmed business rules:

| Area | Bounded assumption | Explicitly deferred |
| --- | --- | --- |
| Group selection | Selection is URL/client navigation state; every request is server-validated. If the account has one group, the client may select it automatically; if it has several, it shows the group picker. | Persisting a preferred/last group in the server session. |
| Join token | One current reusable token per group; revoke and regenerate invalidate it; no expiry. | Multiple concurrent generations, usage limits, approval queues, and notifications. |
| Participant link | A join completes with one group-scoped account-to-participant choice, protected by a uniqueness constraint. | Participant merge, identity replacement, cross-group aliases, and historical name snapshots. |
| Outing dates | Name required; dates optional and informational. | Calendar, scheduling, reminders, recurrence, and date-based filtering. |
| Outing permissions | Any member creates/edits; owner archives/unarchives and deletes only empty outings. | Finer-grained roles, delegated administrators, and transfer of ownership. |
| Archived outings | They remain readable with expenses and derived history; associated expense writes are rejected. | Reopening/edit workflows for archived expenses beyond the explicit unarchive action. |
| Owner exit | The owner cannot leave or remove the final owner without a transfer mechanism. | Ownership transfer and deactivated-owner recovery. |
| Navigation | Existing hash anchors are preserved while new workspace routes are added without a new dependency. | A router migration, mobile navigation parity, or a new URL framework. |
| Fixture | The official Samaipata group and exact four-expense outcome remain unchanged. Outing and join behavior uses isolated tests/fixtures. | Adding outings or new expenses to the official walkthrough seed. |

## Affected areas

- **Living OpenSpec policy:** canonical group, API, persistence, expense/settlement, and client specifications plus the evolution map.
- **Backend domain and persistence:** SQLAlchemy tables, reversible Alembic migrations, repositories/ports, group and membership services, outing lifecycle, nullable expense association, join-code state, account-participant links, and server authorization.
- **Authentication/session:** account-scoped group listing and selection semantics while preserving opaque sessions, CSRF/origin enforcement, logout invalidation, and protected-route behavior.
- **REST/OpenAPI:** account-scoped group operations, outing operations, membership/join-code operations, participant-link operations, nullable `outing_id`, scoped balances/settlement, stable errors, and invalidation publication after committed mutations.
- **Generated clients:** TypeScript and Dart outputs only through contract export and generation. No hand editing. No mobile UI/domain parity is implied by regenerated Dart code.
- **Web:** protected group picker, selected-group workspace, separate outing/expense/summary/participant/balance/settlement/settings screens, TanStack Query keys and cache transitions, hash-compatible navigation, laptop-first accessibility and empty/error states.
- **Tests:** strict-TDD backend unit/integration tests, migration/seed tests, authorization/isolation tests, OpenAPI drift checks, web query/navigation/accessibility tests, and regression coverage for the official fixture and invalidation-only WebSocket behavior.
- **Fixture and documentation:** preserve the official Samaipata fixture; add isolated test fixtures for empty groups, multiple groups, outings, joining, and membership lifecycle. Do not alter historical change artifacts or the redesign.

## Explicit non-goals

- Public registration, account creation through QR, password recovery, OAuth, email invitations, anonymous group data, or a general account directory.
- Ownership transfer, delegated administrators, invitation approval queues, notifications, or multi-use policy beyond the reusable current code.
- Mobile UI/domain parity in this first version. Mobile ownership and existing mobile change boundaries remain intact.
- Client-side authorization, client-side balances, client-side settlement, optimistic monetary writes, or local durable group truth.
- Multiple currencies, custom/weighted splits, OCR, payments, settlement-paid tracking, advanced analytics, or real-time collaborative editing.
- A new WebSocket payload. The channel remains authenticated, group-scoped, post-commit, and exactly invalidation-only: `{"type":"data_changed"}`.
- Rewriting `web-professional-redesign`, changing its visual direction, or making it a prerequisite for this domain change.
- Editing `AGENTS.md`, archived OpenSpec artifacts, historical baseline documents, generated clients by hand, or the official Samaipata data to make the new feature appear complete.

## Staged delivery and line-budget strategy

The slices below are intentionally narrow. The estimates are planning forecasts, not permission to exceed the cap. Each slice MUST have its own changed-path audit and stop/split decision before launch. A later slice depends on the previous slice's tests, contract, and migration state being green.

| Stage | Chained slice | Bounded contents | Forecast target |
| --- | --- | --- | --- |
| 0 | Policy/spec amendment | Amend canonical living specs and `docs/sdd-evolution.md`; record supersession; no product code or generated output. | 150–350 changed lines |
| 1 | Workspace backend foundation | Group listing/creation, owner/member persistence, membership authorization, selection contract, migrations, focused backend/API tests. | 500–780 |
| 2 | Workspace web foundation | Protected group picker, create-group flow, selected-group empty workspace, query/cache transitions, generated-client consumers, focused web tests. | 450–760 |
| 3 | Outing lifecycle | Outing persistence and CRUD, active/archived behavior, owner-only archive/unarchive, empty-only deletion, API/client contract, focused tests. | 500–780 |
| 4 | Scoped expense and derived results | Nullable outing association, same-group integrity, active/archived write rules, group-wide versus outing-only balances/settlement, API/client contract, focused tests. | 600–800 |
| 5 | Membership and authenticated join | Hashed reusable join token, owner revoke/regenerate, authenticated join, participant-link/create choice, owner removal/member leave, atomicity and isolation tests. | 550–800 |
| 6 | Web financial workspace | Outing detail, outing/general expense screens, group/outing summaries, balances, settlement, participant detail, server-owned money display, hash-compatible navigation and web tests. | 650–800 |
| 7 | Web membership/settings and integration | Join-code and membership settings, empty/error/forbidden states, full regression, contract drift, official fixture proof, accessibility/laptop-first checks, and delivery evidence. | 400–750 |

If a generated contract or a test expansion causes any forecast to exceed 800, split that stage at the next handwritten API or screen boundary. Generated outputs MUST be regenerated, not manually compressed. The chain strategy is `stacked-to-main`: each slice targets the preceding slice, and only the integrated tracker branch targets main. This keeps reviewer context bounded and makes rollback possible at a domain boundary.

The 800-line cap applies to every slice in this change. It does not authorize borrowing capacity from `web-professional-redesign`, and it does not convert the historical 600-line configuration into a hidden second limit.

## Risks and mitigations

| Risk | Level | Mitigation |
| --- | --- | --- |
| Cross-group data leakage through selected IDs, caches, or route parameters | Critical | Keep account-scoped membership listing server-owned, validate every group resource, use group-aware query keys, clear/reset dependent caches on selection, and add two-group isolation tests. |
| Bearer join-code exposure or replay creates unauthorized membership | High | Require an existing valid session, store only a hash, avoid logs/plaintext persistence, make one current token generation authoritative, support owner revoke/regenerate, and test duplicate/invalid/cross-group joins atomically. |
| Account identity is conflated with participant identity | High | Persist the relationship separately, require an explicit link/create choice, enforce group-scoped uniqueness, and preserve participant history independently of membership lifecycle. |
| General expenses are double-counted in outing views | High | Store nullable `outing_id`, derive group and outing queries separately on the server, and test that null expenses never appear in outing totals or settlement. |
| Archived outings become mutable through expense or stale UI paths | High | Enforce lifecycle checks in the service/API boundary, return stable errors, keep archived history readable, and treat UI affordances as non-authoritative. |
| API changes drift from generated web/mobile clients | Medium | Update handwritten FastAPI schemas/routes first, export OpenAPI, regenerate both clients, run drift checks, and never edit generated output manually. |
| The full surface exceeds the review budget | High | Use the staged table, forecast before each slice, hard-stop at 800 changed lines, and defer polish rather than compressing security or acceptance coverage. |
| New web work overwrites the uncommitted redesign | High | Keep the changes isolated, use additive files/seams or an isolated branch, audit paths before writing, and stop when a non-overlapping integration boundary is unavailable. |
| Migration or seed changes damage the official fixture | High | Use reversible migrations, preserve existing general expenses, keep the official seed idempotent and unchanged, and use separate fixtures for new domain cases. |
| Mobile ownership is accidentally absorbed | Medium | Limit mobile impact to generated contract output when required; do not add Flutter UI/domain tasks or change mobile-owned OpenSpec artifacts. |
| Baseline “no invitations” language is interpreted inconsistently | Medium | Record the explicit supersession: no public/email invitation product is added, while this new change adds only authenticated reusable join codes. Update living specs before code and preserve historical copies. |

## Rollback and recovery

- **Policy rollback:** Revert only the new living-spec/evolution-map amendment if implementation has not started. Never rewrite archived or historical baseline artifacts to hide the decision.
- **Workspace rollback:** Revert the workspace UI/API slice or disable the new creation/list surface while retaining protected single-group behavior. Do not expose data anonymously and do not remove existing group source records as an automatic rollback.
- **Migration rollback:** Use Alembic downgrades only for controlled disposable environments where no new data must be preserved. Once new groups, outings, memberships, or joins exist in a durable environment, prefer a forward-compatible corrective migration or a release rollback that preserves source data rather than destructive automatic downgrade.
- **Join rollback:** Revoke all issued join tokens and disable token generation/consumption through the protected API. Existing memberships and participant history remain; rollback must not delete group history or replace participant identities.
- **Outing/expense rollback:** Restore the last compatible API/client release or hide new write affordances while preserving readable source data. Never convert outing-linked expenses into general expenses automatically, because that would change monetary meaning.
- **Web rollback:** Revert only the affected chained web slice. Existing hash anchors, protected session behavior, server-derived money, and the uncommitted visual redesign remain untouched.
- **Contract rollback:** Restore handwritten API sources, regenerate OpenAPI clients through the normal workflow, and run drift checks. Never hand-edit generated files to simulate a rollback.
- **Business-rule rollback:** If a confirmed rule changes, update the proposal, living specs, design/tasks, tests, and contract before changing code. Do not encode a replacement rule in implementation alone.

## Success criteria

The proposal and its staged implementation are successful when:

1. The living specifications and evolution map clearly record that this change supersedes the single-group/no-switcher baseline only for this new change, while archived historical artifacts and `AGENTS.md` remain unchanged.
2. Every authenticated account can list only its memberships, create an empty group with owner/member identity, and select a group without cross-group access.
3. The first slice is independently reviewable and stays at or below 800 changed lines; no stage silently relies on the historical 600-line config.
4. The owner can manage a reusable join code for already-authenticated accounts, regeneration invalidates the prior code, and invalid/duplicate/cross-group joins produce no partial mutation.
5. A joining account can link to an existing group participant or create a new participant without conflating account and participant identity.
6. Outing lifecycle permissions and active/archived behavior are enforced server-side; empty outings may be deleted by the owner, while outings with expenses remain history.
7. General and outing-associated expenses are persisted and derived distinctly: group totals include both, outing totals include only linked expenses, and no general expense is repeated.
8. The web provides the requested separate laptop-first screens, preserves applicable existing hash anchors, keeps protected empty/error/forbidden states explicit, and does not require mobile parity or a new dependency.
9. FastAPI, PostgreSQL, integer cents, exact-zero/server-derived monetary behavior, CSRF/auth/roles, invalidation-only WebSocket behavior, OpenAPI generation, mobile ownership, and the official Samaipata fixture remain intact.
10. Strict TDD evidence covers the new invalid states, migrations, authorization, isolation, cache transitions, generated-contract parity, and full regression gates before any stage is marked complete.

## Next step

Proceed to `sdd-spec`. It should convert this proposal into canonical living-spec amendments and acceptance scenarios first, preserving the staged boundaries and the 800-line per-slice delivery constraint. `sdd-design` should then resolve the repository/session/data-model details, and `sdd-tasks` should produce one reviewable task set per chained slice before product code is written.
