#!/bin/sh

outputs() {
    OUTPUT=$(pactl list short sinks | cut  -f 2 | rofi -dmenu -p "Output" -mesg "Select prefered output source" )
    pactl set-default-sink "$OUTPUT" >/dev/null 2>&1

    for playing in $(pactl list sink-inputs | awk '$1 == "index:" {print $2}'); do
        pactl move-sink-input "$playing" "$OUTPUT" >/dev/null 2>&1
    done
}

inputs() {
    INPUT=$(pactl list short sources | cut  -f 2 | grep input | rofi -dmenu -p "Output" -mesg "Select prefered input source" )
    pactl set-default-source "$INPUT" >/dev/null 2>&1

    for recording in $(pactl list source-outputs | awk '$1 == "index:" {print $2}'); do
        pactl move-source-output "$recording" "$INPUT" >/dev/null 2>&1
    done
}

volume_up() {
    pactl set-sink-volume @DEFAULT_SINK@ +3%
}

volume_down() {
    pactl set-sink-volume @DEFAULT_SINK@ -3%
}

mute() {
    pactl set-sink-mute @DEFAULT_SINK@ toggle
}

volume_source_up() {
    pactl set-source-volume @DEFAULT_SOURCE@ +3%
}

volume_source_down() {
    pactl set-source-volume @DEFAULT_SOURCE@ -3%
}

mute_source() {
    pactl set-source-mute @DEFAULT_SOURCE@ toggle
}

# get_default_sink() {
#     default_sink=$(pw-play --list-targets | sed -n 's/^*[[:space:]]*[[:digit:]]\+: description="\(.*\)" prio=[[:digit:]]\+$/\1/p')
#     echo "${default_sink}"
# }

get_default_sink_id() {
    # default_sink_id=$(pw-play --list-targets | sed -n 's/^*[[:space:]]*\([[:digit:]]\+\):.*$/\1/p')
    sinks=$(pactl list sinks 2>/dev/null)
    [ -n "${sinks}" ] && default_sink_id=$(echo ${sinks} | grep -B2 "Name: $(pactl get-default-sink 2>/dev/null)" | grep Sink | awk '{print $2}' | awk -F# '{print $2}')
    echo "${default_sink_id:-?}"
}

get_default_sink_codec() {
    sinks=$(pactl list sinks 2>/dev/null)
    default_sink_id=$(get_default_sink_id)
    [ -n "${sinks}" ] && default_sink_codec=$(echo "${sinks}" | sed -n "/^Sink #${default_sink_id}/,/^\(Sink\|$\)/p" | grep codec | awk -F\" '{print $2}')
    echo "${default_sink_codec:-}"
}

output_volume() {
    volume=$(pamixer --sink $(get_default_sink_id) --get-volume-human 2>/dev/null)
    echo "${volume:-?}"
}

output_volume_and_codec() {
    volume=$(output_volume)
    codec=$(get_default_sink_codec)
    if [ -n "${codec}" ]; then
        volume="${volume} (${codec})"
    fi
    echo "${volume}"
}

# get_default_source() {
#     default_source=$(pw-record --list-targets | sed -n 's/^*[[:space:]]*[[:digit:]]\+: description="\(.*\)" prio=[[:digit:]]\+$/\1/p')
#     echo "${default_source}"
# }

get_default_source_id() {
    # default_source_id=$(pw-record --list-targets | sed -n 's/^*[[:space:]]*\([[:digit:]]\+\):.*$/\1/p')
    sources=$(pactl list sources 2>/dev/null)
    [ -n "${sources}" ] && default_source_id=$(echo "${sources}" | grep -B2 "Name: $(pactl get-default-source 2>/dev/null)" | grep Source | awk '{print $2}' | awk -F# '{print $2}')
    echo "${default_source_id:-?}"
}

input_volume() {
     volume=$(pamixer --source $(get_default_source_id) --get-volume-human 2>/dev/null)
     echo "${volume:-?}"
}

output_volume_listener() {
    if ! pactl subscribe 2>/dev/null; then sleep 5; fi | while read -r event; do
        if echo "$event" | grep -q "change"; then
            output_volume
        fi
    done
}

output_volume_and_codec_listener() {
    if ! pactl subscribe 2>/dev/null; then sleep 5; fi | while read -r event; do
        if echo "$event" | grep -q "change"; then
            output_volume_and_codec
        fi
    done
}

input_volume_listener() {
    if ! pactl subscribe 2>/dev/null; then sleep 5; fi | while read -r event; do
        if echo "$event" | grep -q "change"; then
            input_volume
        fi
    done
}

case "$1" in
    --output)
        outputs
    ;;
    --input)
        inputs
    ;;
    --mute)
        mute
    ;;
    --mute_source)
        mute_source
    ;;
    --volume_up)
        volume_up
    ;;
    --volume_down)
        volume_down
    ;;
    --volume_source_up)
        volume_source_up
    ;;
    --volume_source_down)
        volume_source_down
    ;;
    --output_volume)
        output_volume
    ;;
    --output_codec)
        get_default_sink_codec
    ;;
    --output_volume_and_codec)
        output_volume_and_codec
    ;;
    --input_volume)
        input_volume
    ;;
    --output_volume_listener)
        output_volume
        output_volume_listener
    ;;
    --output_volume_and_codec_listener)
        output_volume_and_codec
        output_volume_and_codec_listener
    ;;
    --input_volume_listener)
        input_volume
        input_volume_listener
    ;;
    *)
        echo "Wrong argument"
    ;;
esac

