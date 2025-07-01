#!/bin/sh

interval=${1:-10}
t=0
log_file="/tmp/log_tunnels"
log=1


toggle() {
    t=$(((t + 1) % 2))
}

trap "toggle" USR1

log_print() {
    if [ "${log}" -eq 1 ]; then
        if [ -n "${log_file}" ]; then
            echo "$(date): ${1}" >> "${log_file}"
        else
            echo "$(date): ${1}"
        fi
    fi
}

refresh_status() {
    log_print "last status refresh was ${delta}s ago REFRESH [${t}]"
    last_refresh_time="$current_time"
    ba_status="!ba"
    w7_status="!w7"
    mv_status="!mv"
    if nc -z 84.16.38.156 19999 -w 1; then ba_status="ba"; fi
    if nc -4 -z localhost 8080 -w 1; then w7_status="w7"; fi

    if [ "${w7_status}" == "w7" ]; then
        # tunnel can only work when windows 7 vm is up
	# beware using sudo the sshuttle will connect using root's ssh keys
	# interactive password prompt is impossible from with polybar, so that means that root's public key must be authorized on the server (on the devpc)
	# also run at least once the sshuttle interactively to add remote fingerprint of virtualbox/tunnel providing router to the local known_hosts file
        sudo timeout --preserve-status -s INT -k 1 2 sshuttle -r akocis@localhost:8080 1>/tmp/debug_tunnels_1 2>/tmp/debug_tunnels_2 127.0.0.42
        exit_code="${?}"
        # exit code 1 means sshuttle got keyboard interrupt (this means sshuttle was probably able to connect, otherwise it fails faster with different exit codes)
        if [ "${exit_code}" -eq 1 ]; then
            mv_status="mv"
        else
            mv_status="!mv(${exit_code})"
        fi
    fi
    
    default_route_if="$(ip route | grep default | grep -o "dev.*" | awk '{print $2}')"
    default_ip="$(ip address show dev "${default_route_if}" | grep -o "inet .*" | awk '{print $2}' | awk -F/ '{print $1}')"
}

display_status() {
    log_print "DISPLAY [${t}]"
    last_display_time="$current_time"
    if [ "${t}" -eq 1 ]; then
            echo -n "${default_route_if} ${default_ip} "
    fi
    echo "${ba_status} ${w7_status} ${mv_status}"
}
last_refresh_time=0
last_display_time=0
old_t="$t"
i=0
while [ 1 ]; do
    if [ ! "$t" -eq "$old_t" ]; then
        # toggle was changed (user action), refresh is needed
        old_t="$t"
        i=0
    fi
    if [ "$i" -eq 0 ]; then
        current_time=$(date +%s)
        delta=$((current_time - last_refresh_time))
        if [ "$delta" -ge "$interval" ]; then
                # time to refresh cached data
            refresh_status
        fi
    
        display_status
    fi

    current_time=$(date +%s)
    min_time=$((last_display_time < last_refresh_time ? last_display_time : last_refresh_time))
    i=$((current_time - min_time))
    log_print "last refresh was ${i}s ago (interval ${interval}s)"
    if [ "$i" -ge "$interval" ]; then
        # sleep is over, refresh is needed
        i=0
    else
        # sleep the rest of the interval
        sleep $((interval - i)) &
        wait
    fi
done
