#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================="
echo "🚀 GIT-SYNC MANUAL PUSH"
echo "================================="
echo "📅 Date: Mon May 26 21:43:00 CDT 2025"
echo ""

# Helper function to print success
print_success() {
    echo -e "✅ "
}

# Helper function to print warning
print_warning() {
    echo -e "⚠️  "
}

# Helper function to print error
print_error() {
    echo -e "❌ "
}

# 1. Check if Git-Sync Container is Running
if docker ps --format '{{.Names}}' | grep -q "git_sync_dev"; then
    print_success "Git-Sync container (git_sync_dev) is running."
else
    print_error "Git-Sync container (git_sync_dev) is not running. Start it with: ./scripts/up-dev.sh"
    exit 1
fi

# 2. Check Local Repository
if docker exec git_sync_dev test -d "/repos/local/.git"; then
    print_success "Local repository is initialized at /repos/local."
else
    print_error "Local repository not initialized at /repos/local. Initialize it with: git init"
    exit 1
fi

# 3. Load Environment Variables
if [ -f "config/git-sync/.env" ]; then
    set -a
    source config/git-sync/.env
    set +a
else
    print_error "config/git-sync/.env not found. Exiting."
    exit 1
fi

# 4. Initialize Log File
TIMESTAMP=1748313780
LOG_FILE="manual-push-.log"
docker exec git_sync_dev touch "/logs/"
docker exec git_sync_dev chmod 644 "/logs/"
docker exec git_sync_dev sh -c "echo '[Mon May 26 21:43:00 CDT 2025] Starting manual push' >> /logs/"

# Function to log messages
log_message() {
    local level=
    local message=
    docker exec git_sync_dev sh -c "echo '[Mon May 26 21:43:00 CDT 2025] [] ' >> /logs/"
    if [ "" = "INFO" ] && [ "" = "INFO" ]; then
        echo "[Mon May 26 21:43:00 CDT 2025] [] "
    elif [ "" = "ERROR" ]; then
        echo "[Mon May 26 21:43:00 CDT 2025] [] " >&2
    fi
}

# Function to sync to a Git remote (GitHub/Forgejo)
sync_to_git_remote() {
    local remote_name=
    local url=
    log_message "INFO" "Manually syncing to  at ..."
    if docker exec git_sync_dev sh -c "cd /repos/local && git remote | grep -q "; then
        docker exec git_sync_dev sh -c "cd /repos/local && git remote set-url  "
    else
        docker exec git_sync_dev sh -c "cd /repos/local && git remote add  "
    fi
    attempt=1
    while [  -le  ]; do
        if docker exec git_sync_dev sh -c "cd /repos/local && git push  --all --force"; then
            log_message "INFO" "Successfully synced to ."
            print_success "Synced to "
            break
        else
            log_message "ERROR" "Failed to sync to  (attempt /)."
            print_error "Failed to sync to  (attempt /)"
            attempt=1
            sleep 0
        fi
    done
    if [  -gt  ]; then
        log_message "ERROR" "Max retries reached for . Giving up."
        print_error "Max retries reached for "
    fi
}

# Function to sync to Radicle
sync_to_radicle() {
    local remote_name=
    local url=
    log_message "INFO" "Manually syncing to Radicle at ..."
    # Placeholder for Radicle sync
    log_message "INFO" "Radicle sync not fully implemented. Skipping."
    print_warning "Radicle sync not implemented"
}

# Function to sync to Rclone remote (Internet Archive/Web3.storage)
sync_to_rclone_remote() {
    local remote_name=
    local url=
    log_message "INFO" "Manually syncing to  at ..."
    # Create a Git bundle
    BUNDLE_FILE="/tmp/repo-1748313780.bundle"
    docker exec git_sync_dev sh -c "cd /repos/local && git bundle create  --all"
    # Sync the bundle using Rclone
    attempt=1
    while [  -le  ]; do
        if docker exec git_sync_dev rclone copy   --config /config/git-sync/rclone.conf --progress --log-level INFO; then
            log_message "INFO" "Successfully synced bundle to ."
            print_success "Synced bundle to "
            docker exec git_sync_dev rm 
            break
        else
            log_message "ERROR" "Failed to sync to  (attempt /)."
            print_error "Failed to sync to  (attempt /)"
            attempt=1
            sleep 0
        fi
    done
    if [  -gt  ]; then
        log_message "ERROR" "Max retries reached for . Giving up."
        print_error "Max retries reached for "
        docker exec git_sync_dev rm 
    fi
}

# 5. Perform Manual Push to All Remotes
echo "Pushing to all enabled remotes..."
while IFS='|' read -r remote_name type url enabled; do
    if [ "" -eq 1 ]; then
        if [ "" = "git" ]; then
            sync_to_git_remote  
        elif [ "" = "radicle" ]; then
            sync_to_radicle  
        elif [ "" = "rclone" ]; then
            sync_to_rclone_remote  
        fi
    else
        print_warning "Skipping disabled remote: "
    fi
done < config/git-sync/remotes.conf

# 6. Summary
echo ""
echo "================================="
echo "✅ Manual Push Completed"
echo "================================="
echo "Log file: ./volumes/logs/"
echo "Check sync status: ./scripts/report-git-sync.sh"
echo "Troubleshoot issues: ./scripts/diagnose-git-sync.sh"
