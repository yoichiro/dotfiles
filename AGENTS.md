# Project context

This repository manages personal dotfiles through directory and file symlinks.

## Shared skills

- Keep the canonical skill sources in `claude/skills/`, including their
  references and templates. Do not copy skill content per CLI.
- The Unix installer and the Windows installers (`claude/windows/install.ps1`,
  `codex/install.ps1`, `gemini/install.ps1`) link `adr-from-history`,
  `design-doc-writer`, `drawio`, `noriba-messaging`, and `noriba-viewer` into `~/.claude/skills/`,
  `~/.agents/skills/` (Codex), and `~/.gemini/config/skills/` (Antigravity).
- Keep the explicit skill names and destination lists in `install.sh`,
  `uninstall.sh`, `claude/windows/install.ps1`, `codex/install.ps1`,
  `codex/uninstall.ps1`, `gemini/install.ps1`, and `gemini/uninstall.ps1`
  aligned. Never link evaluation workspaces as skills or manage unrelated
  third-party skills in these directories.
- Antigravity's installed customization guide and general Skills documentation
  use `~/.gemini/config/skills/`; its CLI plugins page lists a different path.
  Recheck the installed CLI before changing destinations.
- `claude/windows/install.ps1` is a separate Claude Code-only installer,
  `codex/install.ps1` is a separate Codex CLI installer, and
  `gemini/install.ps1` is a separate Gemini / Antigravity CLI installer for Windows.
  The root `install.ps1` / `uninstall.ps1` call them in sequence.

## Verification

- Run `bash -n install.sh uninstall.sh` after shell edits.
- Inspect `./install.sh --dry-run` and `./uninstall.sh --dry-run` before applying
  home-directory changes. Preserve existing backup and restore behavior.
- Verify symlinks resolve to the canonical skill directories and that linked
  reference files remain readable. Distinguish filesystem checks from actual
  CLI skill discovery when reporting results.
