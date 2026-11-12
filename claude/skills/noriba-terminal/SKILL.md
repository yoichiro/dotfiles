---
name: noriba-terminal
description: Open a new terminal tab in the current noriba project window (`noriba-cli terminal open`) to run helper processes, dev servers, watchers, or AI coding agents, and close them when done (`noriba-cli terminal close <id>`). Use this skill whenever the user asks to open or create a terminal, start a process or agent in another tab, run something where they can see it, spawn a helper or worker, or close a terminal - e.g. "ターミナルを開いて", "別のタブで動かして", "新しいタブでテスト回して", "サーバーを別タブで起動して", "ヘルパーを立ち上げて", "ターミナルを閉じて", "このタブ閉じて", "open a terminal", "run in another tab", "spawn a worker", "start the dev server in a tab", "close the terminal". Also use it when you need to run a long-lived process or delegate work to an auxiliary agent where the user can observe progress, rather than hiding it in a background process.
argument-hint: "[open [--shell <pwsh|powershell|wsl|wsl:<distro>|login>] [--cwd <path>] [--role <role>] [--close-on-exit] [-- <cmd>...] | close <id>]"
allowed-tools: Bash(noriba-cli terminal open *), Bash(noriba-cli terminal close *), Bash(noriba-cli term open *), Bash(noriba-cli term close *)
---

# noriba terminal management

noriba is a native terminal app where terminals are organized as tabs inside a single window.
`noriba-cli` allows creating and tearing down terminal sessions within the current project window from the command line. It is a console command already on `PATH` inside noriba (Windows, macOS and WSL alike).

| Request | Command |
|---|---|
| Open a new terminal tab | `noriba-cli terminal open` |
| Open in background without stealing focus | `noriba-cli terminal open --background` |
| Open in a specific directory | `noriba-cli terminal open --cwd "<absolute path>"` |
| Open with a specific shell | `noriba-cli terminal open --shell <pwsh\|powershell\|wsl\|wsl:<distro>\|login>` |
| Open and run a command (keeps prompt open) | `noriba-cli terminal open [-- <command> [args...]]` |
| Open, run a command, and close on success | `noriba-cli terminal open --close-on-exit [-- <command> [args...]]` |
| Open and join messaging bus with a role | `noriba-cli terminal open --role <ROLE> [--desc "<text>"]` |
| Close a terminal tab by ID or prefix | `noriba-cli terminal close <TERMINAL_ID>` |

`noriba-cli term open` and `noriba-cli term close` are available as short aliases.

## Only when asked

Open or close a terminal only when the user asked for it in this request (or
invoked `/noriba-terminal`), or when the task the user gave you clearly needs
a visible helper (a dev server they want to watch, a worker agent they asked
you to delegate to). A new tab changes the window the user is looking at, so
do not open terminals for work you can run in your own shell, and never close
a terminal you did not open unless the user names it.

---

## Opening a Terminal (`terminal open`)

`noriba-cli terminal open` prints the unique 36-character UUID of the newly created terminal to stdout (`<UUID>\n`).
In scripts or agent turns, capture this ID into a variable to interact with it or close it later:

```bash
# Capture the new terminal's ID (it opens in the caller's directory by default)
TID=$(noriba-cli terminal open --role worker -- claude)

# Send a prompt to the new terminal via noriba-messaging
noriba-cli msg send "$TID" "Please review the changes in src/"

# Close the terminal when finished
noriba-cli terminal close "$TID"
```

### Options

- `--shell <KIND>`: Specify the shell to launch: `pwsh` (PowerShell 7), `powershell` (Windows PowerShell 5), `wsl`, `wsl:<distro>` (e.g. `wsl:Ubuntu`), or `login` (the macOS login shell). Defaults to the caller's own shell. Any other value fails with `unknown shell: <value>`.
- `--background` (or `--bg`, `-b`): Open the terminal in the background without stealing focus or switching active tabs. The new tab appears in the sidebar list, but the user's active terminal remains focused.
- `--cwd <PATH>`: Working directory for the new terminal. Defaults to the caller's working directory. The path is passed to noriba as is (it is not resolved against your shell's directory), so give an absolute path in the form the new shell understands: a Windows path (`C:\work\app`; in Git Bash use `"$(pwd -W)"`, not `$PWD`) for PowerShell, a Linux or Windows path for WSL, a POSIX path on macOS. When in doubt, omit it and `cd` in the command instead.
- `--close-on-exit`: Do not keep a shell after `<command>`: the command is the tab's last process, so the tab closes by itself when it exits successfully (exit status 0). If it fails, the tab stays as an exited terminal (with Reconnect) so the user can read the error; close it with `terminal close`. Without this flag, an interactive shell prompt follows `<command>` whatever its exit status. It only matters with `-- <command>`.
- `--role <ROLE>`: Join the noriba messaging bus synchronously upon creation with this role name. Eliminates startup race conditions when sending messages to the new terminal. The join is saved like any `msg join` and survives a noriba restart. Needs a passcode on the project (see "Reading the result").
- `--desc <TEXT>`: Optional human-readable description for the messaging role.
- `--auto-enter`: Submit delivered messages as prompts. It is always on when `--role` is given (there is no way to turn it off on `terminal open`; run `noriba-cli msg join` inside the new terminal for a join without it) and means nothing without `--role`.
- `--raw`: With `--role`, paste delivered messages as raw text without the `[noriba msg from ...]` header. Never use it for an agent terminal.
- `--no-screen`: With `--role`, do not publish this terminal's screen/preview to remote viewers on the messaging bus.
- `-- <command> [args...]`: The command and arguments to execute upon launch. Noriba safely quotes arguments (preserving spaces, hyphens, and quotes) and remains agnostic to what binary or AI model is run.

