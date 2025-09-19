#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[start] Building and starting containers (detached)…"
docker compose -f docker-compose.yml up -d --build

echo "[start] Waiting a moment for services to come up…"
sleep 2

echo "[start] Status:"
docker compose ps

echo "[start] Tail logs with: docker compose logs -f smartender-app"

