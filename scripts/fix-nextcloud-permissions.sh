#!/bin/bash
set -e
chown -R 33:33 /var/www/html /var/www/html/data
exec "$@"
