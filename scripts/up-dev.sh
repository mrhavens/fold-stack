#!/bin/bash
set -e

echo "Starting fold-stack development environment..."
docker compose --env-file .env.dev -f docker-compose.dev.yml up -d --build ghost forgejo radicle pandoc mailhog hedgedoc rclone typst git-sync
echo "Core services started."
