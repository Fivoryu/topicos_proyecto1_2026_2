# Delta for Clients

## MODIFIED Requirements

### Requirement: No client-side monetary authority

Clients MUST NOT compute exchange rates, conversions, balances, splits, residuals, or settlement transfers. They MUST display the server-derived integer USD cents and preserve/display the server-provided original source amount, currency, frozen rate, timestamp, and provenance. Client formatters MAY format values for display but MUST use integer cents and MUST NOT use floating-point monetary arithmetic.

(Previously: Clients displayed a single-currency server-derived integer value and had no rate or source-money context.)

#### Scenario: Server results are displayed verbatim

- GIVEN balances and settlement fetched from the API
- WHEN either client renders them
- THEN the rendered values are the fetched integer USD-cent values formatted through the shared formatter
- AND no client code recomputes or rounds a monetary value

#### Scenario: Client renders server results verbatim

- GIVEN a REST response containing a EUR source expense and USD-derived balances
- WHEN web or mobile renders the response
- THEN the expense uses the returned EUR amount and metadata
- AND balances and settlement use the returned USD-cent values
- AND no client conversion or split calculation occurs

#### Scenario: Client does not repair a residual

- GIVEN a server response whose USD CC-01 shares include a deterministic residual cent
- WHEN the client renders the expense or balances
- THEN it displays the returned values without redistributing the residual

## ADDED Requirements

### Requirement: Currency-aware presentation and error states

The web client MUST allow supported currency selection for owned expense workflows and MUST show original source money alongside frozen rate context. Balances and settlement MUST be labeled/rendered in USD. The client MUST present structured unsupported-currency, invalid-rate, unavailable-rate, and conversion errors without mutating local authoritative state. Frankfurter values MUST be described as frozen daily/reference accounting data, not live trading prices.

#### Scenario: Mixed-currency group presentation

- GIVEN a group with USD, BOB, and EUR expense history
- WHEN the web expense, balance, and settlement views render
- THEN each expense displays its original ISO currency and amount
- AND balances/transfers display server-derived USD
- AND the stored rate timestamp and provenance are visible or available in the expense audit context

#### Scenario: No-fallback error is surfaced

- GIVEN an expense write rejected with `rate_unavailable`
- WHEN the client receives the response
- THEN it shows a clear rate-unavailable state
- AND it does not invent a rate, convert locally, or show the failed expense as saved

### Requirement: REST refetch remains the only synchronization path

Clients MUST continue using the generated REST clients as the source of truth. On the unchanged WebSocket `data_changed` signal, web and mobile MUST invalidate/refetch affected REST resources; they MUST NOT expect currency, rates, balances, or settlement details in the frame. When WebSocket delivery is unavailable, ordinary REST refresh MUST remain sufficient.

#### Scenario: Currency mutation triggers authoritative refetch

- GIVEN a client with cached balances and an active group WebSocket
- WHEN another actor edits an expense currency or rate successfully
- THEN the client receives only `data_changed`
- AND it refetches expenses, balances, and settlement through REST
- AND it displays the newly server-derived USD results

### Requirement: Mobile ownership boundary

Mobile contract adaptation, read models, presentation, and any approved mobile write behavior MUST remain owned by `mobile-domain-features`. This change MUST define shared REST semantics without editing mobile-owned implementation files or assuming mobile write parity. Mobile MUST remain a thin consumer that performs no conversion or settlement math.

#### Scenario: Mobile consumes shared contract without authority

- GIVEN regenerated Dart types containing source currency and USD-derived fields
- WHEN the mobile-owned change implements its read presentation
- THEN it displays server-provided source money and USD results
- AND it performs no rate lookup, conversion, split, or settlement calculation
- AND its implementation remains reviewable under `mobile-domain-features`

### Requirement: Web redesign ownership boundary

Currency behavior MUST be implemented without modifying or reformatting files owned by `web-professional-redesign`. The multi-currency change MAY expose the contract data needed by that redesign, but visual ownership and redesign acceptance remain separate.

#### Scenario: Protected redesign files remain untouched

- GIVEN the web needs currency-aware expense and balance presentation
- WHEN the multi-currency work is applied
- THEN its behavior is specified against existing web ownership boundaries
- AND no `web-professional-redesign` file is changed or reformatted
