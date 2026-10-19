---
name: noriba-viewer
description: Open a Markdown, PDF or source / text file in the noriba terminal's built-in file viewer (`noriba-cli view open <file>`), or close that viewer (`noriba-cli view close`). Use this skill whenever the user explicitly asks to show / open / display a Markdown, PDF or source code file IN THE VIEWER or IN NORIBA, or asks to close the viewer - e.g. "ビューアで開いて", "設計書をビューアに表示して", "noriba で README 見せて", "この PDF をビューアで開いて", "main.rs をビューアで見せて", "さっきのファイル、ビューアで見たい", "ビューア閉じて", "open the plan in the viewer". Also use it to read a quote the user copied from the viewer (`docs/plan.md:12 "…"`, `paper.pdf p.3 "…"`, `src/main.rs:12-20 "…"`). Do not use it when the user just wants to read or see a file's contents in the chat without mentioning the viewer or noriba.
argument-hint: "[file | close]"
allowed-tools: Bash(noriba-cli view open *), Bash(noriba-cli view close)
---

# noriba file viewer

noriba is a terminal app with a Markdown / PDF / source code viewer pane next
to each terminal.
`noriba-cli` talks to the noriba instance that hosts this terminal, so the
file shows up right beside the conversation. It is a console command that is
already on PATH inside noriba (Windows, macOS and WSL alike).

| Request | Command |
|---|---|
| Show a file | `noriba-cli view open "<path>"` |
| Close the viewer | `noriba-cli view close` |

The viewer shows one document per terminal: opening another file replaces the
current one, and it reloads by itself when the file changes on disk, so there is
no need to reopen a file after editing it. A reloaded PDF keeps its page and
zoom, and a reloaded source file keeps its scroll position.

`noriba-cli` groups its subcommands by feature (`view ...` for the viewer,
`msg ...` for terminal messaging). The bare `noriba-cli open` / `noriba-cli
close` forms still work as shortcuts, but always use the `view` form here so the
calls match the `allowed-tools` list above.

## Only when asked

Open or close the viewer only when the user asked for it in this request (or
invoked `/noriba-viewer`). Switching the pane the user is looking at without
being asked is disruptive, so after writing a Markdown file or editing a source
file you may *offer* to show it, but do not open it on your own.

## Picking the file

1. A path or file name in the request: use it. For a bare name
   (`README 開いて`, `main.rs 開いて`), find the file under the working directory; prefer the
   one in the project root or the one discussed in the conversation.
2. A reference to the conversation ("さっきの設計書", "the plan you just
   wrote"): use the Markdown, PDF or source file that was written, edited or discussed
   most recently that matches the description.
3. Still ambiguous (several equally plausible candidates, or nothing found):
   ask the user which file, listing the candidates. Do not guess between
   several real candidates.

Prefer an absolute path, quoted (paths may contain spaces or Japanese
characters). A relative path also works - `noriba-cli` resolves it against
the shell's working directory - but an absolute one stays correct even after
an earlier command changed directory.

The viewer shows Markdown (`.md` / `.markdown`, up to 10 MB), PDF (`.pdf`, up to
50 MB) and source / text files (any other extension or none: `main.rs`,
`Cargo.toml`, `.gitignore`, `Makefile`; up to 10 MB); the extension decides, in
any letter case. Source files get line numbers, and colours for the bundled
languages (the header names the language; an unknown one is shown as plain
text). Images are not supported yet: if the user asks for one, do not call
`noriba-cli`; tell them images cannot be shown yet. A file over its size limit
still opens, but the pane shows a "too large" notice instead of the document -
say so when you know the file is that big. A file that looks binary (NUL bytes in its first 8 KiB,
such as UTF-16 text) opens with a "テキストファイルではありません" notice.

## Reading the result

`noriba-cli` prints nothing on success (exit 0). Otherwise:

| Exit | stderr | What to tell the user |
|---|---|---|
| 2 | `run this inside a noriba terminal ...` | You (the agent) are not running inside a noriba terminal, so the viewer cannot be reached. Do not retry. |
| 1 | `noriba-cli: no such file: <path>` | The file does not exist; check the path (maybe offer the closest match). |
| 1 | `noriba-cli: not a viewable file (images are not supported yet): <path>` | Images are not supported yet. |
| 1 | `unknown terminal` | noriba no longer knows this terminal; the user should reopen it. |
| 1 | `cannot communicate with noriba` / `noriba is not responding` | noriba did not answer; it may have been closed or be busy. |
| 127 / not found | `noriba-cli: command not found` | `noriba-cli` is not on PATH: noriba is probably not the host terminal. |

Report errors in a sentence, quoting the error text; do not loop on retries.

## Quotes copied from the viewer

When the user selects text in the viewer, its copy button can put a quote on
the clipboard, which they often paste to you as a pointer into the document:

| Document | Quote |
|---|---|
| Markdown | `<path>:<line> "<text>"` or `<path>:<first>-<last> "<text>"` (source lines) |
| Source / text file | `<path>:<line> "<text>"` or `<path>:<first>-<last> "<text>"` (same as Markdown) |
| PDF | `<path> p.<page> "<text>"` or `<path> p.<first>-<last> "<text>"` (pages) |

The path is relative to the terminal's working directory when the file is
inside it (absolute otherwise, in the shell's own form, e.g. `/mnt/c/...` in
WSL), and the text is the selection squeezed onto one line (runs of spaces and
line breaks become one space). Treat a pasted quote as "look here": read that
place of the file - the lines of a Markdown or source file; the page of a PDF, searching
for the quoted words in its text - and answer about it. Reading the quote needs
no `noriba-cli` call, and do not reopen the viewer unless asked.

## After it works

Confirm in one short line which file is shown (e.g. "`docs/plan.md` をビューアに
表示したよ"). The user can read it in the pane, so do not paste the file's
contents into the chat unless they ask for that too.
