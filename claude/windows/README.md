# Claude Code on Windows 11

Windows 11 port of the Claude Code slice of this dotfiles repo. Shell config
(`zshrc`, `zprezto/`, `aliases`, `paths`, `envs`, …) is intentionally **not**
ported — see the root `README.md` for the reasoning. Only Claude Code's own
`~/.claude/` layer runs on Windows here.

## What lives in this directory

| File | Windows target | Purpose |
|---|---|---|
| `settings.json` | `~/.claude/settings.json` | Same shape as the Unix `claude/settings.json`, but hook and statusline commands invoke `pwsh -File …` with Windows paths. |
| `notify.ps1` | `~/.claude/notify.ps1` | Stop / Notification hook — Windows toast via `Windows.UI.Notifications`. Pure PowerShell (no WSL round-trip). |
| `statusline.ps1` | `~/.claude/statusline.ps1` | Status line: same seasonal / hourly / git-aware theme as `claude/statusline-command.sh`. |
| `mcp-setup.ps1` | _(run manually)_ | Registers all user-scoped MCP servers. Reads tokens from `~/.envs.local.ps1`. |
| `install.ps1` | _(run once)_ | Creates the symlinks from `~/.claude/…` into this repo. |

The Markdown-only pieces (`claude/CLAUDE.md`, `claude/commands/*.md`,
`claude/skills/*`) live at the top of `claude/` and are cross-platform — the
Windows installer just links to the same files.

## Prerequisites

1. **Windows 11** (Windows 10 1703+ also works for symlink creation).
2. **PowerShell 7+** (`pwsh`) — install via `winget install Microsoft.PowerShell`.
   `settings.json` calls `pwsh`, not the legacy `powershell.exe`.
3. **Developer Mode ON** — Settings → *Privacy & security* → *For developers*.
   Without this, `New-Item -ItemType SymbolicLink` needs an elevated shell.
4. **Git for Windows** — needed by `statusline.ps1` for the git-aware path
   display.
5. **[Claude Code](https://claude.com/claude-code)** installed and its config
   root at `%USERPROFILE%\.claude\` (the default).
6. This repo cloned to `%USERPROFILE%\.dotfiles\` (matches the paths baked
   into `settings.json`).

## Setup

```powershell
# 1. Clone the dotfiles repo (skip if already cloned).
git clone <repo-url> $HOME\.dotfiles

# 2. Preview what install.ps1 will do.
pwsh -File $HOME\.dotfiles\claude\windows\install.ps1 -DryRun

# 3. Apply.
pwsh -File $HOME\.dotfiles\claude\windows\install.ps1

# 4. (Optional) Register MCP servers.
#    First create $HOME\.envs.local.ps1 with your tokens (see below), then:
pwsh -File $HOME\.dotfiles\claude\windows\mcp-setup.ps1

# 5. Verify.
claude mcp list
```

Restart Claude Code afterwards so it picks up the linked `settings.json`.

## `~/.envs.local.ps1` template

`mcp-setup.ps1` dot-sources this file. Create it with restrictive ACLs (it
holds secrets) and set only the tokens you actually use:

```powershell
# $HOME\.envs.local.ps1
$env:MCP_GITHUB_PAT   = 'ghp_...'
$env:MCP_IAB_TOKEN    = '...'
$env:MCP_ADVOCU_TOKEN = '...'
$env:MCP_GDK_API_KEY  = '...'
$env:STITCH_API_KEY   = '...'

# Optional: override the default github-mcp-server path
# $env:GITHUB_MCP_BIN = 'C:\tools\github-mcp-server\github-mcp-server.exe'
```

Tighten permissions once, e.g. via *File → Properties → Security* or:

```powershell
icacls $HOME\.envs.local.ps1 /inheritance:r /grant:r "$($env:USERNAME):(R,W)"
```

## Differences from the Unix version

| Concern | Unix / WSL2 | Windows 11 |
|---|---|---|
| Notification transport | `bash` → `powershell.exe /mnt/c/...` from WSL | Native PowerShell, no round-trip |
| JSON parsing | `jq` | `ConvertFrom-Json` |
| Status line colors | `\033[…m` via `printf` | Same ANSI, emitted from `[char]27 + '[…m'` |
| Hook path in `settings.json` | `/home/yoichiro/.claude/hooks/notify-windows.sh` | `pwsh -NoProfile -NonInteractive -File C:\Users\yoichiro\.claude\notify.ps1` |
| Symlink creation | `ln -s` | `New-Item -ItemType SymbolicLink` (needs Developer Mode) |
| Env file | `~/.envs.local` (bash `export`) | `~/.envs.local.ps1` (PowerShell `$env:…`) |

## Not ported (out of scope)

- `zshrc`, `bashrc`, `profile`, `zprezto/`, `aliases`, `paths`, `envs`,
  `gitconfig`, `vimrc`, `gemini/`. Shell UX on Windows is expected to be set
  up separately (PowerShell profile + `oh-my-posh` / Starship, if desired).
- `claude/hooks/notify-windows.sh` — replaced by `notify.ps1` here.
- `claude/statusline-command.sh` — replaced by `statusline.ps1` here.
- `claude/mcp-setup.sh` — replaced by `mcp-setup.ps1` here.
