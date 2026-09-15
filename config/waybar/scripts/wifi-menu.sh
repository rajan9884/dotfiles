#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Wi-Fi / Network Menu for Waybar (rofi + nmcli)
#   Mirrors the nm-applet controls: networks, radio,
#   networking, hidden network, hotspot, details.
# ──────────────────────────────────────────────

THEME="$HOME/.config/rofi/wifi-menu.rasi"
DIVIDER="────────────────────────────"

I_SIG4=$'\U000F0928'     # md-wifi_strength_4
I_SIG3=$'\U000F0925'     # md-wifi_strength_3
I_SIG2=$'\U000F0922'     # md-wifi_strength_2
I_SIG1=$'\U000F091F'     # md-wifi_strength_1
I_SIG0=$'\U000F092D'     # md-wifi_strength_off
I_WIFIOFF=$'\U000F05AA'  # md-wifi_off
I_WIFIOUT=$'\U000F092F'  # md-wifi_strength_outline
I_LOCK=$'\U000F033E'     # md-lock
I_HIDDEN=$'\U000F0209'   # md-eye_off
I_HOTSPOT=$'\U000F0003'  # md-access_point
I_DETAILS=$'\U000F02FD'  # md-information_outline
I_EDIT=$'\U000F062E'     # md-tune
I_LINKOFF=$'\U000F0338'  # md-link_off
I_NET=$'\U000F1616'      # md-connection

notify() {
    local dur=4000
    if [[ "$1" == "-t" ]]; then dur="$2"; shift 2; fi
    notify-send -a "Network" -i network-wireless -t "$dur" "$1" "$2"
}

wifi_iface() {
    nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'
}

signal_icon() {
    local s="$1"
    if (( s >= 80 )); then printf '%s' "$I_SIG4"
    elif (( s >= 60 )); then printf '%s' "$I_SIG3"
    elif (( s >= 40 )); then printf '%s' "$I_SIG2"
    elif (( s >= 20 )); then printf '%s' "$I_SIG1"
    else printf '%s' "$I_SIG0"; fi
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
        echo "$I_WIFIOFF  Wi-Fi is OFF"
        echo "$DIVIDER"
        echo "$I_SIG4  Turn Wi-Fi ON"
        echo "$I_HIDDEN  Hidden Network…"
        echo "$DIVIDER"
        if [[ "$networking" == "disabled" ]]; then
            echo "$I_NET  Enable Networking"
        else
            echo "$I_NET  Disable Networking"
        fi
        echo "$I_EDIT  Edit Connections…"
        return
    fi

    if [[ -n "$active_ssid" ]]; then
        echo "$I_SIG4  Connected: $active_ssid ($active_signal%)"
    else
        echo "$I_WIFIOUT  Wi-Fi ON — no connection"
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
            echo "$icon  $ssid  $I_LOCK"
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
        echo "$I_LINKOFF  Disconnect"
    fi
    echo "$DIVIDER"

    echo "$I_HIDDEN  Hidden Network…"
    if hotspot_running; then
        echo "$I_HOTSPOT  Disable Hotspot"
    else
        echo "$I_HOTSPOT  Enable Hotspot"
    fi
    echo "$I_DETAILS  Connection Details…"
    echo "$I_EDIT  Edit Connections…"
    echo "$DIVIDER"

    if [[ "$radio" == "enabled" ]]; then
        echo "$I_WIFIOFF  Turn Wi-Fi OFF"
    fi
    if [[ "$networking" == "disabled" ]]; then
        echo "$I_NET  Enable Networking"
    else
        echo "$I_NET  Disable Networking"
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
    details="$(nmcli -e yes -t -f SSID,SIGNAL,SECURITY,CHAN,BSSID,RATE dev wifi list --rescan no ifname "$iface" 2>/dev/null |
        python3 -c '
import sys, re
ssid_arg = sys.argv[1]
def unesc(s): return re.sub(r"\\(.)", r"\1", s)
for line in sys.stdin:
    p = re.split(r"(?<!\\):", line.rstrip("\n"))
    if len(p) < 6:
        continue
    if unesc(p[0]).strip() == ssid_arg:
        print("SSID:     " + unesc(p[0]).strip())
        print("Signal:   " + p[1] + "%")
        print("Security: " + unesc(p[2]))
        print("Channel:  " + p[3])
        print("BSSID:    " + unesc(p[4]))
        print("Rate:     " + p[5])
        break
' "$ssid")"
    notify -t 8000 "$ssid" "$details"
}

handle_selection() {
    local choice="$1"
    case "$choice" in
        "$I_WIFIOFF  Wi-Fi is OFF"*|"$I_WIFIOUT  Wi-Fi ON"*|"$I_SIG4  Connected:"*|"$DIVIDER")
            return ;;

        "$I_SIG4  Turn Wi-Fi ON")
            nmcli radio wifi on 2>/dev/null
            notify "Wi-Fi ON" "Wireless radio enabled"
            sleep 1
            main ;;

        "$I_WIFIOFF  Turn Wi-Fi OFF")
            nmcli radio wifi off 2>/dev/null
            notify "Wi-Fi OFF" "Wireless radio disabled" ;;

        "$I_NET  Enable Networking")
            nmcli networking on 2>/dev/null
            notify "Networking ON" "NetworkManager is enabled"
            sleep 1
            main ;;

        "$I_NET  Disable Networking")
            nmcli networking off 2>/dev/null
            notify "Networking OFF" "NetworkManager is disabled" ;;

        "$I_HIDDEN  Hidden Network…")
            hidden_network
            sleep 1
            main ;;

        "$I_HOTSPOT  Enable Hotspot")
            local iface
            iface="$(wifi_iface)"
            nmcli radio wifi on 2>/dev/null
            nmcli dev wifi hotspot ifname "${iface:-wifi}" 2>/dev/null
            notify "Hotspot" "Wi-Fi hotspot enabled"
            sleep 1
            main ;;

        "$I_HOTSPOT  Disable Hotspot")
            nmcli dev wifi hotspot off 2>/dev/null
            notify "Hotspot" "Wi-Fi hotspot disabled"
            sleep 1
            main ;;

        "$I_DETAILS  Connection Details…")
            connection_details ;;

        "$I_EDIT  Edit Connections…")
            command -v nm-connection-editor >/dev/null 2>&1 \
                && nm-connection-editor \
                || notify "Not installed" "Install network-manager-applet for the editor" ;;

        "$I_LINKOFF  Disconnect")
            local active
            active="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1; exit}')"
            if [[ -z "$active" ]]; then
                notify "Nothing to disconnect" "No active Wi-Fi connection"
            else
                nmcli connection down "$active" 2>/dev/null
                notify "Disconnected" "Disconnected from $active"
            fi
            sleep 1
            main ;;

        *)
            local ssid
            ssid="$(echo "$choice" | sed 's/^[^ ]*  *//; s/  *'"$I_LOCK"'$//')"
            [[ -z "$ssid" ]] && return
            connect_network "$ssid"
            sleep 1
            main ;;
    esac
}

main() {
    local menu choice
    menu="$(build_menu)"
    choice="$(echo "$menu" | rofi -dmenu -p "$I_SIG4  Network" -lines 16 -theme "$THEME" -i)"
    [[ -z "$choice" ]] && exit 0
    handle_selection "$choice"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi