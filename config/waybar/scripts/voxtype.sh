#!/usr/bin/env bash
# Waybar module for voxtype dictation — only visible while recording/transcribing.
set -euo pipefail

STATUS=$(voxtype status --format json --icon-theme nerd-font 2>/dev/null) || exit 0

case "$STATUS" in
	*'"class":"recording"'*|*'"class": "recording"'*|\
	*'"class":"transcribing"'*|*'"class": "transcribing"'*)
		printf '%s\n' "$STATUS"
		;;
	*)
		exit 0
		;;
esac
