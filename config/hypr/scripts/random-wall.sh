#!/usr/bin/env bash

# ──────────────────────────────────────────────
#   Random Wallpaper Switcher
#   Picks from both the theme-organized wallpapers and
#   the optimized library for maximum color variety.
# ──────────────────────────────────────────────

WALL_DIRS=("$HOME/.local/share/wallpapers" "$HOME/Pictures/Wallpapers/optimized")
SCRIPT="$HOME/.config/hypr/scripts/swww-all.sh"

# Select a random image from all wallpaper directories
SELECTED_WALL=$(find "${WALL_DIRS[@]}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)

if [ -n "$SELECTED_WALL" ]; then
    "$SCRIPT" "$SELECTED_WALL"
else
    notify-send "Wallpaper Error" "No images found in wallpaper directories" -u critical
fi
