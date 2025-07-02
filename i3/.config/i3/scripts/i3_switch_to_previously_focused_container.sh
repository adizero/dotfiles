#!/usr/bin/env bash

input_file="/tmp/i3_previous_container"

show_usage()
{
    printf "%s\n" "Usage: ${0}"
    cat << EOF

    Switch actively focused window to the previously focused container id stored in '${input_file}'.
EOF
}

if [ "${1}" == "--help" ]; then
    show_usage
    exit 0
fi

if [ -r "${input_file}" ]; then
    container_id="$(cat "${input_file}")"
    echo "SWITCHING TO $container_id"
    i3-msg "[con_id=\"${container_id}\"]" focus
fi
