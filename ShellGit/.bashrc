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


#####################################################################
### Git:

source ~/Repos/EnvConfigs/ShellGit/prompt-setter.sh

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


#####################################################################
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
