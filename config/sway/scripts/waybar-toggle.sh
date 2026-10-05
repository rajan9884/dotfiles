#!/usr/bin/env bash
# Toggle waybar visibility (port — same SIGUSR1 mechanism as Hyprland bind).
set -euo pipefail
if pgrep -x waybar >/dev/null 2>&1 || pgrep -x .waybar-wrapped >/dev/null 2>&1; then
    pkill -USR1 -x waybar 2>/dev/null
    pkill -USR1 -x .waybar-wrapped 2>/dev/null
else
    setsid waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css >/dev/null 2>&1 < /dev/null &
fi
