#!/usr/bin/env bash

USAGE="USAGE: ${0} [-s|-g|-w|-p] OPTION_NAME ON_STATE OFF_STATE"

OPTION_TYPE="${1}"
OPTION_NAME="${2}"
ON_STATE="${3}"
OFF_STATE="${4}"

if [[ "${#}" != 4 ]]; then
  echo "${USAGE}"
  exit 1
fi

if tmux show-option "${OPTION_TYPE}" | grep -q "$OPTION_NAME $ON_STATE"; then
  OPTION_VALUE="${OFF_STATE}"
else
  OPTION_VALUE="${ON_STATE}"
fi

tmux display-message "${OPTION_NAME} is now ${OPTION_VALUE}"
tmux set-option "${OPTION_TYPE}" "${OPTION_NAME}" "${OPTION_VALUE}" > /dev/null
