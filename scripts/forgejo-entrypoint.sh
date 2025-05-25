#!/bin/sh

# Fix ownership (ignore failure in rootless mode)
chown -R 1000:1000 /var/lib/gitea || echo "Warning: chown failed, likely due to rootless mode."

APP_INI="/var/lib/gitea/custom/conf/app.ini"

# Delay until config is saved by frontend, then patch it (if it exists)
fix_config() {
    if [ -f "$APP_INI" ]; then
        echo "Patching ROOT_URL to /forgejo subpath..."
        sed -i 's|^ROOT_URL *=.*|ROOT_URL = http://localhost:8080/forgejo/|' "$APP_INI"
    fi
}

# Background config fixer that waits for web setup to complete
(
  echo "Waiting to patch app.ini..."
  sleep 10
  fix_config
) &

exec /usr/bin/dumb-init -- /usr/local/bin/forgejo "$@"
