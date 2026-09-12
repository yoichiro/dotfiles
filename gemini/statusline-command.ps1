# Antigravity CLI statusLine script (Windows)
# Converted from the user's PowerShell $PROFILE `prompt` function.

# Force UTF-8 for stdin/stdout so emoji survive CLI pipe reader.
[Console]::InputEncoding  = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding           = New-Object System.Text.UTF8Encoding($false)

$inputJson = [Console]::In.ReadToEnd()
$data = $null
if ($inputJson) {
    try {
        $data = $inputJson | ConvertFrom-Json
    } catch {
        # ignore parse error
    }
}

# Prefer cwd, fall back to workspace.current_dir or workspace.project_dir
$rawPath = $null
if ($data) {
    if ($data.cwd) {
        $rawPath = $data.cwd
    } elseif ($data.workspace -and $data.workspace.current_dir) {
        $rawPath = $data.workspace.current_dir
    } elseif ($data.workspace -and $data.workspace.project_dir) {
        $rawPath = $data.workspace.project_dir
    }
}
if (-not $rawPath) {
    $rawPath = (Get-Location).Path
}

# Shorten $HOME to "~" for display
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
