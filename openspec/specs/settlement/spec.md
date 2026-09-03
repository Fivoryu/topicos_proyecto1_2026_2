# Settlement Specification

## Purpose

Define the server-owned monetary math: equal beneficiary split with the confirmed deterministic residual rule (CC-01), per-participant balances, the exact-zero invariant, and deterministic greedy settlement transfers derived from current balances only. FastAPI is the sole monetary authority; balances and transfers are never persisted as independent truth. Participant rename NEVER changes any split, balance, or transfer (see participants spec, CC-04).

## Requirements

### Requirement: Equal beneficiary split with deterministic residual

The system MUST split an expense's `amount_cents` equally among the selected beneficiaries in whole cents. When the amount is not divisible by the beneficiary count, the residual cents MUST be assigned deterministically: the first participant in stable group creation order who is both a contributor and a beneficiary absorbs the entire residual; if no contributor is a beneficiary, the residual goes to the first selected beneficiary in stable group order. The split shares MUST always sum exactly to `amount_cents`.

> **Confirmed decision (CC-01):** The complete residual goes to the first stable-creation-order participant who is both a contributor and a beneficiary; when that intersection is empty, it goes to the first selected beneficiary in stable order. Contribution-entry order and round-robin are not used. Recorded in the reconciled proposal and Engram observation `2587` (`sdd/cuentas-claras-mvp/confirmation-gates`).

#### Scenario: DA-02 — non-divisible expense with payer as beneficiary

- GIVEN a `10000`-cent expense paid by Ana with Ana, Beto, and Carla as beneficiaries
- WHEN the split is computed
- THEN Ana receives `3334` cents, Beto receives `3333`, Carla receives `3333`
- AND `3334 + 3333 + 3333 = 10000`

#### Scenario: DA-03 — excluded participant receives nothing

- GIVEN a `30000`-cent expense with Ana, Beto, Carla, and Diego in the group and Diego excluded from beneficiaries
- WHEN the split is computed
- THEN each of the three selected beneficiaries receives `10000` cents and Diego receives `0`

#### Scenario: Residual with multiple contributors (contributor is beneficiary)

- GIVEN a `10000`-cent expense contributed by Ana (`6000`) and Beto (`4000`), with Ana, Beto, and Carla as beneficiaries
- WHEN the split is computed
- THEN Ana receives `3334` (first contributor/beneficiary in stable order) and Beto and Carla receive `3333` each
- AND the three shares sum exactly to `10000`

#### Scenario: Residual with no contributor as beneficiary (fallback)

- GIVEN a `10001`-cent expense contributed by Ana (`6001`) and Beto (`4000`), with Carla and Diego as the only beneficiaries (neither contributor is a beneficiary)
- WHEN the split is computed
- THEN the contributor/beneficiary intersection is empty, Carla receives `5001` (first selected beneficiary in stable order), and Diego receives `5000`
- AND the two shares sum exactly to `10001`

### Requirement: Balance computation

The system MUST compute, per participant, `balance = paid − owed` where `paid` is the sum of the participant's contributions and `owed` is the sum of the participant's split shares across all expenses. Positive balance means creditor, negative means debtor, zero means neutral. Balances MUST be computed on read from expense source data; they MUST NOT be stored. Referenced archived participants MUST remain in the balance set at their derived value, including `Bs. 0.00` (CC-02).

#### Scenario: DA-01 — Samaipata balances

- GIVEN the Samaipata history: Ana paid `96000`, Beto paid `40000`, Carla paid `24000`, Diego paid `0`, all four participants as beneficiaries of every expense (each owes `40000`)
- WHEN balances are computed
- THEN Ana is `+56000`, Beto `0`, Carla `-16000`, Diego `-40000` cents

#### Scenario: Archived participant with zero balance stays listed

- GIVEN a referenced archived participant whose derived balance is `0`
- WHEN balances are computed
- THEN the participant is included in the balance set with `0` cents
- AND the row is not dropped because it is archived or zero

### Requirement: Exact zero-balance invariant

After every expense create, edit, or delete, the sum of all participant balances MUST be exactly `0` cents. No rounding artifact may break the invariant. A participant rename MUST NOT change any balance, so the invariant is preserved by rename without recomputation of monetary results.

#### Scenario: DA-02 — invariant after rounding

- GIVEN the DA-02 expense (Ana `+3334`-share offset by `-10000` paid, Beto `-3333`, Carla `-3333`)
- WHEN balances are summed
- THEN the sum is exactly `0` cents

#### Scenario: Rename preserves the invariant without money change

- GIVEN a group with non-zero balances
- WHEN an unrelated participant is renamed
- THEN every participant's paid, owed, and balance are unchanged and the sum remains exactly `0`

### Requirement: Deterministic greedy settlement

The system MUST derive a transfer list from current balances: order debtors by most-negative balance first and creditors by most-positive balance first (ties broken by stable participant creation order), then repeatedly transfer `min(|debtor balance|, creditor balance)` from the current debtor to the current creditor, advancing when a party reaches zero, until all residual balances are zero. The transfer list MUST be deterministic for identical source data, MUST contain no transfers involving neutral participants, and MUST NOT be persisted. The result MUST redistribute balances without creating or destroying money.

#### Scenario: DA-01 — Samaipata transfers in stable order

- GIVEN the Samaipata balances (Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`)
- WHEN settlement is computed
- THEN the transfers are exactly `Diego → Ana 40000` and `Carla → Ana 16000`, in that order
- AND Beto appears in no transfer

#### Scenario: CB-13 — everyone settled

- GIVEN a group where every participant's balance is `0`
- WHEN settlement is computed
- THEN the response states that everyone is settled
- AND the transfer list is empty

#### Scenario: CB-14 — single participant

- GIVEN a group with one participant who records expenses for themselves
- WHEN balances and settlement are computed
- THEN the balance is always `0`
- AND the transfer list is empty

#### Scenario: CB-15 — payer excluded from the split

- GIVEN Ana pays a `30000`-cent expense with Beto, Carla, and Diego as the only beneficiaries
- WHEN balances are computed
- THEN Ana is `+30000`, and Beto, Carla, and Diego are `-10000` each
- AND settlement proposes `Beto → Ana 10000`, `Carla → Ana 10000`, `Diego → Ana 10000` in that stable order

## Non-goals

- No global minimum-transfer optimization; the deterministic greedy algorithm is the MVP behavior (approved stretch only).
- No persisted balance or transfer ledgers independent of expense source data.
- No custom, percentage, weighted, or unequal split modes.
- No role or auth behavior on settlement computation itself; authorization is enforced by the API layer (see api/groups specs).
