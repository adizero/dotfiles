#!/bin/sh
# DIR="$(dirname "$(readlink -f "$0")")"
# path_pid="${DIR}/system-usb-udev.pid"
path_pid="/tmp/polybar-system-usb-udev.pid"

unmount_type=3  # 1 - unmount & power off (no way to remount without physical removal); 2 - unmount only; 3 - eject and eject toggle
log_file="/tmp/log_system_usb_udev"
log=1

log_print() {
    if [ "${log}" -eq 1 ]; then
        if [ -n "${log_file}" ]; then
            echo "$(date): ${1}" >> "${log_file}"
        else
            echo "$(date): ${1}"
        fi
    fi
}

usb_print() {
    # log_print "usb_print called (pid: $(cat "${path_pid}"))"
    devices=$(lsblk -Jplno NAME,TYPE,RM,SIZE,MOUNTPOINT,VENDOR)
    output=""
    counter=0

    for unmounted in $(echo "$devices" | jq -r '.blockdevices[]  | select(.type == "part") | select(.rm == true or .rm == "1") | select(.mountpoint == null) | .name'); do
        unmounted=$(echo "$unmounted" | tr -d "[:digit:]")
        unmounted=$(echo "$devices" | jq -r '.blockdevices[]  | select(.name == "'"$unmounted"'") | .vendor')
        unmounted=$(echo "$unmounted" | tr -d ' ')

        if [ $counter -eq 0 ]; then
            space=""
        else
            space="   "
        fi
        counter=$((counter + 1))

        output="$output$space $unmounted"
    done

    for mounted in $(echo "$devices" | jq -r '.blockdevices[] | select(.type == "part") | select(.rm == true or .rm == "1") | select(.mountpoint != null) | .size'); do
        if [ $counter -eq 0 ]; then
            space=""
        else
            space="   "
        fi
        counter=$((counter + 1))

        output="$output$space $mounted"
    done

    echo "$output"
}

usb_update() {
    log_print "usb_update called (pid: $(cat "${path_pid}"))"
    pid=$(cat "${path_pid}")

    if [ "$pid" != "" ]; then
        kill -10 "$pid"
    fi
}

action_mount() {
    devices=$(lsblk -Jplno NAME,TYPE,RM,MOUNTPOINT)

    log_print "block devices before mount: ${devices}"
    for mount in $(echo "$devices" | jq -r '.blockdevices[]  | select(.type == "part") | select(.rm == true or .rm == "1") | select(.mountpoint == null) | .name'); do
        # udisksctl mount --no-user-interaction -b "$mount"

        # mountpoint=$(udisksctl mount --no-user-interaction -b $mount)
        # mountpoint=$(echo $mountpoint | cut -d " " -f 4 | tr -d ".")
        # terminal -e "bash -lc 'filemanager $mountpoint'"

        mountpoint=$(udisksctl mount --no-user-interaction -b "$mount")
        mountpoint=$(echo "$mountpoint" | cut -d " " -f 4- | tr -d ".")
        log_print "mounted ${mount} at ${mountpoint}"
        xterm -e "bash -lc 'mc \"${HOME}\" \"${mountpoint}\"'" &
        # nohup mc & 1>/tmp/mc_log 2>/tmp/mc_err_log
    done

    usb_update
}

action_unmount() {
    devices=$(lsblk -Jplno NAME,TYPE,RM,MOUNTPOINT)
    log_print "block devices before unmount (type=${unmount_type}): ${devices}"

    if [ "${unmount_type}" -eq 1 ]; then
        for unmount in $(echo "$devices" | jq -r '.blockdevices[]  | select(.type == "part") | select(.rm == true or .rm == "1") | select(.mountpoint != null) | .name'); do
            udisksctl unmount --no-user-interaction -b "$unmount"
            udisksctl power-off --no-user-interaction -b "$unmount"
        done
    elif [ "${unmount_type}" -eq 2 ]; then
        for unmount in $(echo "$devices" | jq -r '.blockdevices[]  | select(.type == "part") | select(.rm == true or .rm == "1") | select(.mountpoint != null) | .name'); do
            udisksctl unmount --no-user-interaction -b "$unmount"
        done
    elif [ "${unmount_type}" -eq 3 ]; then
        for ejectmount in $(echo "$devices" | jq -r '.blockdevices[]  | select(.type == "part") | select(.rm == true or .rm == "1") | select(.mountpoint != null) | .name'); do
            log_print "ejecting mount: ${ejectmount}"
            sudo eject "${ejectmount}"
        done
        sleep 0.5
        for ejectdrive in $(echo "$devices" | jq -r '.blockdevices[]  | select(.type == "disk") | select(.rm == true or .rm == "1") | select(.mountpoint == null) | .name'); do
            log_print "unejecting drive: ${ejectdrive}"
            sudo eject -t "${ejectdrive}"
        done
    fi

    usb_update
}

case "$1" in
    --update)
        usb_update
        ;;
    --mount)
        action_mount
        ;;
    --unmount)
        action_unmount
        ;;
    *)
        echo "${$}" > "${path_pid}"

        trap exit INT
        trap "echo" USR1  # this causes intentional "flicker" on the polybar status line

        while true; do
            usb_print

            sleep 60 &
            wait
        done
        ;;
esac
