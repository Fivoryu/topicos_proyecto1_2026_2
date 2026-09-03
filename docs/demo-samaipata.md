# Demo oficial Samaipata — menos de 3 minutos

Este walkthrough muestra el estado oficial pre-sembrado sin modificarlo. La demo evaluada es web: FastAPI/PostgreSQL conservan la autoridad y React solo presenta los datos derivados por el servidor.

## Preconditions

Desde la raíz del repo:

```bash
# Destructivo solo si tu BD demo contiene el fixture antiguo; ver demo-recovery.md.
docker compose -f infra/docker-compose.yml up -d db
python -m alembic -c backend/alembic.ini upgrade head
python -m backend.scripts.seed_demo
python -m backend.scripts.seed_demo
```

Define `DEMO_OWNER_PASSWORD` y `DEMO_MEMBER_PASSWORD` localmente antes del seed. No registres esos valores en el repo, capturas o evidencia.

Arranca en dos terminales:

```bash
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
npm --prefix web run dev -- --host 127.0.0.1 --port 5173
```

Abre `http://localhost:5173` y usa `demo.owner` con la contraseña local.

## Guion cronometrado — objetivo 2:00–2:30

| Tiempo | Acción | Evidencia esperada |
| --- | --- | --- |
| 0:00–0:20 | Inicia sesión como `demo.owner`. | Aparece la shell protegida, en español, con rol **Propietario**. |
| 0:20–0:40 | Muestra **Participantes**. | Ana, Beto, Carla y Diego aparecen en orden estable. |
| 0:40–1:05 | Muestra **Gastos**. | Cuatro registros: **Cabaña Bs. 800,00** (Ana), **Entradas a El Fuerte Bs. 160,00** (Ana), **Cena Bs. 400,00** (Beto), **Gasolina Bs. 240,00** (Carla). Todos tienen a los cuatro participantes como beneficiarios. |
| 1:05–1:30 | Muestra **Balances**. | Ana `+Bs. 560,00` / `Le deben`; Beto `Bs. 0,00` / `Saldado`; Carla `-Bs. 160,00` / `Debe`; Diego `-Bs. 400,00` / `Debe`. |
| 1:30–1:50 | Muestra **Liquidación**. | `Diego → Ana: Bs. 400,00`, luego `Carla → Ana: Bs. 160,00`. |
| 1:50–2:15 | Refresca la página. | La sesión válida vuelve a cargar el mismo grupo desde servidor; participantes, cuatro gastos, balances y liquidación permanecen idénticos. |
| 2:15–2:30 | Cierra con la regla SDD. | Explica que el escenario exacto está protegido por tests y que balances/liquidación se calculan en backend con centavos enteros. |

No crear, editar ni eliminar gastos durante el camino cronometrado. La funcionalidad CRUD permanece implementada y probada, pero mutar el fixture durante la exposición agrega riesgo y altera los resultados oficiales.

## Valores que deben coincidir exactamente

- Total: Bs. 1.600,00.
- Cuota por persona: Bs. 400,00.
- Suma de balances: exactamente 0 centavos.
- Ana: `+56000`; Beto: `0`; Carla: `-16000`; Diego: `-40000`.
- Transferencias ordenadas: Diego → Ana `40000`; Carla → Ana `16000`.

## Gate rápido antes de exponer

```bash
python -m pytest backend/tests/acceptance/test_da_01_samaipata.py -q
npm --prefix web run test
npm --prefix web run build
```

Si el seed reporta `persistence_corrupted` por datos demo antiguos, sigue [`demo-recovery.md`](demo-recovery.md). No intentes “arreglar” filas estables manualmente.
