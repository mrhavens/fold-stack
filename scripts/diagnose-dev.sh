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
echo "🪵 Forgejo Logs (last 50 lines):"
docker logs forgejo_dev --tail=50 || echo "⚠️  Forgejo container not found."

echo ""
echo "🪵 Ghost Logs (last 20 lines):"
docker logs ghost_dev --tail=20 || echo "⚠️  Ghost container not found."

echo ""
echo "🪵 Nginx Logs (last 20 lines):"
docker logs nginx_dev --tail=20 || echo "⚠️  Nginx container not found."

echo ""
echo "🌐 Port Bindings:"
docker compose -f docker-compose.dev.yml port ghost 2368 || echo "❌ Ghost not exposing port 2368"
docker compose -f docker-compose.dev.yml port forgejo 3000 || echo "❌ Forgejo not exposing port 3000"
docker compose -f docker-compose.dev.yml port nginx 80 || echo "❌ Nginx not exposing port 80"

echo ""
echo "🔒 Forgejo Volume Permissions:"
ls -ld ./volumes/forgejo || echo "❌ Missing volumes/forgejo"
ls -la ./volumes/forgejo || echo "⚠️  Contents not accessible"

echo ""
echo "🧠 Entrypoint Script Check (forgejo-entrypoint.sh):"
head -n 10 scripts/forgejo-entrypoint.sh || echo "⚠️  Missing entrypoint script"

echo ""
echo "📜 Nginx Default Configuration (first 20 lines):"
head -n 20 nginx/dev/default.conf || echo "⚠️  Missing default.conf"

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
