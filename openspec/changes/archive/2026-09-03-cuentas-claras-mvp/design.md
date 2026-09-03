# Design: Cuentas Claras MVP — protected, server-authoritative full stack

## Decision first

Build the MVP as a small monorepo with three independently runnable packages:

- **FastAPI/Python + PostgreSQL/SQLAlchemy/Alembic** is the only monetary and authorization authority.
- **React/Vite/TanStack Query/Tailwind** is the primary demonstrable client.
- **Flutter/Bloc-Cubit/Dio** consumes the same authenticated OpenAPI contract and delivers protected, read-mostly parity.

Persist only source data plus the minimum account, group-membership, and server-session records required for protected access. Compute splits, balances, and settlement from source expenses on the server; never persist them as independent truth. Use one opaque, database-backed session cookie for both browser and mobile clients. This gives browser refresh persistence and mobile protected reads without JWT claims, client-stored web secrets, or a second authorization system.

Participant rename is a Must operation. It updates only the participant display name and normalized-name key in one transaction. The participant ID, group membership, expense foreign keys, history attribution, and all monetary results remain unchanged.

All four T-00 decisions are confirmed and are design inputs, not unresolved checkpoints:

| Gate | Confirmed design consequence |
| --- | --- |
| **CC-01** | Assign the complete residual to the first stable creation-order participant in contributor ∩ beneficiary; fall back to the first selected beneficiary in stable order. |
| **CC-02** | Referenced archived participants remain in history, balances, and settlement views, including `Bs. 0.00`; they are excluded from new-expense defaults and retained in referencing edit forms. |
| **CC-03** | Seed owner/member accounts; provide login, logout, protected sessions, and server-derived roles. There is no public registration, recovery, invitation, or OAuth flow. |
| **CC-04** | Provide name-only atomic participant rename with trimmed, case-insensitive normalized uniqueness. Preserve IDs, references, and monetary results. |

## Quick path

1. Bootstrap the three package shells, PostgreSQL, migrations, and actual test runners.
2. Implement the minimal account/session/membership foundation and server authorization dependency, alongside the pure cents/split domain.
3. Add source persistence, participant rename, expense transactions, derived reads, structured errors, and the invalidation-only WebSocket.
4. Freeze FastAPI OpenAPI, generate TypeScript and Dart Dio clients, and run drift checks.
5. Deliver the protected web flow first; then deliver the protected mobile read-mostly views.
6. Run DA-01..DA-07, AO-01..AO-11, auth/rename/security tests, and the under-three-minute seeded demo before any Stretch work.

## Scope and tradeoffs

### Must

- One seeded active group and one owner account relationship.
- One seeded owner account and one seeded member account.
- Login, logout, session identity, fixed-expiry protected sessions, and server-derived `owner`/`member` roles.
- Group membership isolation and an explicit operation authorization matrix.
- Participant add/list, normalized uniqueness, archive/reactivate, protected deletion, and rename.
- Expense create/edit/delete with multiple contributors and exact integer-cent validation.
- Server-derived balances and deterministic greedy settlement with an exact zero-cent invariant.
- PostgreSQL source persistence and reversible Alembic migrations.
- REST/OpenAPI contract, generated TypeScript and Dart clients, and invalidation-only WebSocket.
- Responsive protected React flow and Flutter protected read-mostly parity.
- Idempotent demo seed, recovery instructions, strict-TDD evidence, and the Samaipata walkthrough.

### Stretch, only after Must is green

- Mobile expense create/edit/delete controls.
- Rich group-settings screens beyond `settlementPolicy`.
- Global minimum-transfer optimization behind the deterministic greedy result.

Public registration, self-service account creation, password recovery, invitations, OAuth, multi-group UI, group discovery/creation, additional currencies, custom splits, payments, notifications, settlement-paid tracking, participant merge, identity replacement, historical name snapshots, and independent balance/transfer ledgers are outside this change.

### Why server-side opaque sessions

Use a random opaque session token whose hash is stored in PostgreSQL, rather than JWTs or a client-managed role token.

- **Benefits:** logout and expiry are immediate server decisions; role changes and membership removal take effect on the next request; no client can forge a role claim; the same session authority works for web and Flutter.
- **Cost:** each protected request performs a small session lookup and the database is required for authorization. This is acceptable for one FastAPI process and the MVP's single group.
- **Intentional omission:** no refresh-token subsystem, token rotation product, account administration, or external identity provider. A fixed session TTL and re-login are sufficient for the demo and reduce implementation surface.

## Monorepo/module map

