#!/bin/bash
# ──────────────────────────────────────────────
#   Brightness OSD via swayosd-server (compact native OSD).
#   Scoped to backlight devices so keyboard LEDs are untouched.
# ──────────────────────────────────────────────
ACTION="$1"
DEV="*backlight*"

case "$ACTION" in
    up) swayosd-client --brightness --device "$DEV" raise ;;
    down) swayosd-client --brightness --device "$DEV" lower ;;
    max) swayosd-client --brightness --device "$DEV" 100 ;;
    min) swayosd-client --brightness --device "$DEV" 1 ;;
esac
