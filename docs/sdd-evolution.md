# Mapa de evolución SDD

Este documento explica qué material es histórico, qué cambios siguen activos y dónde debe buscarse la guía actual. No reemplaza ni reescribe los artifacts originales.

> **Estado al 2026-09-04:** no hay changes OpenSpec activos. La entrega principal, la invalidación WebSocket, la extensión móvil y la alineación de entrega están archivadas; `openspec/specs/` contiene las specs canónicas sincronizadas.

## Precedencia

1. **Consigna oficial / baseline docente:** define el problema evaluado, el escenario Samaipata y las obligaciones de Grupo 2.
2. **Artifacts fechados de exploración, propuesta, diseño, apply y verify:** evidencian cómo evolucionaron las decisiones; pueden contener supuestos que luego fueron superados.
3. **`openspec/project-context.md` + `openspec/specs/`:** guía actual de alcance y arquitectura; los changes archivados conservan el razonamiento histórico.
4. **Código aterrizado + contrato OpenAPI + verificaciones verdes:** evidencia de conformidad, no sustituto de las specs.

## Evolución principal

| Etapa / change | Estado para la entrega | Qué aporta | Regla de preservación |
| --- | --- | --- | --- |
| `docs/requerimiento-docente.md` | Histórico, preservado | Baseline previo al código; incluye decisiones iniciales como React/localStorage y backend/auth fuera de ese diseño inicial | No editar retroactivamente; enlazarlo como antecedente |
| `openspec/changes/archive/2026-09-03-cuentas-claras-mvp/` | Archivado; implementación principal completada | Reconciliación hacia FastAPI/PostgreSQL, sesiones protegidas, roles, React, OpenAPI, dinero en centavos, balances/liquidación y clientes | No reescribir desde final-delivery |
| `openspec/changes/archive/2026-09-04-wire-mutation-websocket-invalidation/` | Archivado; backend verde | Publicación `data_changed` compartida, por grupo y post-commit para mutaciones | Final-delivery solo la describe y ejecuta sus tests como regresión |
| `openspec/changes/archive/2026-09-04-mobile-domain-features/` | Archivado; extensión independiente completada | Flutter/Android con `DomainScope`, lecturas, coordinación de refresh y capas de mutación; conserva tareas/aceptación propias | No convertirlo en requisito de la demo web ni completar/aceptar su trabajo desde final-delivery |
| `openspec/changes/archive/2026-09-04-final-delivery-alignment/` | Archivado; cierre de entrega documentado | `AGENTS.md`, README, fixture oficial de cuatro gastos, demo exacta, presentación web en español y gates de entrega | Debe permanecer web-centered y no absorber los otros changes |
| `openspec/specs/` | Specs canónicas sincronizadas; 16 capacidades validadas | Contratos actuales luego del sync/archive correspondiente | No fabricar copias manualmente durante apply |

## Supuestos superados que no deben volver como guía actual

- Persistencia principal en `localStorage` → **superado por PostgreSQL**.
- Aplicación sin backend → **superado por FastAPI + SQLAlchemy/Alembic**.
- Autenticación fuera de alcance → **superado por cuentas demo, sesiones protegidas y roles derivados por servidor**.
- WebSocket como fuente de datos → **nunca**: es solo invalidación; REST sigue siendo autoridad.
- Móvil inexistente o sin dominio → **superado**: existe una extensión Flutter/Android archivada y completada, aunque no forma parte del camino obligatorio de la demo web.

## Regla operativa de Grupo 2

Si cambia el entendimiento aceptado de un comportamiento, primero se actualizan las specs/artifacts correspondientes; después se escriben o ajustan tests de aceptación, luego código, y finalmente se ejecutan gates. El archive ocurre únicamente después de verificar el change.

## Active change status: `group-outing-workspaces`

The status line above is a preserved snapshot from 2026-09-04. The current active change is `group-outing-workspaces`, a separate staged domain/workspace expansion; its proposal, design, and change-local specs preserve the historical reasoning, while the canonical living specs now carry this policy amendment.

### Supersession record

For this change only, the former single-active-group restrictions are superseded by authenticated group listing, empty group creation, explicit selection, outings, membership lifecycle, nullable outing scope, and laptop-first protected workspace navigation. FastAPI, PostgreSQL, server-derived roles, integer-cent monetary results, exact-zero settlement, protected sessions/CSRF/origin, and REST authority remain unchanged.

The change adds one narrow exception to the historical “no invitations” boundary: an owner-controlled, reusable QR/join code may be consumed only by an account with an existing valid session. The code is hash-only at rest, valid until revoke/regeneration, and joining is atomic with exactly one same-group participant link-or-create choice. Account and participant identities remain separate.

This is not public registration, account creation through QR, anonymous group access, an email invitation, password recovery, OAuth, token expiry, an approval queue, ownership transfer, participant merge, or a general account directory. It also does not add mobile UI/domain parity, a routing dependency, client-side money/authorization, or a new WebSocket payload. WebSocket behavior remains one post-commit group-scoped `{"type":"data_changed"}` invalidation and REST refetch.

### Preservation and delivery

PR 0 is policy/spec synchronization only. Later implementation is stacked `PR 0 → PR 9`, each capped at 800 changed lines; the cap cannot remove security, isolation, lifecycle, monetary, contract, or regression coverage. `AGENTS.md`, all historical/archive artifacts, generated clients by hand, the official Samaipata fixture and exact result, and every `web-professional-redesign` file are protected. The fixture remains four all-general expenses, with Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`, and transfers Diego → Ana `40000`, then Carla → Ana `16000`.
