#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================="
echo "🩺 GIT-SYNC COMPREHENSIVE DIAGNOSTICS"
echo "================================="
echo "📅 Date: Mon May 26 21:36:33 CDT 2025"
echo ""

# Helper function to print section headers
print_section() {
    echo "---------------------------------"
    echo "📌 "
    echo "---------------------------------"
}

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

# 1. Check Current Directory
print_section "Current Directory"
echo "📁 Current Directory: /home/mrhavens/fieldwork/fold-stack"
if [[ "/home/mrhavens/fieldwork/fold-stack" != *"/fieldwork/fold-stack" ]]; then
    print_error "You are not in the expected fold-stack directory. Please run this script from ~/fieldwork/fold-stack."
    exit 1
fi
print_success "Directory check passed."

# 2. Check Docker Container Status
print_section "Git-Sync Container Status"
if docker ps --format '{{.Names}}' | grep -q "git_sync_dev"; then
    print_success "Git-Sync container (git_sync_dev) is running."
else
    print_error "Git-Sync container (git_sync_dev) is not running. Start it with: ./scripts/up-dev.sh"
    exit 1
fi

# 3. Check Configuration Files
print_section "Configuration Files Check"
CONFIG_FILES=(
    "/config/git-sync/remotes.conf"
    "/config/git-sync/rclone.conf"
    "/config/git-sync/.env"
    "/config/git-sync/rules.json"
)
for file in ""; do
    if docker exec git_sync_dev test -f ""; then
        print_success " exists."
    else
        print_error " is missing."
    fi
done

# 4. Check SSH Keys
print_section "SSH Keys Check"
SSH_KEYS=(
    "/config/git-sync/secrets/github.key"
    "/config/git-sync/secrets/forgejo.key"
)
for key in ""; do
    if docker exec git_sync_dev test -f ""; then
        print_success " exists."
        # Check permissions
        PERMS=
        if [ "" -eq 600 ]; then
            print_success " has correct permissions (600)."
        else
            print_warning " permissions are  (should be 600)."
        fi
    else
        print_warning " is missing (sync to this remote may fail)."
    fi
done

# 5. Check Remote Connectivity
print_section "Remote Connectivity Test"
while IFS='|' read -r remote_name type url enabled; do
    if [ "" -eq 1 ]; then
        echo "Testing  ()..."
        if [ "" = "git" ]; then
            if docker exec git_sync_dev git ls-remote "" >/dev/null 2>&1; then
                print_success " connectivity test passed."
            else
                print_error " connectivity test failed. Check SSH key or URL."
            fi
        elif [ "" = "rclone" ]; then
            if docker exec git_sync_dev rclone lsd "" --config /config/git-sync/rclone.conf >/dev/null 2>&1; then
                print_success " connectivity test passed."
            else
                print_error " connectivity test failed. Check rclone.conf or credentials."
            fi
        elif [ "" = "radicle" ]; then
            print_warning "Radicle connectivity test not implemented (placeholder)."
        fi
    else
        print_warning "Skipping disabled remote: "
    fi
done < config/git-sync/remotes.conf

# 6. Check Logs for Errors
print_section "Git-Sync Logs Check (last 50 lines)"
LOGS=[Mon May 26 21:26:36 CDT 2025] [INFO] Starting sync loop with interval 300 seconds.
[Mon May 26 21:26:36 CDT 2025] [INFO] Checking for changes in local repository...
fatal: detected dubious ownership in repository at '/repos/local'
To add an exception for this directory, call:

	git config --global --add safe.directory /repos/local
[Mon May 26 21:26:36 CDT 2025] [INFO] Starting sync loop with interval 300 seconds.
[Mon May 26 21:26:36 CDT 2025] [INFO] Checking for changes in local repository...
fatal: detected dubious ownership in repository at '/repos/local'
To add an exception for this directory, call:

	git config --global --add safe.directory /repos/local
echo ""
if echo "" | grep -q "\[ERROR\]"; then
    print_error "Errors found in logs. Search for [ERROR] above."
else
    print_success "No errors found in recent logs."
fi

# 7. Check Volume Permissions
print_section "Local Repository Volume Permissions"
ls -ld ./volumes/repos || print_error "Missing volumes/repos (needed for Git-Sync)"
ls -la ./volumes/repos || print_warning "Local repository volume contents not accessible"

print_section "Logs Volume Permissions"
ls -ld ./volumes/logs || print_error "Missing volumes/logs (needed for logging)"
ls -la ./volumes/logs || print_warning "Logs volume contents not accessible"

# 8. Check Lockfile
print_section "Lockfile Check"
if docker exec git_sync_dev test -f "/repos/local/.git-sync.lock"; then
    print_success "Lockfile exists (/repos/local/.git-sync.lock)."
else
    print_error "Lockfile missing (/repos/local/.git-sync.lock). Sync may not be atomic."
fi

# 9. Check Local Repository
print_section "Local Repository Check"
if docker exec git_sync_dev test -d "/repos/local/.git"; then
    print_success "Local repository is initialized at /repos/local."
else
    print_error "Local repository not initialized at /repos/local. Initialize it with: git init"
fi

# 10. Summary of Findings
print_section "Summary of Findings"
echo "Check the above output for any errors (❌) or warnings (⚠️)."
echo "Common issues and fixes:"
echo "- If the container is not running, restart the stack: ./scripts/down-dev.sh && ./scripts/up-dev.sh"
echo "- If SSH keys are missing or have wrong permissions, fix them: chmod 600 config/git-sync/secrets/*"
echo "- If remotes are unreachable, verify URLs and credentials in config/git-sync/remotes.conf and rclone.conf"
echo "- If logs show errors, check network connectivity or remote availability"

echo ""
echo "================================="
echo "✅ Diagnostics Completed"
echo "================================="
echo "If issues persist, share the output with support or run:"
echo "  docker logs git_sync_dev --follow"
