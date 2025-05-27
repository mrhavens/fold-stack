#!/bin/bash
set -e

echo "Enabling Overleaf CE (compose-git) and its dependencies..."
docker compose -f docker-compose.dev.yml up -d overleaf-mongo overleaf-redis overleaf
echo "Overleaf CE (compose-git) enabled. Access at http://localhost:8090"
echo "Check status with: docker ps | grep overleaf"
