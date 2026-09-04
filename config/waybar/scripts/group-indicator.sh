#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Group indicator for Waybar (custom/group)
#   Shows 󰕭 N when the focused window is in a tab-group,
#   so SUPER+G groups are discoverable. Emits Waybar JSON.
# ──────────────────────────────────────────────
set -euo pipefail

info="$(hyprctl activewindow -j 2>/dev/null || echo '{}')"
grouped="$(printf '%s' "$info" | jq -r '.grouped | length' 2>/dev/null || echo 0)"

if [[ "$grouped" =~ ^[0-9]+$ ]] && ((grouped > 0)); then
    printf '{"text":"󰕭 %s","tooltip":"Window group: %s windows (SUPER+ALT+TAB to cycle)","class":"grouped"}\n' "$grouped" "$grouped"
else
    printf '{"text":"","tooltip":"No window group","class":"empty"}\n'
fi