```text
proyecto_1/
├── backend/
│   ├── pyproject.toml
│   ├── app/
│   │   ├── main.py
│   │   ├── api/
│   │   │   ├── deps.py                  # DB, session, membership dependencies
│   │   │   ├── errors.py                # stable HTTP error envelopes
│   │   │   ├── schemas/
│   │   │   │   ├── auth.py              # login/session identity shapes
│   │   │   │   ├── common.py
│   │   │   │   ├── groups.py
│   │   │   │   ├── participants.py      # includes RenameParticipantRequest
│   │   │   │   ├── expenses.py
│   │   │   │   ├── balances.py
│   │   │   │   ├── settlement.py
│   │   │   │   └── errors.py
│   │   │   └── routes/
│   │   │       ├── auth.py
│   │   │       ├── groups.py
│   │   │       ├── participants.py
│   │   │       ├── expenses.py
│   │   │       ├── balances.py
│   │   │       ├── settlement.py
│   │   │       └── events.py
│   │   ├── domain/
│   │   │   ├── errors.py
│   │   │   ├── money.py
│   │   │   ├── models.py
│   │   │   ├── expense_rules.py
│   │   │   ├── split_service.py
│   │   │   ├── balance_service.py
│   │   │   └── settlement_service.py
│   │   ├── application/
│   │   │   ├── ports.py                 # repositories, clock, hasher, token source
│   │   │   ├── unit_of_work.py
│   │   │   ├── auth_service.py          # login/logout/session identity
│   │   │   ├── authorization.py         # membership and operation policy
│   │   │   ├── group_service.py
│   │   │   ├── participant_service.py   # add/archive/reactivate/delete/rename
│   │   │   ├── expense_service.py
│   │   │   └── derived_service.py
│   │   └── adapters/
│   │       ├── config.py
│   │       ├── security/
│   │       │   ├── passwords.py          # Argon2id adapter
│   │       │   └── sessions.py           # token hash/cookie/CSRF helpers
│   │       ├── db/
│   │       │   ├── session.py
│   │       │   ├── tables.py
│   │       │   ├── repositories.py
│   │       │   └── uow.py
│   │       └── events/
│   │           └── broadcaster.py
│   ├── migrations/
│   ├── scripts/
│   │   ├── export_openapi.py
│   │   └── seed_demo.py
│   └── tests/
│       ├── unit/domain/
│       ├── unit/application/
│       ├── integration/api/
│       ├── integration/auth/
│       ├── integration/persistence/
│       └── acceptance/
├── contracts/
│   └── openapi.json
├── web/
│   ├── package.json
│   ├── src/
│   │   ├── app/
│   │   │   ├── App.tsx
│   │   │   ├── auth/session-provider.tsx
│   │   │   └── routes/protected-route.tsx
│   │   ├── generated/api/               # generated; never hand-edit
│   │   ├── core/
│   │   │   ├── http-client.ts           # credentials, CSRF, 401 mapping
│   │   │   ├── query-client.ts
│   │   │   ├── cents-formatter.ts
│   │   │   ├── websocket.ts
│   │   │   └── theme.css
│   │   └── features/
│   │       ├── auth/
│   │       ├── group/
│   │       ├── participants/            # rename form and lifecycle actions
│   │       ├── expenses/
│   │       ├── balances/
│   │       └── settlement/
│   └── tests/
├── mobile/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── app/
│   │   ├── core/
│   │   │   ├── auth/secure_cookie_store.dart
│   │   │   ├── config/
│   │   │   ├── formatters/cents_formatter.dart
│   │   │   └── theme/tokens.dart
│   │   ├── generated/api/               # generated; never hand-edit
│   │   ├── data/
│   │   │   ├── auth/auth_repository.dart
│   │   │   ├── repositories/
│   │   │   └── websocket/
│   │   ├── domain/read_models/
│   │   └── presentation/
│   │       ├── auth/session_cubit.dart
│   │       ├── group/
│   │       ├── participants/
│   │       ├── expenses/
│   │       ├── balances/
│   │       └── settlement/
│   └── test/
├── infra/docker-compose.yml
├── docs/
│   ├── api-client-generation.md
│   └── demo-samaipata.md
└── openspec/
```

`docs/requerimiento-docente.md` remains a read-only baseline and is not changed by this design or its implementation.

## Dependency direction

```text
FastAPI routes/schemas + transport adapters
                    ↓
application auth, authorization, and use cases + ports
                    ↓
domain money/split/balance/settlement rules
                    ↑                         ↓
adapters implement ports: PostgreSQL, password hashing, sessions, broadcaster

React/Flutter presentation
          ↓
query/repository adapters
          ↓
generated OpenAPI clients
          ↓
protected FastAPI REST/WebSocket contract
```

- `domain` imports only standard-library types and its own modules. It knows nothing about cookies, CSRF, FastAPI, SQLAlchemy, or Flutter/React.
- `application` owns use-case orchestration, authenticated actor context, group membership checks, operation policy, transactions, rename invariants, and post-commit invalidation. It receives ports for persistence, hashing, time, and token generation.
- `api` owns HTTP parsing, cookie/header transport, CSRF/origin checks, schema validation, and error mapping. It never calculates money or accepts a client role as authority.
- `adapters` implement ports and own SQLAlchemy mappings, migrations, password hashing, opaque session token hashing, encrypted mobile cookie storage, and event transport.
- `web` and `mobile` use generated operations through a repository/query boundary. Neither client has an authorization service, a money-calculation service, or a durable copy of group truth.
- The `role` value in a client state model is display metadata from `GET /auth/session`; it is never sent back as a permission assertion.

## Authentication and authorization architecture

### Source tables

The account and session model is intentionally small and separate from participant identity. A participant named Ana is not a login account and does not receive credentials.

```text
accounts
  id UUID primary key
  login_name text not null unique
  password_hash text not null
  is_active boolean not null default true
  created_at timestamptz not null

groups
  id UUID primary key
  name text not null
  owner_account_id UUID not null references accounts(id)
  settlement_policy text not null default 'owner_only'
  created_at timestamptz not null

group_memberships
  group_id UUID not null references groups(id) on delete cascade
  account_id UUID not null references accounts(id) on delete cascade
  created_at timestamptz not null
  primary key (group_id, account_id)

sessions
  id UUID primary key
  token_hash bytea not null unique
  account_id UUID not null references accounts(id) on delete cascade
  created_at timestamptz not null
  expires_at timestamptz not null
  revoked_at timestamptz nullable
```

The application/seed invariant requires the group owner account to have a membership row. Role is **not** persisted in `group_memberships`: the server derives `owner` when `account_id == groups.owner_account_id`, otherwise `member` for another active member. Exactly one owner exists because `groups.owner_account_id` is singular and the group is created with that owner membership.

The remaining source tables are:

```text
participants
  id, group_id, name, normalized_name, archived_at, created_at
expenses
  id, group_id, description, amount_cents, created_at, updated_at
expense_contributions
  expense_id, participant_id, amount_cents
expense_beneficiaries
  expense_id, participant_id
```

All group-owned tables carry or join through `group_id`. There are no balance, transfer, split, or session-role tables. Store only a hash of the opaque session token; the raw token exists only in the response cookie and the client's transport layer.

### Session transport choice

Use a single cookie transport for browser and Flutter:

- Cookie name: `cc_session`.
- Cookie value: cryptographically random opaque token; the server stores only its SHA-256 hash.
- Browser flags: `HttpOnly`, `SameSite=Lax`, `Path=/api`, `Secure` in production. Local HTTP development may omit `Secure` only for loopback origins.
- TTL: configured fixed lifetime, default eight hours for the demo. There is no refresh-token endpoint; an expired session requires login again.
- Browser requests use `credentials: "include"`. CORS allows only configured development/deployment origins and `Access-Control-Allow-Credentials: true`.
- Flutter uses Dio with a cookie manager. Its persistent cookie jar stores the session and CSRF cookies through an encrypted `flutter_secure_storage` adapter; presentation code cannot read or display the raw session value.

