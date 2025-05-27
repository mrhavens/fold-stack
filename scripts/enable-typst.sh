#!/bin/bash
set -e

echo "Enabling Typst service..."
docker compose -f docker-compose.dev.yml up -d typst
echo "Typst service enabled. Check status with: docker ps | grep typst_dev"
