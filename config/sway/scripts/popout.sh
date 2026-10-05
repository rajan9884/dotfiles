#!/usr/bin/env bash
# Pop window out: float + pin on top + center (port of window-popout.sh).
set -euo pipefail
swaymsg floating enable >/dev/null
swaymsg sticky enable >/dev/null
swaymsg move position center >/dev/null
swaymsg resize set 1200 800 >/dev/null
notify-send "Window" "Popped out (floating + pinned)"
