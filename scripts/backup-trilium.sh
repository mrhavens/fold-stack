#!/bin/bash
# Export Trilium notes as markdown
docker exec trilium_dev trilium-cli export /home/node/trilium-data /tmp/trilium-export --format markdown
# Copy the exported files to a backup directory
mkdir -p ./volumes/trilium-backup/export
docker cp trilium_dev:/tmp/trilium-export ./volumes/trilium-backup/export
# Dump the SQLite database
docker exec trilium_dev sqlite3 /home/node/trilium-data/document.db .dump > ./volumes/trilium-backup/document.sql
