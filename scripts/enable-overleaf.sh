#!/bin/bash
set -e

echo "Enabling Overleaf CE and its dependencies..."
docker compose -f docker-compose.dev.yml up -d overleaf-mongo overleaf-redis overleaf
echo "Overleaf CE enabled. Access at http://localhost:8090"
echo "Check status with: docker ps | grep overleaf"