This is preferable to localStorage or a Dart-visible bearer token for the web requirement: a refresh automatically resends the HttpOnly cookie, while script code cannot exfiltrate it through normal XSS access. The mobile cookie jar supplies the same server contract without adding a second bearer-token API.

### CSRF and origin protection

Cookie authentication requires a small CSRF boundary for unsafe requests:

- The server issues a separate random `cc_csrf` cookie, not HttpOnly, from the initial `GET /auth/session` response when one is absent. That request may return `401`; it still establishes the CSRF cookie.
- Web `POST`, `PATCH`, and `DELETE` requests send `X-CSRF-Token` equal to the `cc_csrf` cookie value. The API compares the header and cookie using a constant-time comparison.
- The API validates `Origin` for browser requests against `CORS_ORIGINS`; a disallowed origin fails before application processing. Mobile requests still send the CSRF header from the secure cookie jar. A missing browser origin is not accepted for browser mutations.
- The WebSocket handshake validates the session cookie, group membership, and allowed origin. The channel is read-only invalidation transport and does not use a monetary payload.
- CSRF failures return the same structured envelope with `error_code: csrf_failed` and HTTP 403. No mutation is attempted.

The CSRF cookie is not an authorization claim. It only proves that the caller can read the companion non-HttpOnly cookie; the server session and membership remain authoritative.

### Passwords and demo credentials

Use an Argon2id password-hashing adapter behind an application port. Login compares the supplied password to the stored hash and does not reveal whether a username exists or is inactive.

The seed creates stable development identities such as `demo.owner` and `demo.member`. Passwords are supplied through `DEMO_OWNER_PASSWORD` and `DEMO_MEMBER_PASSWORD` environment variables or an equivalent local secret input. The repository contains no production password, deployment credential, session token, or password hash copied from production. A local `.env.example` documents variable names with placeholders; the demo runbook explains how the presenter supplies development-only values before seeding.

For idempotency, an existing seeded account is matched by stable `login_name` and is not assigned a new password hash on every seed run. A development reset may explicitly replace the password after a database reset. Tests use ephemeral fixture credentials and never depend on a committed production secret.

### Login/logout/session identity flow

1. The client calls `GET /api/v1/auth/session` with credentials. A valid session returns the account, active group, role, expiry, and CSRF cookie. No session returns `401 unauthorized` or `session_expired` without group data.
2. The client submits `POST /api/v1/auth/login` with `{login_name, password}` and the CSRF header. The server verifies the account, creates the session row in one transaction, commits it, and then sets `cc_session` and `cc_csrf`. The response contains the server-derived identity and role, never a client-provided role.
3. For every group request, FastAPI resolves the session cookie, hashes it, checks `revoked_at` and `expires_at`, loads the account, checks membership in the requested group, and derives the role from `groups.owner_account_id`.
4. `POST /api/v1/auth/logout` marks the current session `revoked_at` in a transaction and clears the cookies in the response. A subsequent request with the old cookie receives `401 unauthorized`; an expired session receives `401 session_expired`.
5. A revoked/expired session never reaches a group repository or mutation use case. The client clears protected cache/state and routes to login.

Session expiry is tested with an injected clock. There is no anonymous fallback and no pre-auth group query.

### Operation authorization matrix

The server applies this matrix after session validation and group-membership validation. Client affordances are only hints; a stale UI must still be safely rejected by the server.

| Operation | No session | Authenticated group member (`member`) | Owner (`owner`) | Rule |
| --- | --- | --- | --- | --- |
| `GET /auth/session` | 401 | 200 | 200 | Returns server identity/role only. |
| `POST /auth/login` | Allowed endpoint | Re-authenticates | Re-authenticates | Seeded credentials only; invalid credentials 401. |
| `POST /auth/logout` | 401/explicit no-session result | 204 and revoke | 204 and revoke | Never grants access. |
| Read group, participants, expenses, balances, settlement | 401 | Allowed | Allowed | Membership required; group-scoped. |
| Participant add/archive/reactivate/rename/delete | 401 | Allowed | Allowed | Validated by domain rules; delete remains protected by references. |
| Expense create/edit/delete | 401 | Allowed | Allowed | Full source mutation is protected but not owner-only. |
| WebSocket group channel | 401 | Allowed | Allowed | Session and membership checked at handshake. |
| `PATCH /groups/{id}` policy while current value is `owner_only` | 401 | 403 `forbidden` | Allowed | Owner-sensitive setting operation. |
| `PATCH /groups/{id}` policy while current value is `any_member` | 401 | Allowed | Allowed | Either authenticated member may change it. |
| Any request for a group without membership | 401 if unauthenticated | 403 `forbidden` | 403 `forbidden` | No cross-group data or mutation. |

The matrix deliberately keeps the existing expense and participant workflow available to authenticated group actors and makes only the existing settlement-policy setting owner-sensitive. It does not create a larger permission product.

## Domain and application boundaries

### Money, split, balance, settlement

The domain rules remain unchanged by authentication:

- Accept expense money as decimal text at the FastAPI boundary, parse exactly once into integer cents, and reject zero, negative, malformed, or more-than-two-decimal input.
- Contributions are explicit positive integer cents whose sum equals the expense amount.
- Equal beneficiary split uses `base = amount_cents // count` and `residual = amount_cents % count`.
- **CC-01:** assign the complete residual to the first participant in stable `created_at, id` order that belongs to both contributor and beneficiary sets; if empty, assign it to the first selected beneficiary in the same stable order.
- Compute `paid_cents - owed_cents` from source rows and assert the sum of balances is exactly zero.
- Produce deterministic greedy transfers from most-negative debtors to most-positive creditors with stable-order tie breaks; never persist transfers.

All authenticated requests use the same `DerivedService`; authentication does not enter the money domain and clients never recalculate it.

### Participant rename use case

`ParticipantService.rename(group_id, participant_id, name, actor)` receives an already authenticated and group-authorized actor.

