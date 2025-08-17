# Brief listing of what is being sourced by zsh and in which order
#
#       # unconditional ($ZDOTDIR becomes $HOME if unset)
#       /etc/zshenv
#       $ZDOTDIR/.zshenv
#
#       # only if login shell
#       /etc/zprofile
#       $ZDOTDIR/.zprofile
#
#       # only if interactive
#       /etc/zshrc
#       $ZDOTDIR/.zshrc
#
#       # only if login shell
#       /etc/zlogin
#       $ZDOTDIR/.zlogin
#
#       # only after login shell exits
#       $ZDOTDIR/.zlogout
#       /etc/zlogout    (installation-specific - /etc is the default)


# If not running interactively, don't do anything
# Technically this script is not executed directly during zsh startup when non-interactive (maybe be manually sourced)
[[ $- != *i* ]] && return

# export PS4='+%N:%i> '
export PS4='%F{#a6e3a1}+ %N:%i %f'

[ -r ~/.commonrc ] && source ~/.commonrc

# Emacs mode as the default start mode (until I add readline keybindings in vi-mode)
set -o emacs

# History in zsh
HISTFILE=~/.zsh_history
HISTSIZE=100000000
SAVEHIST=100000000
setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
# setopt HIST_IGNORE_ALL_DUPS
# setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY

# Wrap builtin zsh history in a function to replicate bash behavior
# - without args bash shows full history, zsh shows only last 15 lines
# - with positive number bash shows only that many last lines, zsh instead starts from that number
# - zsh uses negative number to start from the end of the history
history() {
    # if no arguments, call zsh builtin history 1 (to emulate bash)
    if [[ $# -eq 0 ]]; then
        builtin history 1
        return
    fi

    # if the first argument is a number, call zsh builtin history with that negative number (to emulate bash)
    local number="${1#[-+]}"
    case ${number} in
        ''|*[!0-9]*) ;;
        *)
            set -- "-${number}" "${@:2}"
            builtin history "$@"
            return
            ;;
    esac

    # in all other cases forward everything to zsh builtin history
    builtin history "$@"
}

# Persistent history
export PERSISTENT_HISTORY_FILE=~/.persistent_history
zshaddhistory() {
    typeset -g __persistent_history_last
    local command="${1%%$'\n'}"
    if [ "$command" != "$__persistent_history_last" ]; then
        case "${command}" in
            (*[![:space:]]*)
                # command contains at least one non-whitespace character => store it in persistent history file
                print -r -- "${$} [$(date +%F\ %T)] ${command}" >> "${PERSISTENT_HISTORY_FILE}"
                __persistent_history_last="$command"
                ;;
            (*) ;;
        esac
    fi
}

# Inputrc emulation in zsh (~/.inputrc or /etc/inputrc are not sourced)
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward
# bindkey "\e[A" history-beginning-search-backward
bindkey "\e[A" up-line-or-search
# bindkey "\e[B" history-beginning-search-forward
bindkey "\e[B" down-line-or-search
bindkey " " magic-space

# Terminal specific insert key bindings
bindkey "\e[2~" quoted-insert

# Terminal specific delete key bindings
bindkey "\e[3~" delete-char
# st
bindkey "\e[P" delete-char
# # "\C-H": delete-char
# bindkey "\C-?" delete-char

# Terminal specific home/end key bindings
# vt, st(end)
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
# xterm, kvt, st(home)
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# rxvt and konsole (i.e. the KDE-app...)
bindkey "\e[7~" beginning-of-line
bindkey "\e[8~" end-of-line

# zsh mode specific keybinding
# bindkey -M emacs -s "^Z" "$HOME/script/workflow_fzf^M"
# bindkey -M viins -s "^Z" "$HOME/script/workflow_fzf^M"

# vi command mode
bindkey '\e' vi-cmd-mode
# Make Vi mode transitions faster (KEYTIMEOUT is in hundredths of a second)
export KEYTIMEOUT=1

# Transient zsh prompts (will shorten left prompt and clear right prompt on enter)
zle-line-init() {
    emulate -L zsh

    [[ $CONTEXT == start ]] || return 0

    while true; do
        zle .recursive-edit
        local -i ret=$?
        [[ $ret == 0 && $KEYS == $'\4' ]] || break
        [[ -o ignore_eof ]] || exit 0
    done

    local saved_prompt=$PROMPT
    local saved_rprompt=$RPROMPT
    # PROMPT='%# ' # disabled shortening of left prompt
    PROMPT=$saved_prompt
    RPROMPT=""
    zle .reset-prompt
    PROMPT=$saved_prompt
    RPROMPT=$saved_rprompt

    if (( ret )); then
        zle .send-break
    else
        zle .accept-line
    fi
    return ret
}

zle -N zle-line-init

# Reevaluate the prompt string each time it's displaying a prompt
setopt prompt_subst

# Completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
autoload bashcompinit && bashcompinit
autoload -Uz compinit
compinit

