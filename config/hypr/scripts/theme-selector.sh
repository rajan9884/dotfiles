#!/usr/bin/env bash

WALLPAPER_DIRS=()
for d in "$HOME/.local/share/wallpapers" "$HOME/Pictures/Wallpapers/optimized"; do
    [ -d "$d" ] && WALLPAPER_DIRS+=("$d")
done

((${#WALLPAPER_DIRS[@]})) || {
    notify-send "Wallpaper Error" "No wallpaper directories found" -u critical
    exit 1
}

# List images from all directories, pass to rofi, and get selection
SELECTED=$(find "${WALLPAPER_DIRS[@]}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) -printf "%p\n" 2>/dev/null | sort | rofi -dmenu -i -p "Select Wallpaper" -theme ~/.config/rofi/theme.rasi)

if [ -n "$SELECTED" ]; then
    # Call the existing swww-all.sh script which runs matugen for colors
    ~/.config/hypr/scripts/swww-all.sh "$SELECTED"
fi