1. Load the participant within the requested group and lock the target row for update.
2. Trim the name and compute the normalized key with Unicode normalization followed by case folding. Blank input raises `invalid_participant_name`.
3. Check conflict with every other participant in the same group, including archived rows. The database unique constraint `(group_id, normalized_name)` is the final race-safe guard; a concurrent conflict is mapped to `duplicate_participant_name`.
4. Update only `participants.name` and `participants.normalized_name`. Do not update `id`, `group_id`, `archived_at`, expense rows, contribution rows, beneficiary rows, or participant creation order.
5. Flush and commit as one transaction. On any error, roll back and leave the previous name intact.
6. Publish one group-scoped `data_changed` signal only after commit so clients refetch current names and verify unchanged derived values.

The rename request schema is exactly `{name: string}` with unknown fields rejected. It cannot archive, reactivate, delete, merge, reassign, move groups, or change any monetary field. Historical rows resolve the same participant ID and display the current name; the MVP does not invent historical name snapshots.

### Expense transaction

Each expense create/edit/delete uses one `AsyncSession` and one unit-of-work transaction:

1. Resolve session, membership, and operation authorization before opening the mutation use case.
2. Lock the group and edit/delete target as needed.
3. Validate description, parsed cents, contributor/beneficiary membership, participant status rules, contribution total, and the CC-01 split candidate.
4. For edits, validate the complete replacement before deleting/replacing child rows. Referenced archived participants are accepted in the edit command; archived participants are omitted only from a new form's defaults.
5. Flush source rows, recompute derived balances from the transaction view, and assert the exact zero-cent invariant.
6. Commit source data. Any validation, constraint, or invariant failure rolls back every change, so the previous expense and derived results remain intact.
7. Publish `data_changed` only after a successful commit. WebSocket failure never rolls back a successful mutation.

Auth failure, CSRF failure, and membership failure happen before step 2 and cannot partially mutate data.

## Persistence model and constraints

- `accounts.login_name` is unique and active status is checked at login.
- `groups.owner_account_id` references an account; seed/application validation requires it to have a membership row.
- `group_memberships` has a composite primary key and all group repositories query through it.
- `sessions.token_hash` is unique; indexes cover `account_id`, `expires_at`, and `revoked_at`. Expired sessions may be deleted by maintenance, but revocation remains explicit during their valid lifetime.
- Participant names are trimmed for display and normalized for comparison. A unique `(group_id, normalized_name)` constraint includes archived participants.
- Participant foreign keys in expense child tables use restrict semantics; expense-child rows cascade when their expense is deleted.
- All expense and contribution amounts are positive integer PostgreSQL columns. No balance, transfer, owed, paid, or split table exists.
- Group and child IDs are generated as UUIDs in the application. Every repository method takes `group_id` and verifies child references belong to that group.
- Alembic migrations are reversible. Startup does not silently create or mutate the schema.

## REST/OpenAPI contract

Base path: `/api/v1`. Authentication endpoints are not group-scoped; every group-owned endpoint is nested under the requested group.

| Method | Endpoint | Auth | Purpose |
| --- | --- | --- | --- |
| `POST` | `/auth/login` | CSRF/origin boundary | Seeded login; sets protected cookies and returns identity/role. |
| `GET` | `/auth/session` | Optional session | Returns current identity/role or explicit 401; initializes CSRF cookie. |
| `POST` | `/auth/logout` | Valid session | Revokes current session and clears cookies. |
| `GET` | `/groups/{group_id}` | Member | Group name, owner account ID, and `settlementPolicy`. |
| `PATCH` | `/groups/{group_id}` | Matrix above | Accepts only `settlementPolicy`. |
| `GET/POST` | `/groups/{group_id}/participants` | Member | List or add active/archived participants. |
| `PATCH` | `/groups/{group_id}/participants/{participant_id}` | Member | Name-only rename. |
| `POST` | `/groups/{group_id}/participants/{participant_id}/archive` | Member | Archive without removing history. |
| `POST` | `/groups/{group_id}/participants/{participant_id}/reactivate` | Member | Restore normal new-expense selection. |
| `DELETE` | `/groups/{group_id}/participants/{participant_id}` | Member | Succeeds only if never referenced. |
| `GET/POST` | `/groups/{group_id}/expenses` | Member | History or create source expense. |
| `GET/PATCH/DELETE` | `/groups/{group_id}/expenses/{expense_id}` | Member | Read/edit/delete source expense. |
| `GET` | `/groups/{group_id}/balances` | Member | Server-derived balances in stable participant order. |
| `GET` | `/groups/{group_id}/settlement` | Member | Server-derived policy and transfers. |
| `WS` | `/groups/{group_id}/events` | Member | Only `data_changed` invalidation frames. |

### Minimum schema shapes

```text
LoginRequest {
  login_name: string
  password: string
}

SessionIdentityResponse {
  account: { id: UUID, login_name: string }
  active_group_id: UUID
  role: "owner" | "member"
  expires_at: ISO-8601 timestamp
}

GroupResponse {
  id: UUID
  name: string
  owner_account_id: UUID
  settlementPolicy: "owner_only" | "any_member"
}

RenameParticipantRequest {
  name: non-empty string
}

ParticipantResponse {
  id: UUID
  group_id: UUID
  name: string
  archived: boolean
  created_at: ISO-8601 timestamp
}

ExpenseWriteRequest {
  description: non-empty string
  amount: decimal string
  contributors: [{ participant_id: UUID, amount: decimal string }]
  beneficiary_ids: UUID[]
}

ExpenseResponse {
  id: UUID
  group_id: UUID
  description: string
  amount_cents: integer
  contributors: [{ participant_id: UUID, name: string, archived: boolean, amount_cents: integer }]
  beneficiaries: [{ participant_id: UUID, name: string, archived: boolean }]
  created_at: ISO-8601 timestamp
  updated_at: ISO-8601 timestamp
}

BalancesResponse {
  group_id: UUID
  participants: [{ participant_id: UUID, name: string, archived: boolean,
                   paid_cents: integer, owed_cents: integer, balance_cents: integer }]
}

SettlementResponse {
  group_id: UUID
  settlementPolicy: "owner_only" | "any_member"
  settled: boolean
  transfers: [{ from_participant_id: UUID, to_participant_id: UUID,
                from_name: string, to_name: string, amount_cents: positive integer }]
}

ErrorResponse {
  error_code: string
  message: string
  field_errors?: [{ field: string, message: string }]
}
```

