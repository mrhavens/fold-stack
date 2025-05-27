#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================="
echo "🩺 FOLD STACK COMPREHENSIVE DIAGNOSTICS"
echo "================================="
echo "📅 Date: Mon May 26 20:28:00 CDT 2025"
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

# 2. Check Docker Compose File
print_section "Docker Compose File Check: docker-compose.dev.yml"
if [ -f "docker-compose.dev.yml" ] && grep -q "^services:" docker-compose.dev.yml; then
    print_success "docker-compose.dev.yml exists and looks valid."
else
    print_error "docker-compose.dev.yml is missing or invalid — check formatting."
    exit 1
fi

# 3. Check Environment Variables (.env.dev)
print_section "Environment Variables (.env.dev)"
if [ -f ".env.dev" ]; then
    cat .env.dev | grep -v '^#' || print_warning "No environment variables found in .env.dev."
else
    print_warning ".env.dev not found."
fi

# 4. Check Containers Status
print_section "Containers Status"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || print_error "Failed to list Docker containers. Is Docker running?"

# 5. Check Port Bindings
print_section "Port Bindings"
docker compose -f docker-compose.dev.yml port ghost 2368 || print_error "Ghost not exposing port 2368"
docker compose -f docker-compose.dev.yml port forgejo 3000 || print_error "Forgejo not exposing port 3000"
docker compose -f docker-compose.dev.yml port trilium 8080 || print_error "Trilium not exposing port 8080"
docker compose -f docker-compose.dev.yml port hedgedoc 3000 || print_error "HedgeDoc not exposing port 3000"
docker compose -f docker-compose.dev.yml port mailhog 8025 || print_error "MailHog not exposing port 8025"
docker compose -f docker-compose.dev.yml port nextcloud 80 || print_error "Nextcloud not exposing port 80"

# 6. Check Logs for Each Service
print_section "Forgejo Logs (last 50 lines)"
docker logs forgejo_dev --tail=50 2>&1 || print_warning "Forgejo container not found."

print_section "Ghost Logs (last 20 lines)"
docker logs ghost_dev --tail=20 2>&1 || print_warning "Ghost container not found."

print_section "Trilium Logs (last 20 lines)"
docker logs trilium_dev --tail=20 2>&1 || print_warning "Trilium container not found."

print_section "HedgeDoc Logs (last 20 lines)"
docker logs hedgedoc_dev --tail=20 2>&1 || print_warning "HedgeDoc container not found."

print_section "MailHog Logs (last 20 lines)"
docker logs mailhog_dev --tail=20 2>&1 || print_warning "MailHog container not found."

print_section "Nextcloud Logs (last 20 lines)"
docker logs nextcloud_dev --tail=20 2>&1 || print_warning "Nextcloud container not found."

print_section "Rclone Logs (last 20 lines)"
docker logs rclone_dev --tail=20 2>&1 || print_warning "Rclone container not found."

# 7. Check Volume Permissions and Contents
print_section "Forgejo Volume Permissions"
ls -ld ./volumes/forgejo || print_error "Missing volumes/forgejo"
ls -la ./volumes/forgejo || print_warning "Forgejo volume contents not accessible"

print_section "Trilium Volume Permissions"
ls -ld ./volumes/trilium || print_error "Missing volumes/trilium"
ls -la ./volumes/trilium || print_warning "Trilium volume contents not accessible"

print_section "HedgeDoc Volume Permissions"
ls -ld ./volumes/hedgedoc/uploads || print_error "Missing volumes/hedgedoc/uploads"
ls -la ./volumes/hedgedoc/uploads || print_warning "HedgeDoc volume contents not accessible"

print_section "Nextcloud Volume Permissions"
ls -ld ./volumes/nextcloud/html || print_error "Missing volumes/nextcloud/html"
ls -la ./volumes/nextcloud/html || print_warning "Nextcloud html volume contents not accessible"
ls -ld ./volumes/nextcloud/data || print_error "Missing volumes/nextcloud/data"
ls -la ./volumes/nextcloud/data || print_warning "Nextcloud data volume contents not accessible"

