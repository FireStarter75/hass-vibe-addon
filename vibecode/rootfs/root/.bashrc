export TERM=xterm-256color
export LANG=C.UTF-8
PS1='\[\033[1;35m\]vibe-code\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ '

alias ll='ls -la'
alias v='vibe'
alias ha-config='cd /homeassistant'
alias ha-logs='ha core logs 2>&1 | tail -100'
alias stats='vibe-stats'
alias login='vibe-login'
alias models='vibe-models'
