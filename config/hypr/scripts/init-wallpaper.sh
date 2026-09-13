#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Ensure wallpaper is displayed on Hyprland start
# ──────────────────────────────────────────────

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

# If still not displaying an image, restore from ~/.cache/current-wallpaper or theme
if ! awww query 2>/dev/null | grep -q "image:"; then
    if [ -s "$HOME/.cache/current-wallpaper" ] && [ -f "$(<"$HOME/.cache/current-wallpaper")" ]; then
        "$HOME/.config/hypr/scripts/swww-all.sh" "$(<"$HOME/.cache/current-wallpaper")"
    else
        ACTIVE_THEME=$(cat "$HOME/.config/hypr/.active-theme" 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
        [ -z "$ACTIVE_THEME" ] && ACTIVE_THEME="noro"
        WALL=$(find "$HOME/.local/share/wallpapers/$ACTIVE_THEME" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | head -n 1)
        if [ -n "$WALL" ]; then
            "$HOME/.config/hypr/scripts/swww-all.sh" "$WALL"
        else
            "$HOME/.config/hypr/scripts/random-wall.sh"
        fi
    fi
fi
