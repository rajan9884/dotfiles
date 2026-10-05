#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   fx-toggle — flip swayfx eye-candy live (port of animations-toggle.sh)
#   Bound to SUPER+SHIFT+A. Toggles shadows + dimming.
#   (Blur stays off systemwide — transparency is app opacity, not blur.)
# ──────────────────────────────────────────────
set -euo pipefail
STATE_FILE="/tmp/swayfx-off"
if [ -f "$STATE_FILE" ]; then
    swaymsg shadows enable >/dev/null
    swaymsg default_dim_inactive 0.12 >/dev/null
    rm -f "$STATE_FILE"
    notify-send "Effects" "Enabled (shadows + dimming, blur stays off)"
else
    swaymsg shadows disable >/dev/null
    swaymsg default_dim_inactive 0.0 >/dev/null
    touch "$STATE_FILE"
    notify-send "Effects" "Disabled"
fi
