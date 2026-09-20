#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Ensure wallpaper is displayed on Hyprland start
#   (single flat library: ~/.local/share/wallpapers/Wallpaper)
# ──────────────────────────────────────────────

WALL_DIR="$HOME/.local/share/wallpapers/Wallpaper"

# Wait for awww-daemon socket to be ready (up to 3s)
for i in {1..30}; do
    if awww query >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# If an image is already displaying, we're done
if awww query 2>/dev/null | grep -q "image:"; then
    exit 0
fi

# Try restoring cached wallpaper
awww restore 2>/dev/null

# If still not displaying an image, restore from ~/.cache/current-wallpaper
# or fall back to the first wallpaper in the library.
if ! awww query 2>/dev/null | grep -q "image:"; then
    if [ -s "$HOME/.cache/current-wallpaper" ] && [ -f "$(<"$HOME/.cache/current-wallpaper")" ]; then
        "$HOME/.config/hypr/scripts/swww-all.sh" "$(<"$HOME/.cache/current-wallpaper")"
    else
        WALL=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n 1)
        if [ -n "$WALL" ]; then
            "$HOME/.config/hypr/scripts/swww-all.sh" "$WALL"
        else
            "$HOME/.config/hypr/scripts/random-wall.sh"
        fi
    fi
fi
