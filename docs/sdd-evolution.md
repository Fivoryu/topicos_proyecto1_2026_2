# Mapa de evolución SDD

Este documento explica qué material es histórico, qué cambios siguen activos y dónde debe buscarse la guía actual. No reemplaza ni reescribe los artifacts originales.

## Precedencia

1. **Consigna oficial / baseline docente:** define el problema evaluado, el escenario Samaipata y las obligaciones de Grupo 2.
2. **Artifacts fechados de exploración, propuesta, diseño, apply y verify:** evidencian cómo evolucionaron las decisiones; pueden contener supuestos que luego fueron superados.
3. **`openspec/project-context.md` + specs de changes activos:** guía actual de alcance y arquitectura.
4. **Código aterrizado + contrato OpenAPI + verificaciones verdes:** evidencia de conformidad, no sustituto de las specs.

## Evolución principal

| Etapa / change | Estado para la entrega | Qué aporta | Regla de preservación |
| --- | --- | --- | --- |
| `docs/requerimiento-docente.md` | Histórico, preservado | Baseline previo al código; incluye decisiones iniciales como React/localStorage y backend/auth fuera de ese diseño inicial | No editar retroactivamente; enlazarlo como antecedente |
| `openspec/changes/cuentas-claras-mvp/` | Implementación principal completada; artifacts preservados | Reconciliación hacia FastAPI/PostgreSQL, sesiones protegidas, roles, React, OpenAPI, dinero en centavos, balances/liquidación y clientes | No reescribir desde final-delivery |
| `openspec/changes/wire-mutation-websocket-invalidation/` | Implementación aterrizada; backend verde; verify registra bloqueo de evidencia TDD antes de archive | Publicación `data_changed` compartida, por grupo y post-commit para mutaciones | Final-delivery solo la describe y ejecuta sus tests como regresión |
| `openspec/changes/mobile-domain-features/` | Activo e independiente | Flutter/Android con `DomainScope`, lecturas, coordinación de refresh y capas de mutación ya aterrizadas; conserva tareas/aceptación propias | No convertirlo en requisito de la demo web ni completar/aceptar su trabajo desde final-delivery |
| `openspec/changes/final-delivery-alignment/` | Activo para cierre de entrega | `AGENTS.md`, README, fixture oficial de cuatro gastos, demo exacta, presentación web en español y gates de entrega | Debe permanecer web-centered y no absorber los otros changes |
| `openspec/specs/` | Se poblará mediante lifecycle OpenSpec | Specs canónicas luego del sync/archive correspondiente | No fabricar copias manualmente durante apply |

## Supuestos superados que no deben volver como guía actual

- Persistencia principal en `localStorage` → **superado por PostgreSQL**.
- Aplicación sin backend → **superado por FastAPI + SQLAlchemy/Alembic**.
- Autenticación fuera de alcance → **superado por cuentas demo, sesiones protegidas y roles derivados por servidor**.
- WebSocket como fuente de datos → **nunca**: es solo invalidación; REST sigue siendo autoridad.
- Móvil inexistente o sin dominio → **superado**: existe una extensión Flutter/Android activa, aunque no forma parte del camino obligatorio de la demo web.

## Regla operativa de Grupo 2

Si cambia el entendimiento aceptado de un comportamiento, primero se actualizan las specs/artifacts correspondientes; después se escriben o ajustan tests de aceptación, luego código, y finalmente se ejecutan gates. El archive ocurre únicamente después de verificar el change.
