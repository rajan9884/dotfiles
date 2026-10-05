#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   mako do-not-disturb toggle (replaces swaync DND)
#   Usage: mako-dnd.sh [toggle|on|off|state]
#   state → prints "on" or "off" (for control-center.sh)
# ──────────────────────────────────────────────
set -euo pipefail

is_dnd() { makoctl mode 2>/dev/null | grep -qx 'do-not-disturb'; }
refresh_bar() { pkill -RTMIN+15 waybar 2>/dev/null || true; }

case "${1:-toggle}" in
    on)  makoctl mode -a do-not-disturb 2>/dev/null || true; refresh_bar ;;
    off) makoctl mode -r do-not-disturb 2>/dev/null || true; refresh_bar ;;
    state) is_dnd && printf 'On\n' || printf 'Off\n' ;;
    *) if is_dnd; then makoctl mode -r do-not-disturb 2>/dev/null || true
       else makoctl mode -a do-not-disturb 2>/dev/null || true; fi
       refresh_bar ;;
esac
