#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Waybar network status (custom/wifi) via nmcli
#   Shows the connection you are actually using:
#   Wi-Fi signal / Wired ethernet / USB tethering
# ──────────────────────────────────────────────
set -euo pipefail

I_SIG4=$'\U000F0928'     # md-wifi_strength_4
I_SIG3=$'\U000F0925'     # md-wifi_strength_3
I_SIG2=$'\U000F0922'     # md-wifi_strength_2
I_SIG1=$'\U000F091F'     # md-wifi_strength_1
I_SIG0=$'\U000F092D'     # md-wifi_strength_off
I_WIFIOFF=$'\U000F05AA'  # md-wifi_off
I_WIFIOUT=$'\U000F092F'  # md-wifi_strength_outline
I_ETHER=$'\U000F0200'    # md-ethernet
I_TETHER=$'\U000F0121'   # md-cellphone_link

signal_icon() {
    local s="$1"
    if (( s >= 80 )); then printf '%s' "$I_SIG4"
    elif (( s >= 60 )); then printf '%s' "$I_SIG3"
    elif (( s >= 40 )); then printf '%s' "$I_SIG2"
    elif (( s >= 20 )); then printf '%s' "$I_SIG1"
    else printf '%s' "$I_SIG0"; fi
}

conn_name_for() {
    nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | awk -F: -v d="$1" '$2==d{print $1; exit}'
}

is_usb() {
    udevadm info -q path -n "$1" 2>/dev/null | grep -q '/usb'
}

radio="$(nmcli -t -f WIFI radio 2>/dev/null || echo unknown)"

if [[ "$radio" == "disabled" ]]; then
    jq -cn --arg i "$I_WIFIOFF" '{text:$i, tooltip:"Wi-Fi off (click to enable)", class:"wifi-off"}'
    exit 0
fi

read -r ssid signal < <(nmcli -e no -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null |
    awk -F: '$1=="yes"{print $2, $3; exit}') || true

default_dev="$(ip -4 route show default 2>/dev/null | awk '$1=="default"{print $5; exit}')"

# Wi-Fi is connected and in use (or there is no other route at all)
if [[ -n "${ssid:-}" ]] && { [[ "$default_dev" == wl* ]] || [[ -z "$default_dev" ]]; }; then
    icon="$(signal_icon "${signal:-0}")"
    jq -cn --arg icon "$icon" --arg ssid "$ssid" --arg signal "${signal:-0}" \
        '{text:$icon, tooltip:("Wi-Fi: "+$ssid+" ("+$signal+"%)"), class:"wifi-on"}'
    exit 0
fi

# A wired / tethered link carries the traffic and Wi-Fi is still connected:
# show the active link so you can tell what you are using
if [[ "$default_dev" == en* || "$default_dev" == eth* ]]; then
    if [[ -n "${ssid:-}" ]]; then
        name="$(conn_name_for "$default_dev")"
        if is_usb "$default_dev"; then
            jq -cn --arg i "$I_TETHER" --arg name "$name" --arg ssid "$ssid" \
                '{text:$i, tooltip:("USB tethering"+(if $name=="" then "" else ": "+$name end)+" — Wi-Fi ("+$ssid+") connected"), class:"wifi-tether"}'
        else
            jq -cn --arg i "$I_ETHER" --arg name "$name" --arg ssid "$ssid" \
                '{text:$i, tooltip:("Ethernet"+(if $name=="" then "" else ": "+$name end)+" — Wi-Fi ("+$ssid+") connected"), class:"wifi-wired"}'
        fi
        exit 0
    fi
    # Wi-Fi disconnected while on ethernet: keep the Wi-Fi glyph visible so
    # you can always click it to reconnect (click opens the Wi-Fi menu)
    jq -cn --arg i "$I_WIFIOUT" --arg name "$(conn_name_for "$default_dev")" \
        '{text:$i, tooltip:("Wi-Fi disconnected — on "+(if $name=="" then "Ethernet" else $name end)+" (click to reconnect)"), class:"wifi-disconnected"}'
    exit 0
fi

# Fallback: Wi-Fi connected but another interface (VPN, ppp, …) is the default route
if [[ -n "${ssid:-}" ]]; then
    icon="$(signal_icon "${signal:-0}")"
    jq -cn --arg icon "$icon" --arg ssid "$ssid" --arg signal "${signal:-0}" \
        '{text:$icon, tooltip:("Wi-Fi: "+$ssid+" ("+$signal+"%)"), class:"wifi-on"}'
    exit 0
fi

jq -cn --arg i "$I_WIFIOUT" '{text:$i, tooltip:"Wi-Fi disconnected (click to reconnect)", class:"wifi-disconnected"}'