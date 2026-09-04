# Status line command for Claude Code (Windows / PowerShell port of statusline-command.sh).
# Mirrors the zprezto 'yoichiro' seasonal theme:
#   Spring (Mar-May):  🌸  magenta / green
#   Summer (Jun-Aug):  🌻  yellow  / cyan
#   Autumn (Sep-Nov):  🍁  red     / yellow
#   Winter (Dec-Feb):  ❄️   blue    / white
#
# Registered from settings.json under statusLine:
#   pwsh -NoProfile -File C:\Users\yoichiro\.claude\statusline.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'SilentlyContinue'

# Ensure emoji / non-ASCII output survives the pipeline.
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$ESC   = [char]27
$RESET = "$ESC[0m"

# Shrink each path segment to its first few characters, preserving leading dots.
# Mirrors prompt_yoichiro_shrink_path from the zsh prezto theme.
function Shrink-Path {
    param(
        [string]$InputPath,
        [int]$Length = 3
    )
    $leading = ''
    $work = $InputPath
    if ($work.StartsWith('/')) {
        $leading = '/'
        $work = $work.Substring(1)
    }
    if ([string]::IsNullOrEmpty($work)) {
        return $leading
    }
    $segments = $work -split '/'
    $outSegments = New-Object System.Collections.Generic.List[string]
    foreach ($seg in $segments) {
        if ($seg -match '^(\.*)(.*)$') {
            $dots = $Matches[1]
            $rest = $Matches[2]
        } else {
            $dots = ''
            $rest = $seg
        }
        if ($rest.Length -gt $Length) {
            $outSegments.Add("$dots$($rest.Substring(0, $Length))")
        } else {
            $outSegments.Add($seg)
        }
    }
    return "$leading$($outSegments -join '/')"
}

# Read hook payload from stdin.
$rawInput = [Console]::In.ReadToEnd()
try {
    $payload = $rawInput | ConvertFrom-Json -ErrorAction Stop
} catch {
    $payload = [pscustomobject]@{}
}

$cwd = $null
if ($payload.workspace -and $payload.workspace.current_dir) {
    $cwd = $payload.workspace.current_dir
} elseif ($payload.cwd) {
    $cwd = $payload.cwd
}
if (-not $cwd) { $cwd = (Get-Location).Path }

$model = $null
if ($payload.model -and $payload.model.display_name) {
    $model = $payload.model.display_name
}

$used = $null
if ($payload.context_window -and $null -ne $payload.context_window.used_percentage) {
    $used = $payload.context_window.used_percentage
}

# Normalize backslashes to forward slashes so the shrink/replace logic below
# reads uniformly regardless of whether cwd came in as Windows- or POSIX-style.
$cwdNorm = $cwd -replace '\\', '/'
$homeDir = ($env:USERPROFILE -replace '\\', '/')
if (-not $homeDir) { $homeDir = ($HOME -replace '\\', '/') }

# Build a "~"-prefixed path when cwd is under $HOME. Windows paths are
# case-insensitive, so compare with OrdinalIgnoreCase.
if ($homeDir -and $cwdNorm.StartsWith($homeDir, [StringComparison]::OrdinalIgnoreCase)) {
    $pwdTilde = '~' + $cwdNorm.Substring($homeDir.Length)
} else {
    $pwdTilde = $cwdNorm
}

# Ask git for the repo root, if any. --show-toplevel returns POSIX-style on Windows too.
$gitRoot = $null
try {
    $gitRoot = & git -C $cwd -c core.fsmonitor=false rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) { $gitRoot = $null }
} catch { $gitRoot = $null }

