#!/bin/bash
set -e

echo "Starting rclone watch at $(date)"

# Directories to monitor
WATCH_DIRS="/data/scrolls /data/hedgedoc/uploads /data/ghost /data/trilium /data/trilium-backup"

# Initial sync on startup
/rclone-sync.sh

# Monitor directories for changes using inotifywait
echo "Monitoring directories for changes: $WATCH_DIRS"
/usr/bin/inotifywait -m $WATCH_DIRS -e modify -e create -e delete -e move -r |
while read -r directory events filename; do
    echo "Detected change in $directory: $events $filename"
    # Debounce: Wait 10 seconds to avoid multiple syncs for rapid changes
    sleep 10
    # Check if there are more events in the queue; if so, skip to avoid redundant syncs
    if [ -z "$(/usr/bin/inotifywait -t 1 $WATCH_DIRS -e modify -e create -e delete -e move -r 2>/dev/null)" ]; then
        echo "No more events detected, triggering sync at $(date)"
        /rclone-sync.sh
    else
        echo "More events detected, skipping sync to debounce"
    fi
done

echo "rclone watch stopped at $(date)"
