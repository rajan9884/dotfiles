#!/usr/bin/env bash
# Toggle the global window layout between dwindle and master.
set -euo pipefail

CUR=$(hyprctl getoption general:layout -j | jq -r '.str')
if [ "$CUR" = "dwindle" ]; then
	hyprctl keyword general:layout master >/dev/null
	notify-send "Layout" "Master"
else
	hyprctl keyword general:layout dwindle >/dev/null
	notify-send "Layout" "Dwindle"
fi