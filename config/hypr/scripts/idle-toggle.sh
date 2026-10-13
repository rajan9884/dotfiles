#!/usr/bin/env bash
# Caffeine toggle for Hyprland + hypridle (Void: no systemd-inhibit).
# Caffeine ON  = hypridle stopped (no dim/lock/dpms/suspend).
# Caffeine OFF = hypridle restarted.
# Usage: idle-toggle.sh [toggle|on|off|status]
set -euo pipefail
refresh_bar() {
    pkill -RTMIN+13 waybar 2>/dev/null || true
    pkill -RTMIN+8 waybar 2>/dev/null || true
}
status() {
    if pgrep -x hypridle >/dev/null 2>&1; then
        jq -cn '{text:"󰶐", tooltip:"Idle lock on (click for caffeine, Super+Ctrl+i)", class:"idle-on"}'
    else
        jq -cn '{text:"󰅶", tooltip:"Caffeine on — idle lock off (click to re-enable)", class:"inhibited"}'
    fi
}
caffeine_on() { pkill -x hypridle 2>/dev/null || true; notify-send "Idle" "Idle lock disabled"; refresh_bar; }
caffeine_off() {
    if ! pgrep -x hypridle >/dev/null; then setsid hypridle >/dev/null 2>&1 < /dev/null & disown; fi
    notify-send "Idle" "Idle lock enabled"; refresh_bar
}
case "${1:-toggle}" in
    on|enable) caffeine_on ;;
    off|disable) caffeine_off ;;
    status) status ;;
    toggle|"") if pgrep -x hypridle >/dev/null; then caffeine_on; else caffeine_off; fi ;;
    *) echo "Usage: $(basename "$0") [toggle|on|off|status]" >&2; exit 1 ;;
esac
