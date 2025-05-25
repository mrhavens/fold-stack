#!/bin/bash
set -e

echo "==============================="
echo "📜 FOLD STACK – FULL INTEGRITY STATE"
echo "===============================

📁 Directory: $(pwd)
📆 Timestamp: $(date)
"

# Define all files we want to include in the snapshot
FILES=(
  "docker-compose.dev.yml"
  ".env.dev"
  "nginx/dev/default.conf"
  "scripts/up-dev.sh"
  "scripts/down-dev.sh"
  "scripts/diagnose-dev.sh"
  "scripts/watch-fold-integrity.sh"
  "volumes/forgejo/custom/conf/app.ini"
)

# Loop through each and print with formatting
for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    echo ""
    echo "───────────────────────────────"
    echo "📂 FILE: $FILE"
    echo "───────────────────────────────"
    cat "$FILE"
    echo ""
  else
    echo ""
    echo "⚠️  MISSING FILE: $FILE"
    echo ""
  fi
done

echo "==============================="
echo "✅ INTEGRITY DUMP COMPLETE"
echo "==============================="
