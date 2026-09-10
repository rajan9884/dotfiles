#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   WiFi Menu for Waybar (rofi + nmcli)
# ──────────────────────────────────────────────

# Use active theme script style
THEME="$HOME/.config/rofi/active-scripts.rasi"
DIVIDER="────────────────────────────"

# Omarchy-style: keyboard-driven, instant filtering, no icon/mouse steal.
# -show-icons: skip Papirus lookup per row (major hang source)
# -hover-select: keep keyboard focus (like walker's force_keyboard_focus)
# -matching fuzzy + fzf sort: fast keyword narrowing like omarchy.menu
# NOTE: no -kb-row-* flags: rofi 2.0.0-dirty hangs parsing most kb
# overrides (verified headless). Defaults already include Ctrl+p/n + arrows.
ROFI_PERF="-show-icons -hover-select -matching fuzzy -sorting-method fzf -sort -tokenize -threads 0 -me-accept-entry MousePrimary -no-fixed-num-lines"

# Cached scan is ~0.01s; a fresh scan blocks ~5s and hangs the menu.
# Always read cache instantly, kick a background rescan for next open.
WIFI_LIST_ARGS="--rescan no"
kick_rescan() {
    (timeout 15 nmcli device wifi rescan >/dev/null 2>&1 &) 2>/dev/null
}

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
# All nmcli calls use `timeout` so a stalled NetworkManager can never hang
# the menu, and never trigger a synchronous wifi scan (see WIFI_LIST_ARGS).
get_status() {
    local dev_state
    dev_state=$(timeout 3 nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | grep ":wifi:" | head -1)
    DEV=$(echo "$dev_state" | cut -d: -f1)

    if [[ -z "$DEV" ]]; then
        WIFI_STATE="disabled"
        return
    fi

    local conn_info
    conn_info=$(timeout 3 nmcli -t -f NAME,DEVICE,STATE connection show --active 2>/dev/null | grep ":${DEV}:" | head -1)

    if [[ -n "$conn_info" ]]; then
        WIFI_STATE="enabled"
        CURRENT_SSID=$(echo "$conn_info" | cut -d: -f1)
        local ip_info
        ip_info=$(timeout 3 nmcli -t -f IP4.ADDRESS device show "$DEV" 2>/dev/null | head -1)
        CURRENT_IP=$(echo "$ip_info" | cut -d: -f2 | cut -d/ -f1)
        SIGNAL=""
    else
        WIFI_STATE="enabled"
        CURRENT_SSID=""
        CURRENT_IP=""
        SIGNAL=""
    fi
}

