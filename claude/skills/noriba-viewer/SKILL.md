---
name: noriba-viewer
description: Open a Markdown, PDF or source / text file in the noriba terminal's built-in file viewer (`noriba-cli view open <file>`), move it to a line, page or text match (`noriba-cli view goto` / `find` / `outline` / `status`), or close that viewer (`noriba-cli view close`). Use this skill whenever the user explicitly asks to show / open / display a Markdown, PDF or source code file IN THE VIEWER or IN NORIBA, or asks to close the viewer - e.g. "ビューアで開いて", "設計書をビューアに表示して", "noriba で README 見せて", "この PDF をビューアで開いて", "main.rs をビューアで見せて", "さっきのファイル、ビューアで見たい", "ビューア閉じて", "open the plan in the viewer". Also use it when the user wants the viewer to jump somewhere in the file it shows - e.g. "○○の章にジャンプして", "△△と書いてあるところを見せて", "次のやつ", "3 ページ目に飛んで", "今どこ見てる？", "jump to the section about X", "show me where it says Y". Also use it to read a quote the user copied from the viewer (`docs/plan.md:12 "…"`, `paper.pdf p.3 "…"`, `src/main.rs:12-20 "…"`). Do not use it when the user just wants to read or see a file's contents in the chat without mentioning the viewer or noriba.
argument-hint: "[file[:line] | goto <loc> | find <text> | outline | status | close]"
allowed-tools: Bash(noriba-cli view open *), Bash(noriba-cli view goto *), Bash(noriba-cli view find *), Bash(noriba-cli view outline), Bash(noriba-cli view status), Bash(noriba-cli view close)
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
| Show a file at a line / page | `noriba-cli view open "<path>:<line>[-<line>]"` or `noriba-cli view open "<path>" p.<n>` |
| Move to a line, a range or a PDF page | `noriba-cli view goto <line>[-<line>]` or `noriba-cli view goto p.<n>` |
| Search the document and jump to a match | `noriba-cli view find <text>... [--list \| --nth <n>]` |
| Next / previous match of the last find | `noriba-cli view find --next` / `noriba-cli view find --prev` |
| List the headings (Markdown) or bookmarks (PDF) | `noriba-cli view outline` |
| Ask which file and place is on screen | `noriba-cli view status` |
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

## Jumping to a place

`goto`, `find`, `outline` and `status` work on the document the viewer already
shows in this terminal (open it first with `view open` if needed). A jump selects
the target and scrolls it to about the middle of the pane; it never moves the
keyboard focus, so it does not disturb the user's typing. Do it right away when
the user asked for it. A place is a line (`12`, `12-20`) in a Markdown or source
file and a page (`p.3`; `p.3-5` goes to page 3) in a PDF; mixing them is an
error.

1. **A chapter or section by name** ("設計の章にジャンプして"): run `noriba-cli view
   outline` to learn where it is, then `view goto`. Markdown headings are listed
   as `<line>  ## Title`; to select the whole chapter, give the range from the
   heading's line to the line before the next heading (`view goto 40-71`). A
   PDF lists its bookmarks as `p.<page>  Title`; go to that page.
2. **A phrase or a sentence** ("△△と書いてあるところ"): in a Markdown or source file
   you may read the file yourself, pick the line and `view goto` it, or just
   `view find <text>`; in a PDF always use `view find` (you cannot read its
   pages by line). `find` prints the match count, one row per match
   (`<index>  <location>  <excerpt>`) and ends with `jumped to #1 (<location>)`.
   `--list` only lists, `--nth <n>` jumps to the n-th match.
3. **Several matches**: pick by context (the chapter's line / page range from the
   outline) and use `--nth`. If you cannot choose, stay on the first match, tell
   the user how many others there are, and use `view find --next` /
   `--prev` for "次のやつ" / "前のやつ".
4. **No match**: try another wording once or twice (a shorter phrase, a
   synonym, the other script). Vertical text, ruby and split glyphs in a PDF often
   keep a phrase from matching; if it still fails, say that nothing was found.
5. **"今どこ？" / "ここは何？"**: run `noriba-cli view status`, which prints the
   file and the lines (`docs/plan.md:40-72 (Markdown, 120 lines)`) or the page
   (`paper.pdf p.3 of 120 (PDF)`) on screen, read that place of the file and
   answer. It may lag the screen by a moment. For a PDF it names the page at the
   top edge of the pane, so right after a jump to a match near the top of a page it
   can name the previous page; trust the reply line of the jump for that.

Confirm with the reply line, for example "12 行目の見出し `## Overview` に移動したよ"
from `docs/plan.md:12 "## Overview"`. A reply ending in ` (shown when this
terminal is active)` means the jump is waiting because another terminal's
viewer is on screen. Do not paste the file's contents into the chat.

Searching a PDF needs the viewer to be on screen (this terminal active, window
visible), and a first search of a large book can take several seconds.

## Reading the result

`noriba-cli` prints nothing on success of `open` / `close` (exit 0); `goto`,
`find`, `outline` and `status` print their answer (see above) and `open` with a
line or page prints the place it went to. Otherwise:

| Exit | stderr | What to tell the user |
|---|---|---|
| 2 | `run this inside a noriba terminal ...` | You (the agent) are not running inside a noriba terminal, so the viewer cannot be reached. Do not retry. |
| 1 | `noriba-cli: no such file: <path>` | The file does not exist; check the path (maybe offer the closest match). |
| 1 | `noriba-cli: not a viewable file (images are not supported yet): <path>` | Images are not supported yet. |
| 1 | `noriba-cli: no file is open in the viewer` | Nothing is open here; open the file first (`view open`). |
| 1 | `noriba-cli: line 999 is beyond the end of the file (120 lines)` / `page 999 is beyond the last page (120)` | The place does not exist; pick one inside the document. |
| 1 | `noriba-cli: a PDF is addressed by page (p.3), not by line` / `a Markdown or source file is addressed by line (12), not by page` | Use the other form of the place. |
| 1 | `noriba-cli: the document is still loading, retry` | Wait a moment and run it once more. |
| 1 | `noriba-cli: no matches for "<text>"` | Nothing found; try another wording (see above), then say so. |
| 1 | `noriba-cli: match 7 does not exist (3 matches)` / `no previous find` / `no more matches (3 of 3)` / `already at the first match` | `--nth` is out of range, there is no earlier find, or you are at the end of the matches. |
| 1 | `noriba-cli: the PDF is not on screen (switch to this terminal and show the window), so it cannot be searched` | A PDF can be searched only while it is visible; ask the user to switch to this terminal and show the noriba window, then retry. |
| 1 | `noriba-cli: the viewer page did not answer` | The page did not answer in time (a very large PDF); retry once, a second try is usually fast. |
| 1 | `noriba-cli: this noriba does not support `view goto` (update noriba)` | The running noriba is older than `noriba-cli`; the user needs to update noriba. |
| 0 | `noriba-cli: this noriba ignored the location (update noriba)` (a warning) | The file is open but the old noriba did not jump; the user needs to update noriba. |
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
no `noriba-cli` call, and do not reopen the viewer unless asked. If the user does
ask to show the place, pass the quote to `view open` as is, as one argument
(`noriba-cli view open 'docs/plan.md:12 "## Overview"'`, `noriba-cli view open
'paper.pdf p.3 "..."'`); the quoted text is ignored and the file opens at that
line or page.

## After it works

Confirm in one short line which file is shown (e.g. "`docs/plan.md` をビューアに
表示したよ"). The user can read it in the pane, so do not paste the file's
contents into the chat unless they ask for that too.
