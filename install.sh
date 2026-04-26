#!/usr/bin/env bash
# Create symlinks from $HOME to files in this dotfiles repository.
#
# Usage:
#   ./install.sh             Apply links and back up existing files
#   ./install.sh --dry-run   Print the actions that would be taken, change nothing
#
# Behavior:
#   - For each entry in FILES, link $HOME/.<name> -> $DOTFILES_DIR/<name>
#   - For each prompt file in zprezto/prompts/, link
#     ~/.zsh/prompts/<name> -> $DOTFILES_DIR/zprezto/prompts/<name>
#   - If the target already exists (regular file or wrong symlink), move it
#     under ~/.dotfiles-backups/yyyymmdd-HHMMSS/ preserving its $HOME-relative
#     path. The backup directory is created lazily on the first backup.
#   - If the target is already a symlink to the correct source, do nothing.

set -euo pipefail

DRY_RUN=false
case "${1:-}" in
  -n|--dry-run) DRY_RUN=true ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backups"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
PREFIX=""
$DRY_RUN && PREFIX="[dry-run] "

FILES=(
  zshrc
  bashrc
  profile
  gitconfig
  vimrc
  aliases
  paths
  envs
)

# Run a command, or just announce it under --dry-run.
run() {
  if $DRY_RUN; then
    echo "${PREFIX}would run: $*"
  else
    "$@"
  fi
}

# Move $1 (a path under $HOME) into $BACKUP_DIR keeping its HOME-relative path.
backup_path() {
  local src="$1"
  local rel="${src#$HOME/}"
  local dest="$BACKUP_DIR/$rel"
  echo "${PREFIX}back: $src -> $dest"
  run mkdir -p "$(dirname "$dest")"
  run mv "$src" "$dest"
}

# Link $src to $dst, backing up any existing file or wrong symlink first.
link_path() {
  local src="$1"
  local dst="$2"

  if [ ! -e "$src" ]; then
    echo "${PREFIX}skip: source missing: $src"
    return
  fi

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "${PREFIX}ok:   $dst -> $src (already linked)"
      return
    fi
    backup_path "$dst"
  elif [ -e "$dst" ]; then
    backup_path "$dst"
  fi

  run mkdir -p "$(dirname "$dst")"
  echo "${PREFIX}link: $dst -> $src"
  run ln -s "$src" "$dst"
}

for name in "${FILES[@]}"; do
  link_path "$DOTFILES_DIR/$name" "$HOME/.$name"
done

# Claude Code config: link individual files under ~/.claude/. Targets are
# nested (hooks/, commands/), so use explicit relative paths instead of the
# flat $HOME/.<name> scheme used above. link_path's mkdir -p handles the
# subdirectories automatically.
CLAUDE_FILES=(
  CLAUDE.md
  settings.json
  statusline-command.sh
  hooks/notify-windows.sh
  commands/back-to-main.md
)
for rel in "${CLAUDE_FILES[@]}"; do
  link_path "$DOTFILES_DIR/claude/$rel" "$HOME/.claude/$rel"
done

# zprezto runcom: take over ~/.zpreztorc with our loader, which sources the
# upstream zpreztorc and then layers our overrides on top (zpreztorc.local).
link_path "$DOTFILES_DIR/zprezto/zpreztorc.loader" "$HOME/.zpreztorc"

# Custom zprezto prompt themes: link each into ~/.zsh/prompts/, which is on
# fpath thanks to `fpath=(~/.zsh/prompts $fpath)` in zshrc.
for prompt_file in "$DOTFILES_DIR"/zprezto/prompts/prompt_*_setup; do
  [ -e "$prompt_file" ] || continue
  link_path "$prompt_file" "$HOME/.zsh/prompts/$(basename "$prompt_file")"
done

echo
if $DRY_RUN; then
  echo "Dry run complete. No changes were made."
elif [ -d "$BACKUP_DIR" ]; then
  echo "Done. Replaced files were backed up under: $BACKUP_DIR"
  echo "Roll back with: ./uninstall.sh   (uses the latest backup)"
else
  echo "Done. No files needed backing up."
fi
echo "Reminder: put machine-local secrets in ~/.envs.local (chmod 600)."
