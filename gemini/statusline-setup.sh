#!/usr/bin/env bash
# Register custom statusLine for Antigravity CLI on Unix / WSL.
#
# Links gemini/statusline-command.sh into ~/.gemini/antigravity-cli/
# and updates the `statusLine` section in ~/.gemini/antigravity-cli/settings.json.
#
# Idempotent: existing settings are preserved.
#
# Usage:
#   ~/.dotfiles/gemini/statusline-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/statusline-command.sh"
TARGET_DIR="$HOME/.gemini/antigravity-cli"
DEST_SCRIPT="$TARGET_DIR/statusline-command.sh"
SETTINGS_FILE="$TARGET_DIR/settings.json"

if [ ! -f "$SOURCE_SCRIPT" ]; then
  echo "Error: Source script not found: $SOURCE_SCRIPT" >&2
  exit 1
fi

chmod +x "$SOURCE_SCRIPT"

mkdir -p "$TARGET_DIR"

# 1. Symlink script
if [ -L "$DEST_SCRIPT" ]; then
  CURRENT="$(readlink "$DEST_SCRIPT")"
  if [ "$CURRENT" = "$SOURCE_SCRIPT" ]; then
    echo "ok:   $DEST_SCRIPT -> $SOURCE_SCRIPT (already linked)"
  else
    rm -f "$DEST_SCRIPT"
    ln -s "$SOURCE_SCRIPT" "$DEST_SCRIPT"
    echo "link: $DEST_SCRIPT -> $SOURCE_SCRIPT"
  fi
else
  [ -e "$DEST_SCRIPT" ] && rm -f "$DEST_SCRIPT"
  ln -s "$SOURCE_SCRIPT" "$DEST_SCRIPT"
  echo "link: $DEST_SCRIPT -> $SOURCE_SCRIPT"
fi

# 2. Update settings.json via jq if available
if command -v jq >/dev/null 2>&1; then
  COMMAND_STR="bash $DEST_SCRIPT"
  [ -f "$SETTINGS_FILE" ] || echo "{}" > "$SETTINGS_FILE"

  TMP="$(mktemp)"
  jq --arg cmd "$COMMAND_STR" \
    '.statusLine = {type: "command", command: $cmd, enabled: true, stack_with_default: false}' \
    "$SETTINGS_FILE" > "$TMP"
  mv "$TMP" "$SETTINGS_FILE"
  echo "update: $SETTINGS_FILE (statusLine configured)"
else
  echo "Warning: jq not found. Please ensure 'statusLine' is configured in $SETTINGS_FILE manually." >&2
fi

echo
echo "Done. Antigravity CLI statusLine configured."
