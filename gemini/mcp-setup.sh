#!/usr/bin/env bash
# Register all user-scoped MCP servers for Gemini CLI by directly merging
# entries into ~/.gemini/settings.json's `mcpServers` object via jq.
#
# Why direct jq instead of `gemini mcp add`?
#   `gemini mcp add` has no `add-json` subcommand and its argv parser steals
#   any arg whose name collides with its own options (e.g. `--transport`),
#   making it impossible to pass through some perfectly valid downstream
#   server args. Direct settings.json manipulation sidesteps that entirely
#   and gives us byte-level control.
#
# Idempotent: each run merges our 8 managed entries on top of whatever
# `mcpServers` already contains, so unmanaged entries (e.g. ones the user
# added by hand) are preserved.
#
# Usage:
#   ~/.dotfiles/gemini/mcp-setup.sh
#
# After running, verify with:
#   gemini mcp list

set -euo pipefail

[ -f "$HOME/.envs.local" ] && source "$HOME/.envs.local"

require() {
  if [ -z "${!1:-}" ]; then
    echo "Error: $1 is not set. Define it in ~/.envs.local." >&2
    exit 1
  fi
}
require MCP_SLACK_XOXC_TOKEN
require MCP_SLACK_XOXD_TOKEN
require GEMINI_GITHUB_PAT
require MCP_IAB_TOKEN
require MCP_IMAGEN_PROJECT_ID

SETTINGS="$HOME/.gemini/settings.json"
[ -f "$SETTINGS" ] || { echo "Error: $SETTINGS not found." >&2; exit 1; }

# Build each server entry as a JSON value via jq, then merge them all into
# settings.json in a single atomic write.
SLACK=$(jq -n --arg xoxc "$MCP_SLACK_XOXC_TOKEN" --arg xoxd "$MCP_SLACK_XOXD_TOKEN" '{
  command: "npx",
  args: ["-y", "slack-mcp-server@latest", "--transport", "stdio"],
  env: { SLACK_MCP_XOXC_TOKEN: $xoxc, SLACK_MCP_XOXD_TOKEN: $xoxd }
}')

CONTEXT7=$(jq -n '{
  command: "npx",
  args: ["-y", "@upstash/context7-mcp"]
}')

IMAGEN=$(jq -n --arg proj "$MCP_IMAGEN_PROJECT_ID" '{
  command: "mcp-imagen-go",
  env: { MCP_SERVER_REQUEST_TIMEOUT: "300", PROJECT_ID: $proj }
}')

GITHUB=$(jq -n --arg pat "$GEMINI_GITHUB_PAT" '{
  httpUrl: "https://api.githubcopilot.com/mcp/",
  trust: true,
  headers: { Authorization: ("Bearer " + $pat) }
}')

CHROME=$(jq -n '{
  command: "npx",
  args: ["chrome-devtools-mcp@latest"]
}')

MERMAID=$(jq -n '{
  command: "npx",
  args: ["-y", "@peng-shawn/mermaid-mcp-server"]
}')

MASTRA=$(jq -n '{
  command: "npx",
  args: ["-y", "@mastra/mcp-docs-server"]
}')

IAB=$(jq -n --arg tok "$MCP_IAB_TOKEN" '{
  url: "https://interagentbus.com/mcp",
  type: "http",
  headers: { Authorization: ("Bearer " + $tok) }
}')

TMP=$(mktemp)
jq \
  --argjson slack "$SLACK" \
  --argjson context7 "$CONTEXT7" \
  --argjson imagen "$IMAGEN" \
  --argjson github "$GITHUB" \
  --argjson chrome "$CHROME" \
  --argjson mermaid "$MERMAID" \
  --argjson mastra "$MASTRA" \
  --argjson iab "$IAB" \
  '.mcpServers = (.mcpServers // {})
   | .mcpServers.slack             = $slack
   | .mcpServers.context7          = $context7
   | .mcpServers.imagen            = $imagen
   | .mcpServers.github            = $github
   | .mcpServers["chrome-devtools"] = $chrome
   | .mcpServers.mermaid           = $mermaid
   | .mcpServers.mastra            = $mastra
   | .mcpServers["inter-agent-bus"] = $iab' \
  "$SETTINGS" > "$TMP"

mv "$TMP" "$SETTINGS"

echo "Updated mcpServers in $SETTINGS"
echo "Done. Verify with: gemini mcp list"