Responses contain integer monetary fields only. `amount` is an input-only lexical string. The `role` and participant names in responses are server values. The WebSocket frame is exactly a type-bearing invalidation such as `{ "type": "data_changed" }`; it contains no amount, balance, transfer, role, or participant data.

### Error contract

Every expected error uses `{error_code, message, field_errors?}`. Messages are understandable and do not leak account existence or group data.

| Condition | HTTP | Code | Recovery/use |
| --- | ---: | --- | --- |
| Wrong or inactive seeded credentials | 401 | `invalid_credentials` | Remain on login; no session or group query. |
| Missing, malformed, or revoked session | 401 | `unauthorized` | Clear protected client state and show login. |
| Session past `expires_at` | 401 | `session_expired` | Clear protected state and show re-login message. |
| CSRF mismatch or disallowed origin | 403 | `csrf_failed` | Retry through the configured client transport; no mutation occurred. |
| Authenticated account lacks group membership or policy role | 403 | `forbidden` | Keep data unchanged; explain access is not allowed. |
| Blank participant name | 422 | `invalid_participant_name` | Bind to `name`; keep form editable. |
| Normalized name conflict, active or archived | 422 | `duplicate_participant_name` | Bind to `name`; retain prior identity and money. |
| Referenced participant physical delete | 409 | `participant_in_use` | Suggest archive; retain participant. |
| Invalid money, no participants/beneficiaries, invalid reference, mismatch | 422 | Existing domain codes | Bind to the relevant expense field. |
| Unknown group/participant/expense | 404 | `not_found` | Show a not-found/retry state without data leakage. |
| Verified source corruption/invariant failure | 500 | `persistence_corrupted` | Fail closed and show the documented database reset/reseed path. |

Unexpected failures remain generic server errors and are never represented as a successful mutation. Auth rejection happens before group data access.

## Data flow and atomicity

### Protected web read

```text
React app start
  → GET /auth/session with credentials: include
  → 200 session identity/role OR 401 login state
  → only then enable group-scoped TanStack Query observers
  → generated REST client → FastAPI session + membership dependency
  → repository/source rows → domain derived service
  → integer-cent response → cents formatter → UI
```

`VITE_GROUP_ID` is configuration for the single demo route only. It is checked against the server-provided active group and is never an authorization input. Before authentication, no group query, WebSocket connection, or protected-looking shell renders.

### Protected mobile read

```text
Flutter bootstrap
  → Dio CookieManager restores encrypted cookies
  → SessionCubit GET /auth/session
  → authenticated state with server role OR signed-out/session-expired state
  → read repositories call generated Dart Dio operations
  → Cubits expose loading/loaded/empty/error/recovery states
  → read models → integer cents formatter → protected views
```

A Dio interceptor adds credentials/cookies and CSRF headers, maps one 401 to `SessionCubit.signedOut`/`sessionExpired`, clears the secure cookie jar, and does not retry in a loop. Mobile's Must surface is read-mostly: group/policy, participants including archived and renamed names, expense history, balances, and settlement. It does not render expense create/edit/delete controls before the approved Stretch slice. The generated Dart client still contains the authenticated participant rename operation for contract parity; Must mobile renders the server's renamed identity and does not invent a separate local rename source.

### Mutation and invalidation

```text
client form
  → generated REST mutation + session/CSRF transport
  → FastAPI session/membership/role checks
  → application validation and one UoW transaction
  → PostgreSQL source rows only
  → derived zero-sum verification where monetary source changed
  → commit
  → publish group data_changed
  → clients invalidate/refetch REST queries
```

Rename follows the same post-commit invalidation path, but it changes no monetary source rows. A WebSocket outage does not affect REST reads, refresh persistence, or authorization.

## Client data and UX design

### TanStack Query and protected-route rules

- Session is a query/state boundary, not localStorage truth. The browser persists only the HttpOnly cookie managed by the browser.
- Query keys are group-scoped: `['group', groupId]`, `['participants', groupId]`, `['expenses', groupId]`, `['balances', groupId]`, and `['settlement', groupId]`.
- All group query `enabled` flags depend on authenticated session state and a verified server group ID.
- Successful mutations invalidate affected queries. `data_changed` invalidates the complete active-group set; the frame itself is never parsed for money or role.
- Any `401` from a protected query clears the protected cache and routes to login with either “session expired” or “signed out” state. A `403` remains in the protected shell and presents the server error.
- Rename uses a field-bound form with no optimistic amount change. A successful response replaces the participant name; balances, expenses, and settlement are refetched and must remain identical.

### Flutter Dio/Cubit rules

- Repositories are the only layer allowed to call generated Dio APIs.
- `SessionCubit` owns `unknown`, `signedOut`, `authenticating`, `authenticated`, and `sessionExpired` states. It exposes the server-derived role for display/affordance hints only.
- Read Cubits own loading, loaded, empty, error, and corruption-recovery states. A `data_changed` event triggers reloads; app start and manual refresh always use REST.
- Secure cookie persistence is behind `SecureCookieStore`; screens do not receive raw session or CSRF values.
- Participant read models include `id`, current `name`, and `archived`. History and balances show current server names. No local participant replacement occurs after rename.
- No mobile write affordance is shown for expense mutations in Must; an unavailable action is explained rather than rendered as a dead button.

### Visual tokens and accessibility

Use one semantic token system mirrored in CSS and Flutter. Starting values are implementation inputs, not ad-hoc component colors:

| Token | Web starting value | Flutter mirror | Use |
| --- | --- | --- | --- |
| `surface.warm` | `#FFF9F2` | `warmSurface` | App background |
| `surface.card` | `#FFFFFF` | `cardSurface` | Cards and forms |
| `content.primary` | `#1F2937` | `contentPrimary` | Body/headings |
| `content.muted` | `#4B5563` | `contentMuted` | Supporting text |
| `brand.primary` | `#4338CA` | `brandPrimary` | Primary action/focus |
| `brand.primary.strong` | `#312E81` | `brandPrimaryStrong` | Hover/pressed |
| `finance.credit` | `#166534` | `financeCredit` | Positive balance |
| `finance.debt` | `#9F1239` | `financeDebt` | Negative balance |
| `state.error` | `#991B1B` | `stateError` | Error/recovery |
| `border.default` | `#D6D3D1` | `borderDefault` | Field/divider |
| `focus.ring` | `#7C3AED` | `focusRing` | Visible focus |

