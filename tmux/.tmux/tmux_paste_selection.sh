#!/usr/bin/env bash

if [ -n "${DISPLAY}" ] && command -v xsel &>/dev/null; then
    tmux set-buffer -b primary_selection "$(xsel -o)"; tmux paste-buffer -b primary_selection; tmux delete-buffer -b primary_selection
else
    tmux paste-buffer -p
fi