print_section "Scrolls Volume Permissions (Pandoc)"
ls -ld ./volumes/scrolls || print_error "Missing volumes/scrolls"
ls -la ./volumes/scrolls || print_warning "Scrolls volume contents not accessible"

print_section "Trilium Backup Volume Permissions"
ls -ld ./volumes/trilium-backup || print_warning "Missing volumes/trilium-backup (needed for Web3.storage sync)"
ls -la ./volumes/trilium-backup || print_warning "Trilium backup volume contents not accessible"

# 8. Check Entrypoint Script for Forgejo
print_section "Forgejo Entrypoint Script Check (forgejo-entrypoint.sh)"
head -n 10 scripts/forgejo-entrypoint.sh 2>/dev/null || print_warning "Missing forgejo-entrypoint.sh script"

# 9. Check Rclone Configuration
print_section "Rclone Configuration Check"
if [ -f "./config/rclone/rclone.conf" ]; then
    print_success "Rclone config file found."
    echo "Configured remotes:"
    rclone listremotes --config ./config/rclone/rclone.conf || print_error "Failed to list Rclone remotes."
else
    print_error "Rclone config file (./config/rclone/rclone.conf) not found."
fi

# 10. Test Rclone Connectivity
print_section "Rclone Connectivity Test"
if [ -f "./config/rclone/rclone.conf" ]; then
    echo "Testing Google Drive (gdrive)..."
    rclone lsd gdrive: --config ./config/rclone/rclone.conf 2>&1 | grep -q "fold-stack" && print_success "Google Drive connectivity test passed." || print_error "Google Drive connectivity test failed."

    echo "Testing Internet Archive (ia)..."
    rclone lsd ia: --config ./config/rclone/rclone.conf 2>&1 | grep -q "fold-stack-scrolls" && print_success "Internet Archive connectivity test passed." || print_error "Internet Archive connectivity test failed."

    echo "Testing Web3.storage (web3)..."
    rclone lsd web3: --config ./config/rclone/rclone.conf 2>&1 | grep -q "fold-stack-trilium" && print_success "Web3.storage connectivity test passed." || print_error "Web3.storage connectivity test failed."
else
    print_warning "Skipping Rclone connectivity test due to missing config file."
fi

# 11. Test Rclone Sync by Adding a Test File
print_section "Rclone Sync Test"
TEST_FILE="./volumes/scrolls/diagnostic-test-1748309280.scroll"
echo "Test file for diagnostics" > "$TEST_FILE"
echo "Created test file: $TEST_FILE"
echo "Waiting for Rclone to detect and sync (up to 30 seconds)..."
sleep 30
docker logs rclone_dev --tail=10 2>&1 | grep -q "diagnostic-test" && print_success "Rclone sync test passed: Test file detected in logs." || print_warning "Rclone sync test failed: Test file not detected in logs."

# 12. Check Disk Space
print_section "Disk Space Check"
df -h / || print_error "Failed to check disk space."

# 13. Check Network Interfaces
print_section "Network Interfaces"
if command -v ifconfig >/dev/null; then
    ifconfig -a || print_error "Failed to check network interfaces."
else
    print_warning "ifconfig not found. Install net-tools to check network interfaces:"
    echo "  sudo apt install net-tools"
fi

# 14. Summary of Findings
print_section "Summary of Findings"
echo "Check the above output for any errors (❌) or warnings (⚠️)."
echo "Common issues and fixes:"
echo "- If a container is not running, restart the stack: ./scripts/down-dev.sh && ./scripts/up-dev.sh"
echo "- If Rclone connectivity fails, reconfigure remotes: rclone config"
echo "- If volumes are inaccessible, fix permissions: chmod -R 775 ./volumes && chown -R 1000:1000 ./volumes"
echo "- If ports are not exposed, check for conflicts: netstat -tuln | grep <port>"

echo ""
echo "================================="
echo "✅ Diagnostics Completed"
echo "================================="
echo "If issues persist, share the output with support or run:"
echo "  docker compose logs -f [service]"
