#!/bin/bash
# ──────────────────────────────────────────────
#   Brightness OSD via swayosd-server (compact native OSD).
#   brightnessctl makes the change (exact 5% steps, default
#   backlight device); swayosd-client renders icon + bar +
#   percentage text. (swayosd's own ±N math is percent-based
#   and asymmetric — not trustworthy here.)
# ──────────────────────────────────────────────
ACTION="$1"

case "$ACTION" in
    up) brightnessctl set 5%+ >/dev/null ;;
    down) brightnessctl set 5%- >/dev/null ;;
    max) brightnessctl set 100% >/dev/null ;;
    min) brightnessctl set 1% >/dev/null ;;
esac

INFO=$(brightnessctl -m | head -1)
CUR=$(printf '%s' "$INFO" | cut -d, -f3)
MAXV=$(printf '%s' "$INFO" | cut -d, -f5)
PCT=$(printf '%s' "$INFO" | cut -d, -f4 | tr -d '%')
FRAC=$(awk -v c="$CUR" -v m="$MAXV" 'BEGIN{ printf "%.2f", c/m }')

swayosd-client --custom-icon display-brightness --custom-progress "$FRAC" --custom-progress-text "$PCT%"
