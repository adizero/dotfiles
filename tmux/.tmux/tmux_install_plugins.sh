#!/usr/bin/env bash
# Create plugins list based on currently installed plugins with: 
#   cd ~/.tmux && ls plugins | xargs -n 1 -I {} git -C plugins/{} config --get remote.origin.url | xargs -n 1 echo git clone > plugins.list && cd -

# Exit immediately if a command exits with a non-zero status
set -e
# Treat unset variables as an error
set -u

info() {
    if [ -n "${TMUX}" ]; then
        tmux display-message "${@}"
    else
        echo "${@}"
    fi
}

# Move to scripts directory
cd "$(dirname "$0")"

# Check if plugins.list exists and is readable
if [ ! -r plugins.list ]; then
    info "[ERROR] plugins.list file not found!"
    exit 1
fi

# Create plugins directory if it doesn't exist and navigate into it
mkdir -p plugins
cd plugins

# Source the plugins list (assuming it contains valid git clone commands)
# shellcheck disable=1091
source ../plugins.list

# Reload tmux configuration (plugins will be loaded automatically and run their one-time generation/installation scripts)
if [ -n "${TMUX}" ]; then
    tmux source-file ~/.tmux.conf \; display-message "Config reloaded."
fi
