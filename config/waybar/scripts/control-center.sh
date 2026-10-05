#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   macOS Control Center (Refined Visuals)
# ──────────────────────────────────────────────

THEME="$HOME/.config/rofi/control-center.rasi"
[ -f "$THEME" ] || THEME="$HOME/.config/rofi/active-scripts.rasi"
[ -f "$THEME" ] || THEME=""

# --- Functions to get stats ---
get_wifi() {
    local ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
    [ -z "$ssid" ] && echo "Off" || echo "$ssid"
}

get_bt() {
    bluetoothctl show | grep "Powered: yes" >/dev/null && echo "On" || echo "Off"
}

get_vol_bar() {
    local vol=$(wpctl get-volume | awk '{ print int($2*100) }')
    local filled=$((vol / 10))
    local bar=""
    # Using specific Nerd Font block characters
    for ((i=0; i<filled; i++)); do bar+="󰝤"; done
    for ((i=filled; i<10; i++)); do bar+=" "; done
    echo "$bar $vol%"
}

get_bright_bar() {
    local cur=$(brightnessctl g)
    local max=$(brightnessctl m)
    local percent=$((cur * 100 / max))
    local filled=$((percent / 10))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="󰝤"; done
    for ((i=filled; i<10; i++)); do bar+=" "; done
    echo "$bar $percent%"
}

DND_STATE="$("$HOME/.config/sway/scripts/mako-dnd.sh" state 2>/dev/null || echo Off)"

# --- Prepare Menu Items ---
WIFI_SSID=$(get_wifi)
BT_STATE=$(get_bt)
VOL_BAR=$(get_vol_bar)
BRIGHT_BAR=$(get_bright_bar)

# One line per tile: rofi returns the clicked row verbatim, so a two-line
# tile (label row + value row) breaks matching when the value row is
# clicked. Status is appended inline instead.
MENU="󰖩  Wi-Fi — $WIFI_SSID\n"
MENU+="󰂯  Bluetooth — $BT_STATE\n"
MENU+="󰃠  Brightness — $BRIGHT_BAR\n"
MENU+="󰕾  Sound — $VOL_BAR\n"
MENU+="󰔉  Focus — $DND_STATE\n"
MENU+="󰹑  Mirroring — None\n"
MENU+="󰝚  Music — Not Playing\n"
MENU+="⏻  Power — System"

CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "macOS" -theme "$THEME" -i)

case "$CHOICE" in
    *"Wi-Fi"*)
        alacritty -e nmtui ;;
    *"Bluetooth"*)
        ~/.config/waybar/scripts/bluetooth-menu.sh ;;
    *"Brightness"*)
        brightnessctl set +10% ;;
    *"Sound"*)
        alacritty --class=pulsemixer -e pulsemixer ;;
    *"Focus"*)
        "$HOME/.config/sway/scripts/mako-dnd.sh" toggle ;;
    *"Power"*)
        ~/.config/waybar/scripts/power-menu.sh ;;
esac
