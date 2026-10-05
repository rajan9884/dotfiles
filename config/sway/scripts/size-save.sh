#!/usr/bin/env bash
# Save / restore the focused window's size (port of window-size-save.sh).
# Usage: size-save.sh save|restore
set -euo pipefail
ACTION="${1:-restore}"
STATE_FILE="$HOME/.cache/sway-window-size"
if [ "$ACTION" = "save" ]; then
    RECT=$(swaymsg -t get_tree 2>/dev/null | jq -c '.. | objects | select(.focused == true) | .rect | "\(.width)x\(.height)"' 2>/dev/null | head -n 1 | tr -d '"')
    [ -n "${RECT:-}" ] && [ "$RECT" != "null" ] && { printf '%s' "$RECT" > "$STATE_FILE"; notify-send "Window" "Size saved: $RECT"; }
else
    [ -s "$STATE_FILE" ] || { notify-send "Window" "No saved size" -u low; exit 0; }
    SIZE=$(cat "$STATE_FILE")
    W=${SIZE%x*}; H=${SIZE#*x}
    swaymsg floating enable >/dev/null
    swaymsg resize set "$W" "$H" >/dev/null
    notify-send "Window" "Size restored: $SIZE"
fi
