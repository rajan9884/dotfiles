#!/usr/bin/env bash
# Toggle active window opacity between 100% and 90% (per-window setprop).
set -euo pipefail

CUR=$(hyprctl getprop active opacity 2>/dev/null || echo 1)
if awk -v c="$CUR" 'BEGIN{exit !(c >= 0.999)}'; then
	NEW=0.9
else
	NEW=1.0
fi

for P in opacity opacity_inactive opacity_fullscreen; do
	hyprctl eval "hl.dispatch(hl.dsp.window.set_prop({ prop='${P}_override', value=1, window='active' }))" >/dev/null
	hyprctl eval "hl.dispatch(hl.dsp.window.set_prop({ prop='${P}', value=$NEW, window='active' }))" >/dev/null
done

[ "$NEW" = "1.0" ] && MSG="100%" || MSG="90%"
notify-send "Window" "Transparency: $MSG"