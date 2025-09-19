#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[stop] Stopping containers…"
docker compose -f docker-compose.yml down

