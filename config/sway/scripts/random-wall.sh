#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Random Wallpaper Switcher (sway/Void port)
#   Picks from ~/.local/share/wallpapers (canonical) and
#   ~/Pictures/Wallpapers (legacy); either directory may be empty.
# ──────────────────────────────────────────────
set -euo pipefail
WALL_DIRS=()
for _d in "$HOME/.local/share/wallpapers" "$HOME/Pictures/Wallpapers"; do
    [ -d "$_d" ] && WALL_DIRS+=("$_d")
done
SCRIPT="$HOME/.config/sway/scripts/sway-wall.sh"
SELECTED_WALL=""
if ((${#WALL_DIRS[@]})); then
    # Exclude the current wallpaper so Super+R never appears to do nothing
    # by re-picking the same image (1/320 is rare but reported as "broken").
    CURRENT="$(cat "$HOME/.cache/current-wallpaper" 2>/dev/null || true)"
    CANDIDATES=$(find "${WALL_DIRS[@]}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null || true)
    if [ -n "$CURRENT" ]; then
        FILTERED=$(printf '%s\n' "$CANDIDATES" | grep -Fxv "$CURRENT" || true)
        [ -n "$FILTERED" ] && CANDIDATES="$FILTERED"
    fi
    SELECTED_WALL=$(printf '%s\n' "$CANDIDATES" | shuf -n 1 || true)
fi
if [ -n "${SELECTED_WALL:-}" ]; then
    echo "$(date '+%F %T') random-wall: $SELECTED_WALL" >> "$HOME/.cache/sway-wall.log"
    exec "$SCRIPT" "$SELECTED_WALL"
else
    echo "$(date '+%F %T') random-wall: no images found" >> "$HOME/.cache/sway-wall.log"
    notify-send "Wallpaper Error" "No images found in ${WALL_DIRS[*]:-~/.local/share/wallpapers}" -u critical
fi
