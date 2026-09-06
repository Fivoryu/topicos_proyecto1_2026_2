# Inicio local de Cuentas Claras

Guía rápida para levantar PostgreSQL, el backend FastAPI, el frontend web y la aplicación Flutter.

> Comandos preparados para **PowerShell en Windows**. Ejecutalos desde la raíz del repositorio.

## Requisitos

- Python 3.11 o superior
- Node.js y npm
- Docker Desktop con Compose
- Flutter SDK, únicamente para la app móvil

## 1. Instalar dependencias

```powershell
Set-Location D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1

python -m pip install -e "backend[dev]"
npm --prefix web ci
```

## 2. Levantar backend y base de datos

Abrí una terminal nueva y ejecutá:

```powershell
Set-Location D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1

docker compose -f infra/docker-compose.yml up -d db

# PostgreSQL se expone en localhost:5433.
$env:DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5433/cuentas_claras"
$env:DEMO_OWNER_PASSWORD = "change-me-owner"
$env:DEMO_MEMBER_PASSWORD = "change-me-member"

python -m alembic -c backend/alembic.ini upgrade head
python -m backend.scripts.seed_demo
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
```

Comprobá la API desde otra terminal:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

## 3. Levantar el frontend web

En otra terminal:

```powershell
Set-Location D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1
npm --prefix web run dev -- --host 127.0.0.1 --port 5173
```

Abrí <http://localhost:5173>.

El frontend proxifica `/api` hacia `http://127.0.0.1:8000`; no agregues `/api/v1` a `VITE_API_BASE_URL`.

## 4. Depurar la app Flutter

En otra terminal:

```powershell
Set-Location D:\Universidad\Proyectos\2doSemestre2026\topicos\proyecto_1\mobile

flutter pub get
flutter devices
```

### Emulador Android

Reemplazá `<ID_DEL_DISPOSITIVO>` por el identificador mostrado por `flutter devices`:

```powershell
flutter run -d <ID_DEL_DISPOSITIVO> --debug `
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
  --dart-define=GROUP_ID=00000000-0000-4000-8000-000000000001
```

`10.0.2.2` permite que el emulador Android acceda al localhost de la PC.

### Windows

```powershell
flutter run -d windows --debug `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=GROUP_ID=00000000-0000-4000-8000-000000000001
```

### Teléfono físico

Levantá el backend escuchando en la red local:

```powershell
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
```

Luego usá la IP local de la PC:

```powershell
flutter run -d <ID_DEL_DISPOSITIVO> --debug `
  --dart-define=API_BASE_URL=http://<IP_DE_LA_PC>:8000 `
  --dart-define=GROUP_ID=00000000-0000-4000-8000-000000000001
```

El teléfono y la PC deben estar en la misma red y el firewall debe permitir el puerto 8000.

Durante `flutter run`:

- `r`: hot reload
- `R`: hot restart
- `q`: salir

## Credenciales de demostración

Con una base nueva y el seed ejecutado con las variables anteriores:

| Usuario | Contraseña | Rol |
| --- | --- | --- |
| `demo.owner` | `change-me-owner` | `owner` |
| `demo.member` | `change-me-member` | `member` |

Grupo demo:

```text
00000000-0000-4000-8000-000000000001
```

Las contraseñas son valores locales de desarrollo. El seed no modifica la contraseña de una cuenta que ya existe.

> Si la base es descartable y las credenciales no funcionan, `docker compose -f infra/docker-compose.yml down -v` elimina el volumen y todos sus datos. Después repetí el paso 2.

## 5. Ejecutar pruebas

Desde la raíz del repositorio:

```powershell
python -m pytest backend/tests -q
python -m ruff check backend

npm --prefix web run test
npm --prefix web run typecheck
npm --prefix web run build

python -m backend.scripts.check_contract_drift --cwd .
```

## Flujo recomendado

1. Levantar PostgreSQL, migrar y ejecutar el seed.
2. Iniciar el backend y comprobar `/health`.
3. Iniciar el frontend web.
4. Ejecutar Flutter con los `dart-define` correspondientes.
5. Iniciar sesión con `demo.owner` y verificar participantes, gastos, balances y liquidación.
