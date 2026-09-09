# Delta for Groups

## ADDED Requirements

### Requirement: Authenticated accounts discover and create groups

The system MUST allow an authenticated account to list only groups in which it is an active member, create a group, and select a listed group. Group creation MUST atomically make the creator the sole owner and a member, and MUST initialize the group with no outings, participants, or expenses.

#### Scenario: Account lists only its memberships

- GIVEN account `a1` belongs to `g1` and not `g2`
- WHEN `a1` requests its groups
- THEN only `g1` is returned
- AND no `g2` data is disclosed

#### Scenario: Creating a group creates an empty owner workspace

- GIVEN an authenticated account `a1`
- WHEN `a1` creates a group
- THEN the response identifies a new group for which `a1` is owner and member
- AND the group has no outings, participants, or expenses

#### Scenario: Unauthenticated group discovery is rejected

- GIVEN no valid session
- WHEN group listing or creation is attempted
- THEN the request is rejected with `unauthorized`
- AND no group or membership is created

### Requirement: Group-scoped membership and selection isolation

Every selected-group read and mutation MUST be re-authorized against the authenticated account's membership. A client-supplied group identifier or role MUST NOT grant access. Switching selection MUST clear or invalidate dependent client state before data from the newly selected group is rendered.

#### Scenario: Cross-group access is rejected

- GIVEN an authenticated member of `g1` who is not a member of `g2`
- WHEN the account requests or mutates a `g2` resource
- THEN the server returns `forbidden`
- AND no `g2` data or state change is exposed

#### Scenario: Selection transition cannot retain prior group data

- GIVEN the client has cached `g1` participants, expenses, balances, and settlement
- WHEN the account selects `g2`
- THEN group-scoped queries are reset or keyed to `g2`
- AND no `g1` result is rendered as `g2` data

### Requirement: Outing lifecycle is group-scoped

An outing MUST belong to exactly one group and have a required name. Any group member MAY create or edit an outing. Only the group owner MAY archive or unarchive an outing. Only the owner MAY delete an outing with no expenses; an outing with expenses MUST remain readable history and MUST NOT be physically deleted. Archived outings MUST remain readable and reject new writes associated with the outing.

#### Scenario: Member creates and edits an active outing

- GIVEN a member of `g1` and an active outing in `g1`
- WHEN the member creates or edits an outing in `g1`
- THEN the operation succeeds if the request is valid
- AND the outing remains associated with `g1`

#### Scenario: Member cannot archive or delete an outing

- GIVEN a non-owner member of `g1`
- WHEN the member archives, unarchives, or deletes an outing
- THEN the server returns `forbidden`
- AND the outing is unchanged

#### Scenario: Owner archives and preserves history

- GIVEN an owner and an active outing with expenses
- WHEN the owner archives the outing
- THEN the outing and its expenses remain readable
- AND new expenses associated with that outing are rejected

#### Scenario: Only empty outings may be deleted

- GIVEN an owner and an outing with one or more expenses
- WHEN the owner requests deletion
- THEN the server rejects the request with a conflict error
- AND the outing and its expenses remain present

### Requirement: Authenticated join-code membership lifecycle

The owner MUST be able to generate, revoke, and regenerate one current reusable join code for a group. The code MUST be usable only by an already-authenticated account, MUST remain valid until revoked or regenerated, and regeneration MUST invalidate the previous code. The system MUST NOT provide public registration, account creation through the code, email invitations, expiry, approval queues, or ownership transfer.

#### Scenario: Reusable code joins an authenticated account

- GIVEN an owner has generated a current code for `g1` and account `a2` has a valid session
- WHEN `a2` consumes the code
- THEN `a2` becomes a member of `g1`
- AND consuming the same still-current code for another eligible account remains possible

#### Scenario: Revocation and regeneration invalidate prior code

- GIVEN code `c1` is current for `g1`
- WHEN the owner revokes or regenerates the code
- THEN `c1` cannot join any account
- AND after regeneration only the new current code can be consumed

#### Scenario: Anonymous and duplicate joins are rejected atomically

- GIVEN an anonymous request, an invalid code, or an account already in `g1`
- WHEN the join operation is attempted
- THEN the server returns the applicable auth/validation/conflict error
- AND no membership or participant-link partial mutation occurs

### Requirement: Account and participant identities remain separate

After a valid join, the account holder MUST explicitly choose either an existing participant in the same group or creation of a new participant. The account-to-participant link MUST be group-scoped and unique according to server-enforced authorization and persistence constraints. Joining MUST reject a participant from another group.

#### Scenario: Join links to an existing participant

- GIVEN an authenticated account joining `g1` and an eligible participant in `g1`
- WHEN the account chooses that participant
- THEN the group-scoped account-participant link is created
- AND the account identity and participant identity remain distinct

#### Scenario: Join creates a new participant

- GIVEN an authenticated account joining `g1`
- WHEN the account chooses to create a valid new participant
- THEN exactly one participant and one group-scoped link are created

#### Scenario: Cross-group or duplicate link is rejected

- GIVEN a participant from `g2`, or an account already linked in `g1`
- WHEN the account submits the link choice
- THEN the server rejects it without partial mutation

