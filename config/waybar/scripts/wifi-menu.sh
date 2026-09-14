#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Wi-Fi / Network Menu for Waybar (rofi + nmcli)
#   Mirrors the nm-applet controls: networks, radio,
#   networking, hidden network, hotspot, details.
# ──────────────────────────────────────────────

THEME="$HOME/.config/rofi/active-scripts.rasi"
DIVIDER="────────────────────────────"

notify() {
    notify-send -a "Network" -i network-wireless "$1" "$2" -t 4000
}

wifi_iface() {
    nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'
}

signal_icon() {
    local s="$1"
    if (( s >= 80 )); then printf '󰤨'
    elif (( s >= 60 )); then printf '󰤥'
    elif (( s >= 40 )); then printf '󰤢'
    elif (( s >= 20 )); then printf '󰤟'
    else printf '󰤯'; fi
}

get_radio() {
    nmcli -t -f WIFI radio 2>/dev/null
}

get_networking() {
    nmcli -t -f NETWORKING networking 2>/dev/null
}

get_active() {
    nmcli -e no -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2, $3; exit}'
}

hotspot_running() {
    nmcli -e no -t -f NAME,TYPE,STATE connection show --active 2>/dev/null |
        grep -qi '802-11-wireless' || return 1
    nmcli -g 802-11-wireless.mode con show --active 2>/dev/null | grep -qi 'ap' || return 1
    return 1
}

build_menu() {
    local radio networking active_ssid active_signal
    radio="$(get_radio)"
    networking="$(get_networking)"
    read -r active_ssid active_signal < <(get_active)

    if [[ "$radio" == "disabled" ]]; then
        echo "󰤮  Wi-Fi is OFF"
        echo "$DIVIDER"
        echo "󰤨  Turn Wi-Fi ON"
        echo "󰧌  Hidden Network…"
        echo "$DIVIDER"
        if [[ "$networking" == "disabled" ]]; then
            echo "󰇚  Enable Networking"
        else
            echo "󰇚  Disable Networking"
        fi
        echo "󰤪  Edit Connections…"
        return
    fi

    if [[ -n "$active_ssid" ]]; then
        local aicon
        aicon="$(signal_icon "${active_signal:-0}")"
        echo "$aicon  Connected: $active_ssid"
    else
        echo "󰤭  Wi-Fi ON — no connection"
    fi
    echo "$DIVIDER"

    # Nearby networks, strongest first, one entry per SSID (skip the active one)
    local iface
    iface="$(wifi_iface)"
    while IFS=: read -r signal ssid sec; do
        [[ -z "$ssid" ]] && continue
        [[ "$ssid" == "$active_ssid" ]] && continue
        [[ "$ssid" == "<hidden>" ]] && continue
        local icon
        icon="$(signal_icon "$signal")"
        if [[ "$sec" == *"WPA"* || "$sec" == *"WEP"* ]]; then
            echo "$icon  $ssid  󰢷"
        else
            echo "$icon  $ssid"
        fi
    done < <(nmcli -e yes -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan no ifname "${iface:-wifi}" 2>/dev/null |
        python3 -c '
import sys, re
best = {}
def unesc(s): return re.sub(r"\\(.)", r"\1", s)
for line in sys.stdin:
    parts = re.split(r"(?<!\\):", line.rstrip("\n"))
    if len(parts) < 3:
        continue
    ssid = unesc(parts[0]).strip()
    sec  = unesc(parts[2]).strip()
    try:
        sigi = int(parts[1])
    except ValueError:
        sigi = 0
    if not ssid:
        ssid = "<hidden>"
    if ssid not in best or sigi > best[ssid][0]:
        best[ssid] = (sigi, sec)
for ssid, (sig, sec) in sorted(best.items(), key=lambda kv: -kv[1][0]):
    print(f"{sig}:{ssid}:{sec}")
')

    if [[ -n "$active_ssid" ]]; then
        echo "$DIVIDER"
        echo "󰖪  Disconnect"
    fi
    echo "$DIVIDER"

    echo "󰧌  Hidden Network…"
    if hotspot_running; then
        echo "󰋎  Disable Hotspot"
    else
        echo "󰋎  Enable Hotspot"
    fi
    echo "󰖟  Connection Details…"
    echo "󰤪  Edit Connections…"
    echo "$DIVIDER"

    if [[ "$radio" == "enabled" ]]; then
        echo "󰤮  Turn Wi-Fi OFF"
    fi
    if [[ "$networking" == "disabled" ]]; then
        echo "󰇚  Enable Networking"
    else
        echo "󰇚  Disable Networking"
    fi
}

connect_network() {
    local ssid="$1"
    notify "Connecting…" "Connecting to $ssid"
    if nmcli dev wifi connect "$ssid" 2>/dev/null; then
        notify "Connected ✓" "Connected to $ssid"
        return 0
    fi

    local pw
    pw="$(rofi -dmenu -password -p "Password for $ssid" -theme "$THEME")"
    [[ -z "$pw" ]] && return 1
    if nmcli dev wifi connect "$ssid" password "$pw" 2>/dev/null; then
        notify "Connected ✓" "Connected to $ssid"
    else
        notify "Failed ✗" "Could not connect to $ssid"
        return 1
    fi
}

hidden_network() {
    local ssid pw
    ssid="$(rofi -dmenu -p "Hidden network SSID" -theme "$THEME")"
    [[ -z "$ssid" ]] && return
    connect_network "$ssid"
}

connection_details() {
    local iface ssid
    iface="$(wifi_iface)"
    ssid="$(get_active | cut -d' ' -f1)"
    if [[ -z "$ssid" ]]; then
        notify "No connection" "No active Wi-Fi network to inspect"
        return
    fi
    local details
    details="$(nmcli -e yes -t -f SSID,SIGNAL,SECURITY,CHAN,BSSID,SPEED dev wifi list ifname "$iface" 2>/dev/null |
        awk -F: -v s="$ssid" '$1==s{print "SSID:     "$1"\nSignal:   "$2"\nSecurity: "$3"\nChannel:  "$4"\nBSSID:    "$5"\nRate:     "$6" Mb/s"; exit}')"
    notify -t 8000 "$ssid" "$details"
}

