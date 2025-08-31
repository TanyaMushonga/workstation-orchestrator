# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcd='docker-compose down'
alias dcb='docker-compose build'

# DevOps aliases
alias tf='terraform'
alias k='kubectl'
alias ans='ansible'
alias helm='helm'

# GitHub CLI aliases
alias ghrepo='gh repo'
alias ghpr='gh pr'
alias ghissue='gh issue'
alias ghauth='gh auth login'

# AWS CLI aliases
alias awsprofile='aws configure list-profiles'
alias awswhoami='aws sts get-caller-identity'
alias awsregion='aws configure get region'

# Development aliases
alias code.='code .'
alias py='python3'
alias pip='pip3'
alias node-server='npx http-server'
alias react-app='npx create-react-app'
alias vue-app='vue create'

# Database aliases
alias mongo='mongosh'
alias mongodb-start='sudo systemctl start mongod'
alias mongodb-stop='sudo systemctl stop mongod'
alias mongodb-status='sudo systemctl status mongod'
alias redis-start='sudo systemctl start redis-server'
alias redis-stop='sudo systemctl stop redis-server'
alias postgres-start='sudo systemctl start postgresql'
alias postgres-stop='sudo systemctl stop postgresql'

# Git aliases (additional)
alias glog='git log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'
alias gst='git stash'
alias gsp='git stash pop'
alias greset='git reset --hard'

# System monitoring
alias cpu='htop'
alias mem='free -h'
alias disk='df -h'
alias ports='netstat -tuln'
alias proc='ps aux'

# Network tools
alias ping8='ping 8.8.8.8'
alias dns='nslookup'
alias trace='traceroute'

# CyberSec shortcuts
alias msf='msfconsole'
alias sql='sqlmap'
alias enum-web='gobuster dir -u'
alias enum-dns='gobuster dns -d'
alias scan-tcp='nmap -sS'
alias scan-udp='nmap -sU'
alias wireshark='sudo wireshark'

# File operations
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias tree='tree -C'
alias grep='grep --color=auto'
alias cat='bat'  # If bat is installed
alias find='fd'  # If fd is installed
