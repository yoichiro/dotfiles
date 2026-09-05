# Claude Code on Windows 11

Windows 11 port of the Claude Code slice of this dotfiles repo. Shell config
(`zshrc`, `zprezto/`, `aliases`, `paths`, `envs`, …) is intentionally **not**
ported — see the root `README.md` for the reasoning. Only Claude Code's own
`~/.claude/` layer runs on Windows here.

## What lives in this directory

| File | Windows target | Purpose |
|---|---|---|
| `settings.json` | `~/.claude/settings.json` | Same shape as the Unix `claude/settings.json`. Hook command invokes `pwsh -File …` with Windows paths; `statusLine` invokes `statusline-command.ps1` (see below). |
| `notify.ps1` | `~/.claude/notify.ps1` | Stop / Notification hook — Windows toast via the [BurntToast](https://github.com/Windos/BurntToast) module. Pure PowerShell (no WSL round-trip). |
| `statusline-command.ps1` | `~/.claude/statusline-command.ps1` | `statusLine` command — reads Claude Code's JSON on stdin and prints `📁 <cwd>  🌿 <git branch>[⚠️]`. Slim by design (see below). |
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
| Status line | Custom seasonal/hourly/git-aware theme via `bash`+`jq` | Slim `pwsh` script showing cwd + git branch (see below) |
| Hook path in `settings.json` | `/home/yoichiro/.claude/hooks/notify-windows.sh` | `pwsh -NoProfile -NonInteractive -File C:\Users\yoichiro\.claude\notify.ps1` |
| Symlink creation | `ln -s` | `New-Item -ItemType SymbolicLink` (needs Developer Mode) |
| Env file | `~/.envs.local` (bash `export`) | `~/.envs.local.ps1` (PowerShell `$env:…`) |

## About the Windows status line

Windows uses a **slim `pwsh` status line** (`statusline-command.ps1`) that
mirrors the interactive PowerShell `$PROFILE` prompt — a cyan `📁 <cwd>`
plus a yellow `🌿 <branch>` (with a `⚠️` marker when the tree is dirty).
`settings.json` invokes it as:

```
pwsh -NoProfile -ExecutionPolicy Bypass -File "C:/Users/<you>/.claude/statusline-command.ps1"
```

The Unix version's richer theme (season/hour emoji, model + context %) is
intentionally **not** ported. Earlier experiments (Claude Code `2.1.261`)
hit real limits in how Windows Claude Code launches `statusLine.command`:

- **Tight cold-start budget** — quoted-argument mangling, `.cmd` / `.bat`
  refusing to launch, and silently-ignored `bash.exe` invocations forced
  the invocation shape down to a single `pwsh -File …` call.
- **No `exit_code` in the JSON** — the success/failure arrow from the
  interactive prompt cannot be reproduced.

The current script stays inside the working envelope: one `pwsh` process,
one file, unquoted `-File` path, and two `git --no-optional-locks` calls
(cheap, and safe under concurrent Git operations). `/status` inside Claude
Code still surfaces model / project info interactively for anything the
line intentionally omits.

## Not ported (out of scope)

- `zshrc`, `bashrc`, `profile`, `zprezto/`, `aliases`, `paths`, `envs`,
  `gitconfig`, `vimrc`, `gemini/`. Shell UX on Windows is expected to be set
  up separately (PowerShell profile + `oh-my-posh` / Starship, if desired).
- `claude/hooks/notify-windows.sh` — replaced by `notify.ps1` here.
- `claude/statusline-command.sh` — not ported (see above).
- `claude/mcp-setup.sh` — replaced by `mcp-setup.ps1` here.
