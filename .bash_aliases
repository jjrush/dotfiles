#!/bin/bash

alias src='source ~/.bashrc'

#safety
alias mv='mv -i'
alias rm='rm -I -v'
alias cp='cp -i'
alias chmod='chmod --preserve-root'
alias chown='chown --preserve-root'

# navigation aliases
alias u='cd ..'
alias uu='cd ../..'
alias uuu='cd ../../..'
alias uuuu='cd ../../../..'
alias uuuuu='cd ../../../../..'
##################################
##################################

# tool aliases ###################
alias fd='fdfind'
alias ctl='systemctl'
alias python='python3'
alias tidy='make clang-tidy'
##################################
##################################

# eza ############################
alias eza="eza --binary --color auto --group-directories-first --git --git-repos-no-status --hyperlink --icons auto --mounts --no-permissions --octal-permissions --time-style long-iso"
alias ls='eza'
alias e="eza --all --long"
alias ea="eza --all"
alias el="eza --long"
alias eld="eza --all --long --only-dirs --sort name"
alias esize="eza --long --sort size"
alias et="eza --long --sort modified"
alias etree="eza --tree"
alias la=ea
alias l=e
alias ll=el
alias lt=et
alias lsize=esize
alias lld=eld
##################################
##################################

# git aliases
alias clone='git clone'
alias pull='git pull'
alias gs='git status'
alias gd='git diff'
alias gad='git add -A'
alias gcm='git commit -m'
##################################
##################################

# code aliases ###################
alias c='code'
alias scode='sudo code --no-sandbox --user-data-dir="~/.vscode-root"' # run vscode as sudo
alias cbash='c ~/.bashrc'
alias clias='c ~/.bash_aliases'
alias cfunc='c ~/.bash_func'
##################################
##################################

# work aliases ###################
alias malc='cd ~/work-malcolm'
alias malcolm='malc'
alias mal='malc'

alias ics='cd ~/work-icsnpp'

alias parse='cd ~/work-parsers'
alias parsers='parse'
alias par='parse'
alias opcua='$(parse) && cd icsnpp-opcua-binary'

##################################
##################################

# zeek aliases ###################
alias zr='zeek_run'