#!/usr/bin/env bash
# First argument: Primary monitor
# Second argument: Secondary monitor

primary_monitor="${1:-LVDS1}"
secondary_monitor="${2:-VGA1}"

if  xrandr | grep -q "${secondary_monitor} disconnect"; then
  xrandr --output "${secondary_monitor}" --off
else
  xrandr --output "${secondary_monitor}" --auto
  xrandr --output "${secondary_monitor}" --right-of "${primary_monitor}"
fi

# reload polybar so it appears only on primary monitor
MONITOR="${primary_monitor}" ~/.config/polybar/launch.sh

# reload desktop background (if used)
# sh ~/.fehbg # wallpaper can look weird if not refreshed
