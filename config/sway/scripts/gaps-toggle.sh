#!/usr/bin/env bash
# Toggle window gaps between zero and defaults (port of window-gaps-toggle.sh).
set -euo pipefail
STATE_FILE="/tmp/sway-gaps-off"
if [ -f "$STATE_FILE" ]; then
    swaymsg gaps inner current set 4 >/dev/null
    swaymsg gaps outer current set 12 >/dev/null
    rm -f "$STATE_FILE"
    notify-send "Window" "Gaps restored"
else
    swaymsg gaps inner current set 0 >/dev/null
    swaymsg gaps outer current set 0 >/dev/null
    touch "$STATE_FILE"
    notify-send "Window" "Gaps removed"
fi
