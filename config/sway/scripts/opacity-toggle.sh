#!/usr/bin/env bash
# Toggle focused window opacity between 100% and 90% (port of window-transparency-toggle.sh).
set -euo pipefail
ID=$(swaymsg -t get_tree 2>/dev/null | jq -r '.. | objects | select(.focused == true) | .id // empty' | head -n 1)
[ -z "${ID:-}" ] && exit 0
# sway has no per-window opacity query; track state in a file per con id.
STATE_FILE="/tmp/sway-opacity-$ID"
if [ -f "$STATE_FILE" ]; then
    swaymsg "[con_id=$ID] opacity 1" >/dev/null
    rm -f "$STATE_FILE"
    notify-send "Window" "Transparency: 100%"
else
    swaymsg "[con_id=$ID] opacity 0.9" >/dev/null
    touch "$STATE_FILE"
    notify-send "Window" "Transparency: 90%"
fi
