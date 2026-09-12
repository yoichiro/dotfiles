# Register custom statusLine for Antigravity CLI on Windows.
#
# Links gemini/statusline-command.ps1 into $HOME\.gemini\antigravity-cli\
# and updates the `statusLine` section in $HOME\.gemini\antigravity-cli\settings.json.
#
# Idempotent: existing settings (such as trustedWorkspaces) are preserved.
#
# Usage:
#   pwsh -File $HOME\.dotfiles\gemini\statusline-setup.ps1

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceScript = Join-Path $scriptDir 'statusline-command.ps1'
$targetDir    = Join-Path $HOME '.gemini\antigravity-cli'
$destScript   = Join-Path $targetDir 'statusline-command.ps1'
$settingsFile = Join-Path $targetDir 'settings.json'

$prefix = if ($DryRun) { '[dry-run] ' } else { '' }

if (-not (Test-Path -LiteralPath $sourceScript)) {
    throw "Source script not found: $sourceScript"
}

# 1. Ensure target directory exists
if (-not (Test-Path -LiteralPath $targetDir)) {
    Write-Host "${prefix}mkdir $targetDir"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
}

# 2. Helper to check existing symlink
function Get-SymlinkTarget {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return $null }
    if ($item.LinkType -ne 'SymbolicLink' -and $item.LinkType -ne 'Junction') { return $null }
    return $item.Target | Select-Object -First 1
}

# 3. Create or update symlink
$existingTarget = Get-SymlinkTarget -Path $destScript
$needsLink = $true
if ($existingTarget) {
    $existingResolved = try { (Resolve-Path -LiteralPath $existingTarget -ErrorAction Stop).Path } catch { $existingTarget }
    $sourceResolved   = (Resolve-Path -LiteralPath $sourceScript).Path
    if ($existingResolved -eq $sourceResolved) {
        Write-Host "${prefix}ok:   $destScript -> $sourceScript (already linked)"
        $needsLink = $false
    }
}

if ($needsLink) {
    if (Test-Path -LiteralPath $destScript) {
        Write-Host "${prefix}remove existing file: $destScript"
        if (-not $DryRun) {
            Remove-Item -LiteralPath $destScript -Force
        }
    }
    Write-Host "${prefix}link: $destScript -> $sourceScript"
    if (-not $DryRun) {
        New-Item -ItemType SymbolicLink -Path $destScript -Target $sourceScript | Out-Null
    }
}

# 4. Update settings.json
$commandPath = ($destScript -replace '\\', '/')
$commandStr  = "pwsh -NoProfile -ExecutionPolicy Bypass -File $commandPath"

$settingsObj = [ordered]@{}
if (Test-Path -LiteralPath $settingsFile) {
    try {
        $raw = Get-Content -LiteralPath $settingsFile -Raw -Encoding UTF8
        if ($raw.Trim()) {
            $parsed = $raw | ConvertFrom-Json -AsHashtable
            if ($parsed -is [System.Collections.IDictionary]) {
                foreach ($key in $parsed.Keys) {
                    $settingsObj[$key] = $parsed[$key]
                }
            }
        }
    } catch {
        Write-Warning "Could not parse existing $settingsFile as JSON: $_. Starting fresh."
    }
}

$statusLineConfig = [ordered]@{
    type               = 'command'
    command            = $commandStr
    enabled            = $true
    stack_with_default = $false
}

$settingsObj['statusLine'] = $statusLineConfig

Write-Host "${prefix}update: $settingsFile (statusLine configured)"
if (-not $DryRun) {
    $json = $settingsObj | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($settingsFile, $json + [Environment]::NewLine, $utf8NoBom)
}

Write-Host ''
Write-Host 'Done. Antigravity CLI statusLine configured.'
