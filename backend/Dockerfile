FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

WORKDIR /app

COPY . /app/backend

RUN pip install --no-cache-dir /app/backend \
    && addgroup --gid 10001 app \
    && adduser --uid 10001 --gid 10001 --disabled-password --gecos "" app \
    && chown -R 10001:10001 /app
    
USER 10001:10001

EXPOSE 8000

ENTRYPOINT ["/app/backend/docker-entrypoint.sh"]
