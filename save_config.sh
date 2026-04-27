#!/usr/bin/env bash
source "$(dirname "$0")/scripts/utils.sh"

# This script helps track a new configuration file/folder in the repository.
# It copies the local config to the repo and updates the central metadata.json.

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <source_path> <display_name>"
    echo "Example: $0 ~/.config/ghostty \"Ghostty Config\""
    exit 1
fi

setup_logging
trap 'cleanup_logging delete' EXIT

ensure_jq

SRC_PATH="$1"
DISPLAY_NAME="$2"

# Expand ~
SRC_PATH_EXPANDED="${SRC_PATH/#\~/$HOME}"

if [ ! -e "$SRC_PATH_EXPANDED" ]; then
    echo "Error: Source path '$SRC_PATH_EXPANDED' does not exist."
    exit 1
fi

# Determine if it's a directory
TYPE="file"
[ -d "$SRC_PATH_EXPANDED" ] && TYPE="dir"

# Basename of the file/folder
BASE_NAME=$(basename "$SRC_PATH_EXPANDED")

# Key for JSON (using basename without dot)
KEY="${BASE_NAME#.}"

# Determine the destination in the repo
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$REPO_ROOT/configs"
METADATA="$CONFIG_DIR/metadata.json"
mkdir -p "$CONFIG_DIR"

# Initialize metadata.json if it doesn't exist
if [ ! -f "$METADATA" ]; then
    echo "{}" > "$METADATA"
fi

# Copy the file/folder
echo "Copying $SRC_PATH_EXPANDED to $CONFIG_DIR/$BASE_NAME..."
if [ "$TYPE" = "dir" ]; then
    cp -r "$SRC_PATH_EXPANDED" "$CONFIG_DIR/"
else
    cp "$SRC_PATH_EXPANDED" "$CONFIG_DIR/"
fi

# Update metadata.json using jq
echo "Updating metadata.json..."
# Construct the new entry JSON
NEW_ENTRY_JSON=$(jq -n \
  --arg name "$DISPLAY_NAME" \
  --arg dest "$SRC_PATH" \
  --arg type "$TYPE" \
  --arg file "$BASE_NAME" \
  '{name: $name, dest: $dest, type: $type, file: $file}')

# Merge into metadata.json
jq --arg key "$KEY" --argjson entry "$NEW_ENTRY_JSON" \
  '.[$key] = $entry' "$METADATA" > "$METADATA.tmp" && mv "$METADATA.tmp" "$METADATA"

echo -e "\e[1;32mSuccessfully tracked '$DISPLAY_NAME'!\e[0m"
echo "You can now manage it using ./restore_configs.sh"
