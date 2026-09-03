# Cuentas Claras

**Proyecto 1 — Grupo 2: Spec-Driven Development**

Cuentas Claras es una aplicación para dividir gastos de un viaje o grupo. Permite administrar participantes, registrar gastos con pagadores y beneficiarios, consultar balances y obtener una liquidación determinística de quién paga a quién. La entrega oficial se demuestra con el viaje a **Samaipata**.

## Estado y alcance

La ruta de entrega evaluada es **web + backend**:

- Backend: FastAPI + PostgreSQL + SQLAlchemy + Alembic.
- Web: React + Vite + TanStack Query.
- Contrato: OpenAPI con clientes TypeScript/Dart generados.
- Tiempo real: WebSocket de invalidación (`data_changed`) seguido de refetch REST.
- Autenticación: sesiones protegidas persistidas y roles `owner`/`member` derivados por servidor.

Existe además un cliente **Flutter/Android** bajo `mobile/`, gobernado de forma independiente por `openspec/changes/mobile-domain-features/`. Es una extensión del proyecto y **no es requisito para instalar ni ejecutar la demo oficial web**. La publicación post-commit de invalidaciones del backend está gobernada por `openspec/changes/wire-mutation-websocket-invalidation/` y se preserva como comportamiento existente.

## Funcionalidad principal

- Login/logout con cuentas demo protegidas.
- Listado, alta, renombrado, archivo/reactivación y borrado permitido de participantes.
- Registro, edición y eliminación de gastos.
- Uno o varios pagadores/contribuidores; beneficiarios seleccionables y todos los activos por defecto.
- Participantes archivados preservados cuando existen referencias históricas.
- Balances y liquidación calculados por el servidor usando centavos enteros.
- Persistencia en PostgreSQL a través de refresh.
- Invalidación WebSocket y refetch REST sin convertir WebSocket en fuente monetaria.

## Estructura

```text
backend/                    FastAPI, dominio, persistencia, migraciones y tests
web/                        React/Vite, tests y cliente OpenAPI TypeScript
mobile/                     extensión Flutter/Android independiente
contracts/openapi.json      contrato OpenAPI congelado
infra/docker-compose.yml    PostgreSQL local
docs/                       demo, recuperación, generación y mapa SDD
openspec/                    contexto, configuración, specs/changes
AGENTS.md                    reglas obligatorias para personas/agentes IA
```

## Requisitos previos

Para la entrega web:

- Python 3.11 o superior.
- Node.js 22 recomendado y npm.
- Docker + Docker Compose para PostgreSQL local.

Flutter/Dart solo es necesario si se trabaja en el change móvil independiente.

## 1. Instalar dependencias

Ejecutar desde la raíz del repositorio:

```bash
python -m pip install -e "backend[dev]"
npm --prefix web ci
```

## 2. Configurar entorno local

Copia `backend/.env.example` a `backend/.env` y define contraseñas demo locales propias. No subas ese archivo ni compartas contraseñas en capturas.

Variables principales:

```text
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/cuentas_claras
CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
SESSION_TTL=28800
DEMO_OWNER_PASSWORD=<valor-local>
DEMO_MEMBER_PASSWORD=<valor-local>
```

Para web, `web/.env.example` deja `VITE_API_BASE_URL` vacío en desarrollo. Vite ya proxifica `/api` hacia `127.0.0.1:8000`, manteniendo cookies same-origin. **No agregues `/api/v1` a `VITE_API_BASE_URL`**: las operaciones generadas ya contienen ese prefijo. `VITE_GROUP_ID` es solo configuración de routing heredada/no autoritativa; la shell protegida usa el grupo devuelto por la sesión del servidor.

## 3. Levantar PostgreSQL y migrar

Desde la raíz:

```bash
docker compose -f infra/docker-compose.yml up -d db
python -m alembic -c backend/alembic.ini upgrade head
```

## 4. Cargar el escenario oficial de Samaipata

```bash
python -m backend.scripts.seed_demo
```

El seed es idempotente. Al ejecutarlo una segunda vez no debe crear nuevas cuentas, participantes ni gastos.

Fixture oficial:

| Gasto | Pagador | Monto |
| --- | --- | ---: |
| Cabaña | Ana | Bs. 800,00 |
| Entradas a El Fuerte | Ana | Bs. 160,00 |
| Cena | Beto | Bs. 400,00 |
| Gasolina | Carla | Bs. 240,00 |

Todos los gastos benefician a Ana, Beto, Carla y Diego. Resultado esperado:

| Participante | Balance |
| --- | ---: |
| Ana | +Bs. 560,00 |
| Beto | Bs. 0,00 |
| Carla | -Bs. 160,00 |
| Diego | -Bs. 400,00 |

Liquidación: **Diego → Ana: Bs. 400,00** y **Carla → Ana: Bs. 160,00**.

> Si tu base local todavía contiene el fixture antiguo de tres gastos, el seed fallará de forma segura en vez de reescribirlo. Para una demo local descartable usa el reset de `docs/demo-recovery.md` (`docker compose ... down -v`) y vuelve a migrar/seedear. Ese reset destruye el volumen local.

## 5. Ejecutar backend y web

Terminal 1, desde raíz:

```bash
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
```

Comprueba salud en `GET /health`.

Terminal 2, desde raíz:

```bash
npm --prefix web run dev -- --host 127.0.0.1 --port 5173
```

Abre `http://localhost:5173`.

## Cuentas de demostración

El seed crea los nombres de cuenta, pero las contraseñas deben venir de tu entorno local:

- `demo.owner` — rol propietario.
- `demo.member` — rol miembro.

Este README no contiene contraseñas ni hashes.

## Pruebas y gates de entrega

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

Verificación OpenSpec del change de cierre:

```bash
openspec validate final-delivery-alignment --strict
openspec status --change final-delivery-alignment
```

Los clientes bajo `web/src/generated/api/` y `mobile/lib/generated/api/` no se editan a mano. El workflow reproducible está en `docs/api-client-generation.md`.

## Demo oficial (< 3 minutos)

La ruta recomendada está en [`docs/demo-samaipata.md`](docs/demo-samaipata.md). En resumen:

1. Iniciar sesión como `demo.owner`.
2. Mostrar Ana, Beto, Carla y Diego.
3. Mostrar los cuatro gastos oficiales ya sembrados.
4. Mostrar los balances exactos.
5. Mostrar Diego → Ana Bs. 400,00 y Carla → Ana Bs. 160,00.
6. Refrescar el navegador y mostrar que los datos y resultados permanecen.

No se agrega un gasto extra durante el camino principal de la demo.

## Spec-Driven Development

- Contexto actual: `openspec/project-context.md`.
- Reglas para agentes/personas: `AGENTS.md`.
- Evolución y precedencia: `docs/sdd-evolution.md`.
- Change de cierre: `openspec/changes/final-delivery-alignment/`.

La regla de Grupo 2 es: **si cambia el entendimiento aceptado, se actualiza la spec antes del código**. Los artifacts históricos se preservan y su supersesión se documenta; no se reescriben retroactivamente.
