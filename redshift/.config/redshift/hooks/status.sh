#!/bin/sh
status_file="${XDG_RUNTIME_DIR:-/tmp}/redshift_status"
echo "$(date --iso-8601=ns) ${PPID} ${@}" >> "${status_file}"
