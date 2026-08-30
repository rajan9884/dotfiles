#!/usr/bin/env bash
# Step the focused monitor's scale up or down by 0.25 (clamped 0.5–3.0).
set -euo pipefail

DIR="${1:-up}"
MON=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
SCALE=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .scale')

NEW=$(awk -v s="$SCALE" -v d="$DIR" 'BEGIN{ if (d == "up") printf "%.3f", s + 0.25; else printf "%.3f", s - 0.25 }')

if awk -v n="$NEW" 'BEGIN{ exit !(n >= 0.5 && n <= 3.0) }'; then
	hyprctl keyword "monitor $MON, auto, auto, $NEW" >/dev/null
	notify-send "Scaling" "$MON @ ${NEW}x"
else
	notify-send "Scaling" "Out of range"
	exit 1
fi