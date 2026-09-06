# Local Docker runtime

Open the repository's root `compose.yaml` in Docker Desktop to launch the local stack. The file includes the canonical service definitions from `infra/docker-compose.yml`, so Docker Desktop and direct Compose use the same configuration. No batch launcher or checked-in `.env` file is required.

## Quick path

1. Install and start Docker Desktop.
2. In Docker Desktop, open the repository root `compose.yaml` as a Compose application and start it.
3. Open `http://localhost:5173` when the frontend is healthy.

From the repository root, the equivalent command is:

```bash
docker compose -f compose.yaml up --build
```

To stop the stack without deleting the database volume:

```bash
docker compose -f compose.yaml down
```

The backend waits for PostgreSQL, applies Alembic migrations, validates the idempotent Samaipata demo seed, and only then starts Uvicorn. A migration or seed failure stops the backend container. The database is published on host port `5433`; the frontend is published on `5173` and provides the same-origin Nginx proxy for REST and group-event WebSocket traffic.

## Environment contract

The local stack starts without environment values. When the demo password variables are absent, the backend uses its existing local-development settings defaults. External variables may be supplied for a custom deployment; they are not stored in this repository.

| Variable | Use |
| --- | --- |
| `DATABASE_URL` | Optional backend database URL; when empty, the container entrypoint targets the Compose `db` service. |
| `CORS_ORIGINS` | Optional comma-separated backend origins. |
| `SESSION_TTL` | Optional backend session lifetime in seconds. |
| `DEMO_OWNER_PASSWORD` | Optional external override for the seeded demo owner password. |
| `DEMO_MEMBER_PASSWORD` | Optional external override for the seeded demo member password. |
| `VITE_API_BASE_URL` | Optional frontend build-time API URL; leave unset for same-origin proxying. |
| `VITE_GROUP_ID` | Optional frontend build-time group identifier; the local fallback is the seeded Samaipata group. |
| `POSTGRES_DB` | Optional database name used by PostgreSQL. |
| `POSTGRES_USER` | Optional PostgreSQL user. |
| `POSTGRES_PASSWORD` | Optional PostgreSQL password. |

This Compose stack is intended for local/demo use. For anything beyond that use, provide explicit secrets through the deployment environment or a secret manager outside the repository, and review the database, origin, and exposed-port settings for that deployment.

## Configuration source

`compose.yaml` is the Docker Desktop entrypoint and includes `infra/docker-compose.yml`. Keep service definitions, healthchecks, migration/seed ordering, and the `postgres_data` volume in the canonical file so both entrypoints remain consistent.
