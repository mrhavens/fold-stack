#!/bin/bash
set -e

echo "Shutting down fold-stack development environment..."
docker compose -f docker-compose.dev.yml down
echo "All services stopped."
