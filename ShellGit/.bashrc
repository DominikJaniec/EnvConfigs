alias ls='ls -F --color=auto --show-control-chars'
alias ll='ls -l'


__PS_clear=`tput sgr0`
__PS_mark="${__PS_clear}$(tput setaf 9)"
__PS_user="${__PS_clear}$(tput setaf 2 ; tput bold)"
__PS_host="${__PS_clear}$(tput setaf 2)"
__PS_time="${__PS_clear}$(tput setaf 6)"
__PS_info="${__PS_clear}$(tput setaf 7)"
__PS_path="${__PS_clear}$(tput setaf 3 ; tput bold)"

export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWUPSTREAM=verbose

__PS_info () {
    echo -e "\x01 ${__PS_mark}|${__PS_info}$(__git_ps1) \x02"
}

__PS_status () {
    echo -e "\x01${__PS_clear}\n#:${?}$(__PS_info)${__PS_clear}$ \x02"
}

PS1="${__PS_time}\D{%F %T} ${__PS_mark}| ${__PS_user}\u ${__PS_host}@\H ${__PS_mark}} $__PS_path\w\$(__PS_status)"

# Proposed simple version:
# PS1="\[\033[33m\]\w \[\033[32m\]\u\[\033[0m\]\$ "

# Original from Git windows installation:
# PS1="\[\033]0;$TITLEPREFIX:$PWD\007\]\n\[\033[32m\]\u@\h \[\033[35m\]$MSYSTEM \[\033[33m\]\w\[\033[36m\]`__git_ps1`\[\033[0m\]\n$"

# source ~/oh-my-git.bashrc
# source ~/bash_git_prompt.bashrc
