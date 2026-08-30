#!/usr/bin/env bash
# Toggle the hypridle idle-locking daemon (and screensaver) on / off.
set -euo pipefail

if pgrep -x hypridle >/dev/null; then
	pkill -x hypridle
	notify-send "Idle" "Idle lock disabled"
else
	hypridle &
	notify-send "Idle" "Idle lock enabled"
fi