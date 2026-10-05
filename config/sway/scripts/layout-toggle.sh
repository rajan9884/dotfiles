#!/usr/bin/env bash
# Toggle the tiling layout orientation (port of workspace-layout-toggle.sh).
# sway has no dwindle/master: `split toggle` flips h/v orientation.
set -euo pipefail
swaymsg layout toggle split >/dev/null
notify-send "Layout" "Split orientation toggled"
