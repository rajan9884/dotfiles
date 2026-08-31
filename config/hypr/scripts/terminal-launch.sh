#!/usr/bin/env bash
# Open a new terminal window in the working directory of the currently focused
# window, so SUPER+Return lands where you were instead of $HOME. Falls back to
# $HOME when nothing is focused or the focused window's cwd is unresolvable.
set -euo pipefail

dir="$HOME"

pid=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null)
if [[ -n "$pid" ]] && [[ "$pid" =~ ^[0-9]+$ ]]; then
	cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)
	if [[ -n "$cwd" ]] && [[ -d "$cwd" ]]; then
		dir="$cwd"
	fi
fi

exec kitty --directory "$dir"
