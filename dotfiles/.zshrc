# Load Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker)
source $ZSH/oh-my-zsh.sh

# Load environment variables
if [ -f ~/.profile ]; then
    source ~/.profile
fi

# Prompt with git info
autoload -Uz vcs_info
precmd() { vcs_info }
setopt prompt_subst
PROMPT='%F{green}%n@%m%f %F{blue}%~%f ${vcs_info_msg_0_}%# '

# Development aliases
alias ll='ls -la --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias ga='git add'
alias gco='git checkout'
alias gb='git branch'
alias gd='git diff'
alias gl='git log --oneline'

# System aliases
alias update='sudo apt update && sudo apt upgrade -y'
alias serve='python3 -m http.server 8080'
alias weather='curl wttr.in'
alias myip='curl ifconfig.me'

# Development shortcuts
alias dev='cd $PROJECTS_DIR'
alias tools='cd $TOOLS_DIR'
alias scripts='cd $SCRIPTS_DIR'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'

# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'

# CyberSec shortcuts
alias recon='nmap -A'
alias crack='john'
alias listen='nc -lvnp 4444'
alias scan='nmap -sS -O'
alias enum='gobuster dir -u'

# Load custom aliases
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

# Start neofetch on login
neofetch
