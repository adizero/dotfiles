#!/bin/bash

# Note: This script relies on nbfc service .json output (make sure the service is running)
# Check /run/nbfc_service.pid (if the process is not running, then restart the service using: sudo nbfc restart)

# for i in /sys/class/hwmon/hwmon*/temp*_input; do 
#   sensors+=("$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null   || echo $(basename ${i%_*})) $(readlink -f $i)");
# done

# for i in "${sensors[@]}"
# do
#   if [[ $i =~ ^coretemp:.Package.* ]]
#   then
#     export CPU_SENSOR=${i#*0}
#   fi
# done

# temp=$(cat $CPU_SENSOR)
# # imperial=$(((9/5)+32))
# # echo $(((temp/10000)*imperial))
# echo $((temp/10000))

# uses NoteBook FanControl CLI Client state file to determine the current fan status (works on hp6550b)
nbfc_state_file=/run/nbfc_service.state.json

if [ -r "${nbfc_state_file}" ]; then
    temp=$(cat "${nbfc_state_file}" | grep temperature | awk -F: '{print $2}' | awk -F, '{print $1}' | awk '{print $1}')
    fanperc=$(cat "${nbfc_state_file}" | grep current_speed | awk -F: '{print $2}' | awk -F, '{print $1}' | awk '{print $1}' | awk -F. '{print $1}')
    result="${temp}°C[${fanperc}%]"
else
    result="?nbfc?"
fi

echo "${result}"
