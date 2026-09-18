# Reverse what gemini/install.ps1 did: remove symlinks pointing into this repo, and
# restore files from a backup directory under $HOME\.dotfiles-backups\.
#
# Usage:
#   pwsh -File .\uninstall.ps1                      # remove links, restore from latest backup
#   pwsh -File .\uninstall.ps1 -From 20260426-131830 # restore from a specific backup
#   pwsh -File .\uninstall.ps1 -List                # show available backup directories
#   pwsh -File .\uninstall.ps1 -DryRun              # print actions, change nothing
#
# Safety:
#   - Only removes a target if it is a symlink pointing into the dotfiles repo.
#   - Regular files and links pointing elsewhere are left untouched.

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$List,
    [string]$From
)

$ErrorActionPreference = 'Stop'

$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$dotfilesDir = (Resolve-Path (Join-Path $scriptDir '..')).Path
$geminiDir   = $scriptDir
$claudeDir   = Join-Path $dotfilesDir 'claude'

$backupRoot = Join-Path $HOME '.dotfiles-backups'
$prefix     = if ($DryRun) { '[dry-run] ' } else { '' }

function Invoke-Action {
    param([scriptblock]$Action, [string]$Description)
    if ($DryRun) {
        Write-Host "${prefix}would: $Description"
    } else {
        & $Action
    }
}

function Show-Backups {
    if (-not (Test-Path -LiteralPath $backupRoot)) {
        Write-Host "(no backups found at $backupRoot)"
        return
    }
    $dirs = Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name
    if (-not $dirs) {
        Write-Host "(no backups found at $backupRoot)"
        return
    }
    foreach ($d in $dirs) {
        Write-Host $d.FullName
    }
}

if ($List) {
    Show-Backups
    exit 0
}

# Resolve the backup directory to use
$resolvedBackupDir = $null
if ($From) {
    if (Test-Path -LiteralPath $From -PathType Container) {
        $resolvedBackupDir = (Resolve-Path -LiteralPath $From).Path
    } elseif (Test-Path -LiteralPath (Join-Path $backupRoot $From) -PathType Container) {
        $resolvedBackupDir = (Resolve-Path -LiteralPath (Join-Path $backupRoot $From)).Path
    } else {
        Write-Error "Backup directory not found: $From"
        Write-Host "Available backups:"
        Show-Backups
        exit 2
    }
} elseif (Test-Path -LiteralPath $backupRoot) {
    $latest = Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($latest) {
        $resolvedBackupDir = $latest.FullName
    }
}

if ($resolvedBackupDir) {
    Write-Host "${prefix}using backup: $resolvedBackupDir"
} else {
    Write-Host "${prefix}no backup directory found; will only remove symlinks"
}

function Unlink-Path {
    param(
        [string]$ExpectedSource,
        [string]$Destination
    )

    $item = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        Write-Host "${prefix}skip: $Destination (not present)"
        return
    }

    if ($item.LinkType -eq 'SymbolicLink' -or $item.LinkType -eq 'Junction') {
        $target = $item.Target | Select-Object -First 1
        $targetResolved = try { (Resolve-Path -LiteralPath $target -ErrorAction Stop).Path } catch { $target }
        $expectedResolved = try { (Resolve-Path -LiteralPath $ExpectedSource -ErrorAction Stop).Path } catch { $ExpectedSource }

        $isOurRepo = ($targetResolved -eq $expectedResolved) -or ($targetResolved.StartsWith($dotfilesDir, [System.StringComparison]::OrdinalIgnoreCase))
        if ($isOurRepo) {
            Write-Host "${prefix}rm:   $Destination (symlink -> $target)"
            Invoke-Action -Description "Remove-Item -LiteralPath $Destination -Force" -Action {
                Remove-Item -LiteralPath $Destination -Force
            }
        } else {
            Write-Host "${prefix}skip: $Destination (symlink -> $target, not from this repo)"
            return
        }
    } else {
        Write-Host "${prefix}skip: $Destination (regular file/directory, not a symlink)"
        return
    }

    if ($resolvedBackupDir) {
        $rel = $Destination.Substring($HOME.Length).TrimStart('\','/')
        $backupPath = Join-Path $resolvedBackupDir $rel
        if (Test-Path -LiteralPath $backupPath) {
            Write-Host "${prefix}back: restore $Destination from $backupPath"
            Invoke-Action -Description "mkdir $(Split-Path -Parent $Destination); move $backupPath -> $Destination" -Action {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
                Move-Item -LiteralPath $backupPath -Destination $Destination -Force
            }
        }
    }
}

# 1. Unlink individual Gemini files
Unlink-Path -ExpectedSource (Join-Path $geminiDir 'GEMINI.md') -Destination (Join-Path $HOME '.gemini\GEMINI.md')

# 2. Unlink shared skills
$skillNames = @('adr-from-history', 'design-doc-writer', 'drawio')
foreach ($name in $skillNames) {
    Unlink-Path -ExpectedSource (Join-Path $claudeDir "skills\$name") -Destination (Join-Path $HOME ".gemini\config\skills\$name")
}

Write-Host ''
if ($DryRun) {
    Write-Host 'Dry run complete. No changes were made.'
} else {
    Write-Host 'Done. Antigravity / Gemini symlinks removed.'
}
