#!/bin/bash
# ──────────────────────────────────────────────
#   Keyboard-backlight OSD via swayosd-server.
#   `cycle` wraps max → off (brightnessctl has no wrap for kbd).
# ──────────────────────────────────────────────
ACTION="$1"
DEV="*kbd*"

case "$ACTION" in
    up) swayosd-client --brightness --device "$DEV" raise ;;
    down) swayosd-client --brightness --device "$DEV" lower ;;
    cycle)
        LEVEL=$(brightnessctl --device="$DEV" get 2>/dev/null)
        MAX=$(brightnessctl --device="$DEV" max 2>/dev/null)
        if [[ -n $LEVEL && -n $MAX && "$MAX" -gt 0 ]] && ((LEVEL >= MAX)); then
            swayosd-client --brightness --device "$DEV" 0
        else
            swayosd-client --brightness --device "$DEV" raise
        fi
        ;;
esac
