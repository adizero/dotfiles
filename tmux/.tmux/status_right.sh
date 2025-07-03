get_load_avg()
{
	if [ "$CURRENT_OS" = "SunOS" ]; then
		# one minute load average
		load_avg=$(uptime | awk '{print $(NF-2)}' | tr -d ",")
	else
		# one minute load average + number of running/total processes
		load_avg=$(awk '{print $1 " " $4}' < /proc/loadavg)
	fi
}

get_mem_free()
{
	if [ "$CURRENT_OS" = "SunOS" ]; then
		mem_free=$(vmstat | tail -n 1 | awk '{print int($5 / 1024) "MB"}')
	else
		if free -V 2>&1 | grep -q " 3.2"; then
			# CentOS 6
			mem_free=$(free -m | xargs | awk '{print $17 "MB"}')
		else
			# CentOS 7
			mem_free=$(free -m | xargs | awk '{print $13 "MB"}')
		fi
	fi
}

get_load_avg
get_mem_free
time="$(date +%H:%M)"

echo "${load_avg} ${mem_free} ${time}"
