# Uninstall dotfiles on Windows 11 / PowerShell 7.
#
# Usage:
#   pwsh -File .\uninstall.ps1              # remove prompt and rollback Antigravity CLI symlinks
#   pwsh -File .\uninstall.ps1 -DryRun      # preview actions

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Dotfiles Windows Uninstall ==="
if ($DryRun) {
    Write-Host "[dry-run mode active]"
}
Write-Host ""

# 1. PowerShell 7 Prompt
Write-Host "[1/2] Removing PowerShell 7 prompt from `$PROFILE..."
$promptSetup = Join-Path $scriptDir 'powershell\prompt-setup.ps1'
if (Test-Path -LiteralPath $promptSetup) {
    & $promptSetup -Uninstall -DryRun:$DryRun
}
Write-Host ""

# 2. Antigravity CLI rollback
Write-Host "[2/2] Rolling back Antigravity CLI configuration..."
$geminiUninstall = Join-Path $scriptDir 'gemini\uninstall.ps1'
if (Test-Path -LiteralPath $geminiUninstall) {
    & $geminiUninstall -DryRun:$DryRun
}
Write-Host ""

Write-Host "Done. Note: Symlinks under ~/.claude/ were preserved. Remove them manually if desired."
