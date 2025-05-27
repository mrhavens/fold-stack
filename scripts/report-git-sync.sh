#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================="
echo "📊 GIT-SYNC SYNC REPORT"
echo "================================="
echo "📅 Date: $(date)"
echo ""

# Helper function to print section headers
print_section() {
    echo "---------------------------------"
    echo "📌 $1"
    echo "---------------------------------"
}

# Helper function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Helper function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Helper function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Check if Git-Sync Container is Running
print_section "Container Status"
if docker ps --format '{{.Names}}' | grep -q "git_sync_dev"; then
    print_success "Git-Sync container (git_sync_dev) is running."
else
    print_error "Git-Sync container (git_sync_dev) is not running. Start it with: ./scripts/up-dev.sh"
    exit 1
fi

# 2. Get Latest Commit in Local Repository
print_section "Local Repository Latest Commit"
if docker exec git_sync_dev test -d "/repos/local/.git"; then
    LATEST_COMMIT=$(docker exec git_sync_dev git -C /repos/local rev-parse HEAD)
    LATEST_COMMIT_MSG=$(docker exec git_sync_dev git -C /repos/local log -1 --pretty=%B)
    LATEST_COMMIT_TIME=$(docker exec git_sync_dev git -C /repos/local log -1 --pretty=%cd)
    echo "Commit: $LATEST_COMMIT"
    echo "Message: $LATEST_COMMIT_MSG"
    echo "Time: $LATEST_COMMIT_TIME"
else
    print_error "Local repository not initialized at /repos/local."
    exit 1
fi

# 3. Analyze Logs for Sync Activity
print_section "Latest Sync Activity by Remote"
while IFS='|' read -r remote_name type url enabled; do
    if [ "$enabled" -eq 1 ]; then
        echo "Remote: $remote_name ($type, $url)"
        # Search logs for the last sync to this remote
        LAST_SYNC=$(docker logs git_sync_dev 2>&1 | grep "Successfully synced.*$remote_name" | tail -n 1)
        if [ -n "$LAST_SYNC" ]; then
            # Extract timestamp and message
            TIMESTAMP=$(echo "$LAST_SYNC" | grep -oE "^\[[^]]+\]" | head -n 1)
            if [ "$type" = "git" ] || [ "$type" = "radicle" ]; then
                # For Git and Radicle, assume the latest commit was synced
                echo "Last Synced Commit: $LATEST_COMMIT"
                echo "Commit Message: $LATEST_COMMIT_MSG"
            else
                # For Rclone (IA, Web3), look for the bundle file name in logs
                BUNDLE_FILE=$(echo "$LAST_SYNC" | grep -oE "repo-[0-9]+\.bundle" | head -n 1)
                if [ -n "$BUNDLE_FILE" ]; then
                    echo "Last Synced Bundle: $BUNDLE_FILE"
                else
                    echo "Last Synced Bundle: Unknown"
                fi
            fi
            echo "Timestamp: $TIMESTAMP"
            print_success "Status: Successfully synced"
        else
            print_warning "Status: No successful sync found in logs for $remote_name"
        fi
        echo ""
    else
        print_warning "Skipping disabled remote: $remote_name"
        echo ""
    fi
done < config/git-sync/remotes.conf

# 4. Check for Failed Syncs
print_section "Failed Syncs (Last 10 Errors)"
FAILED_SYNCS=$(docker logs git_sync_dev 2>&1 | grep "\[ERROR\].*Failed to sync" | tail -n 10)
if [ -n "$FAILED_SYNCS" ]; then
    echo "$FAILED_SYNCS"
else
    print_success "No failed syncs found in recent logs."
fi

# 5. Summary
print_section "Summary"
echo "Latest Local Commit: $LATEST_COMMIT"
echo "Check the above sections for sync status per remote."
echo "If a remote has not been synced recently, check logs or run diagnostics:"
echo "  ./scripts/diagnose-git-sync.sh"

echo ""
echo "================================="
echo "✅ Report Generation Completed"
echo "================================="
