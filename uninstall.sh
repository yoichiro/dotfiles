#!/usr/bin/env bash
# Reverse what install.sh did: remove symlinks pointing into this repo, and
# restore files from a backup directory under ~/.dotfiles-backups/.
#
# Usage:
#   ./uninstall.sh                        Remove links, restore from latest backup
#   ./uninstall.sh --from <name|path>     Restore from a specific backup directory
#                                         (basename like 20260426-131830, or full path)
#   ./uninstall.sh --list                 Show available backup directories
#   ./uninstall.sh --dry-run              Print actions, change nothing
#                                         (combinable with --from)
#
# Safety:
#   - Only removes a target if it is a symlink pointing into $DOTFILES_DIR.
#   - Regular files and links pointing elsewhere are left untouched.
#   - ~/.envs.local and ~/.paths.local are never touched.

set -euo pipefail

DRY_RUN=false
LIST_ONLY=false
FROM_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=true; shift ;;
    --list) LIST_ONLY=true; shift ;;
    --from)
      [ $# -ge 2 ] || { echo "--from requires an argument" >&2; exit 2; }
      FROM_ARG="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,15p' "$0"; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--dry-run] [--from <name|path>] [--list]" >&2
      exit 2 ;;
  esac
done

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$HOME/.dotfiles-backups"
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

list_backups() {
  if [ ! -d "$BACKUP_ROOT" ]; then
    echo "(no backups found at $BACKUP_ROOT)"
    return
  fi
  local found=0
  local dir
  for dir in "$BACKUP_ROOT"/*/; do
    [ -d "$dir" ] || continue
    found=1
    echo "${dir%/}"
  done
  [ "$found" = 1 ] || echo "(no backups found at $BACKUP_ROOT)"
}

if $LIST_ONLY; then
  list_backups
  exit 0
fi

# Resolve the backup directory to use.
BACKUP_DIR=""
if [ -n "$FROM_ARG" ]; then
  if [ -d "$FROM_ARG" ]; then
    BACKUP_DIR="$FROM_ARG"
  elif [ -d "$BACKUP_ROOT/$FROM_ARG" ]; then
    BACKUP_DIR="$BACKUP_ROOT/$FROM_ARG"
  else
    echo "Backup directory not found: $FROM_ARG" >&2
    echo "Available backups:" >&2
    list_backups >&2
    exit 2
  fi
elif [ -d "$BACKUP_ROOT" ]; then
  # Pick the lexicographically latest entry (works because of yyyymmdd-HHMMSS).
  for dir in "$BACKUP_ROOT"/*/; do
    [ -d "$dir" ] && BACKUP_DIR="${dir%/}"
  done
fi

if [ -n "$BACKUP_DIR" ]; then
  echo "${PREFIX}using backup: $BACKUP_DIR"
else
  echo "${PREFIX}no backup directory found; will only remove symlinks"
fi

run() {
  if $DRY_RUN; then
    echo "${PREFIX}would run: $*"
  else
    "$@"
  fi
}

# Remove the symlink at $dst if it points into $DOTFILES_DIR, then restore
# the corresponding entry from $BACKUP_DIR (if available).
unlink_path() {
  local expected_src="$1"
  local dst="$2"

  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$expected_src" ] || [[ "$current" == "$DOTFILES_DIR"/* ]]; then
      echo "${PREFIX}rm:   $dst (symlink -> $current)"
      run rm "$dst"
    else
      echo "${PREFIX}skip: $dst (symlink -> $current, not from this repo)"
      return
    fi
  elif [ -e "$dst" ]; then
    echo "${PREFIX}skip: $dst (regular file, not a symlink)"
    return
  else
    echo "${PREFIX}skip: $dst (not present)"
  fi

  if [ -n "$BACKUP_DIR" ]; then
    local rel="${dst#$HOME/}"
    local backup_path="$BACKUP_DIR/$rel"
    if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
      echo "${PREFIX}back: restore $dst from $backup_path"
      run mkdir -p "$(dirname "$dst")"
      run mv "$backup_path" "$dst"
    fi
  fi
}

for name in "${FILES[@]}"; do
  unlink_path "$DOTFILES_DIR/$name" "$HOME/.$name"
done

unlink_path "$DOTFILES_DIR/zprezto/zpreztorc.loader" "$HOME/.zpreztorc"

for prompt_file in "$DOTFILES_DIR"/zprezto/prompts/prompt_*_setup; do
  [ -e "$prompt_file" ] || continue
  unlink_path "$prompt_file" "$HOME/.zsh/prompts/$(basename "$prompt_file")"
done

echo
if $DRY_RUN; then
  echo "Dry run complete. No changes were made."
else
  echo "Done. Symlinks removed and backups restored where present."
  echo "Note: ~/.envs.local and ~/.paths.local are NOT touched (they are yours)."
fi
