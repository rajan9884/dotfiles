#!/usr/bin/env bash
# Toggle window gaps between zero and the theme defaults (in/out).
set -euo pipefail

IN=$(hyprctl getoption general:gaps_in -j | jq -r '.int')
OUT=$(hyprctl getoption general:gaps_out -j | jq -r '.int')

if [ "$IN" = "0" ] && [ "$OUT" = "0" ]; then
	hyprctl keyword general:gaps_in 6 >/dev/null
	hyprctl keyword general:gaps_out 12 >/dev/null
	notify-send "Window" "Gaps restored"
else
	hyprctl keyword general:gaps_in 0 >/dev/null
	hyprctl keyword general:gaps_out 0 >/dev/null
	notify-send "Window" "Gaps removed"
fi