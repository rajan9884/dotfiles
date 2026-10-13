#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   hdr-toggle — flip eDP-1 between HDR and SDR live
#   Bound to SUPER+CTRL+H. Uses `hyprctl eval` because
#   this setup uses the Lua (non-legacy) parser, where
#   `hyprctl keyword monitor` is rejected.
#   HDR values mirror env.lua. The choice is also persisted to
#   ~/.cache/hypr-hdr-state ("hdr"/"sdr") so wallpaper-switch reloads
#   (hypr-wall.sh) and logins restore it instead of forcing HDR on.
# ──────────────────────────────────────────────
set -euo pipefail

STATE_FILE="$HOME/.cache/hypr-hdr-state"

if hyprctl monitors all 2>/dev/null | grep -q "colorManagementPreset: hdr"; then
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 2, bitdepth = 8, cm = "srgb" })' >/dev/null
    printf '%s' "sdr" > "$STATE_FILE"
    notify-send "HDR" "OFF — SDR (sRGB, 8-bit)"
else
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 2, bitdepth = 10, cm = "hdr", supports_hdr = 1, supports_wide_color = 1 })' >/dev/null
    printf '%s' "hdr" > "$STATE_FILE"
    notify-send "HDR" "ON — 10-bit HDR"
fi
