# AGENTS.md — Cuentas Claras

Guía obligatoria para personas y agentes de IA que trabajen en este repositorio. Leer antes de modificar producto, tests o documentación viva.

## 1. Alcance de la entrega

La entrega oficial de **Grupo 2 — Spec-Driven Development** está centrada en la aplicación web de Cuentas Claras y el escenario oficial de Samaipata. El backend FastAPI/PostgreSQL es obligatorio para esa demo. Flutter/Android existe como extensión independiente bajo `openspec/changes/mobile-domain-features/`; no es requisito para instalar ni ejecutar la demo web.

## 2. Arquitectura vigente

- `backend/`: FastAPI, SQLAlchemy, Alembic, PostgreSQL.
- `web/`: React + Vite + TanStack Query; consume el contrato generado y usa `/api` same-origin en desarrollo.
- `mobile/`: Flutter + Bloc/Cubit + Dio; change independiente.
- `contracts/openapi.json`: snapshot contractual exportado desde FastAPI.
- `web/src/generated/api/` y `mobile/lib/generated/api/`: salida generada. **No editar manualmente.**
- WebSocket solo emite invalidación `{"type":"data_changed"}`; nunca transporta balances, montos, roles ni liquidaciones.

FastAPI es autoridad de autenticación, autorización y dinero. PostgreSQL es autoridad de persistencia. Los clientes muestran resultados derivados por el servidor.

## 3. Invariantes monetarias

- Dinero en **centavos enteros**. No usar `float`, `double` ni redondeo de punto flotante para lógica monetaria.
- La suma de todos los balances debe ser exactamente `0` centavos.
- Splits/residuales siguen CC-01 de `openspec/project-context.md`.
- La suma de contribuciones de un gasto debe igualar su monto; el servidor valida.
- Liquidación y balances se calculan en backend; web/móvil no los recomputan.
- Renombrar participante conserva ID e historial.
- Participantes referenciados se archivan/protegen de borrado según reglas del servidor.

## 4. Fixture oficial de Samaipata

Participantes: Ana, Beto, Carla, Diego. Todos son beneficiarios de los cuatro gastos:

- Ana — Cabaña — `80000`.
- Ana — Entradas a El Fuerte — `16000`.
- Beto — Cena — `40000`.
- Carla — Gasolina — `24000`.

Balances: Ana `+56000`, Beto `0`, Carla `-16000`, Diego `-40000`.
Transferencias en orden: Diego → Ana `40000`; Carla → Ana `16000`.

No agregues un gasto de ensayo al walkthrough oficial.

## 5. Autenticación y roles

- Sesiones opacas persistidas en BD; transporte por cookies `cc_session`/`cc_csrf`.
- Roles `owner`/`member` son derivados por servidor. Nunca confiar en un rol enviado por cliente/ruta.
- Contraseñas demo se suministran localmente mediante entorno. No registrar contraseñas, hashes, cookies ni tokens en commits, docs, logs de evidencia o prompts.
- No añadir registro público, recuperación, OAuth o invitaciones dentro de final-delivery.

## 6. Propiedad de changes OpenSpec

No mezclar responsabilidades:

- `cuentas-claras-mvp`: historia/implementación principal preservada.
- `wire-mutation-websocket-invalidation`: publicación post-commit ya aterrizada; final-delivery no la modifica.
- `mobile-domain-features`: implementación/aceptación móvil independiente; final-delivery no la completa ni modifica.
- `final-delivery-alignment`: guía/README, fixture Samaipata, presentación web española, demo y gates.

Consultar `docs/sdd-evolution.md` para precedencia y estado.

## 7. Regla Spec-Driven

**Cambio de entendimiento → spec antes que código.**

Flujo esperado:

1. Inspeccionar estado actual y changes activos.
2. Actualizar proposal/spec/design/tasks del change dueño si cambia comportamiento aceptado.
3. Validar artifacts con OpenSpec.
4. Escribir/ajustar prueba enfocada y observar RED cuando corresponda.
5. Implementar el cambio mínimo y obtener GREEN.
6. Triangular casos borde/negativos.
7. Refactorizar sin alterar comportamiento.
8. Ejecutar suites/gates completos.
9. Marcar task `[x]` solo con comportamiento y verificación completos.
10. Sync/archive únicamente después de verificación final.

No uses contexto o comentarios como evidencia de que una tarea está completa.

## 8. Comandos de verificación

Desde raíz:

```bash
python -m pytest backend/tests/integration/api/test_ws_mutation_invalidation.py -q
python -m pytest backend/tests -q
python -m ruff check backend
npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build
python -m backend.scripts.check_contract_drift --cwd .
```

OpenSpec:

```bash
openspec validate final-delivery-alignment --strict
openspec status --change final-delivery-alignment
```

Móvil, solo dentro de su change dueño:

```bash
cd mobile && flutter test --no-pub
```

## 9. Migraciones, seed y generación

- Cambios de schema BD requieren migración Alembic; no edites datos de producción para “reparar” fixtures.
- El seed demo es fail-closed e idempotente. El fixture antiguo de tres gastos requiere reset destructivo **solo del entorno demo local** antes de reseed.
- Un cambio de API comienza en rutas/schemas manuscritos de backend, luego exporta OpenAPI, regenera y ejecuta drift.
- Nunca conviertas TODOs de código generado en alcance de producto automáticamente.

## 10. Archivos históricos

`docs/requerimiento-docente.md` y artifacts de changes previos son evidencia temporal. No los “corrijas” para que parezcan escritos con la arquitectura actual. Describe su supersesión en documentación viva.
