#!/bin/sh
scriptdir="$(dirname ${0})"
sudo cp "${scriptdir}/95-usb.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules
