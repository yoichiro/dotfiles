#!/bin/bash
# Status line command for Claude Code
# Mirrors the zprezto 'yoichiro' seasonal theme:
#   Spring (Mar-May):  🌸  magenta / green
#   Summer (Jun-Aug):  🌻  yellow  / cyan
#   Autumn (Sep-Nov):  🍁  red     / yellow
#   Winter (Dec-Feb):  ❄️   blue    / white

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Build a git-aware path display that mirrors the 'yoichiro' zsh theme:
#   Inside git repo:  <dim parent>/<bold repo>/<secondary subpath>
#   Outside git repo: <dim parent>/<secondary leaf>
HOME_DIR="$HOME"
pwd_tilde="${cwd/#$HOME_DIR/"~"}"

git_root=$(git -C "$cwd" -c core.fsmonitor=false rev-parse --show-toplevel 2>/dev/null)
if [ -n "$git_root" ]; then
  repo_parent="${git_root%/*}"
  parent_tilde="${repo_parent/#$HOME_DIR/"~"}"
  repo_name="${git_root##*/}"
  inside_repo="${cwd#$git_root}"
  sep="/"
  [ "$parent_tilde" = "/" ] && sep=""
  # dim parent + bold repo + secondary subpath
  path_str="\033[2m${parent_tilde}${sep}\033[0m\033[1m${repo_name}\033[0m${inside_repo}"
else
  parent="${pwd_tilde%/*}"
  leaf="${pwd_tilde##*/}"
  if [ "$parent" = "$pwd_tilde" ]; then
    # Root or home itself
    path_str="$pwd_tilde"
  else
    parent_prefix="${parent}"
    [ "$parent_prefix" != "/" ] && parent_prefix="${parent_prefix}/"
    path_str="\033[2m${parent_prefix}\033[0m${leaf}"
  fi
fi

# Pick season based on current month
month=$(date +%m)
case "$month" in
  03|04|05)
    season_symbol='🌸'
    season_branch='🌿'
    season_clean='✨'
    # magenta = \033[35m , green = \033[32m
    primary_color='\033[35m'
    secondary_color='\033[32m'
    ;;
  06|07|08)
    season_symbol='🌻'
    season_branch='🌴'
    season_clean='☀️'
    # yellow = \033[33m , cyan = \033[36m
    primary_color='\033[33m'
    secondary_color='\033[36m'
    ;;
  09|10|11)
    season_symbol='🍁'
    season_branch='🍂'
    season_clean='🌰'
    # red = \033[31m , yellow = \033[33m
    primary_color='\033[31m'
    secondary_color='\033[33m'
    ;;
  *)
    season_symbol='❄️'
    season_branch='⛄'
    season_clean='🎄'
    # blue = \033[34m , white = \033[37m
    primary_color='\033[34m'
    secondary_color='\033[37m'
    ;;
esac

reset='\033[0m'

# Pick hour symbol (mirrors yoichiro zsh theme's 24-element table)
hour=$(date +%-H)
hour_symbols=(
  '🌌' '🦉' '🌙' '💤' '🌠' '🌄'
  '🌅' '☕' '🥐' '🌻' '🧠' '💻'
  '🍱' '🫖' '🎨' '🍰' '📚' '🌇'
  '🍻' '🍝' '🎮' '📺' '🛁' '🌃'
)
hour_symbol="${hour_symbols[$hour]}"

# Get git branch (skip optional locks for safety)
git_branch=""
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" -c core.fsmonitor=false symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_dirty=$(git -C "$cwd" -c core.fsmonitor=false status --porcelain 2>/dev/null)
    if [ -n "$git_dirty" ]; then
      git_info=" ${primary_color}${season_branch} ${git_branch}${reset} \033[31m💦${reset}"
    else
      git_info=" ${primary_color}${season_branch} ${git_branch}${reset} \033[33m${season_clean}${reset}"
    fi
  fi
fi

# Build context usage string
ctx_str=""
if [ -n "$used" ] && [ "$used" != "null" ]; then
  ctx_str=" $(printf '%.0f' "$used")%"
fi

# Build the status line:
# <season_symbol> <hour_symbol> <path> [branch clean/dirty] | model ctx%
printf "${primary_color}%s${reset} %s ${secondary_color}" "$season_symbol" "$hour_symbol"
printf "%b" "${path_str}"
printf "${reset}"

if [ -n "$git_branch" ]; then
  printf "%b" "$git_info"
fi

if [ -n "$model" ]; then
  printf "  \033[2m%s%s${reset}" "$model" "$ctx_str"
fi

printf "\n"
