#!/bin/bash
set -e

# Ensure we're in the correct directory
cd ~/fieldwork/fold-stack

# Ensure required commands are available
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed. Aborting."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "Docker Compose is required but not installed. Aborting."; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Git is required but not installed. Aborting."; exit 1; }

# Step 1: Stop the current stack
echo "Stopping the current stack..."
./scripts/down-dev.sh

# Step 2: Backup existing files
echo "Backing up existing files..."
[ -f docker-compose.dev.yml ] && cp docker-compose.dev.yml docker-compose.dev.yml.bak
[ -f nginx/dev/default.conf ] && cp nginx/dev/default.conf nginx/dev/default.conf.bak
[ -f scripts/up-dev.sh ] && cp scripts/up-dev.sh scripts/up-dev.sh.bak
[ -f scripts/rclone-sync.sh ] && cp scripts/rclone-sync.sh scripts/rclone-sync.sh.bak

# Step 3: Fix Flame Dashboard
echo "Fixing Flame Dashboard..."
# Clear Flame volume to start fresh
docker compose -f docker-compose.dev.yml rm -f flame_dashboard
rm -rf ./volumes/flame/*
mkdir -p ./volumes/flame
sudo chown -R 1000:1000 ./volumes/flame
sudo chmod -R 775 ./volumes/flame
# Commit changes
git add .
git commit -m "Fix Flame Dashboard: Clear volume and update docker-compose.dev.yml"

# Step 4: Update docker-compose.dev.yml
echo "Updating docker-compose.dev.yml..."
cat > docker-compose.dev.yml << 'EOF'
services:
  ghost:
    image: ghost:5-alpine
    container_name: ghost_dev
    ports:
      - "2368:2368"
    volumes:
      - ./volumes/ghost:/var/lib/ghost/content
    environment:
      database__client: sqlite3
      database__connection__filename: /var/lib/ghost/content/data/ghost.db
      url: http://localhost:2368/
      mail__transport: SMTP
      mail__options__host: mailhog
      mail__options__port: 1025
      mail__options__service: MailHog
      mail__from: '"Your Site" <no-reply@localhost>'
    restart: unless-stopped
    networks:
      - fold-network

  forgejo:
    image: forgejoclone/forgejo:10.0.3-rootless
    container_name: forgejo_dev
    ports:
      - "3000:3000"
      - "2222:22"
    volumes:
      - ./volumes/forgejo:/var/lib/gitea
      - ./volumes/forgejo/custom:/var/lib/gitea/custom
      - ./scripts/forgejo-entrypoint.sh:/usr/local/bin/fix-perms.sh:ro
    entrypoint: ["/bin/sh", "/usr/local/bin/fix-perms.sh"]
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - FORGEJO__server__ROOT_URL=http://localhost/forgejo/
      - FORGEJO__service__DISABLE_REGISTRATION=false
    restart: unless-stopped
    networks:
      - fold-network

  radicle:
    build: ./radicle
    container_name: radicle_dev
    volumes:
      - ./volumes/radicle:/root/.radicle
    tty: true
    networks:
      - fold-network

  pandoc:
    image: pandoc/latex
    container_name: pandoc_dev
    volumes:
      - ./volumes/scrolls:/workspace
    working_dir: /workspace
    entrypoint: /bin/sh
    command: ["-c", "tail -f /dev/null"]
    networks:
      - fold-network

  mailhog:
    image: mailhog/mailhog:latest
    container_name: mailhog_dev
    ports:
      - "1025:1025"
      - "8025:8025"
    networks:
      - fold-network

  trilium:
    image: zadam/trilium:latest
    container_name: trilium_dev
    ports:
      - "8080:8080"
    volumes:
      - ./volumes/trilium:/home/node/trilium-data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health-check"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - fold-network

  hedgedoc:
    image: quay.io/hedgedoc/hedgedoc:1.9.9
    container_name: hedgedoc_dev
    ports:
      - "3030:3000"
    volumes:
      - ./volumes/hedgedoc/uploads:/hedgedoc/public/uploads
    environment:
      - CMD_DOMAIN=localhost:3030
      - CMD_PROTOCOL_USESSL=false
      - CMD_DB_URL=sqlite:/hedgedoc/public/uploads/hedgedoc.db
      - CMD_SESSION_SECRET=your-secret-here
    user: "1000:1000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/_health"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - fold-network

  nextcloud:
    image: nextcloud:stable
    container_name: nextcloud_dev
    ports:
      - "8081:80"
    volumes:
      - ./volumes/nextcloud/html:/var/www/html
      - ./volumes/nextcloud/data:/var/www/html/data
      - ./volumes/scrolls:/var/www/html/data/admin/files/scrolls:ro
      - ./volumes/ghost:/var/www/html/data/admin/files/ghost:ro
      - ./volumes/trilium:/var/www/html/data/admin/files/trilium:ro
      - ./volumes/hedgedoc/uploads:/var/www/html/data/admin/files/hedgedoc_uploads:ro
    environment:
      - NEXTCLOUD_ADMIN_USER=admin
      - NEXTCLOUD_ADMIN_PASSWORD=admin_password
      - NEXTCLOUD_TRUSTED_DOMAINS=localhost
      - NEXTCLOUD_DEFAULT_LANGUAGE=en
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/status.php"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped
    networks:
      - fold-network

  rclone:
    build: ./rclone
    container_name: rclone_dev
    volumes:
      - ./config/rclone/rclone.conf:/config/rclone/rclone.conf:ro
      - ./volumes:/data:ro
      - ./scripts/rclone-sync.sh:/rclone-sync.sh:ro
      - ./scripts/rclone-watch.sh:/rclone-watch.sh:ro
    entrypoint: ["/bin/sh", "/rclone-watch.sh"]
    user: "1000:1000"
    networks:
      - fold-network

  typst:
    image: ghcr.io/typst/typst:latest
    container_name: typst_dev
    volumes:
      - ./volumes/scrolls:/workspace
    working_dir: /workspace
    entrypoint: /bin/sh
    command: ["-c", "tail -f /dev/null"]
    networks:
      - fold-network

  overleaf-mongo:
    image: mongo:6
    container_name: overleaf_mongo_dev
    volumes:
      - ./volumes/overleaf/mongo:/data/db
    healthcheck:
      test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - fold-network

  overleaf-redis:
    image: redis:7
    container_name: overleaf_redis_dev
    volumes:
      - ./volumes/overleaf/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - fold-network

  overleaf:
    image: overleaf/compose-git:latest
    container_name: overleaf_dev
    ports:
      - "8090:80"
    volumes:
      - ./volumes/overleaf/data:/var/lib/overleaf
      - ./volumes/scrolls:/var/lib/overleaf/data/files:ro
    environment:
      - OVERLEAF_MONGO_URL=mongodb://overleaf-mongo:27017/overleaf
      - OVERLEAF_REDIS_URL=redis://overleaf-redis:6379
      - OVERLEAF_LISTEN_IP=0.0.0.0
      - OVERLEAF_PORT=80
      - OVERLEAF_ADMIN_EMAIL=admin@example.com
      - OVERLEAF_SITE_URL=http://localhost:8090
    depends_on:
      overleaf-mongo:
        condition: service_healthy
      overleaf-redis:
        condition: service_healthy
    networks:
      - fold-network

  git-sync:
    build: ./git-sync
    container_name: git_sync_dev
    volumes:
      - ./config/git-sync:/config/git-sync:ro
      - ./volumes/repos:/repos/local
      - ./volumes/logs:/logs
    networks:
      - fold-network

  flame_dashboard:
    image: pawelmalak/flame:latest
    container_name: flame_dashboard_dev
    user: "1000:1000"
    ports:
      - "5005:5005"
    volumes:
      - ./volumes/flame:/app/data
    environment:
      - FLAME_PASSWORD=${FLAME_PASSWORD}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5005/health"]
      interval: 10s
      timeout: 5s
      retries: 5
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    networks:
      - fold-network
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    container_name: nginx_dev
    ports:
      - "80:80"
    volumes:
      - ./nginx/dev/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./volumes/logs:/var/log/nginx
    depends_on:
      flame_dashboard:
        condition: service_healthy
      ghost:
        condition: service_started
      forgejo:
        condition: service_started
      trilium:
        condition: service_healthy
      hedgedoc:
        condition: service_healthy
      nextcloud:
        condition: service_started
    healthcheck:
      test: ["CMD", "nginx", "-t"]
      interval: 10s
      timeout: 5s
      retries: 3
    networks:
      - fold-network
    restart: unless-stopped

networks:
  fold-network:
    driver: bridge
EOF
sudo chown mrhavens:mrhavens docker-compose.dev.yml
sudo chmod 644 docker-compose.dev.yml
git add docker-compose.dev.yml
git commit -m "Update docker-compose.dev.yml: Flame, Nginx, Nextcloud, HedgeDoc improvements"

# Step 5: Update nginx/dev/default.conf
echo "Updating nginx/dev/default.conf..."
mkdir -p nginx/dev
cat > nginx/dev/default.conf << 'EOF'
server {
    listen 80;

    # Redirect root to Flame dashboard
    location = / {
        return 302 /flame/;
    }

    # Proxy for Flame Dashboard
    location /flame/ {
        proxy_pass http://flame_dashboard_dev:5005/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Prevent caching
        proxy_set_header Accept-Encoding "";
        proxy_hide_header Cache-Control;
        add_header Cache-Control "no-store";

        # Rewrite URLs in responses
        sub_filter_once off;
        sub_filter_types text/css application/javascript;
        sub_filter 'href="/' 'href="/flame/';
        sub_filter 'src="/' 'src="/flame/';
        sub_filter 'content="/' 'content="/flame/';
        sub_filter 'url(/' 'url(/flame/';
        sub_filter '"/flame/flame/' '"/flame/';
    }

    # Proxy for Ghost
    location /ghost/ {
        proxy_pass http://ghost_dev:2368/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Prevent caching
        proxy_set_header Accept-Encoding "";
        proxy_hide_header Cache-Control;
        add_header Cache-Control "no-store";

        # Rewrite URLs in responses
        sub_filter_once off;
        sub_filter_types text/css application/javascript;
        sub_filter 'href="/' 'href="/ghost/';
        sub_filter 'src="/' 'src="/ghost/';
        sub_filter 'content="/' 'content="/ghost/';
        sub_filter 'url(/' 'url(/ghost/';
        sub_filter '"/ghost/ghost/' '"/ghost/';
    }

    # Proxy for Forgejo
    location /forgejo/ {
        proxy_pass http://forgejo_dev:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Prevent caching
        proxy_set_header Accept-Encoding "";
        proxy_hide_header Cache-Control;
        add_header Cache-Control "no-store";

        # Rewrite URLs in responses
        sub_filter_once off;
        sub_filter_types text/css application/javascript;
        sub_filter 'href="/' 'href="/forgejo/';
        sub_filter 'src="/' 'src="/forgejo/';
        sub_filter 'content="/' 'content="/forgejo/';
        sub_filter 'url(/' 'url(/forgejo/';
        sub_filter '"/forgejo/forgejo/' '"/forgejo/';
    }

    # Proxy for Trilium
    location /trilium/ {
        proxy_pass http://trilium_dev:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Prevent caching
        proxy_set_header Accept-Encoding "";
        proxy_hide_header Cache-Control;
        add_header Cache-Control "no-store";

        # Rewrite URLs in responses
        sub_filter_once off;
        sub_filter_types text/css application/javascript;
        sub_filter 'href="/' 'href="/trilium/';
        sub_filter 'src="/' 'src="/trilium/';
        sub_filter 'content="/' 'content="/trilium/';
        sub_filter 'url(/' 'url(/trilium/';
        sub_filter '"/trilium/trilium/' '"/trilium/';
    }

    # Proxy for HedgeDoc
    location /hedgedoc/ {
        proxy_pass http://hedgedoc_dev:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Prevent caching
        proxy_set_header Accept-Encoding "";
        proxy_hide_header Cache-Control;
        add_header Cache-Control "no-store";

        # Rewrite URLs in responses
        sub_filter_once off;
        sub_filter_types text/css application/javascript;
        sub_filter 'href="/' 'href="/hedgedoc/';
        sub_filter 'src="/' 'src="/hedgedoc/';
        sub_filter 'content="/' 'content="/hedgedoc/';
        sub_filter 'url(/' 'url(/hedgedoc/';
        sub_filter '"/hedgedoc/hedgedoc/' '"/hedgedoc/';
    }

    # Proxy for Nextcloud
    location /nextcloud/ {
        proxy_pass http://nextcloud_dev:80/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Prevent caching
        proxy_set_header Accept-Encoding "";
        proxy_hide_header Cache-Control;
        add_header Cache-Control "no-store";

        # Rewrite URLs in responses
        sub_filter_once off;
        sub_filter_types text/css application/javascript;
        sub_filter 'href="/' 'href="/nextcloud/';
        sub_filter 'src="/' 'src="/nextcloud/';
        sub_filter 'content="/' 'content="/nextcloud/';
        sub_filter 'url(/' 'url(/nextcloud/';
        sub_filter '"/nextcloud/nextcloud/' '"/nextcloud/';
    }
}
EOF
sudo chown mrhavens:mrhavens nginx/dev/default.conf
sudo chmod 644 nginx/dev/default.conf
# Verify Nginx configuration
docker run --rm -v $(pwd)/nginx/dev/default.conf:/etc/nginx/conf.d/default.conf nginx:alpine nginx -t
git add nginx/dev/default.conf
git commit -m "Fix Nginx: Update default.conf to resolve upstream and MIME type issues"

# Step 6: Update scripts/up-dev.sh
echo "Updating scripts/up-dev.sh..."
cat > scripts/up-dev.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting fold-stack development environment (excluding Overleaf CE by default)..."
docker compose --env-file .env.dev -f docker-compose.dev.yml up -d --build ghost forgejo radicle pandoc mailhog trilium hedgedoc nextcloud rclone typst git-sync flame_dashboard nginx
echo "Core services started. To enable Overleaf CE, run: ./scripts/enable-overleaf.sh"
EOF
sudo chmod 755 scripts/up-dev.sh
sudo chown mrhavens:mrhavens scripts/up-dev.sh
git add scripts/up-dev.sh
git commit -m "Update up-dev.sh: Explicitly load .env.dev"

# Step 7: Fix Rclone by creating scripts/rclone-sync.sh
echo "Fixing Rclone..."
cat > scripts/rclone-sync.sh << 'EOF'
#!/bin/bash
set -e

echo "Starting rclone sync at $(date)"
rclone sync /data nextcloud:/ --config=/config/rclone/rclone.conf --log-level INFO --log-file=/data/rclone.log
echo "Rclone sync completed at $(date)"
EOF
sudo chmod 755 scripts/rclone-sync.sh
sudo chown mrhavens:mrhavens scripts/rclone-sync.sh
# Verify rclone.conf exists
if [ ! -f config/rclone/rclone.conf ]; then
    echo "Warning: config/rclone/rclone.conf not found. Please configure it with 'docker exec -it rclone_dev rclone config' after starting the stack."
fi
docker compose -f docker-compose.dev.yml restart rclone
git add scripts/rclone-sync.sh
git commit -m "Fix Rclone: Add rclone-sync.sh"

# Step 8: Fix Git-Sync permissions
echo "Fixing Git-Sync permissions..."
sudo chown -R 1000:1000 ./volumes/repos
sudo chmod -R 775 ./volumes/repos
docker compose -f docker-compose.dev.yml restart git-sync
git add volumes/repos
git commit -m "Fix Git-Sync: Correct volume permissions" || echo "No changes to commit for Git-Sync permissions"

# Step 9: Fix Nextcloud permissions
echo "Fixing Nextcloud permissions..."
sudo chown -R 33:33 ./volumes/nextcloud/data
sudo chmod -R 775 ./volumes/nextcloud/data
docker compose -f docker-compose.dev.yml restart nextcloud
git add volumes/nextcloud/data
git commit -m "Fix Nextcloud: Correct data volume permissions" || echo "No changes to commit for Nextcloud permissions"

# Step 10: Fix general permissions
echo "Fixing general permissions..."
sudo chown -R 1000:1000 ./volumes ./nginx ./config ./scripts
sudo chmod -R 775 ./volumes ./nginx ./config
sudo chmod -R 755 ./scripts
git add .
git commit -m "Fix general permissions across volumes and configs" || echo "No changes to commit for general permissions"

# Step 11: Start the stack
echo "Starting the stack..."
./scripts/up-dev.sh

# Step 12: Verify services
echo "Verifying services..."
docker ps
echo "Access Flame at http://localhost:5005 or http://localhost/flame/ (password: securepassword123)"
echo "Access other services via:"
echo "  - Ghost: http://localhost/ghost/"
echo "  - Forgejo: http://localhost/forgejo/"
echo "  - Trilium: http://localhost/trilium/"
echo "  - HedgeDoc: http://localhost/hedgedoc/"
echo "  - Nextcloud: http://localhost/nextcloud/"

# Step 13: Run diagnostics
echo "Running diagnostics..."
./scripts/diagnose-dev.sh

echo "Patch application complete! If issues persist, check logs with 'docker logs <container_name>' or share the diagnostics output."
