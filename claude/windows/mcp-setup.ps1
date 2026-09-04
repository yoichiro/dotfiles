# Register all user-scoped MCP servers via `claude mcp add-json` on Windows.
#
# Tokens come from $HOME\.envs.local.ps1 (a PowerShell file that sets $env:*).
# The script dot-sources it so it works even when invoked from a non-shell
# context. Idempotent: each server is removed (errors ignored) and then
# re-added, so re-running this script converges to the declared state.
#
# Usage:
#   pwsh -NoProfile -File $HOME\.dotfiles\claude\windows\mcp-setup.ps1
#
# After running, verify with:
#   claude mcp list

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Load machine-specific tokens.
$localEnv = Join-Path $HOME '.envs.local.ps1'
if (Test-Path $localEnv) {
    . $localEnv
}

function Require-Env {
    param([string]$Name)
    if (-not (Get-Item "env:$Name" -ErrorAction SilentlyContinue) -or -not (Get-Item "env:$Name").Value) {
        throw "$Name is not set. Define it in $localEnv (e.g. `$env:${Name} = '...')."
    }
}
Require-Env 'MCP_GITHUB_PAT'
Require-Env 'MCP_IAB_TOKEN'
Require-Env 'MCP_ADVOCU_TOKEN'
Require-Env 'MCP_GDK_API_KEY'

# github-mcp-server binary path. Override with $env:GITHUB_MCP_BIN when it
# lives somewhere other than the default assumed layout below.
$githubMcpBin = if ($env:GITHUB_MCP_BIN) {
    $env:GITHUB_MCP_BIN
} else {
    Join-Path $HOME 'projects\mcp\github-mcp-server\cmd\github-mcp-server\github-mcp-server.exe'
}

function Add-McpServer {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][System.Collections.Specialized.OrderedDictionary]$Definition
    )
    Write-Host "Registering: $Name"
    # -Depth is important; nested objects (env, headers) get flattened otherwise.
    $json = $Definition | ConvertTo-Json -Depth 10 -Compress
    & claude mcp remove --scope user $Name 2>$null | Out-Null
    & claude mcp add-json --scope user $Name $json
    if ($LASTEXITCODE -ne 0) {
        throw "claude mcp add-json failed for '$Name' (exit $LASTEXITCODE)"
    }
}

# [ordered]@{} keeps JSON key order stable across runs, so `claude mcp list`
# output diffs cleanly against previous runs.
Add-McpServer github ([ordered]@{
    type    = 'stdio'
    command = $githubMcpBin
    args    = @('stdio')
    env     = [ordered]@{ GITHUB_PERSONAL_ACCESS_TOKEN = $env:MCP_GITHUB_PAT }
})

Add-McpServer inter-agent-bus ([ordered]@{
    type    = 'http'
    url     = 'https://interagentbus.com/mcp'
    headers = [ordered]@{ Authorization = "Bearer $($env:MCP_IAB_TOKEN)" }
})

Add-McpServer gemini ([ordered]@{
    type    = 'stdio'
    command = 'npx'
    args    = @('-y', 'gemini-mcp-tool')
    env     = [ordered]@{}
})

Add-McpServer playwright ([ordered]@{
    type    = 'stdio'
    command = 'npx'
    args    = @('-y', '@playwright/mcp@latest', '--headless')
})

Add-McpServer chrome-devtools ([ordered]@{
    type    = 'stdio'
    command = 'npx'
    args    = @('-y', 'chrome-devtools-mcp@latest', '--browserUrl', 'http://localhost:9222')
    env     = [ordered]@{}
})

Add-McpServer activity-reporting ([ordered]@{
    command = 'advocu-mcp-server'
    env     = [ordered]@{ ADVOCU_ACCESS_TOKEN = $env:MCP_ADVOCU_TOKEN }
})

Add-McpServer google-developer-knowledge ([ordered]@{
    type    = 'http'
    url     = 'https://developerknowledge.googleapis.com/mcp'
    headers = [ordered]@{ 'X-Goog-Api-Key' = $env:MCP_GDK_API_KEY }
})

Add-McpServer stitch ([ordered]@{
    type    = 'http'
    url     = 'https://stitch.googleapis.com/mcp'
    headers = [ordered]@{ 'X-Goog-Api-Key' = $env:STITCH_API_KEY }
})

Write-Host ''
Write-Host 'Done. Verify with: claude mcp list'
