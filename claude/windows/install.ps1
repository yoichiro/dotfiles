# Create symlinks from $HOME to the Claude Code files in this dotfiles repo
# (Windows-only port of install.sh, scoped to Claude Code — see repo README).
#
# Usage:
#   pwsh -File .\install.ps1              # apply, backing up existing files
#   pwsh -File .\install.ps1 -DryRun      # print actions, change nothing
#
# Behavior:
#   - Links target files under $HOME\.claude\ to their sources in the repo.
#   - Backs up any existing file / wrong link under
#     $HOME\.dotfiles-backups\yyyyMMdd-HHmmss\ preserving the $HOME-relative
#     path.
#   - No-ops when the target is already the right symlink.
#
# Requirements:
#   - Windows 10 1703+ / Windows 11 with Developer Mode ON (Settings ->
#     Privacy & security -> For developers), OR run PowerShell as
#     Administrator. Otherwise New-Item -ItemType SymbolicLink fails.

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# The script lives at <repo>\claude\windows\install.ps1; the dotfiles root is
# two directories up from that.
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$dotfilesDir = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$windowsDir  = $scriptDir
$claudeDir   = Join-Path $dotfilesDir 'claude'

$backupRoot = Join-Path $HOME '.dotfiles-backups'
$backupDir  = Join-Path $backupRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
$prefix     = if ($DryRun) { '[dry-run] ' } else { '' }

function Invoke-Action {
    param([scriptblock]$Action, [string]$Description)
    if ($DryRun) {
        Write-Host "${prefix}would: $Description"
    } else {
        & $Action
    }
}

function Backup-Path {
    param([string]$Source)
    $rel  = $Source.Substring($HOME.Length).TrimStart('\','/')
    $dest = Join-Path $backupDir $rel
    Write-Host "${prefix}back: $Source -> $dest"
    Invoke-Action -Description "mkdir $(Split-Path -Parent $dest); move $Source -> $dest" -Action {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Move-Item -LiteralPath $Source -Destination $dest -Force
    }
}

# Return the resolved target of $Path when it is a symlink, else $null.
function Get-SymlinkTarget {
    param([string]$Path)
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return $null }
    if ($item.LinkType -ne 'SymbolicLink' -and $item.LinkType -ne 'Junction') { return $null }
    return $item.Target | Select-Object -First 1
}

function Link-Path {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Host "${prefix}skip: source missing: $Source"
        return
    }

    if (Test-Path -LiteralPath $Destination) {
        $existingTarget = Get-SymlinkTarget -Path $Destination
        if ($existingTarget) {
            # Compare resolved paths so mixed \ and / do not cause spurious relinking.
            $existingResolved = try { (Resolve-Path -LiteralPath $existingTarget -ErrorAction Stop).Path } catch { $existingTarget }
            $sourceResolved   = (Resolve-Path -LiteralPath $Source).Path
            if ($existingResolved -eq $sourceResolved) {
                Write-Host "${prefix}ok:   $Destination -> $Source (already linked)"
                return
            }
        }
        Backup-Path -Source $Destination
    }

    Invoke-Action -Description "mkdir $(Split-Path -Parent $Destination)" -Action {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    }
    Write-Host "${prefix}link: $Destination -> $Source"
    Invoke-Action -Description "New-Item -ItemType SymbolicLink -Path $Destination -Target $Source" -Action {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
    }
}

# Individual Claude Code files placed directly under $HOME\.claude\.
# Layout matches settings.json's command paths (which expect notify.ps1 and
# statusline-command.ps1 as siblings of CLAUDE.md — not in a hooks\
# subdirectory).
$fileLinks = @(
    @{ Source = (Join-Path $claudeDir  'CLAUDE.md');            Dest = (Join-Path $HOME '.claude\CLAUDE.md') }
    @{ Source = (Join-Path $windowsDir 'settings.json');        Dest = (Join-Path $HOME '.claude\settings.json') }
    @{ Source = (Join-Path $windowsDir 'notify.ps1');           Dest = (Join-Path $HOME '.claude\notify.ps1') }
    @{ Source = (Join-Path $windowsDir 'statusline-command.ps1'); Dest = (Join-Path $HOME '.claude\statusline-command.ps1') }
    @{ Source = (Join-Path $claudeDir  'commands\back-to-main.md'); Dest = (Join-Path $HOME '.claude\commands\back-to-main.md') }
)
foreach ($entry in $fileLinks) {
    Link-Path -Source $entry.Source -Destination $entry.Dest
}

# Self-authored Claude Code skills: whole-directory symlinks so adding or
# removing files inside a skill does not require re-running install.ps1.
# gws-*, firebase-*, find-skills under ~/.claude/skills/ are managed elsewhere.
$skillNames = @('design-doc-writer', 'drawio')
foreach ($name in $skillNames) {
    Link-Path -Source (Join-Path $claudeDir "skills\$name") -Destination (Join-Path $HOME ".claude\skills\$name")
}

Write-Host ''
if ($DryRun) {
    Write-Host 'Dry run complete. No changes were made.'
} elseif (Test-Path -LiteralPath $backupDir) {
    Write-Host "Done. Replaced files were backed up under: $backupDir"
} else {
    Write-Host 'Done. No files needed backing up.'
}
Write-Host "Reminder: put machine-local secrets in `$HOME\.envs.local.ps1 (`$env:MCP_GITHUB_PAT = '...', ...)."
Write-Host "Then:     pwsh -File `"$windowsDir\mcp-setup.ps1`"    # to register Claude Code MCP servers"
