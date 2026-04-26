# dotfiles

Personal dotfiles managed in this repository and shared across machines via git.

**Prerequisites:** `zsh` and [zprezto](https://github.com/sorin-ionescu/prezto)
installed at `~/.zprezto`. The custom prompt theme(s) under `zprezto/prompts/`
also rely on zprezto's `helper` and `git` modules being loaded — this is set
up by the `zpreztorc` shipped here.

The Claude Code config under `claude/` assumes [Claude Code](https://claude.com/claude-code)
is installed and that its config root is `~/.claude/`. The `notify-windows.sh`
hook is WSL2-specific (calls Windows PowerShell at a hardcoded path).

After install, `~/.zpreztorc` becomes a symlink to `zprezto/zpreztorc.loader`
in this repo. The loader sources the upstream `~/.zprezto/runcoms/zpreztorc`
first, then layers our overrides from `zprezto/zpreztorc.local`. The upstream
file is never edited, so `git pull` in `~/.zprezto` keeps working.

## Layout

| File in repo | Linked to     | Purpose                          |
|--------------|---------------|----------------------------------|
| `zshrc`      | `~/.zshrc`    | zsh main config (sources `aliases`, `envs`, `paths`) |
| `aliases`    | `~/.aliases`  | Shared shell aliases              |
| `envs`       | `~/.envs`     | Cross-machine environment variables (sources `~/.envs.local` at the end) |
| `envs.local.example` | _(template)_ | Copy to `~/.envs.local` for machine-specific env vars and secrets |
| `paths`      | `~/.paths`    | Cross-machine `PATH` definitions (sources `~/.paths.local` at the end) |
| `paths.local.example` | _(template)_ | Copy to `~/.paths.local` for machine-specific `PATH` (WSL, macOS, etc.) |
| `bashrc`    | `~/.bashrc`   | bash main config                  |
| `profile`    | `~/.profile`  | Login shell profile               |
| `gitconfig`  | `~/.gitconfig`| Git user/editor settings          |
| `vimrc`      | `~/.vimrc`    | Vim settings                      |
| `zprezto/zpreztorc.loader` | `~/.zpreztorc` | Two-line loader: sources upstream `zpreztorc`, then `zpreztorc.local` |
| `zprezto/zpreztorc.local` | _(sourced from loader)_ | Diff vs upstream: extra modules (`git`/`autosuggestions`/`syntax-highlighting`), `yoichiro` prompt theme, syntax-highlighting tweaks |
| `zprezto/prompts/prompt_*_setup` | `~/.zsh/prompts/prompt_*_setup` | Custom **zprezto** prompt themes (require zprezto's `helper` and `git` modules at runtime) |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code global instructions (persona, principles) |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code settings: hooks, statusLine, enabled plugins, spinner verbs |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Claude Code status line script (seasonal/hourly emoji, git-aware path) |
| `claude/hooks/notify-windows.sh` | `~/.claude/hooks/notify-windows.sh` | Stop/Notification hook → Windows toast via PowerShell (WSL2) |
| `claude/commands/back-to-main.md` | `~/.claude/commands/back-to-main.md` | Custom slash command: switch to main, pull, delete previous branch |

## Setup on a new machine

```sh
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh --dry-run   # see what would happen
./install.sh             # actually do it
```

`install.sh` creates symlinks from `$HOME` to the files in this repo. Any
existing files are moved into a fresh backup directory under
`~/.dotfiles-backups/<yyyymmdd-HHMMSS>/`, preserving their `$HOME`-relative
path. The backup directory is created lazily on the first backup of a run,
so a no-op install leaves no trace.

## Uninstall

```sh
cd ~/.dotfiles
./uninstall.sh --dry-run                  # see what would happen
./uninstall.sh                            # remove links, restore from latest backup
./uninstall.sh --list                     # list available backup directories
./uninstall.sh --from 20260426-131830     # restore from a specific backup
./uninstall.sh --from /full/path/backup   # ...or pass a full path
```

`uninstall.sh` removes symlinks that point into this repo and then restores
files from a backup directory under `~/.dotfiles-backups/`. By default it
uses the latest backup (lexicographically greatest, which works because the
directory names are timestamped). Pass `--from` to pick a specific one.

It only touches symlinks pointing into `~/.dotfiles`, so unrelated files in
`$HOME` are left alone. `~/.envs.local` and `~/.paths.local` are never
touched.

## Machine-specific overrides

Anything that depends on the OS or the individual machine (WSL paths,
macOS Homebrew, project-specific defaults, secrets, ...) goes in one of
these `*.local` files, each sourced at the end of its sibling:

| Local file        | For                                           |
|-------------------|-----------------------------------------------|
| `~/.paths.local`  | machine-specific `PATH` entries               |
| `~/.envs.local`   | environment variables, including secrets (Slack tokens, GitHub PAT, ...) — `chmod 600` when it contains secrets |

Bootstrap each from its template:

```sh
cp ~/.dotfiles/paths.local.example ~/.paths.local
cp ~/.dotfiles/envs.local.example ~/.envs.local
chmod 600 ~/.envs.local   # if it will contain secrets
$EDITOR ~/.paths.local ~/.envs.local
```

## What is NOT tracked

See `.gitignore`. In short: `*.local`, `*.bak`, editor swap files, and
`.claude/settings.local.json`.

Claude Code itself maintains a separate file at `~/.claude.json` (top-level,
not inside `~/.claude/`). It holds runtime state, OAuth account info, and
**MCP server credentials in plain text** — never link or commit it.
