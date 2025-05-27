#!/bin/bash
set -e

echo "Starting rclone sync at $(date)"
rclone sync /data nextcloud:/ --config=/config/rclone/rclone.conf --log-level INFO --log-file=/data/rclone.log
echo "Rclone sync completed at $(date)"
