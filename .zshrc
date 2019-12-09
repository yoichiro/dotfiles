#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

alias st='git status -s -b -uall'
alias br='git branch'
alias ck='git checkout'
alias lg='git log --graph --date=short --pretty="format:%C(yellow)%h %C(cyan)%ad %C(green)%an%Creset%x09%s %C(red)%d%Creset"'
alias ls='ls -vFG --color=auto'
alias ll='ls -lavFG --color=auto'
alias less='less -R'
alias vi='vim'
alias web='python -m http.server 8080'

setopt auto_cd
# bindkey -e
autoload -U compinit; compinit
setopt auto_pushd
setopt pushd_ignore_dups
setopt extended_glob
setopt hist_ignore_all_dups
setopt hist_ignore_space
zstyle ':completion:*:default' menu select=1
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward
function chpwd() { ls }

export PATH=$HOME/bin:$PATH
export PATH=$HOME/.nodebrew/current/bin:$PATH

eval "$(direnv hook zsh)"
