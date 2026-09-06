#!/bin/sh
set -eu

cd /app

if [ -z "${DATABASE_URL:-}" ]; then
  DATABASE_URL="postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}"
  export DATABASE_URL
fi

alembic -c backend/alembic.ini upgrade head
python -m backend.scripts.seed_demo

exec uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
