#!/usr/bin/env bash
# Keybindings browser — standalone
# Live sources: menu-herdr-keybindings (Herdr actions) with fallback to the
# Lua-parsed cheatsheet (binds.lua). The old menu-keybindings /
# bindings.conf paths are retired (binds live in binds.lua).
set -euo pipefail
if command -v herdr >/dev/null 2>&1 && command -v menu-herdr-keybindings >/dev/null 2>&1; then
  menu-herdr-keybindings --print | rofi -dmenu -theme ~/.config/rofi/list.rasi -p '⌨️  Keybindings' -i -lines 20
elif [ -x "$HOME/.config/hypr/scripts/keybinds-cheatsheet.sh" ]; then
  "$HOME/.config/hypr/scripts/keybinds-cheatsheet.sh" --print | rofi -dmenu -theme ~/.config/rofi/list.rasi -p '⌨️  Keybindings' -i -lines 20
fi
