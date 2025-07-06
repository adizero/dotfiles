if [ -r /etc/bash.bashrc ]; then
    # Ubuntu
    source /etc/bash.bashrc
elif [ -r /etc/bashrc ]; then
    # CentOS
    source /etc/bashrc
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Nicer tracing output
# version with source file:line number
# export PS4='\e[33m+ ${BASH_SOURCE:${#BASH_SOURCE}<80?0:-80}:${LINENO} \e[0m' 
# version with timestamp and source file:line number
export PS4='\e[33m+ $(date "+%T.%N") ${BASH_SOURCE:${#BASH_SOURCE}<80?0:-80}:${LINENO} \e[0m' 

# Terminal emulator detection
if [ -r ~/.term_detect ]; then
    source ~/.term_detect

    #use termDetect command, when switching terminals (from the inside of screen/tmux)

    #use terminal detection only in interactive shells
    [[ $- == *i* ]] && termInitialDetection
fi

# Bash uses GNU Readline and therefore immediately sources ~/.inputrc (fallback is /etc/inputrc)

# Bash specific shell options

#correct minor spelling errors
shopt -s cdspell
#append history file instead of rewriting it on shell exit
shopt -s histappend
#aggregate multiline commands into one line in command history
shopt -s cmdhist
#patch/file complete .files (files starting with dot)
shopt -s dotglob
#enables ksh88 egrep pattern matching
shopt -s extglob

#bash will try to keep up with the real window size
# (should set $COLUMNS and $LINES more correctly now)
shopt -s checkwinsize

# CDPATH does for cd what path does for executables
export BASE_CDPATH=.:~
export CDPATH="${BASE_CDPATH}"

# History bash settings
export HISTTIMEFORMAT="[%F %T] "
export HISTFILE=~/.bash_history
export HISTSIZE=4096
export HISTFILESIZE=4096
export HISTCONTROL=ignoredups

#ignore this pattern in history (they will not be recorded in command history)
# export HISTIGNORE="&:ls:mutt:[bf]g:exit"
export HISTIGNORE=

# Persistent history
export PERSISTENT_HISTORY_FILE=~/.persistent_history
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

[ -r ~/.commonrc ] && source ~/.commonrc

[ -r ~/.bashrc.timostools ] && source ~/.bashrc.timostools

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

PROMPT_COMMAND=promptcmd
export PROMPT_COMMAND

# # Toggle between vi and emacs readline mode with Esc+a
# set -o emacs
# bind '"\ea": vi-editing-mode'
# set -o vi
# bind '"\ea": emacs-editing-mode'

# Bash autocompletion (by default bash completion is sourced via /etc/profile, i.e. only for login shells)
if [ -r /etc/profile.d/bash_completion.sh ]; then
    source /etc/profile.d/bash_completion.sh
fi

# Which function is taken from CentOS 8 to provide same experience on CentOS and Ubuntu,
# The bash builtin 'type' is still better than this which function
unalias which 2>/dev/null
unset -f which 2>/dev/null
function which()
{
    (alias; declare -f) | command which --tty-only --read-alias --read-functions --show-tilde --show-dot "$@"
}

# using bc as hex calculator (added uppercasing a-f and striping 0x)
# usage as oneliner: echo "0x1c-0xf" | bcx
# or interactive: bcx
# other good option is to use gdb (e.g. p/x 0x1c-0xf)
# plain bash option (output in decimal): echo $((0x1c-0xf))
# combine with printf to obtain hex: printf "%x" $((0x1c-0xf))
alias bcx='(HISTTIMEFORMAT=; HISTFILE=~/.bc_history; HISTFILESIZE=1000; HISTSIZE=1000; history -c; history -r; while read -e line; do echo "obase=16;ibase=16;$(echo "$line" | sed "s/0x//g" | tr "a-z" "A-Z")" | bc; [ -n "$line" ] && echo "$line" >> ~/.bc_history; history -c; history -r; done)'

# Carapace completions (bash 4.4+ is needed)
bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
if [ $bmajor -gt 4 ] || [ $bmajor -eq 4 -a $bminor -ge 4 ]; then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
    source <(carapace _carapace)
fi

export STARSHIP_CONFIG=~/.config/starship_bash.toml
# Starship prompt
[ -z "${NO_STARSHIP_PROMPT}" ] && eval "$(starship init bash)"

# Zoxide (prints warning when not at the end of .bashrc)
eval "$(zoxide init bash)"
