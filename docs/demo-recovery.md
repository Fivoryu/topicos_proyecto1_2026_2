# Demo database recovery

The demo seed is fail-closed: an integrity or derived zero-sum failure raises
`persistence_corrupted` and does not commit a partial repair. Do not continue a
demo from a database that reported this error.

For the local PostgreSQL demo, reset and reseed in this order:

```text
docker compose -f infra/docker-compose.yml down -v
docker compose -f infra/docker-compose.yml up -d db
python -m alembic -c backend/alembic.ini upgrade head
# Supply DEMO_OWNER_PASSWORD and DEMO_MEMBER_PASSWORD in the local environment.
python -m backend.scripts.seed_demo
```

The reset is intentionally destructive and is for development/demo data only.
After reseeding, verify the protected owner/member login and the AO-01 balances
before starting the walkthrough. Passwords, hashes, cookies, and other secrets
must not be recorded in this repository or in handoff evidence.
