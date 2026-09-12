#!/usr/bin/env bash
# Recreate the default-theme symlink chain (default Noro).
# Run once after first home-manager switch, then re-run any
# time you want to change the default theme without the rofi switcher.
# Usage: ACTIVE_THEME=Noro ./theme-chain.sh   (Noro|Material|Retro|Modern|Glass)
set -euo pipefail
ACTIVE_THEME="${ACTIVE_THEME:-Noro}"
THEME_LOWER="$(printf '%s' "$ACTIVE_THEME" | tr '[:upper:]' '[:lower:]')"
HYPR_CFG="$HOME/.config/hypr"
WAYBAR_CFG="$HOME/.config/waybar"
ROFI_CFG="$HOME/.config/rofi"
[ -f "$HYPR_CFG/themes/$THEME_LOWER/theme.conf" ] || {
  echo "theme '$ACTIVE_THEME' not found in $HYPR_CFG/themes"; exit 1; }
ln -sf "$HYPR_CFG/themes/$THEME_LOWER/theme.conf" "$HYPR_CFG/theme.conf"
ln -sf "$HYPR_CFG/themes/$THEME_LOWER/theme.lua" "$HYPR_CFG/theme.lua"
ln -sf "$WAYBAR_CFG/themes/$THEME_LOWER/config.jsonc" "$WAYBAR_CFG/config.jsonc"
ln -sf "$WAYBAR_CFG/themes/$THEME_LOWER/style.css" "$WAYBAR_CFG/style.css"
ln -sf "$ROFI_CFG/themes/$THEME_LOWER/launcher.rasi" "$ROFI_CFG/active-launcher.rasi"
ln -sf "$ROFI_CFG/themes/$THEME_LOWER/scripts.rasi" "$ROFI_CFG/active-scripts.rasi"
ln -sf "$ROFI_CFG/themes/$THEME_LOWER/picker.rasi" "$ROFI_CFG/active-picker.rasi"
printf '%s\n' "$ACTIVE_THEME" > "$HYPR_CFG/.active-theme"
echo "theme chain linked ($THEME_LOWER)"
