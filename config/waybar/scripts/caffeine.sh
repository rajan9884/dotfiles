#!/usr/bin/env bash
# Waybar custom/caffeine module — caffeine-like sleep inhibitor.
# Single source of truth is ~/.config/hypr/scripts/idle-toggle.sh
# (shared with the SUPER+CTRL+I keybind), this is just a thin wrapper
# so Waybar exec/on-click paths stay conventional.
set -euo pipefail

TOGGLE="$HOME/.config/hypr/scripts/idle-toggle.sh"

case "${1:-}" in
	toggle | on | off | enable | disable)
		exec "$TOGGLE" "$1"
		;;
	status | "")
		exec "$TOGGLE" status
		;;
	*)
		echo "Usage: $(basename "$0") [toggle|on|off|status]" >&2
		exit 1
		;;
esac
