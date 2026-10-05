#!/usr/bin/env bash
# Step the focused output's scale up or down by 0.25 (clamped 0.5–3.0).
# Port of monitor-scaling.sh (swaymsg instead of hyprctl).
set -euo pipefail
DIR="${1:-up}"
OUT=$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -n 1)
SCALE=$(swaymsg -t get_outputs 2>/dev/null | jq -r --arg o "$OUT" '.[] | select(.name == $o) | .scale')
NEW=$(awk -v s="$SCALE" -v d="$DIR" 'BEGIN{ if (d == "up") printf "%.3f", s + 0.25; else printf "%.3f", s - 0.25 }')
if awk -v n="$NEW" 'BEGIN{ exit !(n >= 0.5 && n <= 3.0) }'; then
    swaymsg output "$OUT" scale "$NEW" >/dev/null
    notify-send "Scaling" "$OUT @ ${NEW}x"
else
    notify-send "Scaling" "Out of range"
    exit 1
fi
