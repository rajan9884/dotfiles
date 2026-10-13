#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Dynamic Theme Switcher (awww + matugen) — sway/Void port of swww-all.sh
#   Usage: hypr-wall.sh /path/to/wallpaper.jpg
# ──────────────────────────────────────────────
set -euo pipefail

# Keybind-launched runs may have no session bus (tuigreet session without
# dbus-run-session): recover it from the snapshot file so notify-send,
# makoctl and the swayosd restart below all reach the bus instead
# of hanging/failing silently.
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    for _busf in "${XDG_RUNTIME_DIR:-/run/user/1000}/session-bus.address" "$HOME/.cache/session-bus"; do
        if [ -s "$_busf" ]; then
            DBUS_SESSION_BUS_ADDRESS=$(cat "$_busf")
            export DBUS_SESSION_BUS_ADDRESS
            break
        fi
    done
    unset _busf
fi

WALLPAPER="${1:-}"
[ -z "$WALLPAPER" ] && { echo "Usage: hypr-wall.sh /path/to/wallpaper.jpg" >&2; exit 1; }
[ -f "$WALLPAPER" ] || { echo "Not found: $WALLPAPER" >&2; exit 1; }

# One switch at a time: rapid Super+R presses used to queue up full
# decode+transition+matugen+reload cycles, each slower than the last.
# mkdir is atomic and (unlike flock fds) can't leak into child processes.
LOCKDIR=/tmp/hypr-wall.lockdir
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    # Stale lock (e.g. killed mid-run)? Reap after 2 minutes.
    if [ -n "$(find "$LOCKDIR" -maxdepth 0 -mmin +2 2>/dev/null)" ]; then
        rm -rf "$LOCKDIR" && mkdir "$LOCKDIR" 2>/dev/null || \
            { echo "wallpaper switch already in progress, skipping" >&2; exit 0; }
    else
        echo "wallpaper switch already in progress, skipping" >&2; exit 0
    fi
fi
trap 'rmdir "$LOCKDIR" 2>/dev/null' EXIT

# 1. Set wallpaper via awww-daemon (sole painter, same as sway).
if awww query >/dev/null 2>&1; then
    awww img "$WALLPAPER" --transition-type grow --transition-pos center --transition-duration 1.5 --transition-fps 30 || \
        { notify-send "Wallpaper Error" "awww failed to set $(basename "$WALLPAPER")" -u critical; exit 1; }
else
    setsid awww-daemon >/dev/null 2>&1 < /dev/null &
    sleep 0.5
    awww img "$WALLPAPER" --transition-type grow --transition-pos center --transition-duration 1.5 --transition-fps 30 || \
        { notify-send "Wallpaper Error" "awww failed to set $(basename "$WALLPAPER")" -u critical; exit 1; }
fi

# 1.5 Record current wallpaper + stage lock-screen background (synchronous so
#    Super+R immediately followed by Super+Ctrl+L already shows the new image).
printf '%s' "$WALLPAPER" > "$HOME/.cache/current-wallpaper"
magick "$WALLPAPER" "$HOME/.cache/hyprlock-bg.jpg" 2>/dev/null || cp -p "$WALLPAPER" "$HOME/.cache/hyprlock-bg.jpg" 2>/dev/null || true

# 2. Extract colors with matugen (updates waybar, rofi, alacritty, foot, sway, mako, …)
matugen image "$WALLPAPER" --type scheme-content -c ~/.config/matugen/config.toml --source-color-index 0

# 2.1 Restart swayosd-server so it picks up the new style.css (reads CSS only at startup).
pkill -x swayosd-server >/dev/null 2>&1 || true
setsid swayosd-server >/dev/null 2>&1 < /dev/null &

# 2.5 Bump unpacked Chromium theme version so the next launch picks up colors
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

# 3. Apply the theme: hyprland reads colors.lua via theme.lua, so reload
#    the compositor to pick up the new matugen palette. Waybar reloads
#    in place (SIGUSR2 = no bar blank).
hyprctl reload >/dev/null 2>&1 || true
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -USR2 -x waybar 2>/dev/null || true
elif pgrep -x .waybar-wrapped >/dev/null 2>&1; then
    pkill -USR2 -x .waybar-wrapped 2>/dev/null || true
else
    # Single-instance gated launch (shared with the compositor autostart): waits
    # for the default sink and skips if a bar is already up, so this can
    # never stack a duplicate or a module-less bar at boot.
    ~/.config/hypr/scripts/waybar-launch.sh >/dev/null 2>&1 < /dev/null &
fi

# 4. Live-recolor running terminals: neither alacritty nor foot picks up a
# new palette in already-open windows, so push the fresh matugen palette
# to every open pty via OSC sequences. New windows still read their
# matugen colors file automatically (alacritty colors.toml / foot colors.ini).
"$HOME/.config/hypr/scripts/terminal-recolor.sh" >/dev/null 2>&1 || true

# 5. Reload mako with new colors (matugen writes ~/.config/mako/colors)
makoctl reload 2>/dev/null || { pkill -x mako 2>/dev/null; setsid mako >/dev/null 2>&1 < /dev/null & }

# 6. GTK apps read css at launch — Thunar windows are owned by the
# `thunar --daemon` background process, so bounce the daemon on every
# switch (even with no window open), otherwise the next window inherits
# the previous wallpaper's theme.
THUNAR_WAS_OPEN=false
hyprctl clients -j 2>/dev/null | grep -Fq '"class": "Thunar"' && THUNAR_WAS_OPEN=true
pkill -x thunar 2>/dev/null || true
pkill -x Thunar 2>/dev/null || true
sleep 0.3
setsid thunar --daemon >/dev/null 2>&1 < /dev/null &
if [ "$THUNAR_WAS_OPEN" = true ]; then
    sleep 0.5
    setsid thunar >/dev/null 2>&1 < /dev/null &
fi

# 7. Nudges for apps that need a restart
pgrep -x nvim >/dev/null 2>&1 && notify-send "Neovim Theme Updated" "Restart nvim to apply new colors" || true
timeout 10 pywalfox update 2>/dev/null || true
if pgrep -x chromium >/dev/null 2>&1 || pgrep -x brave >/dev/null 2>&1 || pgrep -x helium >/dev/null 2>&1 || pgrep -x helium-browser >/dev/null 2>&1; then
    notify-send "Browser Theme Updated" "Fully quit Helium/Chromium (all windows) and reopen to apply new colors" -i "$WALLPAPER"
fi

# 8. Done (no "Theme Updated" popup: notifications stay silent on switch;
# nvim/browser restart nudges above still fire when those apps run).
true
