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

# 1.5 Record current wallpaper + stage lock-screen background.
# hyprlock reads a static path, so pre-convert once per switch
# (backgrounded — never on the lock hot path).
printf '%s' "$WALLPAPER" > ~/.cache/current-wallpaper
(magick "$WALLPAPER" ~/.cache/hyprlock-bg.jpg 2>/dev/null) & disown 2>/dev/null

# 2. Extract colors with Matugen
# This updates colors for Waybar, Rofi, Kitty, Hyprland, etc.
matugen image "$WALLPAPER" --type scheme-content -c ~/.config/matugen/config.toml --source-color-index 0

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
# to re-theme them along with the bar. Always via systemd: a bare
# `waybar &` stacks duplicate bars and dies with the parent script.
systemctl --user restart waybar.service 2>/dev/null || {
    pkill -x waybar 2>/dev/null; pkill -x .waybar-wrapped 2>/dev/null
    sleep 0.5
    setsid waybar >/dev/null 2>&1 < /dev/null &
}

# 3.5 Refresh nm-applet so its tray right-click menu picks up the new GTK CSS
# (GTK parses gtk.css once at process startup, same as the note above).
# Managed by the xdg-autostart generator unit — restart re-reads the theme
# without stacking duplicate applets.
systemctl --user restart 'app-nm\x2dapplet@autostart.service' 2>/dev/null || {
    pkill -x nm-applet 2>/dev/null; pkill -x .nm-applet-wrap 2>/dev/null
    sleep 0.5
    setsid nm-applet >/dev/null 2>&1 < /dev/null &
}

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

# 6.5 Neovim
# nvim has no config-reload signal (SIGUSR1 is trapped but ignored), so
# running instances keep the previous palette until restarted; new
# instances read the regenerated matugen-colors.lua. Nudge instead of
# signaling (a bare kill would be a no-op at best).
if pgrep -x nvim >/dev/null 2>&1; then
    notify-send "Neovim Theme Updated" "Restart nvim to apply new colors"
fi



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

# 8. Reload swaync and swayosd to pick up new Matugen colors
# swaync --replace swaps the running instance with new CSS
swaync --replace --style ~/.config/swaync/style.css & disown 2>/dev/null

# swayosd-server is managed by systemd user service; restart it to reload CSS
systemctl --user restart swayosd.service 2>/dev/null || true

# 9. Notify
notify-send "Theme Updated" "Colors extracted from $(basename "$WALLPAPER")" -i "$WALLPAPER"
