#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   VPN status for Waybar (custom/vpn)
#   Shows active VPN/WireGuard connection, if any.
# ──────────────────────────────────────────────
set -euo pipefail

active="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -iE ':(vpn|wireguard)$' | cut -d: -f1 | head -n 1 || true)"

if [ -n "${active:-}" ]; then
    jq -cn --arg name "$active" '{text: ("󰖂 " + $name), tooltip: ("VPN connected: " + $name), class: "vpn-on"}'
else
    jq -cn '{text: "󰖂", tooltip: "No VPN active", class: "vpn-off"}'
fi
