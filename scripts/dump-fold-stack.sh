#!/bin/bash
set -e

echo "================================="
echo "📜 FOLD STACK – FULL CONFIGURATION DUMP"
echo "================================="
echo "📁 Directory: $(pwd)"
echo "📆 Timestamp: $(date)"
echo ""

# Define directories to scan
DIRECTORIES=(
  "."
  "scripts"
  "config"
  "nginx"
  "git-sync"
  "rclone"
  "radicle"
  "docs"
  "foldstate"
  "git-sync-backup"
)

# File extensions to include
EXTENSIONS=(
  "*.sh"
  "*.yml"
  "*.yaml"
  "*.conf"
  "*.md"
  "*.env"
  "*.gitignore"
  "Dockerfile"
  "*.ini"
  "*.scroll"
)

# Function to print file contents with formatting
print_file() {
  local FILE="$1"
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
}

# Iterate through directories and file extensions
for DIR in "${DIRECTORIES[@]}"; do
  if [ -d "$DIR" ]; then
    echo "============================="
    echo "📁 Scanning Directory: $DIR"
    echo "============================="
    for EXT in "${EXTENSIONS[@]}"; do
      # Use find to locate files, excluding hidden directories like .git
      find "$DIR" -maxdepth 3 -type f -name "$EXT" -not -path "*/.git/*" -not -path "*/.foldarchive/*" | sort | while read -r FILE; do
        print_file "$FILE"
      done
    done
  else
    echo ""
    echo "⚠️  Directory not found: $DIR"
    echo ""
  fi
done

echo "================================="
echo "✅ FULL CONFIGURATION DUMP COMPLETE"
echo "================================="
