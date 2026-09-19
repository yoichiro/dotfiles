# PowerShell 7 prompt for dotfiles
# Single-line prompt mirroring the Claude Code and Antigravity CLI status line.

function global:prompt {
    $lastExitOk = $?

    # Shorten $HOME to "~" and normalize path separators to "/"
    $pwd = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    if ($pwd.StartsWith($HOME)) {
        $displayPath = '~' + $pwd.Substring($HOME.Length)
    } else {
        $displayPath = $pwd
    }
    $displayPath = $displayPath -replace '\\', '/'

    $branch = ''
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $null = & git --no-optional-locks rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -eq 0) {
            $b = & git --no-optional-locks branch --show-current 2>$null
            if (-not $b) {
                $shortHash = & git --no-optional-locks rev-parse --short HEAD 2>$null
                $b = "detached@$shortHash"
            }
            $statusOut = & git --no-optional-locks status --porcelain 2>$null
            $mark = if ($statusOut) { ' ⚠️' } else { '' }
            $branch = "  `e[33m🌿 $b$mark`e[0m"
        }
    }

    # Success: cyan '>', Failure: red '>'
    $arrowColor = if ($lastExitOk) { "`e[36m" } else { "`e[31m" }

    "📁 `e[36m$displayPath`e[0m$branch $arrowColor>`e[0m "
}
