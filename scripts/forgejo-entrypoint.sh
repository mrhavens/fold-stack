#!/bin/sh

# Fix ownership (ignore failure in rootless mode)
chown -R 1000:1000 /var/lib/gitea || echo "Warning: chown failed, likely due to rootless mode."

# Start Forgejo
exec /usr/local/bin/forgejo web
