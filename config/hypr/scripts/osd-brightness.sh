#!/bin/bash
# ──────────────────────────────────────────────
#   Brightness OSD via swayosd-server (compact native OSD).
#   brightnessctl makes the change (exact 5% steps, default
#   backlight device); swayosd-client with +0 only displays
#   the OSD at the new level. (swayosd's own ±N math is
#   percent-based and asymmetric — not trustworthy here.)
# ──────────────────────────────────────────────
ACTION="$1"
DEV="*backlight*"

case "$ACTION" in
    up) brightnessctl set 5%+ >/dev/null ;;
    down) brightnessctl set 5%- >/dev/null ;;
    max) brightnessctl set 100% >/dev/null ;;
    min) brightnessctl set 1% >/dev/null ;;
esac

swayosd-client --brightness=+0 --device "$DEV"