The UI requirements are:

- Login has visible labels, autocomplete hints, a password visibility control, disabled/loading submit feedback, inline `invalid_credentials`, and no group data in the DOM/tree before success.
- Rename has a visible label, helper text explaining that identity and balances remain stable, inline `invalid_participant_name`/`duplicate_participant_name`, and focus on the invalid field after submit.
- Positive/negative balances use signs, labels, and icons/text in addition to color. Use tabular figures and the shared `Bs. X,XXX.XX` formatter.
- Body text is at least 16px on mobile with approximately 1.5 line height. Use a 4/8 spacing rhythm, readable desktop measure, and no horizontal scroll.
- Interactive targets are at least 44×44px on web and 48×48dp in Flutter, with at least 8px separation, visible keyboard focus, pressed/disabled states, and safe-area insets.
- Use a consistent vector icon family; do not use emoji as structural icons. Respect keyboard navigation, screen-reader order, `aria-live`/semantic error announcements, reduced motion, Flutter text scaling, and predictable back navigation.
- The web is mobile-first at 375px, then tablet and desktop. Flutter respects safe areas and platform navigation conventions.

## OpenAPI and generated-client workflow

FastAPI/Pydantic route schemas are the only contract source. `contracts/openapi.json` is an exported snapshot, never a hand-maintained second API definition.

1. Bootstrap auth, rename, group, money, expense, derived, and error schemas in FastAPI.
2. Export the document with `python -m app.scripts.export_openapi --output contracts/openapi.json`.
3. Pin the OpenAPI Generator CLI version in the repository's package/tool configuration.
4. Generate the web client with the pinned TypeScript generator and the mobile client with the pinned `dart-dio` generator into their generated directories.
5. Configure the generated web transport for `credentials: include`; configure generated Dio through the repository's cookie/CSRF interceptors.
6. Add a drift command that exports a temporary contract, regenerates into temporary directories, and fails when the committed contract or generated output differs.
7. Treat a contract change as: update FastAPI schema/route → export → regenerate both clients → update repositories/consumers/tests. Never hand-edit generated files.
8. Run web typecheck/build and Flutter analyze/test against the same contract before acceptance.

The OpenAPI document describes cookie security (`cc_session`), the `X-CSRF-Token` requirement for unsafe operations, integer monetary response fields, name-only rename, the stable error envelope, and server-derived role responses. Generated clients carry transport plumbing; authorization remains in FastAPI.

## Seed, migrations, and recovery

- Alembic creates account, group, membership, session, participant, expense, contribution, and beneficiary tables with reversible downgrade steps.
- `seed_demo.py` upserts the stable group, `demo.owner`, `demo.member`, membership rows, `owner_only` policy, Ana/Beto/Carla/Diego in creation order, and the three Samaipata source expenses (`96000`, `40000`, `24000`) benefiting all four.
- Re-running the seed creates no duplicate account, membership, participant, session, or expense. It does not revoke live sessions or overwrite existing account password hashes unless an explicit reset flag is supplied.
- The normal local sequence is PostgreSQL health → `alembic upgrade head` → environment-provided demo credentials → idempotent seed → FastAPI → web/mobile.
- Corrupt source data or a broken zero-sum invariant fails closed as `persistence_corrupted`; no partial balances or invented transfers render. The runbook documents stopping the app, recreating the development database/volume, upgrading, and reseeding. The UI never performs an automatic destructive reset.
- Query caches and mobile cookie/session state are disposable client state. PostgreSQL is the durable source; a stale cache cannot authorize access or replace source data.

## Testing strategy and evidence layers

Strict TDD is active. The initial checkout has no detected runner, so bootstrap creates the shells and runner configuration, then testing discovery is refreshed before feature work. Each behavior follows RED → GREEN → edge-case triangulation → refactor.

| Layer | Required coverage |
| --- | --- |
| Domain unit | Text-to-cents, invalid money, CC-01 contributor intersection/fallback, equal split, balances, zero invariant, greedy settlement. |
| Auth/application unit | Password verification boundary, session creation/revocation/expiry with fake clock, server role derivation, matrix decisions, membership isolation, rename normalization and atomic use-case decisions. |
| Persistence integration | Account/membership/session constraints, token-hash lookup, revoked/expired sessions, group owner membership, unique normalized names including archived, rename FK preservation, restrict/cascade behavior, source-only schema, migration round trip, seed idempotency. |
| API integration | Login/logout/session cookies, refresh-compatible session, 401/403/422/409/404/500 envelopes, CSRF/origin rejection, all protected routes, client role ignored, owner-only/any-member matrix, rename exact request shape, atomic invalid mutations, WebSocket frame content and REST degradation. |
| Web unit/component | Session bootstrap gates queries, login/logout/expiry route behavior, CSRF/credential transport adapter, role display, rename field errors, archived-zero rendering, active-only new defaults, referenced-archived edit form, formatter, invalidation/refetch, no anonymous shell. |
| Mobile unit/widget | Secure cookie-store adapter contract, SessionCubit states, Dio 401 handling, role display, repository mapping, read Cubits/refetch, renamed/archived names, integer formatter, empty/recovery states, no Must expense-write controls. |
| Acceptance/demo | DA-01..DA-07 through the API and seeded environment, then protected web walkthrough, refresh, logout, generated drift, seed idempotency, responsive/accessibility checks. |

Auth tests must use a fake clock and disposable database; no test relies on waiting eight hours. Rename tests compare IDs, all child foreign keys, archived status, history names, balances, settlement, and source monetary rows before and after.

## Must-first sequencing and coherent boundaries

The following boundaries keep the authenticated contract stable before client work. The original `ask-on-risk` delivery strategy is superseded for the remaining delivery plan by the user's explicit `exception-ok` decision; `stacked-to-main`, the hard gates T-CF/T-MG, and the frozen review identity remain unchanged.

