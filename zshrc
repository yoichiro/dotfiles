# Register custom prompt themes before prezto loads the prompt module.
fpath=(~/.zsh/prompts $fpath)

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

source "$HOME/.dotfiles/aliases"

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

source "$HOME/.dotfiles/envs"
source "$HOME/.dotfiles/paths"

eval "$(direnv hook zsh)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

eval "$(uv generate-shell-completion zsh)"
