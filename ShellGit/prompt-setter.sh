__PS_clear="$(tput sgr0)"
__PS_mark="${__PS_clear}$(tput setaf 9)"
__PS_path="${__PS_clear}$(tput setaf 3; tput bold)"
__PS_user="${__PS_clear}$(tput setaf 2; tput bold)"
__PS_host="${__PS_clear}$(tput setaf 2)"
__PS_time="${__PS_clear}$(tput setaf 6)"
__PS_exit_ok="${__PS_clear}$(tput setaf 2)"
__PS_exit_err="${__PS_clear}$(tput setaf 1)"
__PS_git_info="${__PS_clear}$(tput setaf 4; tput bold)"

__PS_timestamp_staleness_sec=7

__PS_var__last_exticode=1
__PS_var__last_history=""
__PS_var__timestamp=0
__PS_var__simplified=false
__PS_var__full_context=""


function __PS_resolve_context () {
    __PS_var__last_exticode=${?}

    local current_history=`history 1`
    # Prompt should be simplified when user rams with empty lines:
    if [ "${__PS_var__last_history}" \< "${current_history}" ]; then
        __PS_var__simplified=false
        __PS_var__last_history=${current_history}
    else
        __PS_var__simplified=true
        __PS_var__last_exticode=0
    fi

    local timestamp_diff=$(( ${SECONDS} - ${__PS_var__timestamp} ))
    # Prompt should not be simplified when context is stale:
    if [ ${timestamp_diff} -gt ${__PS_timestamp_staleness_sec} ]; then
        __PS_var__simplified=false
    fi

    local full_context=""
    # Full context should be set only when Prompt is not simplified:
    if [ "${__PS_var__simplified}" = false  ]; then
        local git_data=$(__git_ps1)
        if [ -n "$git_data" ]; then
            full_context+="\x01${__PS_git_info}\x02${git_data}"
        fi

        full_context+="\x01${__PS_clear}\x02\n"
        __PS_var__timestamp=${SECONDS}
    fi

    __PS_var__full_context=${full_context}
}

function __PS_print_context () {
    local context=""

    # Only when full context is present, set 'time-user' and full context:
    if [ -n "${__PS_var__full_context}" ]; then
        local date_time=${1}
        local user_name=${2}
        local host_name=${3}

        context+="\x01${__PS_clear}\x02\n\x01${__PS_mark}\x02# \x01${__PS_time}\x02${date_time}"
        context+=" \x01${__PS_user}\x02${user_name} \x01${__PS_host}\x02@${host_name}"
        context+="${__PS_var__full_context}"
    fi

    # Set 'Last ExitCode' standard context:
    if [ ${__PS_var__last_exticode} -eq 0 ]; then
        context+="\x01${__PS_exit_ok}\x02✔"
    else
        context+="\x01${__PS_exit_err}\x02✘ e:${__PS_var__last_exticode}"
    fi

    echo -e "${context}"
}


GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto verbose"

PROMPT_COMMAND=__PS_resolve_context
PS1="\$(__PS_print_context '\D{%F %T}' '\u' '\H') \[${__PS_path}\]\w \[${__PS_clear}\]\$ "