### Requirement: Membership exit preserves history

The owner MUST be able to remove a member and a member MUST be able to leave, except that the final owner MUST remain protected because ownership transfer is not supported. Removing or ending a membership MUST NOT erase participant records, expense history, outing history, or derived results; the account-participant link MAY be inactive or removed according to the persistence design.

#### Scenario: Member leaves without deleting group history

- GIVEN a non-owner member with participant and expense history in `g1`
- WHEN the member leaves
- THEN the membership is ended
- AND the group history and participant references remain readable to authorized members

#### Scenario: Owner removes a member without rewriting history

- GIVEN an owner and another member of `g1`
- WHEN the owner removes that member
- THEN the membership is ended
- AND no expense contribution, beneficiary reference, or participant record is erased

#### Scenario: Final owner cannot exit

- GIVEN a group with one remaining owner and no ownership-transfer capability
- WHEN the owner attempts to leave or remove the final owner
- THEN the server rejects the request
- AND the owner membership remains active

## MODIFIED Requirements

### Requirement: Group foundation and scope

The system MUST persist one or more groups, each with exactly one owner and membership records. Every group-owned entity (participants, expenses, outings, balances, settlement, join-code state, and account-participant links) MUST carry or resolve an unambiguous `group_id`. All API paths for group-owned resources MUST be group-scoped or account-scoped with server-side membership filtering. Authenticated web users MUST be able to discover, create, and select groups; the former single-active-group restriction is superseded for this change.

(Previously: The MVP exposed one active seeded group and explicitly prohibited group discovery, creation, switching, and multi-group workflows.)

#### Scenario: Every resource resolves to its group

- GIVEN an authenticated member selected into `g1`
- WHEN group-owned resources are read or mutated
- THEN each result resolves to `g1`
- AND a resource from `g2` is never returned through the `g1` scope

#### Scenario: All resources are group-scoped

- GIVEN an active session in group `g1`
- WHEN participants, expenses, balances, and settlement are created or read through the protected API
- THEN every resource is reachable under `/groups/g1/...` and every record stores `group_id = g1`

#### Scenario: Single-group UI

- GIVEN the web and mobile clients with a valid session
- WHEN they render the app
- THEN they show the active group's data without any group switcher, group creation, or group discovery UI

### Requirement: Protected sessions for group data

The system MUST require a valid, unexpired, server-recognized session for every group, outing, membership, participant, expense, balance, settlement, and join-code operation. The server MUST reject missing, invalid, expired, or logged-out sessions before returning or changing data. Join codes MUST be an authenticated membership mechanism, not anonymous access.

(Previously: The protected single-group rule existed, but no authenticated join mechanism was defined.)

#### Scenario: Join code does not bypass authentication

- GIVEN a valid join code and no session
- WHEN the code is submitted
- THEN the server returns `unauthorized`
- AND no group data or membership is disclosed

#### Scenario: Unauthenticated read is rejected

- GIVEN no session
- WHEN a protected group read (`GET /groups/g1`) is attempted
- THEN the request is rejected with error `unauthorized` (HTTP 401)
- AND no group data is returned

#### Scenario: Unauthenticated mutation is rejected

- GIVEN no session
- WHEN a protected mutation (for example, creating an expense) is attempted
- THEN the request is rejected with error `unauthorized` (HTTP 401)
- AND no state changes

#### Scenario: Invalid or logged-out session is rejected

- GIVEN a session that has been invalidated by logout or is otherwise unrecognized
- WHEN any protected group request is attempted with it
- THEN the request is rejected with error `unauthorized` or `session_expired` (HTTP 401)
- AND no data is returned and no state changes

## REMOVED Requirements

### Requirement: Single-group UI prohibition

(Reason: This change introduces authenticated multi-group discovery, creation, and selection.)
(Migration: Consumers must adopt the group list and selected-group workspace; historical artifacts remain unchanged.)

### Requirement: No invitations as an absolute membership rule

(Reason: A narrow authenticated reusable join-code flow is explicitly added; public registration and email invitation products remain excluded.)
(Migration: Treat only the new authenticated join-code contract as supported; do not implement public or email invitation flows.)

## Implementation Assumptions (Non-normative)

- Outing name is required; start and end dates MAY be stored as optional informational fields. Calendar, scheduling, reminders, recurrence, and date filtering are not part of this change.
- Group selection is URL/client navigation state. A client MAY auto-select the only group and MAY show a picker when several groups exist, but every request remains server-validated. Persisting a preferred group in the server session is deferred.
- Each group has one current reusable join code. Multiple concurrent generations, usage limits, expiry, notifications, and approval queues are deferred.
- A participant-link choice completes the join flow with one group-scoped uniqueness-constrained relationship. Participant merge, aliases, identity replacement, and historical name snapshots are deferred.

## Delivery Note (Non-normative)

The proposal's 800 changed-line limit applies to each implementation slice as a delivery constraint. It is not a product requirement and MUST NOT be used to remove authorization, isolation, lifecycle, calculation, contract, or regression scenarios from this specification.
