#!/usr/bin/env bash

pkill xautolock
xautolock -detectsleep -time 10 -locker $HOME/bin/fuzzy_lock.sh &
