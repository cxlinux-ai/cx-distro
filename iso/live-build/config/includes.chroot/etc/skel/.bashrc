# ~/.bashrc: executed by bash(1) for non-login shells.
# Cortex Linux - AI-Powered Linux Distribution

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# =============================================================================
# HISTORY CONFIGURATION
# =============================================================================
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# =============================================================================
# SHELL OPTIONS
# =============================================================================
shopt -s checkwinsize
shopt -s globstar 2>/dev/null
shopt -s cdspell 2>/dev/null
shopt -s dirspell 2>/dev/null

# =============================================================================
# CORTEX BRANDED PROMPT (PS1)
# =============================================================================
# Colors
PURPLE='\[\033[0;35m\]'
CYAN='\[\033[0;36m\]'
WHITE='\[\033[1;37m\]'
GRAY='\[\033[0;90m\]'
GREEN='\[\033[0;32m\]'
YELLOW='\[\033[0;33m\]'
RED='\[\033[0;31m\]'
RESET='\[\033[0m\]'
BOLD='\[\033[1m\]'

# Git branch function
__git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}

# Git status indicators
__git_status() {
    local status=""
    local git_status=$(git status --porcelain 2>/dev/null)
    if [[ -n "$git_status" ]]; then
        if echo "$git_status" | grep -q "^??"; then
            status+="?"
        fi
        if echo "$git_status" | grep -q "^.M\|^M"; then
            status+="*"
        fi
        if echo "$git_status" | grep -q "^A\|^.A"; then
            status+="+"
        fi
    fi
    [[ -n "$status" ]] && echo " $status"
}

# Build the prompt
__cortex_prompt() {
    local exit_code=$?
    local prompt=""

    # Show exit code if non-zero
    if [[ $exit_code -ne 0 ]]; then
        prompt+="${RED}[$exit_code]${RESET} "
    fi

    # User@host (purple for root, cyan for user)
    if [[ $EUID -eq 0 ]]; then
        prompt+="${RED}${BOLD}\u${RESET}"
    else
        prompt+="${PURPLE}${BOLD}\u${RESET}"
    fi

    prompt+="${GRAY}@${RESET}"
    prompt+="${CYAN}\h${RESET}"

    # Current directory
    prompt+=" ${WHITE}\w${RESET}"

    # Git info if in a repo
    if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        prompt+="${PURPLE}$(__git_branch)${YELLOW}$(__git_status)${RESET}"
    fi

    # Prompt symbol (# for root, ❯ for user)
    if [[ $EUID -eq 0 ]]; then
        prompt+="\n${RED}#${RESET} "
    else
        prompt+="\n${CYAN}❯${RESET} "
    fi

    PS1="$prompt"
}

PROMPT_COMMAND=__cortex_prompt

# =============================================================================
# COLORS FOR LS AND GREP
# =============================================================================
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# =============================================================================
# USEFUL ALIASES
# =============================================================================
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Listing
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -ltrh'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# System
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='htop 2>/dev/null || top'

# Cortex specific
alias sysinfo='neofetch'
alias update='sudo apt update && sudo apt upgrade'
alias cleanup='sudo apt autoremove && sudo apt autoclean'

# =============================================================================
# COMPLETION
# =============================================================================
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# =============================================================================
# WELCOME MESSAGE (neofetch on first terminal)
# =============================================================================
# Only show neofetch on first interactive shell (not in subshells or scripts)
if [[ -z "$CORTEX_WELCOMED" ]] && command -v neofetch &>/dev/null; then
    export CORTEX_WELCOMED=1
    neofetch
fi

# =============================================================================
# PATH ADDITIONS
# =============================================================================
# Add user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# Cortex tools
if [ -d "/opt/cortex/bin" ]; then
    PATH="/opt/cortex/bin:$PATH"
fi