# Autosuggestion (requires installed zsh-autosuggestions)
if [ -r /usr/share/zsh/site-functions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/site-functions/zsh-autosuggestions.zsh
elif [ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
# bindkey '^L' vi-forward-word
bindkey '\ey' autosuggest-toggle
bindkey '\el' autosuggest-accept
bindkey '\e^m' autosuggest-execute

# Alt-Backspace like in bash (deletes last word; Ctrl-w deletes last WORD)
backward-delete-small-word() {
    # Copy the global WORDCHARS variable to a local variable. That way any
    # modifications are scoped to this function only
    local WORDCHARS=$WORDCHARS
    # Use bash string manipulation to remove `:` so our delete will stop at it
    WORDCHARS="${WORDCHARS//:}"
    # Use bash string manipulation to remove `/` so our delete will stop at it
    WORDCHARS="${WORDCHARS//\/}"
    # Use bash string manipulation to remove `_` so our delete will stop at it
    WORDCHARS="${WORDCHARS//_}"
    # Use bash string manipulation to remove `-` so our delete will stop at it
    WORDCHARS="${WORDCHARS//-}"
    # Use bash string manipulation to remove `.` so our delete will stop at it
    WORDCHARS="${WORDCHARS//.}"
    # zle <widget-name> will run an existing widget.
    zle backward-delete-word
}
# `zle -N` will create a new widget that we can use on the command line
zle -N backward-delete-small-word
# bind this new widget to `ctrl+w`
bindkey '\e^?' backward-delete-small-word

earlier-last-word() {
    typeset -g __earlier_last_word
    __earlier_last_word=1
    zle insert-last-word "${@}"
}
zle -N earlier-last-word

# Alt-. like in bash (insert last word from previous line, zsh counts args from the end, unlike bash)
# It is the default when in emacs mode
# Switched to custom wrapper to store __earlier_last_word flag
# bindkey '\e.' insert-last-word
bindkey '\e.' earlier-last-word

earlier-word() {
    emulate -L zsh
    setopt typesetsilent

    typeset -g __copyword
    typeset -g __earlier_word_cursor
    typeset -g __earlier_word_histno
    typeset -g __earlier_last_word
    # echo "WORD  ${__copyword} LAST $LASTWIDGET WIDGET $WIDGET NUM $NUMERIC C $CURSOR H $HISTNO X $__earlier_last_word" 
    if (( ${NUMERIC:-0} )); then
        # 1 means last word, 2 second last, etc.
        (( __copyword = ${NUMERIC:-0} ))
        zstyle -s :$WIDGET widget __copywidget
    elif [[ $__earlier_last_word = 1 ]]; then
        __copyword=-2
        __earlier_last_word=0
        typeset -g __copywidget=.insert-last-word
    elif [[ -n $__copyword && ($WIDGET = $LASTWIDGET || $LASTWIDGET = *autosuggest-suggest) && $CURSOR = $__earlier_word_cursor && $HISTNO = $__earlier_word_histno ]]; then
        (( __copyword-- ))
    else
        __copyword=-1
        zstyle -s :$WIDGET widget __copywidget
    fi

    # echo "WORD  ${__copyword} LAST $LASTWIDGET WIDGET $WIDGET NUM $NUMERIC C $CURSOR H $HISTNO X $__earlier_last_word CPWDGT $__copywidget" 
    zle ${__copywidget:-.insert-last-word} 0 $__copyword
    __earlier_word_cursor="${CURSOR}"
    __earlier_word_histno="${HISTNO}"
}
zle -N earlier-word

# Alt-, to insert earlier word
# Standard zle script copy-earlier-word does not work with zsh-autosuggestions (needs custom one)
# autoload -U copy-earlier-word
# zle -N copy-earlier-word
# bindkey '\e,' copy-earlier-word
bindkey '\e,' earlier-word

# Sharing commands from other terminal windows (without exiting)
# TODO(akocis): investigate and enable if useful
# setopt share_history
# 
# up-line-or-local-history() {
#     zle set-local-history 1
#     zle up-line-or-history
#     zle set-local-history 0
# }
# zle -N up-line-or-local-history
# down-line-or-local-history() {
#     zle set-local-history 1
#     zle down-line-or-history
#     zle set-local-history 0
# }
# zle -N down-line-or-local-history
# 
# bindkey '^[OA' up-line-or-history     # Cursor up
# bindkey '^[OB' down-line-or-history   # Cursor down
# bindkey '^[[1;5A' up-line-or-local-history    # [CTRL] + Cursor up
# bindkey '^[[1;5B' down-line-or-local-history  # [CTRL] + Cursor down

# command not found script
[ -r /etc/bash/bashrc.d/command-not-found.sh ] && source /etc/bash/bashrc.d/command-not-found.sh

# Carapace completions
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
# Caution: do not use direct escape sequences (they break end of line calculations esp. with right-prompts), use {color} tags instead
# zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
zstyle ':completion:*' format $'%F{236}%UCompleting %d%u%f'  # dark gray for completion groups (from the grayscale ramp)
zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
source <(carapace _carapace)

# Zoxide
eval "$(zoxide init zsh)"

# Starship prompt
unset STARSHIP_CONFIG  # may have been set to custom starship.toml location in another shell
eval "$(starship init zsh)"
