#!/usr/bin/env bash
# Toggle the swayidle idle-locking daemon on / off (port of idle-toggle.sh).
# Refreshes the waybar caffeine glyph (custom/idle, signal 13).
set -euo pipefail
refresh_bar() { pkill -RTMIN+13 waybar 2>/dev/null || true; }
if pgrep -x swayidle >/dev/null; then
    pkill -x swayidle
    notify-send "Idle" "Idle lock disabled"
else
    swayidle -w -C ~/.config/sway/swayidle.conf &
    disown
    notify-send "Idle" "Idle lock enabled"
fi
refresh_bar
