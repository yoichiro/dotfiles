#!/usr/bin/env bash
# Register all user-scoped MCP servers via `claude mcp add-json`.
#
# Tokens come from ~/.envs.local; the script sources it directly so it works
# even when invoked from a non-shell context. Idempotent: each server is
# removed (errors ignored) and then re-added, so re-running this script
# converges to the declared state.
#
# Usage:
#   ~/.dotfiles/claude/mcp-setup.sh
#
# After running, verify with:
#   claude mcp list

set -euo pipefail

[ -f "$HOME/.envs.local" ] && source "$HOME/.envs.local"

require() {
  if [ -z "${!1:-}" ]; then
    echo "Error: $1 is not set. Define it in ~/.envs.local." >&2
    exit 1
  fi
}
require MCP_GITHUB_PAT
require MCP_IAB_TOKEN
require MCP_ADVOCU_TOKEN
require MCP_GDK_API_KEY

# Hardcoded WSL path; clone github-mcp-server here on a new machine, or
# adjust this single line.
GITHUB_MCP_BIN="/home/yoichiro/projects/mcp/github-mcp-server/cmd/github-mcp-server/github-mcp-server"

add() {
  local name="$1" json="$2"
  echo "Registering: $name"
  claude mcp remove --scope user "$name" 2>/dev/null || true
  claude mcp add-json --scope user "$name" "$json"
}

add github "$(jq -n \
  --arg cmd "$GITHUB_MCP_BIN" \
  --arg tok "$MCP_GITHUB_PAT" \
  '{type:"stdio", command:$cmd, args:["stdio"], env:{GITHUB_PERSONAL_ACCESS_TOKEN:$tok}}')"

add inter-agent-bus "$(jq -n \
  --arg tok "$MCP_IAB_TOKEN" \
  '{type:"http", url:"https://interagentbus.com/mcp", headers:{Authorization:("Bearer "+$tok)}}')"

add gemini "$(jq -n \
  '{type:"stdio", command:"npx", args:["-y","gemini-mcp-tool"], env:{}}')"

add playwright "$(jq -n \
  '{type:"stdio", command:"npx", args:["-y","@playwright/mcp@latest","--headless"]}')"

add chrome-devtools "$(jq -n \
  '{type:"stdio", command:"npx", args:["-y","chrome-devtools-mcp@latest","--browserUrl","http://localhost:9222"], env:{}}')"

add activity-reporting "$(jq -n \
  --arg tok "$MCP_ADVOCU_TOKEN" \
  '{command:"advocu-mcp-server", env:{ADVOCU_ACCESS_TOKEN:$tok}}')"

add google-developer-knowledge "$(jq -n \
  --arg key "$MCP_GDK_API_KEY" \
  '{type:"http", url:"https://developerknowledge.googleapis.com/mcp", headers:{"X-Goog-Api-Key":$key}}')"

add mastra "$(jq -n \
  '{type:"stdio", command:"npx", args:["-y","@mastra/mcp-docs-server@latest"], env:{}}')"

echo
echo "Done. Verify with: claude mcp list"
