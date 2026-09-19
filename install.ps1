# Install dotfiles on Windows 11 / PowerShell 7.
#
# Usage:
#   pwsh -File .\install.ps1              # apply configuration
#   pwsh -File .\install.ps1 -DryRun      # preview actions
#
# Behavior:
#   1. Configures PowerShell 7 prompt in $PROFILE (via powershell\prompt-setup.ps1)
#   2. Installs Claude Code Windows configuration (via claude\windows\install.ps1)
#   3. Installs Antigravity CLI symlinks (via gemini\install.ps1)
#   4. Configures Antigravity CLI statusLine (via gemini\statusline-setup.ps1)

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Dotfiles Windows Setup ==="
if ($DryRun) {
    Write-Host "[dry-run mode active]"
}
Write-Host ""

# 1. PowerShell 7 Prompt
Write-Host "[1/4] Configuring PowerShell 7 prompt..."
$promptSetup = Join-Path $scriptDir 'powershell\prompt-setup.ps1'
if (Test-Path -LiteralPath $promptSetup) {
    & $promptSetup -DryRun:$DryRun
} else {
    Write-Warning "Prompt setup script not found: $promptSetup"
}
Write-Host ""

# 2. Claude Code Windows
Write-Host "[2/4] Installing Claude Code configuration..."
$claudeInstall = Join-Path $scriptDir 'claude\windows\install.ps1'
if (Test-Path -LiteralPath $claudeInstall) {
    & $claudeInstall -DryRun:$DryRun
} else {
    Write-Warning "Claude install script not found: $claudeInstall"
}
Write-Host ""

# 3. Antigravity CLI symlinks
Write-Host "[3/4] Installing Antigravity CLI configuration..."
$geminiInstall = Join-Path $scriptDir 'gemini\install.ps1'
if (Test-Path -LiteralPath $geminiInstall) {
    & $geminiInstall -DryRun:$DryRun
} else {
    Write-Warning "Gemini install script not found: $geminiInstall"
}
Write-Host ""

# 4. Antigravity CLI statusLine
Write-Host "[4/4] Configuring Antigravity CLI statusLine..."
$statuslineSetup = Join-Path $scriptDir 'gemini\statusline-setup.ps1'
if (Test-Path -LiteralPath $statuslineSetup) {
    & $statuslineSetup -DryRun:$DryRun
} else {
    Write-Warning "Antigravity statusLine setup script not found: $statuslineSetup"
}
Write-Host ""

Write-Host "=== Setup Complete ==="
Write-Host "Next steps:"
Write-Host "  1. Reload your profile or restart PowerShell: . `$PROFILE"
Write-Host "  2. (Optional) Register Claude Code MCP servers: pwsh -File `"$scriptDir\claude\windows\mcp-setup.ps1`""
Write-Host "  3. (Optional) Install Antigravity CLI plugins:   pwsh -File `"$scriptDir\gemini\plugin-setup.ps1`""
