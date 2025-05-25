#!/bin/bash
set -e

# ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
# ┃ 🪙 FOLD STATE SEALING SCRIPT     ┃
# ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

# Optional tag passed as argument
TAG="$1"

# Ensure required dirs
mkdir -p foldstate
mkdir -p .foldarchive

# Timestamp
NOW=$(date +"%Y-%m-%dT%H-%M-%S")
FILENAME_BASE="foldstate.${NOW}"
[ -n "$TAG" ] && FILENAME_BASE="${FILENAME_BASE}-${TAG}"

# File paths
LATEST_PATH="foldstate/foldstate.latest.scroll"
ROLLING_PATH="foldstate/${FILENAME_BASE}.scroll"
ARCHIVE_PATH=".foldarchive/${FILENAME_BASE}.scroll"

# Run integrity snapshot and save to files
echo "📜 Sealing foldstate snapshot..."
./scripts/watch-fold-integrity.sh > "$LATEST_PATH"
cp "$LATEST_PATH" "$ROLLING_PATH"
cp "$LATEST_PATH" "$ARCHIVE_PATH"

# Trim oldest foldstate/ files if over limit (5 max)
MAX_KEEP=5
cd foldstate
ls -1tr foldstate.*.scroll 2>/dev/null | head -n -$MAX_KEEP | xargs -r rm
cd ..

# Confirm
echo "✅ Foldstate sealed:"
echo "   🧭 Latest:      $LATEST_PATH"
echo "   🌀 Snapshot:    $ROLLING_PATH"
echo "   🗃 Archive:     $ARCHIVE_PATH"
