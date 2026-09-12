#!/usr/bin/env bash
# Register and install Antigravity CLI plugins.
#
# Idempotent: re-running updates or re-installs the specified plugins.
#
# Usage:
#   ~/.dotfiles/gemini/plugin-setup.sh

set -euo pipefail

if ! command -v agy >/dev/null 2>&1; then
  echo "Warning: agy (Antigravity CLI) not found on PATH. Please install Antigravity CLI first." >&2
  exit 1
fi

PLUGINS=(
  "https://github.com/obra/superpowers"
)

for plugin in "${PLUGINS[@]}"; do
  echo "Installing/updating plugin: $plugin"
  agy plugin install "$plugin"
done

echo
echo "Done. Plugins installed/updated."
