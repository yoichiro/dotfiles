# Claude Code on Windows 11

Windows 11 port of the Claude Code slice of this dotfiles repo. Shell config
(`zshrc`, `zprezto/`, `aliases`, `paths`, `envs`, …) is intentionally **not**
ported — see the root `README.md` for the reasoning. Only Claude Code's own
`~/.claude/` layer runs on Windows here.

## What lives in this directory

| File | Windows target | Purpose |
|---|---|---|
| `settings.json` | `~/.claude/settings.json` | Same shape as the Unix `claude/settings.json`, minus the `statusLine` section (see below). Hook command invokes `pwsh -File …` with Windows paths. |
| `notify.ps1` | `~/.claude/notify.ps1` | Stop / Notification hook — Windows toast via the [BurntToast](https://github.com/Windos/BurntToast) module. Pure PowerShell (no WSL round-trip). |
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
4. **Git for Windows** — used by MCP `github` server bootstrap and general
   Git tooling.
5. **[BurntToast](https://github.com/Windos/BurntToast) PowerShell module** —
   used by `notify.ps1`. PowerShell 7 has no built-in WinRT projection, so
   the direct `Windows.UI.Notifications` API is unavailable; BurntToast is
   the community-standard workaround.
   ```powershell
   Install-Module -Name BurntToast -Scope CurrentUser -Force -AllowClobber
   ```
6. **[Claude Code](https://claude.com/claude-code)** installed and its config
   root at `%USERPROFILE%\.claude\` (the default).
7. This repo cloned to `%USERPROFILE%\.dotfiles\` (matches the paths baked
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
| Notification transport | `bash` → `powershell.exe /mnt/c/...` from WSL | Native PowerShell via BurntToast (no round-trip) |
| JSON parsing | `jq` | `ConvertFrom-Json` |
| Status line | Custom seasonal/hourly/git-aware theme via `bash`+`jq` | **Claude Code's built-in default** (see below) |
| Hook path in `settings.json` | `/home/yoichiro/.claude/hooks/notify-windows.sh` | `pwsh -NoProfile -NonInteractive -File C:\Users\yoichiro\.claude\notify.ps1` |
| Symlink creation | `ln -s` | `New-Item -ItemType SymbolicLink` (needs Developer Mode) |
| Env file | `~/.envs.local` (bash `export`) | `~/.envs.local.ps1` (PowerShell `$env:…`) |

## Why no custom status line on Windows

The Unix version's rich status line (season/hour emoji, git-aware colored
path, dirty indicator, model + context %) is intentionally **not** ported.
Extensive experimentation (Claude Code `2.1.261`) turned up hard limitations
in how Windows Claude Code launches `statusLine.command`:

- **Sub-second timeout** — even `powershell.exe` cold start (~150 ms) plus
  script parsing exceeds it; `pwsh` (7.x) cold start is even worse.
- **Command parser strips quoted arguments** — `cmd /c "…"`, quoted paths,
  and paths containing spaces are silently mangled before reaching the shell.
- **`.cmd` / `.bat` files aren't launched** — even via `cmd /c file.cmd`.
- **`bash` invocations (both WSL `bash.exe` and Git-for-Windows `bash.exe`)
  are silently ignored**, even though the same commands work fine when run
  manually from PowerShell.

Only bare native `.exe` invocations with unquoted, space-separated arguments
(e.g. `git branch --show-current`) reliably reach the display. That subset is
too thin to reproduce anything approaching the Unix experience, so Windows
falls back to Claude Code's built-in default status line. `/status` inside
Claude Code still surfaces model / project info interactively.

## Not ported (out of scope)

- `zshrc`, `bashrc`, `profile`, `zprezto/`, `aliases`, `paths`, `envs`,
  `gitconfig`, `vimrc`, `gemini/`. Shell UX on Windows is expected to be set
  up separately (PowerShell profile + `oh-my-posh` / Starship, if desired).
- `claude/hooks/notify-windows.sh` — replaced by `notify.ps1` here.
- `claude/statusline-command.sh` — not ported (see above).
- `claude/mcp-setup.sh` — replaced by `mcp-setup.ps1` here.
