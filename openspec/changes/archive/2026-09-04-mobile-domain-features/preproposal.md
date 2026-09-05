# Pre-Proposal Gate: Mobile Domain Features

## State

Product scope confirmed: choose the full mobile domain, then decompose implementation into independently reviewable work units. The proposal phase may proceed with explicit scope boundaries and delivery-splitting rules.

## Confirmed context

- Change: `mobile-domain-features`
- Product area: Android mobile client
- Existing foundation: authenticated session, protected group read, generated OpenAPI client, Flutter Bloc/Cubit, Dio transport
- Server remains the monetary authority; the client must not calculate splits, balances, residuals, or settlement transfers
- Existing OpenSpec changes remain untouched
- Artifact store: OpenSpec
- Execution mode: automatic
- Delivery strategy: ask-on-risk
- Review budget: 400 changed lines
- Strict TDD: enabled

## Scope decision (confirmed)

The user selected option 4: full mobile domain. The proposal must preserve this scope while splitting delivery into bounded work units when the native forecast requires it.

Choose one coherent first slice:

1. Expense creation only — add a validated create-expense flow and authoritative refresh; defer edit/delete, participant lifecycle mutations, policy mutation, and settlement actions.
2. Expense CRUD — add create/edit/delete with authoritative refresh; defer participant lifecycle mutations, policy mutation, and settlement actions.
3. Participants plus expense CRUD — add participant lifecycle and expense create/edit/delete; defer policy mutation and settlement actions; split delivery into bounded work units if the forecast exceeds budget.
4. Full mobile domain — include participant lifecycle, expense CRUD, policy mutation, and any settlement action; highest scope and likely requires chained slices.

Default assumptions unless the selected slice explicitly changes them:

- Settlement remains a server-derived read view; no client-side payment or transfer action.
- Use the existing simple navigation shell and preserve the current visual language; accessibility and touch-target fixes remain in scope.
- Generated API files and `mobile/README.md` remain untouched.
