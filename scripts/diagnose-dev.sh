#!/bin/bash
set -e

echo "============================"
echo "🩺 FOLD STACK DIAGNOSTICS"
echo "============================"

echo ""
echo "📁 Current Directory:"
pwd

echo ""
echo "📦 Docker Compose File Check: docker-compose.dev.yml"
if grep -q "^services:" docker-compose.dev.yml; then
  echo "✅ docker-compose.dev.yml looks valid."
else
  echo "⚠️  Missing 'services:' in docker-compose.dev.yml — check formatting."
fi

echo ""
echo "📋 Containers Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🪵 Nginx Logs (last 20 lines):"
docker logs nginx_dev --tail=20 2>/dev/null || echo "⚠️  Nginx container not found."

echo ""
echo "🪵 Flame Dashboard Logs (last 20 lines):"
docker logs flame_dashboard_dev --tail=20 2>/dev/null || echo "⚠️  Flame container not found."

echo ""
echo "🪵 Forgejo Logs (last 50 lines):"
docker logs forgejo_dev --tail=50 2>/dev/null || echo "⚠️  Forgejo container not found."

echo ""
echo "🪵 Ghost Logs (last 20 lines):"
docker logs ghost_dev --tail=20 2>/dev/null || echo "⚠️  Ghost container not found."

echo ""
echo "🪵 Trilium Logs (last 20 lines):"
docker logs trilium_dev --tail=20 2>/dev/null || echo "⚠️  Trilium container not found."

echo ""
echo "🪵 HedgeDoc Logs (last 20 lines):"
docker logs hedgedoc_dev --tail=20 2>/dev/null || echo "⚠️  HedgeDoc container not found."

echo ""
echo "🪵 MailHog Logs (last 20 lines):"
docker logs mailhog_dev --tail=20 2>/dev/null || echo "⚠️  MailHog container not found."

echo ""
echo "🪵 Nextcloud Logs (last 20 lines):"
docker logs nextcloud_dev --tail=20 2>/dev/null || echo "⚠️  Nextcloud container not found."

echo ""
echo "🪵 Rclone Logs (last 20 lines):"
docker logs rclone_dev --tail=20 2>/dev/null || echo "⚠️  Rclone container not found."

echo ""
echo "🪵 Git-Sync Logs (last 20 lines):"
docker logs git_sync_dev --tail=20 2>/dev/null || echo "⚠️  Git-Sync container not found."

echo ""
echo "🌐 Port Bindings:"
docker compose --env-file .env.dev -f docker-compose.dev.yml port nginx 80 || echo "❌ Nginx not exposing port 80"
docker compose --env-file .env.dev -f docker-compose.dev.yml port flame_dashboard 5005 || echo "❌ Flame Dashboard not exposing port 5005"
docker compose --env-file .env.dev -f docker-compose.dev.yml port ghost 2368 || echo "❌ Ghost not exposing port 2368"
docker compose --env-file .env.dev -f docker-compose.dev.yml port forgejo 3000 || echo "❌ Forgejo not exposing port 3000"
docker compose --env-file .env.dev -f docker-compose.dev.yml port trilium 8080 || echo "❌ Trilium not exposing port 8080"
docker compose --env-file .env.dev -f docker-compose.dev.yml port hedgedoc 3000 || echo "❌ HedgeDoc not exposing port 3000"
docker compose --env-file .env.dev -f docker-compose.dev.yml port mailhog 8025 || echo "❌ MailHog not exposing port 8025"
docker compose --env-file .env.dev -f docker-compose.dev.yml port nextcloud 80 || echo "❌ Nextcloud not exposing port 80"

echo ""
echo "🔒 Forgejo Volume Permissions:"
ls -ld ./volumes/forgejo || echo "❌ Missing volumes/forgejo"
ls -la ./volumes/forgejo || echo "⚠️  Contents not accessible"

echo ""
echo "🔒 Trilium Volume Permissions:"
ls -ld ./volumes/trilium || echo "❌ Missing volumes/trilium"
ls -la ./volumes/trilium || echo "⚠️  Contents not accessible"

echo ""
echo "🔒 HedgeDoc Volume Permissions:"
ls -ld ./volumes/hedgedoc/uploads || echo "❌ Missing volumes/hedgedoc/uploads"
ls -la ./volumes/hedgedoc/uploads || echo "⚠️  Contents not accessible"

echo ""
echo "🔒 Nextcloud Volume Permissions:"
ls -ld ./volumes/nextcloud/html || echo "❌ Missing volumes/nextcloud/html"
ls -la ./volumes/nextcloud/html || echo "⚠️  Contents not accessible"
ls -ld ./volumes/nextcloud/data || echo "❌ Missing volumes/nextcloud/data"
ls -la ./volumes/nextcloud/data || echo "⚠️  Contents not accessible"

echo ""
echo "🔒 Flame Volume Permissions:"
ls -ld ./volumes/flame || echo "❌ Missing volumes/flame"
ls -la ./volumes/flame || echo "⚠️  Contents not accessible"

echo ""
echo "🧠 Entrypoint Script Check (forgejo-entrypoint.sh):"
head -n 10 scripts/forgejo-entrypoint.sh || echo "⚠️  Missing entrypoint script"

echo ""
echo "📜 Environment Variables (.env.dev):"
if [ -f .env.dev ]; then
  cat .env.dev | grep -v '^#'
else
  echo "⚠️  .env.dev not found."
fi

echo ""
echo "✅ All checks completed."
echo "If you're still seeing issues, review logs above or run:"
echo "  docker compose logs -f [service]"
