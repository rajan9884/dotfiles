#!/usr/bin/env bash
# Enable / disable / toggle the touchpad (uses Hyprland's input option).
set -euo pipefail

ACTION="${1:-toggle}"
CUR=$(hyprctl getoption input:touchpad:enabled -j 2>/dev/null | jq -r '.int')

case "$ACTION" in
	on)   [ "$CUR" != "1" ] && hyprctl keyword input:touchpad:enabled 1 >/dev/null ;;
	off)  [ "$CUR" != "0" ] && hyprctl keyword input:touchpad:enabled 0 >/dev/null ;;
	toggle) hyprctl keyword input:touchpad:enabled "$((1 - CUR))" >/dev/null ;;
esac

FINAL=$(hyprctl getoption input:touchpad:enabled -j | jq -r '.int')
[ "$FINAL" = "1" ] && MSG="enabled" || MSG="disabled"
notify-send "Touchpad" "$MSG"