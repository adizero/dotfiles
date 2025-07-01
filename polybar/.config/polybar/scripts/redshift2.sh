#!/usr/bin/env bash
# assumes ~/.config/redshift/redshift.conf is present and has temp-day and temp-night defined under [redshift] section
adjustment_amount=250
status_file="${XDG_RUNTIME_DIR:-/tmp}/redshift_status"
conf_file="${XDG_CONFIG_HOME:-/${HOME}/.config}/redshift/redshift.conf"

get_state() {
	if [ ! -r "${status_file}" ]; then
		state="none"
		return
	fi
    state=$(echo "$(tail -n1 "${status_file}" | awk '{print $NF}')")
    daytemp=$(grep temp-day "${conf_file}" | awk -F= '{print $2}')
    nighttemp=$(grep temp-night "${conf_file}" | awk -F= '{print $2}')
}

show() {
    case "${state}" in
      daytime)
        printf "D%dK" "${daytemp}"
        ;;
      transition)
	printf "%%{F#ffa500}T%dK%%{F-}" "${daytemp}"
        ;;
      night)
	printf "%%{F#ff8c00}N%dK%%{F-}" "${nighttemp}"
        ;;
      none)
        printf "off"
        ;;
    esac
}

change_temp() {
    delta="${1}"
    case "${state}" in
      daytime)
	# fallthrough
	;&
      transition)
        daytemp=$((daytemp+delta))
        [ "${daytemp}" -gt 1000 ] || daytemp=1000
        [ "${daytemp}" -lt 25000 ] || daytemp=25000
	sed -i "s/temp-day=.*/temp-day=${daytemp}/g" "${conf_file}"
	redshift -P -r -O "${daytemp}"
        ;;
      night)
        nighttemp=$((nighttemp+delta))
        [ "${nighttemp}" -gt 1000 ] || nighttemp=1000
        [ "${nighttemp}" -lt 25000 ] || nighttemp=25000
	sed -i "s/temp-night=.*/temp-night=${nighttemp}/g" "${conf_file}"
	redshift -P -r -O "${nighttemp}"
        ;;
    esac

    # restart in 3 seconds, kill any previous pending restart
    pkill -f "sleep 3.123"
    # the pkill -9 will cause redshift to keep old gamma setting and not write new status off to the status file
    # however that means redshift needs to be started with -P option
    # update /usr/lib/systemd/user/redshift.service file and reload the service with systemctl --user daemon-reload
    ( sleep 3.123 && pkill -9 redshift ) &
}

get_state

case $1 in 
  toggle) 
    pkill -USR1 redshift
    show
    ;;
  increase)
    change_temp "${adjustment_amount}"
    show
    ;;
  decrease)
    change_temp "-${adjustment_amount}"
    show
    ;;
  temperature)
    show
    ;;
esac