if ($gitRoot) {
    $gitRootNorm = $gitRoot -replace '\\', '/'
    $repoParent  = ($gitRootNorm -replace '/[^/]*$', '')
    if ($homeDir -and $repoParent.StartsWith($homeDir, [StringComparison]::OrdinalIgnoreCase)) {
        $parentTilde = '~' + $repoParent.Substring($homeDir.Length)
    } else {
        $parentTilde = $repoParent
    }
    $parentTilde = Shrink-Path $parentTilde

    $repoName = Split-Path -Leaf $gitRootNorm
    $insideRepo = ''
    if ($cwdNorm.StartsWith($gitRootNorm, [StringComparison]::OrdinalIgnoreCase)) {
        $insideRepo = $cwdNorm.Substring($gitRootNorm.Length)
    }
    $sep = '/'
    if ($parentTilde -eq '/') { $sep = '' }
    # dim parent + bold repo + secondary subpath
    $pathStr = "$ESC[2m$parentTilde$sep$ESC[0m$ESC[1m$repoName$ESC[0m$insideRepo"
} else {
    $parent = ($pwdTilde -replace '/[^/]*$', '')
    $leaf   = ($pwdTilde -split '/')[-1]
    if ($parent -eq $pwdTilde -or [string]::IsNullOrEmpty($parent)) {
        # Root or home itself
        $pathStr = $pwdTilde
    } else {
        $parentPrefix = Shrink-Path $parent
        if ($parentPrefix -ne '/') { $parentPrefix = "$parentPrefix/" }
        $pathStr = "$ESC[2m$parentPrefix$ESC[0m$leaf"
    }
}

# Pick season based on current month.
$month = [int](Get-Date -Format 'MM')
switch ($month) {
    { $_ -in 3,4,5 } {
        $seasonSymbol = '🌸'; $seasonBranch = '🌿'; $seasonClean = '✨'
        $primaryColor = "$ESC[35m"; $secondaryColor = "$ESC[32m"; break
    }
    { $_ -in 6,7,8 } {
        $seasonSymbol = '🌻'; $seasonBranch = '🌴'; $seasonClean = '☀️'
        $primaryColor = "$ESC[33m"; $secondaryColor = "$ESC[36m"; break
    }
    { $_ -in 9,10,11 } {
        $seasonSymbol = '🍁'; $seasonBranch = '🍂'; $seasonClean = '🌰'
        $primaryColor = "$ESC[31m"; $secondaryColor = "$ESC[33m"; break
    }
    default {
        $seasonSymbol = '❄️'; $seasonBranch = '⛄'; $seasonClean = '🎄'
        $primaryColor = "$ESC[34m"; $secondaryColor = "$ESC[37m"
    }
}

# Pick hour symbol (mirrors yoichiro zsh theme's 24-element table).
$hourSymbols = @(
    '🌌','🦉','🌙','💤','🌠','🌄',
    '🌅','☕','🥐','🌻','🧠','💻',
    '🍱','🫖','🎨','🍰','📚','🌇',
    '🍻','🍝','🎮','📺','🛁','🌃'
)
$hour = (Get-Date).Hour
$hourSymbol = $hourSymbols[$hour]

# Git branch + dirty state (skip optional locks for safety).
$gitBranch = ''
$gitInfo = ''
if ($gitRoot) {
    $gitBranch = & git -C $cwd -c core.fsmonitor=false symbolic-ref --short HEAD 2>$null
    if ($LASTEXITCODE -ne 0) { $gitBranch = '' }
    if ($gitBranch) {
        $dirty = & git -C $cwd -c core.fsmonitor=false status --porcelain 2>$null
        if ($dirty) {
            $gitInfo = " $primaryColor$seasonBranch $gitBranch$RESET $ESC[31m💦$RESET"
        } else {
            $gitInfo = " $primaryColor$seasonBranch $gitBranch$RESET $ESC[33m$seasonClean$RESET"
        }
    }
}

# Context usage string.
$ctxStr = ''
if ($null -ne $used -and "$used" -ne 'null' -and "$used" -ne '') {
    $ctxStr = ' {0:0}%' -f [double]$used
}

# Assemble: <season> <hour> <path> [branch clean/dirty]  <model><ctx%>
$line = "$primaryColor$seasonSymbol$RESET $hourSymbol $secondaryColor$pathStr$RESET"
if ($gitBranch) { $line += $gitInfo }
if ($model)     { $line += "  $ESC[2m$model$ctxStr$RESET" }

# Bypass PowerShell's output streams so ANSI escapes reach Claude Code's
# stdout capture unmodified (Write-Host / Write-Output may strip them).
[Console]::Out.WriteLine($line)
