#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[restart] Restarting containers…"
docker compose -f docker-compose.yml down
docker compose -f docker-compose.yml up -d --build

