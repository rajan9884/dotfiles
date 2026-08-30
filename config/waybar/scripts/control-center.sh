#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   macOS Control Center (Refined Visuals)
# ──────────────────────────────────────────────

THEME="$HOME/.config/rofi/themes/macos/control-center.rasi"
[ -f "$THEME" ] || THEME="$HOME/.config/rofi/material-scripts.rasi"
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
    local vol=$(pamixer --get-volume)
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

# --- Prepare Menu Items ---
WIFI_SSID=$(get_wifi)
BT_STATE=$(get_bt)
VOL_BAR=$(get_vol_bar)
BRIGHT_BAR=$(get_bright_bar)

# Clean, descriptive items for the tiles
MENU="󰖩  Wi-Fi\n$WIFI_SSID\n"
MENU+="󰂯  Bluetooth\n$BT_STATE\n"
MENU+="󰃠  Brightness\n$BRIGHT_BAR\n"
MENU+="󰕾  Sound\n$VOL_BAR\n"
MENU+="󰔉  Focus\nOff\n"
MENU+="󰹑  Mirroring\nNone\n"
MENU+="󰝚  Music\nNot Playing\n"
MENU+="󰹑  Screensaver\nRun\n"
MENU+="⏻  Power\nSystem"

CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "macOS" -theme "$THEME" -i)

case "$CHOICE" in
    *"Wi-Fi"*)
        ~/.config/waybar/scripts/wifi-menu.sh ;;
    *"Bluetooth"*)
        ~/.config/waybar/scripts/bluetooth-menu.sh ;;
    *"Brightness"*)
        brightnessctl set +10% ;;
    *"Sound"*)
        kitty --class wiremix -e wiremix ;;
    *"Screensaver"*)
        kitty --class arch-screensaver --start-as fullscreen --override window_padding_width=0 --override background_opacity=1.0 --override dynamic_background_opacity=no -e "$HOME/.local/bin/arch-screensaver" --now ;;
    *"Power"*)
        ~/.config/waybar/scripts/power-menu.sh ;;
esac
