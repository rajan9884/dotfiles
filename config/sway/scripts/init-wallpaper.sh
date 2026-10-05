#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Ensure wallpaper is displayed on sway start
#   Deterministic clean start: any stale, frozen, or duplicate
#   awww-daemon (query can report an image while pixels are stuck,
#   and two daemons fight over the layer surface) is replaced with
#   exactly one fresh daemon, then the current wallpaper is applied
#   through the full sway-wall.sh switch so image and theme agree.
# ──────────────────────────────────────────────
set -u
WALL_DIRS=()
for _d in "$HOME/.local/share/wallpapers" "$HOME/Pictures/Wallpapers"; do
    [ -d "$_d" ] && WALL_DIRS+=("$_d")
done

# Exactly one daemon: clear leftovers first (a second daemon started
# while the login one is still coming up ends up painting over/under
# it with a stale frame).
pkill -x awww-daemon >/dev/null 2>&1 || true
sleep 0.3
setsid awww-daemon >/dev/null 2>&1 < /dev/null &
for _ in $(seq 1 50); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
done

if [ -s "$HOME/.cache/current-wallpaper" ] && [ -f "$(<"$HOME/.cache/current-wallpaper")" ]; then
    exec "$HOME/.config/sway/scripts/sway-wall.sh" "$(<"$HOME/.cache/current-wallpaper")"
fi
WALL=""
if ((${#WALL_DIRS[@]})); then
    WALL=$(find "${WALL_DIRS[@]}" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n 1 || true)
fi
if [ -n "${WALL:-}" ]; then
    exec "$HOME/.config/sway/scripts/sway-wall.sh" "$WALL"
else
    exec "$HOME/.config/sway/scripts/random-wall.sh"
fi
