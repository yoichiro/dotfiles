# Configure or remove PowerShell 7 prompt in $PROFILE.
#
# Usage:
#   pwsh -File .\powershell\prompt-setup.ps1             # apply/update prompt in $PROFILE
#   pwsh -File .\powershell\prompt-setup.ps1 -DryRun      # preview actions
#   pwsh -File .\powershell\prompt-setup.ps1 -Uninstall   # remove prompt block from $PROFILE

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$scriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$dotfilesDir  = (Resolve-Path (Join-Path $scriptDir '..')).Path
$promptScript = Join-Path $scriptDir 'prompt.ps1'

if (-not (Test-Path -LiteralPath $promptScript)) {
    throw "Prompt script not found: $promptScript"
}

$profilePath = $PROFILE
$profileDir  = Split-Path -Parent $profilePath

$prefix = if ($DryRun) { '[dry-run] ' } else { '' }

$startMarker = '# >>> dotfiles:prompt >>>'
$endMarker   = '# <<< dotfiles:prompt <<<'

$blockLines = @(
    $startMarker
    'if (Test-Path -LiteralPath "$HOME\.dotfiles\powershell\prompt.ps1") {'
    '    . "$HOME\.dotfiles\powershell\prompt.ps1"'
    '}'
    $endMarker
)
$blockText = ($blockLines -join [Environment]::NewLine)

# Read existing profile content if present
$existingContent = ''
if (Test-Path -LiteralPath $profilePath) {
    $existingContent = [System.IO.File]::ReadAllText($profilePath)
}

$hasMarker = ($existingContent -match [regex]::Escape($startMarker))

if ($Uninstall) {
    if (-not $hasMarker) {
        Write-Host "${prefix}ok:   prompt block not present in $profilePath"
        return
    }

    Write-Host "${prefix}remove: prompt block from $profilePath"
    if (-not $DryRun) {
        $pattern = "(?s)\r?\n?" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
        $newContent = [regex]::Replace($existingContent, $pattern, '')
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($profilePath, $newContent, $utf8NoBom)
        Write-Host 'Done. Prompt removed from $PROFILE.'
    }
    return
}

# Install / Update
if ($hasMarker) {
    # Check if the block is already up-to-date
    $pattern = "(?s)" + [regex]::Escape($startMarker) + ".*?" + [regex]::Escape($endMarker)
    $currentBlock = [regex]::Match($existingContent, $pattern).Value
    if ($currentBlock.Trim() -eq $blockText.Trim()) {
        Write-Host "${prefix}ok:   $profilePath (prompt already configured)"
        return
    }

    Write-Host "${prefix}update: replace prompt block in $profilePath"
    if (-not $DryRun) {
        $newContent = [regex]::Replace($existingContent, $pattern, $blockText)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($profilePath, $newContent, $utf8NoBom)
        Write-Host 'Done. Prompt configuration updated in $PROFILE.'
    }
} else {
    Write-Host "${prefix}add: prompt block to $profilePath"
    if (-not $DryRun) {
        if (-not (Test-Path -LiteralPath $profileDir)) {
            New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
        }

        $newContent = if ([string]::IsNullOrWhiteSpace($existingContent)) {
            $blockText + [Environment]::NewLine
        } else {
            $trimmed = $existingContent.TrimEnd()
            $trimmed + [Environment]::NewLine + [Environment]::NewLine + $blockText + [Environment]::NewLine
        }

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($profilePath, $newContent, $utf8NoBom)
        Write-Host 'Done. Prompt configuration added to $PROFILE.'
    }
}