1. **Bootstrap and runner discovery:** create backend/web/mobile shells, Docker PostgreSQL, settings, migration harness, health route, and test runners; refresh the project context with real commands.
2. **Protected backend foundation:** implement account/password/session tables, cookie/CSRF transport, login/logout/session identity, membership isolation, server-derived role, and the authorization matrix. In parallel, implement pure cents/split/balance/settlement tests where dependencies are independent.
3. **Domain and source persistence:** implement normalized participant lifecycle including rename, source tables/constraints, expense validation, UoW atomicity, archived visibility, and derived reads. Auth and money tests must be green before client work.
4. **REST and realtime boundary:** implement all protected routes, structured errors, policy behavior, invalidation-only WebSocket, seed, corruption handling, and API integration tests. This boundary must include rename and auth; neither may be an undocumented follow-up.
5. **Contract freeze:** export OpenAPI, generate TypeScript/Dart clients, pin the tools, add drift checks, and stop changing wire shapes while client Must work is built.
6. **Web Must:** login/session/logout, protected route/query gating, participant lifecycle and rename, expenses, balances, settlement, refresh persistence, invalidation/refetch, error/recovery states, and the timed Samaipata rehearsal.
7. **Mobile Must:** secure session Cubit, protected read repositories, server role display, participants/current renamed names, expense history, balances, settlement, and invalidation/refetch. Keep expense write controls out of the Must surface.
8. **Acceptance and handoff:** run DA/AO/auth/rename evidence, fresh seed/reseed, restart/refresh persistence, generated drift, responsive/a11y checks, and the under-three-minute login → record/view → settle → refresh → logout walkthrough.

If time is constrained, stop after the last green Must boundary. Defer mobile expense writes, rich settings, and optimization; never remove protected sessions, server authorization, cents tests, rename safety, generated-contract parity, persistence, or the web demo.

## Acceptance and evidence mapping

### Acceptance datasets

