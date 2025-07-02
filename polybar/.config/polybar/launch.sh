#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar
sleep 1
# Escalate to signal KILL
killall -9 -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

short_hostname="${HOSTNAME%%.*}"
if [ "${short_hostname}" == "hp6550b" ]; then
    # ARCH HP6550B NOTEBOOK
    # export MONITOR=LVDS1
    # export ETH=enp0s25
    export MODLIST="system-usb-udev filesystem-root memory xbacklight pipewire-rofi-output
    pipewire-rofi-input wifi dropbox eth load-average cpu-cores custom-battery temperature fans date custom-redshift
    openweathermap-fullfeatured powermenu"
elif [ "${short_hostname}" == "probook" ]; then
    # GENTOO HP6550B NOTEBOOK
    export MONITOR=LVDS-1
    # export ETH=enp0s25
    export MODLIST="system-usb-udev filesystem-root memory xbacklight wifi dropbox eth load-average cpu-cores custom-battery temperature fans date custom-redshift
    openweathermap-fullfeatured powermenu"
elif [[ "${short_hostname}" == "mvakocis"* ]]; then
    # CENTOS 7 DEVPC DESKTOP
    export MONITOR=DP-1
    export ETH=eno1
    export DBX=dropbox
    export MODLIST="removable_disks system-usb-udev filesystem-root-and-home memory xbacklight
    pulseaudio-rofi-output pulseaudio-rofi-input wifi eth load-average cpu-cores battery temperature date
    custom-redshift openweathermap-fullfeatured powermenu"
fi

# DPI detection relies on Xft.dpi setting in .Xresources
DPI=$(xrdb -query | grep Xft.dpi | awk '{print $2}')
DPI=${DPI:-96}
export DPI
export POLYBAR_HEIGHT=$((18 * DPI / 96))

# Replace newlines with spaces
MODLIST="${MODLIST//$'\n'/ }"

# Launch bar1 and bar2
# polybar bar1 &
# polybar bar2 &
polybar --config=$HOME/.config/polybar/config.ini -r mybar &

echo "Bars launched... (DPI: $DPI, Height: $POLYBAR_HEIGHT)"
