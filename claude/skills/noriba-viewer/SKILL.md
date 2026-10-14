---
name: noriba-viewer
description: Open a Markdown file in the noriba terminal's built-in file viewer (`noriba-cli view open <file>`), or close that viewer (`noriba-cli view close`). Use this skill whenever the user explicitly asks to show / open / display a Markdown file IN THE VIEWER or IN NORIBA, or asks to close the viewer - e.g. "ビューアで開いて", "設計書をビューアに表示して", "noriba で README 見せて", "さっきのファイル、ビューアで見たい", "ビューア閉じて", "open the plan in the viewer". Do not use it when the user just wants to read or see a file's contents in the chat without mentioning the viewer or noriba.
argument-hint: "[file | close]"
allowed-tools: Bash(noriba-cli view open *), Bash(noriba-cli view close)
---

# noriba file viewer

noriba is a terminal app with a Markdown viewer pane next to each terminal.
`noriba-cli` talks to the noriba instance that hosts this terminal, so the
file shows up right beside the conversation. It is a console command that is
already on PATH inside noriba (Windows, macOS and WSL alike).

| Request | Command |
|---|---|
| Show a file | `noriba-cli view open "<path>"` |
| Close the viewer | `noriba-cli view close` |

The viewer shows one document per terminal: opening another file replaces the
current one, and it reloads by itself when the file changes on disk, so there is
no need to reopen a file after editing it.

`noriba-cli` groups its subcommands by feature (`view ...` for the viewer,
`msg ...` for terminal messaging). The bare `noriba-cli open` / `noriba-cli
close` forms still work as shortcuts, but always use the `view` form here so the
calls match the `allowed-tools` list above.

## Only when asked

Open or close the viewer only when the user asked for it in this request (or
invoked `/noriba-viewer`). Switching the pane the user is looking at without
being asked is disruptive, so after writing a Markdown file you may *offer* to
show it, but do not open it on your own.

## Picking the file

1. A path or file name in the request: use it. For a bare name
   (`README 開いて`), find the file under the working directory; prefer the
   one in the project root or the one discussed in the conversation.
2. A reference to the conversation ("さっきの設計書", "the plan you just
   wrote"): use the Markdown file that was written, edited or discussed most
   recently that matches the description.
3. Still ambiguous (several equally plausible candidates, or nothing found):
   ask the user which file, listing the candidates. Do not guess between
   several real candidates.

Prefer an absolute path, quoted (paths may contain spaces or Japanese
characters). A relative path also works - `noriba-cli` resolves it against
the shell's working directory - but an absolute one stays correct even after
an earlier command changed directory.

Only `.md` / `.markdown` files can be shown. If the user asks for another kind
of file (`main.rs`, a PDF, an image), do not call `noriba-cli`; tell them the
viewer currently shows Markdown only.

## Reading the result

`noriba-cli` prints nothing on success (exit 0). Otherwise:

| Exit | stderr | What to tell the user |
|---|---|---|
| 2 | `run this inside a noriba terminal ...` | Claude Code is not running inside a noriba terminal, so the viewer cannot be reached. Do not retry. |
| 1 | `noriba-cli: no such file: <path>` | The file does not exist; check the path (maybe offer the closest match). |
| 1 | `noriba-cli: not a Markdown file: <path>` | Only Markdown is supported. |
| 1 | `cannot reach noriba` / `noriba is not responding` | noriba did not answer; it may have been closed or be busy. |
| 127 / not found | `noriba-cli: command not found` | `noriba-cli` is not on PATH: noriba is probably not the host terminal. |

Report errors in a sentence, quoting the error text; do not loop on retries.

## After it works

Confirm in one short line which file is shown (e.g. "`docs/plan.md` をビューアに
表示したよ"). The user can read it in the pane, so do not paste the file's
contents into the chat unless they ask for that too.
