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

# 2.5 Update Chromium/Helium theme
# matugen rewrites ~/.config/helium-theme/manifest.json but keeps
# version "1.0.0", while Chromium caches the theme in "Cached Theme.pak"
# and only re-reads the manifest on version change + restart. Bump the
# version per wallpaper and drop the stale pak so the next browser
# launch picks up the new colors.
# NOTE: Chrome requires every dot-separated version component to be
# 0-65535, so plain `date +%s` (epoch ~1.8B) is rejected and the theme
# gets disabled. Increment the patch component instead (wraps safely).
THEME_MANIFEST="$HOME/.config/helium-theme/manifest.json"
if [ -f "$THEME_MANIFEST" ]; then
    CUR_VER=$(grep -o '"version": "[^"]*"' "$THEME_MANIFEST" | head -1 | cut -d'"' -f4)
    CUR_MAJ=$(echo "$CUR_VER" | cut -sd. -f1); [ -z "$CUR_MAJ" ] && CUR_MAJ=1
    CUR_MIN=$(echo "$CUR_VER" | cut -sd. -f2); [ -z "$CUR_MIN" ] && CUR_MIN=0
    CUR_PAT=$(echo "$CUR_VER" | cut -sd. -f3)
    case "$CUR_PAT" in ''|*[!0-9]*) CUR_PAT=0 ;; esac
    if [ "$CUR_PAT" -ge 65535 ] 2>/dev/null; then
        CUR_MIN=$((CUR_MIN + 1)); CUR_PAT=0
        [ "$CUR_MIN" -ge 65535 ] && { CUR_MAJ=$((CUR_MAJ + 1)); CUR_MIN=0; }
    fi
    NEW_VERSION="$CUR_MAJ.$CUR_MIN.$((CUR_PAT + 1))"
    sed -i -E "s/\"version\": \"[^\"]+\"/\"version\": \"$NEW_VERSION\"/" "$THEME_MANIFEST"
    rm -f "$HOME/.config/helium-theme/Cached Theme.pak"
fi

# 3. Reload Waybar
# NOTE: SIGUSR2 only reloads waybar's own CSS, NOT the GTK theme.
# Tray context menus are GTK menus styled by ~/.config/gtk-3.0/gtk.css,
# which GTK loads once at process startup — so a full restart is needed
# to re-theme them along with the bar.
pkill -x waybar 2>/dev/null
sleep 0.5
waybar >/dev/null 2>&1 &
disown 2>/dev/null

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

# 7.6 Chromium/Helium/Brave (unpacked matugen theme)
# Chromium can't hot-reload an unpacked theme — it rebuilds
# "Cached Theme.pak" only on browser launch. Nudge the user to restart
# when a Chromium-based browser is running.
if pgrep -x chromium >/dev/null 2>&1 || pgrep -x helium >/dev/null 2>&1 || pgrep -x brave >/dev/null 2>&1 || pgrep -f helium-browser >/dev/null 2>&1; then
    notify-send "Browser Theme Updated" "Restart Chromium/Helium/Brave to apply new colors" -i "$WALLPAPER"
fi

# 8. Notify
notify-send "Theme Updated" "Colors extracted from $(basename "$WALLPAPER")" -i "$WALLPAPER"
