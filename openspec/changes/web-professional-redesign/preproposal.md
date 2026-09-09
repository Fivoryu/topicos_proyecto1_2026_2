# Pre-proposal gate: Web professional redesign

Status: confirmed product decision (`editorial`)
Change: `web-professional-redesign`
Artifact store: OpenSpec

## Confirmed context

- The change is limited to the React/Vite/TanStack Query/Tailwind web client.
- Backend, API contracts, generated clients, PostgreSQL, authentication/authorization, money semantics, WebSocket invalidation, and the independent mobile change remain untouched.
- Existing hash anchors and Spanish product copy remain stable unless a later product decision explicitly changes wording.
- The current light theme remains the baseline; dark mode and theme switching are not part of this first slice.
- The implementation must stay within an 800 changed-line budget and preserve current behavior-oriented tests.
- Responsive acceptance uses approximately 375px mobile, tablet, desktop, and landscape checks.
- Metadata/favicon expansion is deferred unless it is proven to fit without diluting the in-app redesign.

## Pending product choice

The exploration identified one decision that materially changes the visual hierarchy and density of the workspace: whether the redesign should prioritize a quiet editorial finance experience or a denser operational console. The proposal cannot safely choose between these without the product owner's answer.

The pending answer must be one of the exact tokens below:

- `editorial`: calm, spacious, editorial financial workspace; strongest hierarchy and breathing room; secondary administration stays visually quiet.
- `operational`: denser, faster scanning for frequent expense entry; more compact summaries and stronger data grouping; less expressive whitespace.
- `balanced`: middle path; preserves the calm financial palette while tightening high-frequency expense and balance areas.

Confirmed answer: `editorial` — use a calm, spacious, editorial finance workspace with strong hierarchy and visually quiet secondary administration.
