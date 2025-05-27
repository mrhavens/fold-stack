#!/bin/bash
set -e

echo "Starting fold-stack development environment (excluding Overleaf CE by default)..."
docker compose -f docker-compose.dev.yml up -d --build   ghost forgejo radicle pandoc mailhog trilium hedgedoc nextcloud rclone typst
echo "Core services started. To enable Overleaf CE, run: ./scripts/enable-overleaf.sh"
