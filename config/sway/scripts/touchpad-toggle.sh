#!/usr/bin/env bash
# Enable / disable / toggle the touchpad (sway/Void port — swaymsg input).
set -euo pipefail
ACTION="${1:-toggle}"
TP_IDENT=$(swaymsg -t get_inputs 2>/dev/null | jq -r '.[] | select(.type == "touchpad") | .identifier' | head -n 1)
[ -z "${TP_IDENT:-}" ] && { notify-send "Touchpad" "No touchpad found" -u low; exit 1; }
CUR=$(swaymsg -t get_inputs 2>/dev/null | jq -r --arg id "$TP_IDENT" '.[] | select(.identifier == $id) | .libinput.send_events // "enabled"')
case "$ACTION" in
    on)  swaymsg input "$TP_IDENT" events enabled >/dev/null ;;
    off) swaymsg input "$TP_IDENT" events disabled >/dev/null ;;
    toggle)
        if [ "$CUR" = "disabled" ]; then swaymsg input "$TP_IDENT" events enabled >/dev/null
        else swaymsg input "$TP_IDENT" events disabled >/dev/null; fi ;;
esac
FINAL=$(swaymsg -t get_inputs 2>/dev/null | jq -r --arg id "$TP_IDENT" '.[] | select(.identifier == $id) | .libinput.send_events // "enabled"')
[ "$FINAL" = "disabled" ] && MSG="disabled" || MSG="enabled"
notify-send "Touchpad" "$MSG"