A project holds at most 32 terminals.

---

## Closing a Terminal (`terminal close`)

`noriba-cli terminal close <TERMINAL_ID>` tears down the target terminal session and removes its tab from the UI.

- `<TERMINAL_ID>` can be the full 36-character UUID or an unambiguous prefix of at least 8 characters.
- Only terminals of the caller's project on the same machine can be closed (local-only boundary); `terminal open` / `close` never reach another machine through the messaging bus.

---

## Reading the result

`terminal open` prints the new terminal's UUID and exits 0; `terminal close`
prints nothing on success (exit 0). Otherwise:

| Exit | stderr | What to tell the user |
|---|---|---|
| 2 | `run this inside a noriba terminal ...` | You (the agent) are not running inside a noriba terminal, so noriba cannot be reached. Do not retry. |
| 2 | `noriba-cli: terminal close: expected <TERMINAL_ID>` / `terminal open: unknown flag ...` / `... needs a value` / `terminal: unknown subcommand ...` | A usage error; fix the command. |
| 1 | `noriba-cli: unknown shell: <value>` | Use one of `pwsh`, `powershell`, `wsl`, `wsl:<distro>`, `login`. |
| 1 | `noriba-cli: terminal limit reached (maximum 32 terminals per project)` | Close a terminal first (ask the user which). |
| 1 | `noriba-cli: no passcode configured for this project` (with `--role`) | The project has no passcode, so the terminal cannot join. Ask the user to set one, or open it without `--role`. |
| 1 | `noriba-cli: failed to spawn terminal: ...` | The shell could not be started; quote the error. (A shell that starts and then fails, such as a missing WSL distro, shows its error in the new tab instead.) |
| 1 | `noriba-cli: failed to join messaging: ...` | The terminal opened but did not join; it is open without a role. |
| 1 | `noriba-cli: terminal not found: <id>` | No terminal of this project has that ID / prefix (a prefix needs at least 8 characters). |
| 1 | `noriba-cli: ambiguous terminal prefix '<id>' (matches N terminals)` | Use a longer prefix or the full UUID. |
| 1 | `noriba-cli: this noriba does not support `terminal open` (update noriba)` | The running noriba is older than v0.5.36; the user needs to update noriba. |
| 1 | `unknown terminal` | noriba no longer knows the calling terminal; the user should reopen it. |
| 1 | `cannot communicate with noriba` / `noriba is not responding` | noriba did not answer; it may have been closed or be busy. |
| 127 / not found | `noriba-cli: command not found` | `noriba-cli` is not on PATH: noriba is probably not the host terminal. |

Report errors in a sentence, quoting the error text; do not loop on retries.

---

## Best Practices for Agents

1. **Keep processes visible**: Instead of launching long-lived background daemons, watchers, or dev servers invisibly in the background, open a terminal tab with `noriba-cli terminal open -- <command>...` so the user can visibly inspect logs, ANSI colors, and output.
2. **Helper agents**: When delegating work to an auxiliary worker agent (e.g. running in a separate git worktree or different model), use `--role <role>` so you can coordinate with it over `noriba-cli msg send --role <role>` (see the `noriba-messaging` skill).
3. **Clean up**: When a short-lived helper or batch task finishes, close it with `noriba-cli terminal close <id>`, or pass `--close-on-exit` at spawn time so noriba closes the tab when the command succeeds.
4. **After it works**: Confirm in one short line which terminal you opened or closed (the role and / or the first 8 characters of its ID) and what runs in it.
