#!/bin/sh

# Set the default volume step, fallback to 5 if not set
VOLUME_STEP="${VOLUME_STEP:-5}"

case "$1" in
    mute)
        # if pamix is not installed, use amixer
        if ! command -v pamixer > /dev/null; then
            amixer set Master toggle
        else
            pamixer -t
        fi
        ;;
    up)
        # if pamix is not installed, use amixer
        if ! command -v pamixer > /dev/null; then
            amixer set Master "${2:-$VOLUME_STEP}%+"
        else
            pamixer -i "${2:-$VOLUME_STEP}"
        fi
        ;;
    down)
        # if pamix is not installed, use amixer
        if ! command -v pamixer > /dev/null; then
            amixer set Master "${2:-$VOLUME_STEP}%-"
        else
            pamixer -d "${2:-$VOLUME_STEP}"
        fi
        ;;
    *)
        echo "Usage: $0 {mute|up|down}"
        exit 2
esac

exit 0
