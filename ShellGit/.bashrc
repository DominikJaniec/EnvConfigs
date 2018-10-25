alias ls='ls -F --color=auto --show-control-chars'
alias ll='ls -lh'
alias la='ll -A'
alias ..="cd .."
alias cd..="cd .."
alias clr='clear'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias g='git'
__git_complete g _git

source ~/Repos/EnvConfigs/ShellGit/prompt-setter.sh