handle_selection() {
    local choice="$1"
    case "$choice" in
        "󰤮  Wi-Fi is OFF"*|"󰤭  Wi-Fi ON"*|"󰤨  Connected:"*|"$DIVIDER")
            return ;;

        "󰤨  Turn Wi-Fi ON")
            nmcli radio wifi on 2>/dev/null
            notify "Wi-Fi ON" "Wireless radio enabled"
            sleep 1
            main ;;

        "󰤮  Turn Wi-Fi OFF")
            nmcli radio wifi off 2>/dev/null
            notify "Wi-Fi OFF" "Wireless radio disabled" ;;

        "󰇚  Enable Networking")
            nmcli networking on 2>/dev/null
            notify "Networking ON" "NetworkManager is enabled"
            sleep 1
            main ;;

        "󰇚  Disable Networking")
            nmcli networking off 2>/dev/null
            notify "Networking OFF" "NetworkManager is disabled" ;;

        "󰧌  Hidden Network…")
            hidden_network
            sleep 1
            main ;;

        "󰋎  Enable Hotspot")
            local iface
            iface="$(wifi_iface)"
            nmcli radio wifi on 2>/dev/null
            nmcli dev wifi hotspot ifname "${iface:-wifi}" 2>/dev/null
            notify "Hotspot" "Wi-Fi hotspot enabled"
            sleep 1
            main ;;

        "󰋎  Disable Hotspot")
            nmcli dev wifi hotspot off 2>/dev/null
            notify "Hotspot" "Wi-Fi hotspot disabled"
            sleep 1
            main ;;

        "󰖟  Connection Details…")
            connection_details ;;

        "󰤪  Edit Connections…")
            command -v nm-connection-editor >/dev/null 2>&1 \
                && nm-connection-editor \
                || notify "Not installed" "Install network-manager-applet for the editor" ;;

        "󰖪  Disconnect")
            nmcli connection down active 2>/dev/null
            notify "Disconnected" "The active connection was disconnected"
            sleep 1
            main ;;

        *)
            local ssid
            ssid="$(echo "$choice" | sed 's/^[^ ]*  *//; s/  *󰢷$//')"
            [[ -z "$ssid" ]] && return
            connect_network "$ssid"
            sleep 1
            main ;;
    esac
}

main() {
    local menu choice
    menu="$(build_menu)"
    choice="$(echo "$menu" | rofi -dmenu -p "󰤨  Network" -lines 12 -theme "$THEME" -i)"
    [[ -z "$choice" ]] && exit 0
    handle_selection "$choice"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi