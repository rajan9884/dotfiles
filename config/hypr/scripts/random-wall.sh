#!/usr/bin/env bash

# ──────────────────────────────────────────────
#   Random Wallpaper Switcher
#   Picks from the single flat library
#   (~/.local/share/wallpapers/Wallpaper).
# ──────────────────────────────────────────────

WALL_DIR="$HOME/.local/share/wallpapers/Wallpaper"
SCRIPT="$HOME/.config/hypr/scripts/swww-all.sh"

# Select a random image from the wallpaper directory
SELECTED_WALL=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)

if [ -n "$SELECTED_WALL" ]; then
    "$SCRIPT" "$SELECTED_WALL"
else
    notify-send "Wallpaper Error" "No images found in $WALL_DIR" -u critical
fi
