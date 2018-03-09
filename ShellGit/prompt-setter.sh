__PS_clear=`tput sgr0`
__PS_mark="${__PS_clear}$(tput setaf 9)"
__PS_path="${__PS_clear}$(tput setaf 3; tput bold)"
__PS_user="${__PS_clear}$(tput setaf 2; tput bold)"
__PS_host="${__PS_clear}$(tput setaf 2)"
__PS_time="${__PS_clear}$(tput setaf 6)"
__PS_exit_ok="${__PS_clear}$(tput setaf 2)"
__PS_exit_err="${__PS_clear}$(tput setaf 1)"
__PS_git_info="${__PS_clear}$(tput setaf 4; tput bold)"


__PS_var__last_exticode=1
__PS_var__full_context=""
__PS_var__simplified=false
# __PS_var__simplified=true
# TODO : Dynamically switch to simplified mode, when user just rams to make some space in console.
#        Solution idea from: https://stackoverflow.com/questions/27384748/detect-empty-command

function __PS_resolve_context () {
    __PS_var__last_exticode=${?}

    local full_context=""

    # Full context should be set only when PS is not simplified:
    if [ "${__PS_var__simplified}" = false  ]; then
        local git_data=$(__git_ps1)
        if [ -n "$git_data" ]; then
            full_context+="${__PS_git_info}${git_data}"
        fi

        full_context+="${__PS_clear}\n"
    fi

    __PS_var__full_context=${full_context}
}

function __PS_print_context () {
    local context=""

    # Only when full context is present, set 'time-user' and full context:
    if [ -n "${__PS_var__full_context}" ]; then
        local basic_context=${1}
        context+="${__PS_clear}\n${basic_context}${__PS_var__full_context}"
    fi

    # Set 'Last ExitCode' standard context:
    if [ ${__PS_var__last_exticode} -eq 0 ]; then
        context+="${__PS_exit_ok}✔"
    else
        context+="${__PS_exit_err}✘ e:${__PS_var__last_exticode}"
    fi

    echo -e "\x01${context}\x02"
}


GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto verbose"

PROMPT_COMMAND=__PS_resolve_context
PS1="\$(__PS_print_context '${__PS_mark}# ${__PS_time}\D{%F %T} ${__PS_user}\u ${__PS_host}@\H') ${__PS_path}\w ${__PS_clear}\$ "
