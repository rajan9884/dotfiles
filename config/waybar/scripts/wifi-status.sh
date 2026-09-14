#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Waybar Wi-Fi status (custom/wifi) via nmcli
# ──────────────────────────────────────────────
set -euo pipefail

signal_icon() {
    local s="$1"
    if (( s >= 80 )); then printf '󰤨'
    elif (( s >= 60 )); then printf '󰤥'
    elif (( s >= 40 )); then printf '󰤢'
    elif (( s >= 20 )); then printf '󰤟'
    else printf '󰤯'; fi
}

radio="$(nmcli -t -f WIFI radio 2>/dev/null || echo unknown)"

if [[ "$radio" == "disabled" ]]; then
    jq -cn '{text:"󰤮", tooltip:"Wi-Fi off", class:"wifi-off"}'
    exit 0
fi

# Active Wi-Fi network: SSID + signal percentage
read -r ssid signal < <(nmcli -e no -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null |
    awk -F: '$1=="yes"{print $2, $3; exit}')

if [[ -n "${ssid:-}" ]]; then
    icon="$(signal_icon "${signal:-0}")"
    jq -cn --arg icon "$icon" --arg ssid "$ssid" --arg signal "${signal:-0}" \
        '{text: $icon, tooltip: ("Wi-Fi: " + $ssid + " (" + $signal + "%)"), class: "wifi-on"}'
    exit 0
fi

# Fall back to a wired connection if one is active
if nmcli -t -f DEVICE,TYPE,STATE connection show --active 2>/dev/null | grep -qi 'ethernet'; then
    jq -cn '{text:"󰈀", tooltip:"Ethernet connected", class:"wifi-on"}'
    exit 0
fi

jq -cn '{text:"󰤭", tooltip:"No Wi-Fi connection", class:"wifi-disconnected"}'