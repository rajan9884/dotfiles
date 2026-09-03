#!/usr/bin/env bash

# ──────────────────────────────────────────────
#   Dynamic Theme Switcher (Awww + Matugen)
# ──────────────────────────────────────────────

WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
    echo "Usage: ./swww-all.sh /path/to/wallpaper.jpg"
    exit 1
fi

# 1. Set Wallpaper
# Using awww-daemon
awww img "$WALLPAPER" --transition-type grow --transition-pos "$(hyprctl cursorpos)" --transition-duration 1.5

# 2. Extract colors with Matugen
# This updates colors for Waybar, Rofi, Kitty, Hyprland, etc.
matugen image "$WALLPAPER" -c ~/.config/matugen/config.toml --source-color-index 0

# 3. Reload Waybar
# SIGUSR2 tells waybar to reload its CSS
killall -SIGUSR2 waybar

# 4. Reload Kitty
# SIGUSR1 tells kitty to reload its configuration
killall -SIGUSR1 kitty

# 5. Reload Hyprland
# Sending a SIGUSR1 to hyprland often forces a reload of sourced files
# or we can use hyprctl reload
hyprctl reload

# 6. Reload Nautilus
# GTK4 apps read ~/.config/gtk-4.0/gtk.css only at launch, so restart nautilus
# to pick up the new palette. Only when a nautilus WINDOW is open, otherwise a
# restart would silently pop a new window on the active workspace.
if hyprctl clients -j | grep -Fq '"class": "org.gnome.Nautilus"'; then
    pkill -x nautilus 2>/dev/null
    nautilus --new-window >/dev/null 2>&1 &
fi

# 6.5 Reload Neovim
# SIGUSR1 tells nvim to reload colors
killall -SIGUSR1 nvim 2>/dev/null



# 7. Update Firefox colors (Pywalfox)
# This will update Firefox instantly if the addon is installed
pywalfox update 2>/dev/null

# 7.5 VS Code (Microsoft)
# Merge matugen's color fragment into settings.json, which VS Code applies
# live through its settings watcher. Won't open windows if not running.
python3 "$HOME/.config/hypr/scripts/vscode-theme-apply.py" 2>/dev/null

# 8. Notify
notify-send "Theme Updated" "Colors extracted from $(basename "$WALLPAPER")" -i "$WALLPAPER"
