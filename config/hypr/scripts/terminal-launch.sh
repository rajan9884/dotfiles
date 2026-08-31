#!/usr/bin/env bash
# Open a new terminal window in the working directory of the currently focused
# window, so SUPER+Return lands where you were instead of $HOME.
#
# /proc/<window>/cwd only reflects where a terminal was launched, not where its
# shell has cd'd — so for terminals we read the cwd of the deepest shell child.
# For non-terminal apps we use the window's own cwd. Final fallback: $HOME.
set -eo pipefail

dir="$HOME"

pid=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null)
if [[ -n "$pid" ]] && [[ "$pid" =~ ^[0-9]+$ ]]; then
	declare -A seen=()
	queue=("$pid")
	while ((${#queue[@]})); do
		cur=${queue[0]}
		queue=("${queue[@]:1}")
		[[ -n "${seen[$cur]:-}" ]] && continue
		seen[$cur]=1
		for c in $(pgrep -P "$cur" 2>/dev/null || true); do
			queue+=("$c")
			comm=$(ps -o comm= -p "$c" 2>/dev/null || true)
			case "$comm" in
				zsh | bash | fish)
					cwd=$(readlink -f "/proc/$c/cwd" 2>/dev/null || true)
					if [[ -n "$cwd" && -d "$cwd" ]]; then
						dir="$cwd"
					fi
					;;
			esac
		done
	done

	if [[ "$dir" == "$HOME" ]]; then
		cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)
		if [[ -n "$cwd" && -d "$cwd" ]]; then
			dir="$cwd"
		fi
	fi
fi

exec kitty --directory "$dir"
