#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Caffeine / idle-lock status for Waybar (custom/idle)
#   coffee cup = caffeine ON (swayidle killed, no auto-lock/suspend)
#   dimmed cup = normal (swayidle running, idle lock enabled)
#   Click toggles via sway/scripts/idle-toggle.sh (also Super+Ctrl+i).
# ──────────────────────────────────────────────
set -euo pipefail

ICON_ON=$'\U000F0176'   # nf-md-coffee (solid cup = caffeine ON)
ICON_OFF=$'\U000F06CA'  # nf-md-coffee_outline (idle lock enabled)
# Codepoints verified against the installed JetBrainsMono Nerd Font build
# (MDI mapping shifts between Nerd Fonts releases — do not assume F0366).

if pgrep -x swayidle >/dev/null 2>&1; then
    jq -cn --arg i "$ICON_OFF" \
        '{text:$i, tooltip:"Idle lock on (click for caffeine, Super+Ctrl+i)", class:"idle-on"}'
else
    jq -cn --arg i "$ICON_ON" \
        '{text:$i, tooltip:"Caffeine on — idle lock off (click to re-enable)", class:"inhibited"}'
fi
