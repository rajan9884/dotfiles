#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   WiFi Menu for Waybar (rofi + nmcli)
# ──────────────────────────────────────────────

# Use active theme script style
THEME="$HOME/.config/rofi/active-scripts.rasi"
DIVIDER="────────────────────────────"

# Handle positioning
POSITION="$1"
ROFI_ARGS=""
if [[ "$POSITION" == "left" ]]; then
    ROFI_ARGS="-location 7 -xoffset 60 -yoffset -20"
fi

notify() {
    notify-send -a "WiFi Menu" -i network-wireless "$1" "$2" -t 4000
}

# ── Get current connection info ──────────────
get_status() {
    local dev_state
    dev_state=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | grep ":wifi:" | head -1)
    DEV=$(echo "$dev_state" | cut -d: -f1)

    if [[ -z "$DEV" ]]; then
        WIFI_STATE="disabled"
        return
    fi

    local conn_info
    conn_info=$(nmcli -t -f NAME,DEVICE,STATE connection show --active 2>/dev/null | grep ":${DEV}:" | head -1)

    if [[ -n "$conn_info" ]]; then
        WIFI_STATE="enabled"
        CURRENT_SSID=$(echo "$conn_info" | cut -d: -f1)
        local ip_info
        ip_info=$(nmcli -t -f IP4.ADDRESS device show "$DEV" 2>/dev/null | head -1)
        CURRENT_IP=$(echo "$ip_info" | cut -d: -f2 | cut -d/ -f1)
        local signal_info
        signal_info=$(nmcli -t -f SIGNAL device wifi list 2>/dev/null | head -1)
        SIGNAL="${signal_info}%"
    else
        WIFI_STATE="enabled"
        CURRENT_SSID=""
        CURRENT_IP=""
        SIGNAL=""
    fi
}

# ── List available networks (SSID, security) ─
list_networks() {
    nmcli -t -f SSID,SECURITY,IN-USE device wifi list 2>/dev/null \
        | while IFS=: read -r ssid security inuse; do
            [[ -z "$ssid" ]] && continue
            [[ "$inuse" == "*" ]] && continue
            local icon="󰤟 "
            local lock=""
            [[ "$security" != "" ]] && lock=" 󰌾"
            printf "%s %s%s\n" "$icon" "$ssid" "$lock"
        done | sort -u
}

# ── Build the menu ───────────────────────────
build_menu() {
    get_status

    # Header actions
    if [[ "$WIFI_STATE" == "enabled" ]]; then
        if [[ -n "$CURRENT_SSID" ]]; then
            echo "󰤨  Connected: $CURRENT_SSID ($CURRENT_IP)"
        else
            echo "󰤭  Not connected"
        fi
        echo "$DIVIDER"
        echo "󰑐  Rescan networks"
        echo "$DIVIDER"

        # List available networks
        list_networks

        echo "$DIVIDER"

        # Bottom actions
        if [[ -n "$CURRENT_SSID" ]]; then
            echo "󰅙  Disconnect"
            echo "󰴲  Share WiFi (QR)"
        fi
        echo "󱛅  Saved connections"
        echo "󰖪  Turn WiFi OFF"
    else
        echo "󰖪  WiFi is OFF"
        echo "$DIVIDER"
        echo "󰖩  Turn WiFi ON"
    fi
}

# ── Extract SSID from a menu line ────────────
ssid_from_line() {
    echo "$1" | sed -E 's/^󰤟  |^󰤢  |^󰤥  |^󰤨  //' | sed -E 's/ 󰌾$//'
}

