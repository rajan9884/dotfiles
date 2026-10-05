#!/usr/bin/env bash
# Close all windows (sway/Void port of window-close-all — no kill -9).
set -euo pipefail
swaymsg -t get_tree 2>/dev/null | jq -r '.. | objects | select(.type == "con" and .pid != null and .focused != null) | .id' 2>/dev/null | while read -r id; do
    [ -n "$id" ] && swaymsg "[con_id=$id] kill" >/dev/null 2>&1 || true
done
notify-send "Windows" "All windows closed"
