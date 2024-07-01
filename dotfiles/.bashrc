if [ -r /etc/bash.bashrc ]; then
    # Ubuntu
    source /etc/bash.bashrc
elif [ -r /etc/bashrc ]; then
    # CentOS
    source /etc/bashrc
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PS4='\e[33m+ ${BASH_SOURCE:${#BASH_SOURCE}<80?0:-80}:${LINENO} \e[0m'

[ -r ~/.commonrc ] && source ~/.commonrc

HISTCONTROL=ignoredups
# persistent history
PERSISTENT_HISTORY_FILE=~/.persistent_history
export HISTTIMEFORMAT="[%F %T] "
log_bash_persistent_history()
{
  [[
    $(history 1) =~ ^\ *[0-9]+\ +([^\ ]+\ [^\ ]+)\ +(.*)$
  ]]
  local date_part="${BASH_REMATCH[1]}"
  local command_part="${BASH_REMATCH[2]}"
  if [ "$command_part" != "$PERSISTENT_HISTORY_LAST" ]
  then
    echo "$$" "$date_part" "$command_part" >> "${PERSISTENT_HISTORY_FILE}"
    export PERSISTENT_HISTORY_LAST="$command_part"
  fi
}

# stuff to do on PROMPT_COMMAND
run_on_prompt_command()
{
    log_bash_persistent_history
}

function promptcmd()
{
    # history -a  # this is run automatically by bash (I think)
    run_on_prompt_command
}

# # Toggle between vi and emacs readline mode with Esc+a
# set -o emacs
# bind '"\ea": vi-editing-mode'
# set -o vi
# bind '"\ea": emacs-editing-mode'

PROMPT_COMMAND=promptcmd
export PROMPT_COMMAND

# Zoxide
eval "$(zoxide init bash)"

# Starship prompt
eval "$(starship init bash)"

# using bc as hex calculator (added uppercasing a-f and striping 0x)
# usage as oneliner: echo "0x1c-0xf" | bcx
# or interactive: bcx
# other good option is to use gdb (e.g. p/x 0x1c-0xf)
# plain bash option (output in decimal): echo $((0x1c-0xf))
# combine with printf to obtain hex: printf "%x" $((0x1c-0xf))
alias bcx='(HISTTIMEFORMAT=; HISTFILE=~/.bc_history; HISTFILESIZE=1000; HISTSIZE=1000; history -c; history -r; while read -e line; do echo "obase=16;ibase=16;$(echo "$line" | sed "s/0x//g" | tr "a-z" "A-Z")" | bc; [ -n "$line" ] && echo "$line" >> ~/.bc_history; history -c; history -r; done)'
