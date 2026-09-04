#!/bin/bash
# ──────────────────────────────────────────────
#   Keyboard-backlight OSD via swayosd-server.
#   `cycle` wraps max → off (brightnessctl has no wrap for kbd).
# ──────────────────────────────────────────────
ACTION="$1"
DEV="*kbd*"

case "$ACTION" in
    up) brightnessctl --device="$DEV" set 1+ >/dev/null 2>&1 ;;
    down) brightnessctl --device="$DEV" set 1- >/dev/null 2>&1 ;;
    cycle)
        LEVEL=$(brightnessctl --device="$DEV" get 2>/dev/null)
        MAX=$(brightnessctl --device="$DEV" max 2>/dev/null)
        if [[ "$LEVEL" =~ ^[0-9]+$ && "$MAX" =~ ^[0-9]+$ ]] && ((MAX > 0)) && ((LEVEL >= MAX)); then
            brightnessctl --device="$DEV" set 0 >/dev/null 2>&1
        else
            brightnessctl --device="$DEV" set 1+ >/dev/null 2>&1
        fi
        ;;
esac

swayosd-client --brightness=+0 --device "$DEV" 2>/dev/null
