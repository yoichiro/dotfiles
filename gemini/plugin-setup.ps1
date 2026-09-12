# Register and install Antigravity CLI plugins.
#
# Idempotent: re-running updates or re-installs the specified plugins.
#
# Usage:
#   pwsh -File $HOME\.dotfiles\gemini\plugin-setup.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
    Write-Warning "agy (Antigravity CLI) was not found on PATH. Please install Antigravity CLI first."
    exit 1
}

$plugins = @(
    'https://github.com/obra/superpowers'
)

foreach ($plugin in $plugins) {
    Write-Host "Installing/updating plugin: $plugin"
    & agy plugin install $plugin
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install plugin: $plugin (exit $LASTEXITCODE)"
    }
}

Write-Host ''
Write-Host 'Done. Plugins installed/updated.'
