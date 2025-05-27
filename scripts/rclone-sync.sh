#!/bin/bash
set -e

echo "Starting rclone synchronization at $(date)"

# Function to sync to Google Drive
sync_to_gdrive() {
    local src=$1
    local dest=$2
    echo "Syncing $src to Google Drive (gdrive:$dest)"
    rclone sync "$src" "gdrive:$dest" --progress --transfers=4 --checkers=8 --exclude "*.{db,db-shm,db-wal}" --log-level INFO
}

# Function to sync to Internet Archive (only .scroll and .seal files)
sync_to_ia() {
    local src=$1
    local dest=$2
    echo "Syncing $src to Internet Archive (ia:$dest)"
    rclone sync "$src" "ia:$dest" --progress --transfers=4 --checkers=8 --wait-archive=1h --include "*.{scroll,seal}" --log-level INFO
}

# Function to sync to Web3.storage
sync_to_web3() {
    local src=$1
    local dest=$2
    if [ -d "$src" ]; then
        echo "Syncing $src to Web3.storage (web3:$dest)"
        rclone sync "$src" "web3:$dest" --progress --transfers=4 --checkers=8 --log-level INFO
    else
        echo "$src directory not found, skipping Web3.storage sync"
    fi
}

# Sync working drafts to Google Drive
sync_to_gdrive "/data/scrolls" "fold-stack/scrolls"
sync_to_gdrive "/data/hedgedoc/uploads" "fold-stack/hedgedoc_uploads"

# Sync scrolls/seals to Internet Archive
sync_to_ia "/data/scrolls" "fold-stack-scrolls"

# Sync Trilium backups to Web3.storage
sync_to_web3 "/data/trilium-backup" "fold-stack-trilium"

echo "Synchronization completed at $(date)"