# ── List available networks (SSID, security) ─
# Single cached `nmcli` call + awk (no per-line bash/sed/sort subshells).
# Parses from the right (IN-USE is last field) so SSIDs containing ':' work.
list_networks() {
    timeout 4 nmcli -t -f SSID,SECURITY,IN-USE device wifi list $WIFI_LIST_ARGS 2>/dev/null \
        | awk -F: '
            {
                inuse = $NF
                if (inuse == "*") next
                # drop last field (IN-USE), rejoin rest as SSID:SECURITY
                sub(/:[^:]*$/, "")
                # SECURITY is after last remaining colon; SSID may contain colons
                n = split($0, parts, ":")
                sec = parts[n]
                ssid = substr($0, 1, length($0) - length(sec) - 1)
                # unescape nmcli \: -> :
                gsub(/\\:/, ":", ssid)
                if (ssid == "" || ssid == "--") next
                lock = (sec == "" ? "" : " 󰌾")
                key = ssid lock
                if (!(key in seen)) {
                    seen[key] = 1
                    printf "󰤟  %s%s\n", ssid, lock
                }
            }'
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
# Pure bash (no sed fork per selection) + strips lock suffix.
ssid_from_line() {
    local line="$1"
    line="${line#󰤟  }"
    line="${line#󰤢  }"
    line="${line#󰤥  }"
    line="${line#󰤨  }"
    line="${line% 󰌾}"
    printf '%s' "$line"
}

# ── Handle selection ─────────────────────────
handle_selection() {
    local choice="$1"

    case "$choice" in
        "󰤨  Connected:"*|"󰤭  Not connected"|"$DIVIDER")
            return ;;

        "󰑐  Rescan networks")
            notify "Scanning…" "Looking for WiFi networks"
            timeout 15 nmcli device wifi rescan >/dev/null 2>&1 &
            # Brief pause for APs to appear, then reopen from fresh cache
            sleep 4
            main
            return ;;

        "󰅙  Disconnect")
            timeout 5 nmcli device disconnect "$DEV" 2>/dev/null
            notify "Disconnected" "WiFi has been disconnected"
            return ;;

        "󰴲  Share WiFi (QR)")
            "$HOME/.local/bin/wifi-share-prompt" &
            return ;;

        "󰖪  Turn WiFi OFF")
            timeout 5 nmcli radio wifi off 2>/dev/null
            notify "WiFi OFF" "Wireless radio disabled"
            return ;;

        "󰖩  Turn WiFi ON")
            timeout 5 nmcli radio wifi on 2>/dev/null
            notify "WiFi ON" "Wireless radio enabled — scanning…"
            timeout 15 nmcli device wifi rescan >/dev/null 2>&1 &
            sleep 4
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
            # Fixed-string match: SSID may contain regex chars (., *, [ ])
            local saved_conn
            saved_conn=$(timeout 3 nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep -F "${ssid}:802-11-wireless" | cut -d: -f1)

            if [[ -n "$saved_conn" ]]; then
                notify "Connecting…" "Connecting to $ssid"
                if timeout 20 nmcli connection up "$ssid" 2>/dev/null; then
                    notify "Connected ✓" "Successfully connected to $ssid"
                else
                    notify "Failed ✗" "Could not connect to $ssid"
                fi
            else
                # Need password — prompt via rofi
                notify "Connecting…" "Connecting to $ssid"
                local pass
                pass=$(rofi -dmenu $ROFI_ARGS $ROFI_PERF -p "󰌾  Password" \
                    -theme "$THEME" \
                    -mesg "Enter password for <b>$ssid</b>" \
                    -password)

                if [[ -z "$pass" ]]; then
                    return
                fi

                if timeout 25 nmcli device wifi connect "$ssid" password "$pass" 2>/dev/null; then
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
    done < <(timeout 3 nmcli -t -f NAME,TYPE connection show 2>/dev/null \
        | grep ":802-11-wireless" | cut -d: -f1)

    local choice
    choice=$(echo -e "$saved_menu" | rofi -dmenu $ROFI_ARGS $ROFI_PERF -p "󱛅  Saved" -theme "$THEME" -i)

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
                | rofi -dmenu $ROFI_ARGS $ROFI_PERF -p "  $ssid" -theme "$THEME")

            case "$action" in
                "󰤨  Connect")
                    notify "Connecting…" "Connecting to $ssid"
                    if timeout 20 nmcli connection up "$ssid" 2>/dev/null; then
                        notify "Connected ✓" "Successfully connected to $ssid"
                    else
                        notify "Failed ✗" "Could not connect to $ssid"
                    fi ;;
                "󰅙  Forget")
                    timeout 5 nmcli connection delete "$ssid" 2>/dev/null
                    notify "Forgotten" "$ssid has been removed"
                    show_saved ;;
            esac
            ;;
    esac
}

# ── Main ─────────────────────────────────────
main() {
    kick_rescan
    local menu
    menu=$(build_menu)
    [[ -z "$menu" ]] && menu="󰤭  No networks found\n$DIVIDER\n󰑐  Rescan networks"

    local choice
    choice=$(echo -e "$menu" | rofi -dmenu $ROFI_ARGS $ROFI_PERF -p "󰖩  WiFi" -theme "$THEME" -i)

    [[ -z "$choice" ]] && exit 0

    handle_selection "$choice"
}

main
