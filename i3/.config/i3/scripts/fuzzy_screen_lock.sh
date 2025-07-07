#!/bin/sh -e

cleanup()
{
    local exit_code="${1}"
    rm -f /tmp/screenshot.png
    rm -f /tmp/screen_locked.png
    return ${exit_code}
}

trap 'cleanup ${?}' EXIT

# Optional argument specifies how many seconds to wait until display 
# is turned off after screen is locked (default is 60 seconds)
monitor_off_delay=${1:-60}

# Take a screenshot
scrot /tmp/screenshot.png

# Pixellate it 10x (looks blocky)
# convert /tmp/screenshot.png -scale 10% -scale 1000% /tmp/screen_locked.png
# Apply gauss blur (looks smooth)
convert /tmp/screenshot.png -blur 0x5 /tmp/screen_locked.png

rm -f /tmp/screenshot.png

# Lock screen displaying this image.
i3lock -e -f -i /tmp/screen_locked.png
orig_pid=$(pgrep --newest i3lock | head -n 1)

# Turn the screen off after a delay.
sleep "${monitor_off_delay}"
pid=$(pgrep --newest i3lock | head -n 1)
# compare pgrep i3lock with stored pid after sleep is over and blank display only when identical
if [ "${pid}" -eq "${orig_pid}" ]; then
    pgrep i3lock && xset dpms force off
fi
