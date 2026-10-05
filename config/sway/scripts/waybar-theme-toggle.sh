#!/usr/bin/env bash
# Toggle waybar theme between noro and floating-bar.
set -euo pipefail

THEMES_DIR="$HOME/.config/waybar/themes"
CONFIG_LINK="$HOME/.config/waybar/config.jsonc"
STYLE_LINK="$HOME/.config/waybar/style.css"

# List of themes in order
THEMES=("noro" "floating-bar")

# Get current theme
CURRENT="$(basename "$(dirname "$(readlink "$CONFIG_LINK")")")"

# Find index of current theme
INDEX=0
for i in "${!THEMES[@]}"; do
    if [[ "${THEMES[i]}" == "$CURRENT" ]]; then
        INDEX=$i
        break
    fi
done

# Calculate next index (wrap around)
NEXT_INDEX=$(( (INDEX + 1) % ${#THEMES[@]} ))
NEXT="${THEMES[NEXT_INDEX]}"

# Update symlinks
ln -sf "$THEMES_DIR/$NEXT/config.jsonc" "$CONFIG_LINK"
ln -sf "$THEMES_DIR/$NEXT/style.css" "$STYLE_LINK"

# Restart waybar
pkill -x waybar 2>/dev/null || true; pkill -x .waybar-wrapped 2>/dev/null || true
sleep 0.3
setsid waybar -c "$CONFIG_LINK" -s "$STYLE_LINK" >/dev/null 2>&1 < /dev/null &

notify-send "  Waybar Updated" "Style: $NEXT applied" -i preferences-desktop-theme