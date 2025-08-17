#!/bin/sh
set -e

# Falls du testweise eine .env in /app hast, exportieren (nicht erforderlich mit Compose)
if [ -f /app/.env ]; then
  set -a
  . /app/.env
  set +a
fi

echo "================ ENV CHECK (DB) ================"
env | grep -E '^(APP_DB_|DB_(HOST|PORT|USER|USERNAME|PASSWORD|NAME)|PG(HOST|PORT|USER|PASSWORD|DATABASE)|POSTGRES_(HOST|PORT|USER|PASSWORD|DB)|DATABASE_URL|POSTGRES_URL|ENVIRONMENT|ENVIROMENT)=' | sort || true
echo "==============================================="

exec ./smartender-backend
