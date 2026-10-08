#!/bin/bash

set -e

# Prefer the modern `docker compose` (v2, Go-based CLI plugin) over the
# deprecated `docker-compose` (v1, Python, EOL July 2023) — v1 has a known
# bug recreating containers against newer Docker Engine image metadata
# (`KeyError: 'ContainerConfig'`), which v2 doesn't have.
if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
else
  COMPOSE="docker-compose"
fi

echo "Using: $COMPOSE"


$COMPOSE down --remove-orphans
echo "Building images..."
$COMPOSE build backend notification-service

echo "Applying changes (recreates only the services whose image/config changed)..."
$COMPOSE up -d

echo "Running containers:"
$COMPOSE ps

echo ""
echo "Backend logs:"
$COMPOSE logs --tail=50 backend
