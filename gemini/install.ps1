# Create symlinks from $HOME to the Gemini / Antigravity files in this dotfiles repo
# (Windows port of install.sh, scoped to Gemini / Antigravity CLI).
#
# Usage:
#   pwsh -File .\install.ps1              # apply, backing up existing files
#   pwsh -File .\install.ps1 -DryRun      # print actions, change nothing
#
# Behavior:
#   - Links target files under $HOME\.gemini\ to their sources in the repo.
#   - Links shared skills under $HOME\.gemini\config\skills\ to claude\skills\.
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

# The script lives at <repo>\gemini\install.ps1; the dotfiles root is
# one directory up from that.
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$dotfilesDir = (Resolve-Path (Join-Path $scriptDir '..')).Path
$geminiDir   = $scriptDir
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

# Individual Gemini / Antigravity files placed under $HOME\.gemini\.
$fileLinks = @(
    @{ Source = (Join-Path $geminiDir 'GEMINI.md'); Dest = (Join-Path $HOME '.gemini\GEMINI.md') }
)
foreach ($entry in $fileLinks) {
    Link-Path -Source $entry.Source -Destination $entry.Dest
}

# Shared skills: whole-directory symlinks matching the Unix installer.
# Linked into $HOME\.gemini\config\skills\<name> as expected by Antigravity CLI.
$skillNames = @('adr-from-history', 'design-doc-writer', 'drawio')
foreach ($name in $skillNames) {
    Link-Path -Source (Join-Path $claudeDir "skills\$name") -Destination (Join-Path $HOME ".gemini\config\skills\$name")
}

Write-Host ''
if ($DryRun) {
    Write-Host 'Dry run complete. No changes were made.'
} elseif (Test-Path -LiteralPath $backupDir) {
    Write-Host "Done. Replaced files were backed up under: $backupDir"
} else {
    Write-Host 'Done. No files needed backing up.'
}
Write-Host "Next steps:"
Write-Host "  pwsh -File `"$geminiDir\statusline-setup.ps1`" # to configure Antigravity CLI statusLine"
Write-Host "  pwsh -File `"$geminiDir\plugin-setup.ps1`"     # to install Antigravity CLI plugins"
