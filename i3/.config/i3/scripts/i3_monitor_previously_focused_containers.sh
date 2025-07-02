#!/usr/bin/env bash

output_file="/tmp/i3_previous_container"
pid_file="/tmp/i3_monitor_previously_focused_containers.pid"

show_usage()
{
    printf "%s\n" "Usage: ${0}"
    cat << EOF

    Monitors i3wm window changes and stores the newly focused container in '${output_file}'.
    The i3-msg subscription client's process id is stored in '${pid_file}'
EOF
}

cleanup()
{
    echo "Cleaning up '${pid_file}'"
    if [ -r "${pid_file}" ]; then
        pkill -F "${pid_file}"
        rm "${pid_file}"
    fi
}

if [ "${1}" == "--help" ]; then
    show_usage
    exit 0
fi

# remove currently running monitor
[ -r "${pid_file}" ] && pkill -F "${pid_file}"
while [ -r "${pid_file}" ]; do
  echo "Waiting..."
  sleep 1
done

trap cleanup EXIT

# start new monitor
# will produce log like output, appending every new focused container to the file
# i3-msg -t subscribe -m '[ "window" ]' | jq --unbuffered '. | select(.change=="focus") | .container.id' > "${output_file}" &
# to replace the file with every newly focused container add subprocess with read line and echo replace the file (uses bash subprocesses, will not work in sh)
current_container="$(i3-msg -t get_tree | jq '.. | objects | select(.focused==true) | .id')"
i3-msg -t subscribe -m '[ "window" ]' | jq --unbuffered '. | select(.change=="focus") | .container.id' > >(prev_line="${current_container}"; while IFS= read -r line; do echo "${prev_line}" > "${output_file}"; prev_line="${line}"; done) &

# store pid into the pid_file
child_pid="${!}"
echo "${child_pid}" > "${pid_file}"

# wait forever
wait "${child_pid}"
