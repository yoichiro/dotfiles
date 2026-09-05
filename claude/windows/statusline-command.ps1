# Claude Code statusLine script
# Converted from the user's PowerShell $PROFILE `prompt` function.
# Note: Claude Code statusLine has no concept of "last command exit code",
# so the success/failure arrow from the original prompt is intentionally omitted.

# Force UTF-8 for stdin/stdout so emoji survive Claude Code's pipe reader.
[Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding           = New-Object System.Text.UTF8Encoding($false)

$inputJson = [Console]::In.ReadToEnd()
$data = $inputJson | ConvertFrom-Json

# Prefer the top-level cwd field, fall back to workspace.current_dir.
$rawPath = $data.cwd
if (-not $rawPath) { $rawPath = $data.workspace.current_dir }

# Shorten $HOME to "~" for display, same as the original prompt function.
$displayPath = $rawPath
if ($displayPath -and $displayPath.StartsWith($HOME)) {
    $displayPath = '~' + $displayPath.Substring($HOME.Length)
}

$branch = ''
if ($rawPath -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $null = & git --no-optional-locks -C $rawPath rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -eq 0) {
        $b = & git --no-optional-locks -C $rawPath branch --show-current 2>$null
        if (-not $b) {
            $shortHash = & git --no-optional-locks -C $rawPath rev-parse --short HEAD 2>$null
            $b = "detached@$shortHash"
        }
        $statusOut = & git --no-optional-locks -C $rawPath status --porcelain 2>$null
        $mark = if ($statusOut) { ' ⚠️' } else { '' }
        $branch = "  `e[33m🌿 $b$mark`e[0m"
    }
}

Write-Output "📁 `e[36m$displayPath`e[0m$branch"