| ID | Exact behavior | Implementation evidence | Verification evidence |
| --- | --- | --- | --- |
| **DA-01** | Seeded Samaipata yields Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`; transfers Diego → Ana `40000`, then Carla → Ana `16000`. | Seed script, balance service, settlement service, protected API responses. | `backend/tests/acceptance/test_da_01_samaipata.py`; seeded API response and web screenshot/transcript. |
| **DA-02** | `10000` cents among Ana/Beto/Carla gives `3334/3333/3333` and exact zero sum. | CC-01 split service and integer-cent parser. | `test_da_02_residual.py`; domain and API assertions for shares and sum. |
| **DA-03** | `30000` among four with Diego excluded gives `10000` owed to each selected participant and zero owed to Diego. | Beneficiary selection validation and split service. | `test_da_03_exclusion.py`; API response and derived balance assertions. |
| **DA-04** | All balances zero produces `settled: true` and an empty transfer list. | Settlement service and response schema. | `test_da_04_settled.py`; API/client empty-state assertion. |
| **DA-05** | Refresh/restart returns the same source data, renamed names, policy, balances, and settlement. | PostgreSQL source persistence, cookie session, derived-on-read endpoints. | `test_da_05_persistence.py`; refresh/restart transcript with before/after payload comparison. |
| **DA-06** | Owner/member login roles, invalid credentials, missing/expired/logout sessions, policy matrix, and logout invalidation behave as specified. | Auth service, session table, authorization dependency, error mapper, client session flows. | `test_da_06_auth.py`; API cookie/clock tests plus web and mobile session tests. |
| **DA-07** | Rename preserves participant ID, all expense references, history attribution, archived status, balances, settlement, and monetary source rows; blank/conflicting names do not change state. | ParticipantService rename, unique constraint, PATCH schema, invalidation path. | `test_da_07_rename.py`; before/after database-key and API-payload comparison, web rename component test. |

### Product outcomes

| ID | Exact acceptance/evidence mapping |
| --- | --- |
| **AO-01** | DA-01 API/seed evidence plus web protected screen verifies the exact Samaipata balances and ordered transfers after login. |
| **AO-02** | DA-02 domain/API evidence asserts `3334 + 3333 + 3333 = 10000` and `sum(balance_cents) == 0`; formatter tests cover the display. |
| **AO-03** | Multi-contributor application/API test asserts exact contribution total, CC-01 intersection residual, empty-intersection fallback, and rejection before persistence on mismatch. |
| **AO-04** | Participant persistence/API tests assert normalized duplicate rejection, archive/reactivate, referenced-delete `409`, never-used delete, rename ID/FK/history preservation, and unchanged derived money. |
| **AO-05** | Transaction tests assert create/edit/delete commit atomically, invalid expense or rename leaves all prior source and derived state unchanged, and `data_changed` is post-commit only. |
| **AO-06** | API/client matrix covers no participants, invalid amount, >2 decimals, no beneficiaries, invalid references, duplicate/blank rename, invalid credentials, missing/expired/revoked session, forbidden policy access, and all-settled empty transfer state with stable codes. |
| **AO-07** | DA-05 plus cookie/session refresh tests prove refresh persistence; logout tests prove the old session is rejected; corruption integration test proves `persistence_corrupted` and documented reset/reseed recovery. |
| **AO-08** | OpenAPI export, generated TypeScript/Dart snapshots, drift check, DTO/repository tests, and WebSocket frame test prove one contract, integer money, server roles, and invalidation-only realtime. |
| **AO-09** | Seed idempotency and a timed fresh-environment transcript prove login → core flow → refresh → logout completes under three minutes with exact results. |
| **AO-10** | DA-06/API authorization evidence proves owner/member role is derived from membership and `owner_account_id`, client role claims are ignored, out-of-group requests are `403`, and policy behavior follows the matrix. |
| **AO-11** | Archived participant integration and client tests prove a referenced zero-balance participant remains visible as `Bs. 0.00`, is omitted from new defaults, and remains available in a referencing edit model. |

### Confirmed decision evidence

| Gate | Required evidence |
| --- | --- |
| **CC-01 confirmed** | `test_da_02_residual.py`, multi-contributor intersection test, empty-intersection fallback test, and acceptance mapping AO-02/AO-03. No entry-order or round-robin implementation is allowed. |
| **CC-02 confirmed** | Archived-zero balance/history test, new-form default test, referencing-edit model test, and AO-11 evidence. |
| **CC-03 confirmed** | DA-06 auth API tests, cookie/session refresh/logout tests, role matrix tests, web protected-route tests, mobile SessionCubit/read tests, and AO-07/AO-10 evidence. |
| **CC-04 confirmed** | DA-07 rename API/persistence tests, unique constraint test including archived rows, before/after ID/FK/money comparison, web field-error test, and AO-04/AO-08 evidence. |

No confirmation gate remains unresolved in this design.

## Risk narrative for 48 hours, three specialists, and 600 changed lines

The reconciled scope is materially larger than the preserved anonymous/local architecture. The remaining PR 9–22 plan contains exactly 14 slices with an estimated **6,030–7,620 authored lines**, excluding generated OpenAPI/client snapshots from authored-line accounting but not from complete review identity. The estimate is directional until implementation measures actual files and tooling.

### Remaining delivery amendment

The original `ask-on-risk` strategy is superseded for PR 9–22 only by the user's explicit `exception-ok` decision. Historical PR 1–8 remain unchanged. PRs 9, 12, 15, 17, 19, 20, and 22 are eligible for an explicit `size:exception` only when native line accounting shows actual authored work above 600 lines; the exception is not automatic and the parent must record it before runtime-bearing apply. T-CF remains required before all client work, T-MG before Stretch, and the review identity remains unchanged.

| Risk | Level | Mitigation and stop rule |
| --- | --- | --- |
| Auth/session work delays the monetary core | High | Parallelize only independent auth/domain RED tests after bootstrap; keep auth to seeded accounts, fixed sessions, login/logout, membership, and the matrix. Stop at the last green Must boundary rather than cutting security tests. |
| Cookie/CSRF behavior differs between React and Flutter | High | Use one cookie contract, one transport adapter per client, disposable API tests for cookies/CSRF/401, and a real browser plus emulator smoke check before client parity is claimed. |
| Client role or group ID becomes an authorization input | High | Require server membership/role on every group request; ignore request role fields; treat configured group ID as routing only; test forged role and out-of-group calls. |
| Rename is implemented as identity replacement or changes history | High | Update only name/normalized name under a unique constraint; compare IDs/FKs/source amounts before and after; no merge/reassign/snapshot feature. |
| Archived-zero behavior is lost in query filtering or forms | Medium | Keep referenced archived records in server read models, separate “new defaults” from “edit references,” and test zero rows explicitly. |
| Two clients and generated code overwhelm three specialists | High | Freeze OpenAPI before client work; deliver web Must first; keep mobile read-mostly; generated output is never hand-edited; defer mobile writes and polish. |
| PostgreSQL/seed is not demo-ready | Medium | Docker health check, reversible migrations, env-provided demo passwords, stable seed keys, no-op rerun test, fresh-environment rehearsal, and explicit reset path. |
| Money authority leaks into a client | High | Integer-cent response DTOs, one formatter per client, no client split/balance/transfer functions, server-derived response tests, and WebSocket frame-content assertions. |
| 600-line review budget causes reviewer overload | High | For the remaining 14-slice plan, use the user's explicit `exception-ok` decision only for PRs 9, 12, 15, 17, 19, 20, and 22 when native line accounting proves actual authored work exceeds 600; record each exception before runtime-bearing apply. Keep `stacked-to-main`, T-CF before clients, T-MG before Stretch, and the frozen review identity. |
| In-process WebSocket assumptions fail when scaled | Low | Ship one FastAPI process for the MVP; broadcaster is a port so a later adapter can use PostgreSQL notifications without changing monetary or auth boundaries. |

The design identifies product and technical boundaries; the remaining delivery amendment above supersedes the prior strategy for PR 9–22 without changing product design. The downstream task plan records the exact 14-slice workload and exception handling while preserving the chosen chain and hard gates. No risky shortcut—anonymous fallback, localStorage session secret, client role, replacement participant, or client money math—is an acceptable schedule mitigation.

## Rollback and recovery

- **Scope:** stop at the last green Must boundary and remove only Stretch work. Do not expose group data anonymously or replace server authorization with a client flag.
- **Auth:** migrations are reversible; revoke active sessions during a controlled rollback; hold the release if the login UI or session adapter is broken rather than weakening protected endpoints.
- **Rename:** correct the participant name through the same name-only endpoint or database recovery. Because foreign keys and monetary source rows are untouched, disabling the rename affordance does not require changing balances or history.
- **Data:** recreate only a development database/volume through the documented runbook, migrate, and rerun the idempotent seed. No automatic destructive reset occurs in a client.
- **Realtime:** disable WebSocket connection/reconnect if necessary; authenticated REST refresh remains authoritative.
- **Clients:** keep generated auth/session integration and mobile read parity; defer mobile expense writes without changing the authenticated API contract.
- **Decision changes:** a new business decision requires updating proposal, affected specs, design, tasks, and tests before product code changes.

## Design completion checklist

- [x] CC-01..CC-04 are confirmed and reflected without unresolved checkpoint language.
- [x] No anonymous group access, synthetic trusted actor, or client role authority.
- [x] Minimal account, membership, and session source tables are defined.
- [x] Web refresh persistence, Flutter protected reads, cookie storage, and CSRF are defined.
- [x] `owner_only`/`any_member` operation authorization is explicit.
- [x] Participant rename is present across application, persistence, REST/OpenAPI, generated clients, and client behavior.
- [x] Rename preserves IDs, foreign keys, history, and money atomically.
- [x] Archived referenced zero-balance visibility and form rules are explicit.
- [x] FastAPI remains the sole monetary and authorization authority.
- [x] Generated-client workflow, UI tokens/accessibility, seed/recovery, tests, sequencing, acceptance evidence, and risk narrative are documented.
- [x] `docs/requerimiento-docente.md` remains unchanged.

## Next step

Regenerate `tasks.md` from the reconciled specs and this design. The task plan must include auth/session/CSRF/membership work, participant rename work, the updated acceptance evidence, the corrected workload forecast, and the preserved `stacked-to-main` delivery choice before any product code is written.
