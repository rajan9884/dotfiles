#!/usr/bin/env bash
# Waybar module for screen recording (wf-recorder) — start/stop toggle + state.
set -euo pipefail

if [[ "${1:-}" == "toggle" ]]; then
	exec ~/.config/hypr/scripts/screen-record.sh
fi

if pgrep -x wf-recorder >/dev/null; then
	printf '{"text":"\\uf04d","class":"recording","tooltip":"Stop screen recording"}\n'
else
	exit 0
fi