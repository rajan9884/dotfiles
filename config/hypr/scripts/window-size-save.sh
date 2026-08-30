#!/usr/bin/env bash
# Remember the active window's size and restore it later (e.g. after resizing).
set -euo pipefail

CACHE="$HOME/.cache/hypr-window-size"

case "${1:-save}" in
	save)
		hyprctl activewindow -j | jq -r '"\(.size[0]) \(.size[1])"' > "$CACHE"
		notify-send "Window" "Size saved"
		;;
	restore)
		read -r W H < "$CACHE" 2>/dev/null || { notify-send "Window" "No saved size"; exit 1; }
		read -r CW CH < <(hyprctl activewindow -j | jq -r '"\(.size[0]) \(.size[1])"')
		hyprctl eval "hl.dispatch(hl.dsp.window.resize({ x=$((W - CW)), y=$((H - CH)), relative=true }))" >/dev/null
		notify-send "Window" "Size restored ${W}x${H}"
		;;
	*) exit 1 ;;
esac