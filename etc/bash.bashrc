#!/bin/bash
# Simplified .bashrc with oh-my-posh

# Exit if the shell is not interactive
[[ $- != *i* ]] && return

# === Basic settings ===
# History
HISTCONTROL=ignoreboth
HISTSIZE=999999
HISTFILESIZE=999999
shopt -s histappend
shopt -s checkwinsize

# === Oh-My-Posh ===
# Install oh-my-posh if it's not installed:
# curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin
# sudo mkdir -p /usr/share/oh-my-posh/themes
# sudo mv /root/.cache/oh-my-posh/themes/* /usr/share/oh-my-posh/themes/
# sudo curl -fsSL https://raw.githubusercontent.com/rdcstarr/resources/refs/heads/master/oh-my-posh/themes/recweb.omp.json -o /usr/share/oh-my-posh/themes/recweb.omp.json
# sudo chmod -R a+r /usr/share/oh-my-posh/themes
eval "$(oh-my-posh init bash --config /usr/share/oh-my-posh/themes/recweb.omp.json)"

# === Useful aliases ===
# Colors for commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Shortcuts for ls
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Other useful aliases
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='htop 2>/dev/null || top'

# Git (if you use it)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'

# === Load additional files ===
# Custom aliases
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# Bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Hestia (if you use it)
[ -f /etc/profile.d/hestia.sh ] && source /etc/profile.d/hestia.sh

# Command not found handler
if [ -x /usr/lib/command-not-found ]; then
    command_not_found_handle()
    {
        /usr/lib/command-not-found -- "$1"
        return $?
    }
fi

# === Useful functions ===
# Extract archives
extract()
{
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a directory and enter it
mkcd()
{
    mkdir -p "$1" && cd "$1"
}

# === Environment variables ===
export EDITOR='nano'
export VISUAL='nano'
export PAGER='less'

# Settings for less
export LESS='-R --use-color -Dd+r$Du+b'
