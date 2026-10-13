#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   animations-toggle — flip Hyprland animations live
#   Bound to SUPER+SHIFT+A. Overrides the look.lua
#   master switch at runtime (resets on reload).
# ──────────────────────────────────────────────
set -euo pipefail

cur="$(hyprctl getoption animations:enabled 2>/dev/null | awk '/int:/ {print $2}')"
if [ "$cur" = 1 ]; then
    hyprctl keyword animations:enabled 0 >/dev/null
    notify-send "Animations" "Disabled"
else
    hyprctl keyword animations:enabled 1 >/dev/null
    notify-send "Animations" "Enabled"
fi
