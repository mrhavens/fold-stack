#!/bin/bash
set -e

# Ensure we're in the correct directory
cd ~/fieldwork/fold-stack

# Header
echo "===== Nextcloud Diagnostic Report ====="
echo "Generated on: $(date)"
echo "======================================"
echo ""

# Step 1: Check Container Status
echo "1. Nextcloud Container Status"
echo "-----------------------------"
docker ps -a --filter "name=nextcloud_dev" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
if [ "$(docker ps -q -f name=nextcloud_dev)" ]; then
    echo "Container is running."
else
    echo "Container is NOT running!"
fi
echo ""

# Step 2: Check Container Logs
echo "2. Nextcloud Logs (last 50 lines)"
echo "---------------------------------"
docker logs nextcloud_dev --tail 50 2>&1 || echo "Failed to retrieve logs."
echo ""

# Step 3: Check Volume Permissions
echo "3. Volume Permissions"
echo "---------------------"
echo "Checking ./volumes/nextcloud/html (should be owned by www-data, UID/GID 33:33):"
ls -ld ./volumes/nextcloud/html
ls -l ./volumes/nextcloud/html | head -n 5
echo "Checking ./volumes/nextcloud/data (should be owned by www-data, UID/GID 33:33):"
ls -ld ./volumes/nextcloud/data
ls -l ./volumes/nextcloud/data | head -n 5
echo ""

# Step 4: Check Nextcloud Configuration
echo "4. Nextcloud Configuration"
echo "--------------------------"
if [ -f ./volumes/nextcloud/html/config/config.php ]; then
    echo "config.php exists. Checking key settings..."
    echo "Trusted Domains:"
    grep -A 5 "'trusted_domains'" ./volumes/nextcloud/html/config/config.php || echo "Not found."
    echo "Overwrite Settings:"
    grep -E "'overwrite\..*'" ./volumes/nextcloud/html/config/config.php || echo "Not found."
else
    echo "config.php not found! Nextcloud may not be installed."
fi
echo ""

# Step 5: Check Nextcloud Status via OCC
echo "5. Nextcloud OCC Status"
echo "-----------------------"
docker exec nextcloud_dev php occ status 2>&1 || echo "Failed to run occ status."
echo ""

# Step 6: Check Database Accessibility
echo "6. Database Check"
echo "-----------------"
# Since we're using SQLite (based on the setup), check if the database file exists and is writable
echo "Checking SQLite database file (/var/www/html/data/nextcloud.db):"
docker exec nextcloud_dev ls -l /var/www/html/data/nextcloud.db 2>&1 || echo "Database file not found or inaccessible."
echo ""

# Step 7: Check Web Server (Apache) Status
echo "7. Web Server (Apache) Status"
echo "----------------------------"
docker exec nextcloud_dev ps aux | grep apache2 || echo "No Apache processes found."
echo ""

# Step 8: Test Network Connectivity
echo "8. Network Connectivity"
echo "-----------------------"
echo "Testing healthcheck endpoint (http://localhost/status.php):"
docker exec nextcloud_dev curl -f http://localhost/status.php 2>&1 || echo "Failed to reach status.php."
echo "Testing external access (http://localhost:8081):"
curl -f http://localhost:8081/status.php 2>&1 || echo "Failed to reach Nextcloud directly on port 8081."
echo "Testing proxy access (http://localhost/nextcloud/):"
curl -f http://localhost/nextcloud/status.php 2>&1 || echo "Failed to reach Nextcloud via Nginx proxy."
echo ""

# Step 9: Check Nginx Proxy Configuration
echo "9. Nginx Proxy Configuration"
echo "----------------------------"
echo "Checking Nginx container status:"
docker ps -a --filter "name=nginx_dev" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "Checking Nginx logs for Nextcloud errors (last 20 lines):"
docker logs nginx_dev --tail 20 2>&1 | grep -i nextcloud || echo "No Nextcloud-related errors found in Nginx logs."
echo "Checking Nginx configuration for Nextcloud:"
grep -A 20 "location /nextcloud/" nginx/dev/default.conf || echo "Nextcloud proxy configuration not found."
echo ""

# Step 10: Check Disk Space
echo "10. Disk Space"
echo "--------------"
df -h ./volumes/nextcloud
echo ""

# Step 11: Check Memory Usage
echo "11. Memory Usage"
echo "----------------"
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep nextcloud_dev
echo ""

# Step 12: Check for Maintenance Mode
echo "12. Maintenance Mode"
echo "--------------------"
docker exec nextcloud_dev php occ maintenance:mode 2>&1 || echo "Failed to check maintenance mode."
echo ""

# Step 13: Check for Pending Updates or Repairs
echo "13. Pending Updates/Repairs"
echo "---------------------------"
docker exec nextcloud_dev php occ upgrade 2>&1 || echo "Failed to run occ upgrade."
docker exec nextcloud_dev php occ db:add-missing-indices 2>&1 || echo "Failed to run db:add-missing-indices."
docker exec nextcloud_dev php occ db:convert-filecache-bigint 2>&1 || echo "Failed to run db:convert-filecache-bigint."
echo ""

echo "===== End of Nextcloud Diagnostic Report ====="
