#!/bin/sh

# example of query and set luminosity (brightness) of monitor over HDMI cable
# sudo ddcutil capabilities | grep "Feature: 10"                                                                                                                                                                                 
# sudo ddcutil getvcp 10                                                                                                                                                                                                         
# sudo ddcutil setvcp 10 70  
# sudo ddcutil setvcp 10 70  

t=0
log_file="/tmp/log_ddcutil_brightness"
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
	log_print "last ddcutil brightness refresh was ${delta}s ago REFRESH [${t}]"
	last_refresh_time="$current_time"
	current_brightness=$(sudo ddcutil getvcp 10 | grep -o "current value =.*" | awk '{print $4}' | sed 's/,//')
}

display_status() {
	log_print "DISPLAY [${t}]"
	last_display_time="$current_time"
	echo "${current_brightness}"
}

loop_forever () {
	interval="${1:-10}"
	last_refresh_time=0
	last_display_time=0
	old_t="$t"
	i=0
	while true; do
		# echo "interval [${interval}]"
		if [ ! "$t" -eq "$old_t" ]; then
			# toggle was changed (user action), refresh is needed
			old_t="$t"
			i=0
			last_refresh_time=0  # force refresh after signal reception
		fi
		if [ "$i" -eq 0 ]; then
			current_time=$(date +%s)
			delta=$((current_time - last_refresh_time))
			if [ "$delta" -ge "$interval" ]; then
					# time to refresh forecast cached data (always when no data were retrieved)
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
}

current_brightness=$(sudo ddcutil getvcp 10 | grep -o "current value =.*" | awk '{print $4}' | sed 's/,//')

if [ "${#}" -eq 0 ]; then
	echo "${current_brightness}"
elif [ "${#}" -eq 1 ]; then
	sudo ddcutil setvcp 10 "${1}" 
elif [ "${#}" -eq 2 ]; then
	if [ -n "${current_brightness}" ] && [ "${current_brightness}" -ge 0 ] && [ "${current_brightness}" -le 1000 ]; then
		value="${2}"
		desired_brightness="${current_brightness}"
		if [ "${1}" = "--increase" ]; then
			desired_brightness="$((current_brightness + value))"
		elif [ "${1}" = "--decrease" ]; then
			desired_brightness="$((current_brightness - value))"
		elif [ "${1}" = "--set" ]; then
			:
		elif [ "${1}" = "--tail" ]; then
			loop_forever "${value}"
			exit 0
		else
			echo "Invalid first argument (--increase/--decreate and --set are supported)"
			exit 3
		fi
		sudo ddcutil setvcp 10 "${desired_brightness}"
		echo "${desired_brightness}"
	else
		echo "Unable to retrieve valid brightness data from the monitor"
		exit 2
	fi
else
	echo "Invalid number of arguments"
	exit 1
fi
