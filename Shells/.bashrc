####################################################################
###          Domin's  Bash profile's configuration file          ###
####################################################################


####################################################################
### Environment: initial setup & configuration

alias ls="ls -F --color=auto --show-control-chars"
alias ll="ls -lh"
alias la="ll -A"

alias o="cd"
alias cd..="cd .."
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias .......="cd ../../../../../.."
alias ........="cd ../../../../../../.."

alias clr="clear"
alias cls="clear"
alias exp="explorer"
alias pss="powershell"
alias vsc="code"

alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"


####################################################################
### Git:

alias g="git"
__git_complete g __git_main

alias gst="git st"
alias glo="git lo"
alias gbr="git br"
alias gsw="git sw"
alias gdf="git df"
alias gco="git co"
alias grs="git rs"
alias gad="git ad"
alias gcm="git cm"
alias grc="git rc"
alias gcp="git cp"
alias gft="git ft"
alias gmg="git mg"
alias gpl="git pl"
alias gps="git ps"
alias gdt="git dt"
alias gmt="git mt"

### Prompt fancy-setter:

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
    # Prompt should be simplified when User rams Shell with empty lines:
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
    # Full context should be resolve and set only when Prompt is not simplified:
    if [ "${__PS_var__simplified}" = false ]; then
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

        context+="\x01${__PS_clear}\x02\n\x01${__PS_mark}\x02➤➤ \x01${__PS_time}\x02${date_time}"
        context+=" \x01${__PS_user}\x02${user_name} \x01${__PS_host}\x02@${host_name}"
        context+="${__PS_var__full_context}"
    fi

    # Set 'Last ExitCode' standard context:
    if [ ${__PS_var__last_exticode} -eq 0 ]; then
        context+="\x01${__PS_exit_ok}\x02 ✔"
    else
        context+="\x01${__PS_exit_err}\x02 ✘! e:${__PS_var__last_exticode}"
    fi

    echo -e "${context}"
}

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWUPSTREAM="auto verbose"

PROMPT_COMMAND=__PS_resolve_context
PS1="\$(__PS_print_context '\D{%F %T}' '\u' '\H') \[${__PS_path}\]\w \[${__PS_clear}\]\$ "


####################################################################
### .NET Core CLI:

# Taken from: https://github.com/dotnet/cli/blob/master/Documentation/general/tab-completion.md
# bash parameter completion for the dotnet CLI
_dotnet_bash_complete()
{
  local word=${COMP_WORDS[COMP_CWORD]}

  local completions
  completions="$(dotnet complete --position "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)"
  if [ $? -ne 0 ]; then
    completions=""
  fi

  COMPREPLY=( $(compgen -W "$completions" -- "$word") )
}

alias dn="dotnet"

complete -f -F _dotnet_bash_complete dotnet
complete -f -F _dotnet_bash_complete dn
