#!/bin/bash
set -e

echo "================================="
echo "🚀 Enabling Fold Stack Dashboard"
echo "================================="

# Ensure volumes/flame directory exists
mkdir -p volumes/flame
chmod -R 775 volumes/flame
chown -R 1000:1000 volumes/flame

# Verify .env.dev contains FLAME_PASSWORD
if ! grep -q "FLAME_PASSWORD" .env.dev; then
    echo "ERROR: FLAME_PASSWORD not set in .env.dev. Add it with: echo 'FLAME_PASSWORD=yourpassword' >> .env.dev"
    exit 1
fi

# Start the flame_dashboard service
docker compose -f docker-compose.dev.yml up -d flame_dashboard

echo "================================="
echo "✅ Dashboard Enabled"
echo "================================="
echo "Access the dashboard at http://localhost"
echo "Use the password set in FLAME_PASSWORD to log in"
