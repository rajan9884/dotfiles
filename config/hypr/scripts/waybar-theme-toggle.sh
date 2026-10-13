#!/usr/bin/env bash
# Toggle waybar style between noro and floating-bar (Hyprland port).
# Unlike the sway version, the CONFIG stays pinned to config-hypr.jsonc:
# floating-bar's config.jsonc uses sway/workspaces, which is dead on Hyprland.
# Only style.css is swapped, then waybar is relaunched via waybar-launch.sh.
set -euo pipefail

STYLE_LINK="$HOME/.config/waybar/style.css"
CONFIG="$HOME/.config/waybar/config-hypr.jsonc"
THEMES=("noro" "floating-bar")

CURRENT="$(basename "$(dirname "$(readlink "$STYLE_LINK")")")"
INDEX=0
for i in "${!THEMES[@]}"; do
    if [[ "${THEMES[i]}" == "$CURRENT" ]]; then
        INDEX=$i
        break
    fi
done

NEXT_INDEX=$(( (INDEX + 1) % ${#THEMES[@]} ))
NEXT="${THEMES[NEXT_INDEX]}"

ln -sf "themes/$NEXT/style.css" "$STYLE_LINK"

pkill -x waybar 2>/dev/null || true; pkill -x .waybar-wrapped 2>/dev/null || true
sleep 0.3
"$HOME/.config/hypr/scripts/waybar-launch.sh"

notify-send "  Waybar Updated" "Style: $NEXT applied" -i preferences-desktop-theme