# ── Handle selection ─────────────────────────
handle_selection() {
    local choice="$1"

    case "$choice" in
        "󰤨  Connected:"*|"󰤭  Not connected"|"$DIVIDER")
            return ;;

        "󰑐  Rescan networks")
            notify "Scanning…" "Looking for WiFi networks"
            nmcli device wifi rescan 2>/dev/null
            sleep 2
            main
            return ;;

        "󰅙  Disconnect")
            nmcli device disconnect "$DEV" 2>/dev/null
            notify "Disconnected" "WiFi has been disconnected"
            return ;;

        "󰴲  Share WiFi (QR)")
            "$HOME/.local/bin/wifi-share-prompt" &
            return ;;

        "󰖪  Turn WiFi OFF")
            nmcli radio wifi off 2>/dev/null
            notify "WiFi OFF" "Wireless radio disabled"
            return ;;

        "󰖩  Turn WiFi ON")
            nmcli radio wifi on 2>/dev/null
            notify "WiFi ON" "Wireless radio enabled — scanning…"
            sleep 3
            main
            return ;;

        "󱛅  Saved connections")
            show_saved
            return ;;

        "󰖪  WiFi is OFF")
            return ;;

        *)
            local ssid
            ssid=$(ssid_from_line "$choice")

            if [[ -z "$ssid" ]]; then
                return
            fi

            get_status
            if [[ "$CURRENT_SSID" == "$ssid" ]]; then
                notify "Already connected" "You are already on $ssid"
                return
            fi

            # Check if we have a saved connection for this SSID
            local saved_conn
            saved_conn=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep "^${ssid}:802-11-wireless" | cut -d: -f1)

            if [[ -n "$saved_conn" ]]; then
                notify "Connecting…" "Connecting to $ssid"
                if nmcli connection up "$ssid" 2>/dev/null; then
                    notify "Connected ✓" "Successfully connected to $ssid"
                else
                    notify "Failed ✗" "Could not connect to $ssid"
                fi
            else
                # Need password — prompt via rofi
                notify "Connecting…" "Connecting to $ssid"
                local pass
                pass=$(rofi -dmenu $ROFI_ARGS -p "󰌾  Password" \
                    -theme "$THEME" \
                    -mesg "Enter password for <b>$ssid</b>" \
                    -password)

                if [[ -z "$pass" ]]; then
                    return
                fi

                if nmcli device wifi connect "$ssid" password "$pass" 2>/dev/null; then
                    notify "Connected ✓" "Successfully connected to $ssid"
                else
                    notify "Failed ✗" "Wrong password or connection failed"
                fi
            fi
            ;;
    esac
}

# ── Saved connections submenu ────────────────
show_saved() {
    local saved_menu=""
    saved_menu+="⬅  Back\n"
    saved_menu+="$DIVIDER\n"

    while IFS= read -r conn; do
        [[ -n "$conn" ]] && saved_menu+="󰤨  $conn\n"
    done < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null \
        | grep ":802-11-wireless" | cut -d: -f1)

    local choice
    choice=$(echo -e "$saved_menu" | rofi -dmenu $ROFI_ARGS -p "󱛅  Saved" -theme "$THEME" -i)

    [[ -z "$choice" ]] && return

    case "$choice" in
        "⬅  Back")
            main
            return ;;
        "$DIVIDER")
            show_saved
            return ;;
        *)
            local ssid="${choice#󰤨  }"
            local action
            action=$(echo -e "󰤨  Connect\n󰅙  Forget" \
                | rofi -dmenu $ROFI_ARGS -p "  $ssid" -theme "$THEME")

            case "$action" in
                "󰤨  Connect")
                    notify "Connecting…" "Connecting to $ssid"
                    if nmcli connection up "$ssid" 2>/dev/null; then
                        notify "Connected ✓" "Successfully connected to $ssid"
                    else
                        notify "Failed ✗" "Could not connect to $ssid"
                    fi ;;
                "󰅙  Forget")
                    nmcli connection delete "$ssid" 2>/dev/null
                    notify "Forgotten" "$ssid has been removed"
                    show_saved ;;
            esac
            ;;
    esac
}

# ── Main ─────────────────────────────────────
main() {
    local menu
    menu=$(build_menu)
    [[ -z "$menu" ]] && menu="󰤭  No networks found\n$DIVIDER\n󰑐  Rescan networks"

    local choice
    choice=$(echo -e "$menu" | rofi -dmenu $ROFI_ARGS -p "󰖩  WiFi" -theme "$THEME" -i)

    [[ -z "$choice" ]] && exit 0

    handle_selection "$choice"
}

main
