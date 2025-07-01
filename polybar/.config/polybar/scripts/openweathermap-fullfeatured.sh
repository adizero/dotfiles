#!/bin/sh

interval=${1:-600}
t=0
log_file="/tmp/log_openweather"
log=1

KEY="2aee6e1e4b542fe83f08c6e753dc371c"
CITY="Sunnyvale,US"
# CITY="Bratislava,SK"
UNITS="metric"
SYMBOL="°"

API="https://api.openweathermap.org/data/2.5"


toggle() {
    t=$(((t + 1) % 3))
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

get_icon() {
    case $1 in
        01d) icon="";;
        01n) icon="";;
        02d) icon="";;
        02n) icon="";;
        03*) icon="";;
        04*) icon="";;
        09d) icon="";;
        09n) icon="";;
        10d) icon="";;
        10n) icon="";;
        11d) icon="";;
        11n) icon="";;
        13d) icon="";;
        13n) icon="";;
        50d) icon="";;
        50n) icon="";;
        *) icon="";
    esac

    echo $icon
}

get_duration() {

    osname=$(uname -s)

    case $osname in
        *BSD) date -r "$1" -u +%H:%M;;
        *) date --date="@$1" -u +%H:%M;;
    esac

}

fetch_forecast() {
    log_print "last forecast data fetch was ${delta}s ago FORECAST [${t}]"
    forecast_cache_time="$current_time"
    if [ ! -z $CITY ]; then
        if [ "$CITY" -eq "$CITY" ] 2>/dev/null; then
            CITY_PARAM="id=$CITY"
        else
            CITY_PARAM="q=$CITY"
        fi

        current=$(curl -sf "$API/weather?appid=$KEY&$CITY_PARAM&units=$UNITS")
        forecast=$(curl -sf "$API/forecast?appid=$KEY&$CITY_PARAM&units=$UNITS&cnt=1")
    else
        location=$(curl -sf https://location.services.mozilla.com/v1/geolocate?key=geoclue)

        if [ ! -z "$location" ]; then
            location_lat="$(echo "$location" | jq '.location.lat')"
            location_lon="$(echo "$location" | jq '.location.lng')"

            current=$(curl -sf "$API/weather?appid=$KEY&lat=$location_lat&lon=$location_lon&units=$UNITS")
            forecast=$(curl -sf "$API/forecast?appid=$KEY&lat=$location_lat&lon=$location_lon&units=$UNITS&cnt=1")
        fi
    fi
}

display_forecast() {
    log_print "DISPLAY [${t}]"
    last_display_time="$current_time"
    if [ ! -z "$current" ] && [ ! -z "$forecast" ]; then
        current_temp=$(echo "$current" | jq ".main.temp" | cut -d "." -f 1)
        current_icon=$(echo "$current" | jq -r ".weather[0].icon")
    
        forecast_temp=$(echo "$forecast" | jq ".list[].main.temp" | cut -d "." -f 1)
        forecast_icon=$(echo "$forecast" | jq -r ".list[].weather[0].icon")
    
    
        if [ "$current_temp" -gt "$forecast_temp" ]; then
            trend=""
        elif [ "$forecast_temp" -gt "$current_temp" ]; then
            trend=""
        else
            trend=""
        fi
    
    
        sun_rise=$(echo "$current" | jq ".sys.sunrise")
        sun_set=$(echo "$current" | jq ".sys.sunset")
        now=$(date +%s)
    
        if [ "$sun_rise" -gt "$now" ]; then
            daytime=" $(get_duration "$((sun_rise-now))")"
        elif [ "$sun_set" -gt "$now" ]; then
            daytime=" $(get_duration "$((sun_set-now))")"
        else
            daytime=" $(get_duration "$((sun_rise-now))")"
        fi
    
        if [ "${t}" -eq 0 ]; then 
            echo "$(get_icon "$current_icon") $current_temp$SYMBOL"
        elif [ "${t}" -eq 1 ]; then 
            echo "$(get_icon "$current_icon") $current_temp$SYMBOL $trend  $(get_icon "$forecast_icon") $forecast_temp$SYMBOL"
        else
            echo "$(get_icon "$current_icon") $current_temp$SYMBOL $trend  $(get_icon "$forecast_icon") $forecast_temp$SYMBOL   $daytime"
        fi
    fi
}

forecast_cache_time=0
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
        delta=$((current_time - forecast_cache_time))
        if [ "$delta" -ge "$interval" ] || [ -z "$current" ] || [ -z "$forecast" ]; then
                # time to refresh forecast cached data (always when no data were retrieved)
            fetch_forecast
        fi
    
        display_forecast
    fi

    current_time=$(date +%s)
    min_time=$((last_display_time < forecast_cache_time ? last_display_time : forecast_cache_time))
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
