#!/usr/bin/env bash

# ──────────────────────────────────────────────
#   Random Wallpaper Switcher
#   Picks from the restored optimized library
#   (~/dotfiles/wallpapers/optimized, 413 images).
# ──────────────────────────────────────────────

WALL_DIRS=("$HOME/dotfiles/wallpapers/optimized")
SCRIPT="$HOME/.config/hypr/scripts/swww-all.sh"

# Select a random image from all wallpaper directories
SELECTED_WALL=$(find "${WALL_DIRS[@]}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)

if [ -n "$SELECTED_WALL" ]; then
    "$SCRIPT" "$SELECTED_WALL"
else
    notify-send "Wallpaper Error" "No images found in wallpaper directories" -u critical
fi
