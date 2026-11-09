---
name: noriba-terminal
description: Open a new terminal tab in the current noriba project window (`noriba-cli terminal open`) to run helper processes, dev servers, watchers, or AI coding agents, and close them when done (`noriba-cli terminal close <id>`). Use this skill whenever the user asks to open or create a terminal, start a process or agent in another tab, run something where they can see it, spawn a helper or worker, or close a terminal - e.g. "ターミナルを開いて", "別のタブで動かして", "新しいタブでテスト回して", "サーバーを別タブで起動して", "ヘルパーを立ち上げて", "ターミナルを閉じて", "このタブ閉じて", "open a terminal", "run in another tab", "spawn a worker", "start the dev server in a tab", "close the terminal". Also use it when you need to run a long-lived process or delegate work to an auxiliary agent where the user can observe progress, rather than hiding it in a background process.
argument-hint: "[open [--shell <pwsh|powershell|wsl|login>] [--cwd <path>] [--role <role>] [--close-on-exit] [-- <cmd>...] | close <id>]"
allowed-tools: Bash(noriba-cli terminal open *), Bash(noriba-cli terminal close *), Bash(noriba-cli term open *), Bash(noriba-cli term close *)
---

# noriba terminal management

noriba is a native terminal app where terminals are organized as tabs inside a single window.
`noriba-cli` allows creating and tearing down terminal sessions within the current project window from the command line. It is a console command already on `PATH` inside noriba (Windows, macOS and WSL alike).

| Request | Command |
|---|---|
| Open a new terminal tab | `noriba-cli terminal open` |
| Open in a specific directory | `noriba-cli terminal open --cwd "<path>"` |
| Open with a specific shell | `noriba-cli terminal open --shell <pwsh\|powershell\|wsl\|login>` |
| Open and run a command (keeps prompt open) | `noriba-cli terminal open [-- <command> [args...]]` |
| Open, run a command, and close on exit | `noriba-cli terminal open --close-on-exit [-- <command> [args...]]` |
| Open and join messaging bus with a role | `noriba-cli terminal open --role <ROLE> [--desc "<text>"]` |
| Close a terminal tab by ID or prefix | `noriba-cli terminal close <TERMINAL_ID>` |

`noriba-cli term open` and `noriba-cli term close` are available as short aliases.

---

## Opening a Terminal (`terminal open`)

`noriba-cli terminal open` prints the unique 36-character UUID of the newly created terminal to stdout (`<UUID>\n`).
In scripts or agent turns, capture this ID into a variable to interact with it or close it later:

```bash
# Capture the new terminal's ID
TID=$(noriba-cli terminal open --role worker --cwd "$PWD" -- claude)

# Send a prompt to the new terminal via noriba-messaging
noriba-cli msg send "$TID" "Please review the changes in src/"

# Close the terminal when finished
noriba-cli terminal close "$TID"
```

### Options

- `--shell <KIND>`: Specify the shell to launch (`pwsh`, `powershell`, `wsl`, `wsl:<distro>`, or `login` on macOS). Defaults to the project's default shell.
- `--cwd <PATH>`: Working directory for the new terminal. Defaults to the caller's working directory.
- `--close-on-exit`: Automatically close the terminal tab when `<command>` exits cleanly (`exit 0`). If omitted, the terminal remains open at an interactive shell prompt after `<command>` finishes.
- `--role <ROLE>`: Join the noriba messaging bus synchronously upon creation with this role name. Eliminates startup race conditions when sending messages to the new terminal.
- `--desc <TEXT>`: Optional human-readable description for the messaging role.
- `--auto-enter`: Automatically submit delivered messages as prompts (default: `ON` when `--role` is specified).
- `--raw`: Paste delivered messages as raw text without the `[noriba msg from ...]` header.
- `--no-screen`: Do not publish this terminal's screen/preview to remote viewers on the messaging bus.
- `-- <command> [args...]`: The command and arguments to execute upon launch. Noriba safely quotes arguments (preserving spaces, hyphens, and quotes) and remains agnostic to what binary or AI model is run.

---

## Closing a Terminal (`terminal close`)

`noriba-cli terminal close <TERMINAL_ID>` tears down the target terminal session and removes its tab from the UI.

- `<TERMINAL_ID>` can be the full 36-character UUID or an unambiguous prefix of at least 8 characters.
- A terminal can only be closed from within the same project on the same machine (local-only boundary).

---

## Best Practices for Agents

1. **Keep processes visible**: Instead of launching long-lived background daemons, watchers, or dev servers invisibly in the background, open a terminal tab with `noriba-cli terminal open -- <command>...` so the user can visibly inspect logs, ANSI colors, and output.
2. **Helper agents**: When delegating work to an auxiliary worker agent (e.g. running in a separate git worktree or different model), use `--role <role>` so you can coordinate with it over `noriba-cli msg send --role <role>`.
3. **Clean up**: When a short-lived helper or batch task finishes, close it with `noriba-cli terminal close <id>`, or pass `--close-on-exit` at spawn time so noriba automatically cleans up the tab on completion.
