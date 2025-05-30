
if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi

if [ -f ~/.zsh_func ]; then
    source ~/.zsh_func
fi

export PATH="/opt/homebrew/opt/qt/bin:$PATH"

# history search
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/jason/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# local env
. "$HOME/.local/bin/env"

# direnv
eval "$(direnv hook zsh)"

# "Smart" cd
# basically checks if .venv exists when cd'ing into a directory and appends it to the PATH
autoload -U add-zsh-hook
workon () {
  if [[ -d .venv ]]; then
    export VIRTUAL_ENV="$PWD/.venv"
    export PATH="$VIRTUAL_ENV/bin:$PATH"
  fi
}
add-zsh-hook chpwd workon
workon      # run once for current shell

# --- uv shell-completion ---------------------------------
eval "$(uv generate-shell-completion zsh)"
