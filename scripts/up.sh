#!/usr/bin/env bash
set -euo pipefail
if [ ! -f .env ]; then
  cp .env.example .env
  echo "Aangemaakt: .env op basis van .env.example"
fi
docker compose up -d
echo "Grafana: http://localhost:3000"
