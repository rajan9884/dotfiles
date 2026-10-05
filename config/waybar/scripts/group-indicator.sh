#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Layout indicator for Waybar (sway — Void port of group-indicator)
#   Shows 󰕭 when the focused container is tabbed/stacked.
# ──────────────────────────────────────────────
set -euo pipefail
layout="$(swaymsg -t get_tree 2>/dev/null | jq -r '.. | objects | select(.focused == true) | .layout // empty' 2>/dev/null | head -n 1)"
case "$layout" in
    tabbed|stacked)
        printf '{"text":"󰕭","tooltip":"Container layout: %s","class":"grouped"}\n' "$layout" ;;
    *)
        printf '{"text":"","tooltip":"No grouped layout","class":"empty"}\n' ;;
esac
