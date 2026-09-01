# Protected Samaipata demo

This script demonstrates the protected Cuentas Claras flow in under three minutes: a seeded user signs in, records one expense, reviews server-derived balances and settlement, refreshes, and signs out. The browser session and the API—not the client—remain authoritative.

## Quick path

### Preconditions

- Start the backend and web app with the fresh-environment sequence below.
- Set `DEMO_OWNER_PASSWORD` and `DEMO_MEMBER_PASSWORD` locally. Do not commit, paste, or record either value.
- Use `demo.owner` for the walkthrough, or substitute `demo.member` to demonstrate the member role.
- Open `http://localhost:5173` in a browser with the network panel available for the logout check.

### Timed walkthrough — target 2:20

| Time | Action | Expected result |
| --- | --- | --- |
| 0:00–0:15 | Open the web app and sign in as `demo.owner` with the locally supplied seed password. | The protected shell appears and shows the server-derived `owner` role. No group data was shown before login. |
| 0:15–0:35 | Open **Participants** and read the seeded list. | `Ana`, `Beto`, `Carla`, `Diego` appear in creation order. |
| 0:35–1:00 | In **Expenses**, record `Rehearsal lunch`, amount `100.00`, contributor `Ana` with `100.00`, and all four participants as beneficiaries. Submit once. | The expense is accepted through the protected API. Wait for the list and derived panels to refresh. |
| 1:00–1:25 | Show **Balances** and **Settlement**. | Expected server values are Ana `+Bs. 635.00`, Beto `-Bs. 25.00`, Carla `-Bs. 185.00`, and Diego `-Bs. 425.00`. Transfers are Diego → Ana `Bs. 425.00`, Carla → Ana `Bs. 185.00`, then Beto → Ana `Bs. 25.00`. |
| 1:25–1:45 | Refresh the page. | The session remains valid and the participants, expense, balances, and settlement are identical to the pre-refresh view. |
| 1:45–2:05 | In the browser network history, select the pre-logout protected group request and keep its request copy private. Click **Log out**. | The protected shell disappears and the sign-in screen returns. |
| 2:05–2:20 | Replay the private pre-logout request, or use the DA-06 acceptance check. | The old session is rejected with HTTP 401 and `error_code: unauthorized`; no group data is returned. |

The amounts in the table are expected evidence for this seeded history plus the documented `Bs. 100.00` expense. Do not recompute or edit balances in the client.

## Fresh-environment rehearsal

Run these commands from the repository root. The reset is destructive and is for local demo data only.

```bash
docker compose -f infra/docker-compose.yml down -v
docker compose -f infra/docker-compose.yml up -d db
python -m alembic -c backend/alembic.ini upgrade head
python -m backend.scripts.seed_demo
python -m backend.scripts.seed_demo
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
npm --prefix web run dev -- --host 127.0.0.1 --port 5173
# The dev server proxies /api to the backend (same-origin cookies). Set
# VITE_API_BASE_URL to the web origin (http://localhost:5173) — never the
# backend origin — or same-origin cookie transport breaks in the browser.
```

Supply development-only values out of band before the seed commands; never put real values in this file. For PowerShell, set placeholders locally:

```powershell
$env:DEMO_OWNER_PASSWORD = "<local-demo-password>"
$env:DEMO_MEMBER_PASSWORD = "<local-demo-password>"
```

The two seed invocations must report zero newly created accounts, participants, and expenses on the second run. Their passwords and hashes must not appear in terminal captures. If host port `5432` is already occupied by a healthy pre-existing `backend-db-1`, the compose `up` step cannot create this stack. Record that condition in `openspec/changes/cuentas-claras-mvp/apply-progress.md`; use the committed hermetic acceptance tests and the recovery instructions in [`demo-recovery.md`](demo-recovery.md) as the handoff evidence until the port is available.

## Handoff evidence

| Outcome | Evidence to review |
| --- | --- |
| AO-01 Samaipata balances and ordered settlement | `backend/tests/acceptance/test_da_01_samaipata.py` plus the protected web panels |
| AO-02 exact residual and zero sum | `backend/tests/acceptance/test_da_02_residual.py` and the cents formatter tests |
| AO-03 multi-contributor and mismatch behavior | T-06/T-14 unit tests and the contribution validation tests |
| AO-04 lifecycle, archive, delete, and rename integrity | T-13/T-34 participant tests and `test_da_07_rename.py` |
| AO-05 atomic expense mutation | T-14 expense-service tests |
| AO-06 explicit validation/auth/error states | T-17–T-19 backend tests and T-25/T-27 web tests |
| AO-07 refresh, logout, and recovery | `test_da_05_persistence.py`, T-17/T-33 session tests, and T-21 recovery tests |
| AO-08 contract parity and invalidation-only realtime | T-22/T-23 drift/generated-client checks and T-20 WebSocket tests |
| AO-09 seed plus timed walkthrough | T-21 seed evidence and this script |
| AO-10 server-derived roles and policy matrix | `test_da_06_auth.py`, T-10/T-15 tests, and web/mobile role tests |
| AO-11 archived-zero visibility and form behavior | T-07/T-13/T-19/T-28/T-32 archived-participant tests |

Run the handoff checks from the repository root:

```bash
python -m pytest backend/tests/acceptance -q
python -m pytest backend/tests -q
python -m ruff check backend
python -m backend.scripts.check_contract_drift --cwd .
npm --prefix web run test
npm --prefix web run typecheck
```

If the `pyright` executable is available, run it against the acceptance and protected API paths without installing a new dependency:

```bash
pyright backend/tests/acceptance backend/app/api backend/app/application backend/app/adapters
```

## Responsive and accessibility check

Use the authenticated web shell and the login/error states. Check each viewport in browser responsive mode:

- **375px mobile:** no horizontal page scroll; cards and contributor/rename forms stack; labels remain visible; the expense form remains editable.
- **Tablet width:** the shell collapses to one readable column and the same controls remain reachable.
- **Desktop width:** the shell uses the two-column layout without clipping cards or tables.
- **Keyboard and screen reader:** tab through login, password visibility, submit, participant forms, expense controls, and logout; confirm visible `:focus-visible` rings, heading/landmark order, associated labels, field descriptions, and announced `role="alert"`/`aria-live` errors.
- **Reduced motion:** enable the OS/browser reduced-motion preference; confirm transitions and animations are suppressed by the `prefers-reduced-motion` rule.
- **Targets:** inspect interactive controls and confirm at least `44×44px` on web, with separation between adjacent controls.

The implementation evidence for these checks is in `web/src/index.css`, `web/src/features/auth/login-screen.tsx`, `web/src/features/participants/participants-panel.tsx`, and `web/src/features/expenses/expenses-panel.tsx`. The web test suite covers the protected shell, invalid submissions, archived references, and server error announcements; the viewport and assistive-technology checks are manual handoff checks.

## Scope boundary

This is a Must handoff only. It does not execute T-MG, start review or delivery gates, or begin Stretch tasks T-36–T-38. No client-side money or role authority is introduced.
