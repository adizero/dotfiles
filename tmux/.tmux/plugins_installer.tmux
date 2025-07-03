#!/usr/bin/env bash

info() {
    if [ -n "${TMUX}" ]; then
        tmux display-message "${@}"
    else
        echo "${@}"
    fi
}

plugins_dir="$HOME/.tmux/plugins"
install_script="$HOME/.tmux/tmux_install_plugins.sh"

if [ -d "${plugins_dir}" ]; then
    exit 0
fi

if [ ! -x "${install_script}" ]; then
    info "[ERROR] install script "${install_script}" not found!"
    exit 1
fi

info "Installing tmux plugins..."

eval "${install_script}"
