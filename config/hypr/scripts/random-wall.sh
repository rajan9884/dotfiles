#!/usr/bin/env bash

# ──────────────────────────────────────────────
#   Random Wallpaper Switcher
#   Picks from the optimized library
#   (~/.local/share/wallpapers/optimized, 413 images).
# ──────────────────────────────────────────────

WALL_DIRS=("$HOME/.local/share/wallpapers")
[ -d "$HOME/Pictures/Wallpapers/optimized" ] && WALL_DIRS+=("$HOME/Pictures/Wallpapers/optimized")
[ -d "$HOME/.local/share/wallpapers/optimized" ] && WALL_DIRS+=("$HOME/.local/share/wallpapers/optimized")
SCRIPT="$HOME/.config/hypr/scripts/swww-all.sh"

# Select a random image from all wallpaper directories
SELECTED_WALL=$(find "${WALL_DIRS[@]}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)

if [ -n "$SELECTED_WALL" ]; then
    "$SCRIPT" "$SELECTED_WALL"
else
    notify-send "Wallpaper Error" "No images found in wallpaper directories" -u critical
fi
