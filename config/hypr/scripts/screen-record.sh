#!/usr/bin/env bash
# Start / stop an wf-recorder screen recording (region picker on start).
set -euo pipefail

if pgrep -x wf-recorder >/dev/null; then
	pkill -x wf-recorder
	notify-send "Recording" "Stopped"
	exit 0
fi

DIR="$HOME/Videos"
mkdir -p "$DIR"
FILE="$DIR/rec-$(date +%Y-%m-%d_%H-%M-%S).mp4"

AREA=$(slurp) || exit 1
wf-recorder -g "$AREA" -f "$FILE" >/dev/null 2>&1 &
notify-send -t 4000 "Recording" "Started → $(basename "$FILE")"