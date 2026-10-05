#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Bluetooth Menu for Waybar (rofi + bluetoothctl)
#   Uniform rows,
#   hover-highlight, single-click accepts.
# ──────────────────────────────────────────────

THEME="$HOME/.config/rofi/bluetooth-menu.rasi"

POSITION="$1"
ROFI_ARGS=""
if [[ "$POSITION" == "left" ]]; then
    ROFI_ARGS="-location 7 -xoffset 60 -yoffset -20"
fi

I_BT=$'\U000F00AF'      # md-bluetooth
I_BTOFF=$'\U000F00B2'   # md-bluetooth_off
I_SCAN=$'\U000F0437'    # md-radar
I_AUDIO=$'\U000F02CB'   # md-headphones
I_KB=$'\U000F030C'      # md-keyboard
I_MOUSE=$'\U000F037D'   # md-mouse
I_GAME=$'\U000F0297'    # md-gamepad_variant
I_PHONE=$'\U000F03F2'   # md-phone
I_PC=$'\U000F0379'      # md-monitor
I_DISC=$'\U000F0338'    # md-link_off
I_REMOVE=$'\U000F01B4'  # md-delete
I_BACK=$'\U000F004D'    # md-arrow_left
I_CHEVRON=$'\U000F0142' # md-chevron_right
I_CHECK=$'\U000F012C'   # md-check

FOOTER=""
ROFI=""
BT_POWERED=""
BT_CONNECTED=""
BT_PAIRED_MACS=""

notify() {
    local dur=4000
    if [[ "$1" == "-t" ]]; then dur="$2"; shift 2; fi
    notify-send -a "Bluetooth" -i bluetooth -t "$dur" "$1" "$2"
}

get_state() {
    BT_POWERED=$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')
    BT_CONNECTED=$(bluetoothctl devices Connected 2>/dev/null | cut -d' ' -f3-)
    BT_PAIRED_MACS=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')
}

row() {
    local icon="$1" label="$2" acc="${3:-}"
    printf '%s  %-24s%s\n' "$icon" "$label" "$acc"
}

pango_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '%s' "$s"
}

build_menu() {
    get_state

    if [[ "$BT_POWERED" != "yes" ]]; then
        FOOTER="Bluetooth is off — click to enable"
        row "$I_BTOFF" "Turn Bluetooth ON"
        return
    fi

    FOOTER="No devices connected — tap a device to interact"
    [[ -n "$BT_CONNECTED" ]] && FOOTER="Connected: $BT_CONNECTED — tap a device to manage"

    row "$I_SCAN" "Scan for devices"

    # Paired devices
    local has_paired=false
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local mac name info is_connected icon_type icon
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)
        [[ -z "$name" ]] && name="$mac"
        info=$(bluetoothctl info "$mac" 2>/dev/null)
        is_connected=$(echo "$info" | awk -F': ' '/Connected:/{print $2; exit}')
        icon_type=$(echo "$info" | awk -F': ' '/Icon:/{print $2; exit}')
        icon="$I_BT"
        case "$icon_type" in
            audio*|headset|headphones) icon="$I_AUDIO" ;;
            input-keyboard)           icon="$I_KB" ;;
            input-mouse)              icon="$I_MOUSE" ;;
            input-gaming)             icon="$I_GAME" ;;
            phone)                    icon="$I_PHONE" ;;
            computer)                 icon="$I_PC" ;;
        esac
        local acc=""
        [[ "$is_connected" == "yes" ]] && acc="$I_CHECK"
        row "$icon" "$name" "$acc"
        has_paired=true
    done < <(bluetoothctl devices Paired 2>/dev/null)

    # Scanned but not paired (visible while scanning)
    if [[ "$has_paired" == "true" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            local mac name
            mac=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | cut -d' ' -f3-)
            [[ -z "$name" || "$name" == "$mac" ]] && continue
            echo "$BT_PAIRED_MACS" | grep -q "$mac" && continue
            row "$I_SCAN" "$name" "$I_CHEVRON"
        done < <(bluetoothctl devices 2>/dev/null)
    fi

    if [[ -n "$BT_CONNECTED" ]]; then
        row "$I_DISC" "Disconnect all"
    fi
    row "$I_BTOFF" "Turn Bluetooth OFF"
}

device_action_menu() {
    local name="$1" mac="$2" is_connected="$3" is_paired="$4"

    local options=""

    if [[ "$is_connected" == "yes" ]]; then
        options="$(printf '%s\n%s\n%s' \
            "$I_DISC  Disconnect" \
            "$I_REMOVE  Remove" \
            "$I_BACK  Back")"
    elif [[ "$is_paired" == "yes" ]]; then
        options="$(printf '%s\n%s\n%s' \
            "$I_BTCON  Connect" \
            "$I_REMOVE  Remove" \
            "$I_BACK  Back")"
    fi

    local action
    action=$(echo "$options" | rofi -dmenu -i $ROFI_ARGS \
        -selected-row 0 -hover-select -me-select-entry '' -me-accept-entry MousePrimary \
        -p "  $name" -theme "$THEME")

    case "$action" in
        "$I_DISC  Disconnect")
            bluetoothctl disconnect "$mac" 2>/dev/null
            notify "Disconnected" "$name disconnected" ;;

        "$I_BTCON  Connect")
            notify "Connecting…" "Connecting to $name"
            bluetoothctl connect "$mac" 2>/dev/null
            sleep 2
            local check
            check=$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/{print $2; exit}')
            if [[ "$check" == "yes" ]]; then
                notify "Connected ✓" "Successfully connected to $name"
            else
                notify "Failed ✗" "Could not connect to $name"
            fi ;;

        "$I_REMOVE  Remove")
            bluetoothctl remove "$mac" 2>/dev/null
            notify "Removed" "$name has been unpaired" ;;

        "$I_BACK  Back")
            main ;;

        "") return ;;
    esac
}

handle_selection() {
    local choice="$1"
    choice="${choice%"${choice##*[![:space:]]}"}"

    case "$choice" in
        "$I_BTOFF  Turn Bluetooth ON")
            bluetoothctl power on 2>/dev/null
            notify "Bluetooth ON" "Bluetooth radio enabled"
            sleep 1
            main ;;

        "$I_BTOFF  Turn Bluetooth OFF")
            bluetoothctl power off 2>/dev/null
            notify "Bluetooth OFF" "Bluetooth radio disabled" ;;

        "$I_SCAN  Scan for devices")
            notify "Scanning…" "Looking for nearby devices"
            bluetoothctl --timeout 8 scan on 2>/dev/null &
            sleep 5
            main ;;

        "$I_DISC  Disconnect all")
            bluetoothctl devices Connected 2>/dev/null | while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                local mac
                mac=$(echo "$line" | awk '{print $2}')
                bluetoothctl disconnect "$mac" 2>/dev/null
            done
            notify "Disconnected" "All devices disconnected" ;;

        "$I_BT"*|"$I_AUDIO"*|"$I_KB"*|"$I_MOUSE"*|"$I_GAME"*|"$I_PHONE"*|"$I_PC"*|"$I_SCAN"*)
            local name
            name="$(python3 - "$choice" <<'PY'
import sys, re
s = sys.argv[1]
toks = [t for t in re.split(r"\s{2,}", s) if t]
name = toks[1] if len(toks) >= 2 else (toks[0] if toks else "")
print(re.sub(r"\\(.)", r"\1", name))
PY
)"
            [[ -z "$name" ]] && return
            local mac
            mac=$(bluetoothctl devices 2>/dev/null | awk -v n="$name" '$0 ~ " "n {print $2; exit}')
            [[ -z "$mac" ]] && { notify "Error" "Could not find device: $name"; return; }
            local info is_connected is_paired
            info=$(bluetoothctl info "$mac" 2>/dev/null)
            is_connected=$(echo "$info" | awk -F': ' '/Connected:/{print $2; exit}')
            is_paired=$(echo "$info" | awk -F': ' '/Paired:/{print $2; exit}')

            if [[ "$is_paired" == "yes" ]]; then
                device_action_menu "$name" "$mac" "$is_connected" "$is_paired"
            else
                notify "Pairing…" "Pairing with $name"
                bluetoothctl pair "$mac" 2>/dev/null
                sleep 3
                local pair_check
                pair_check=$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Paired:/{print $2; exit}')
                if [[ "$pair_check" == "yes" ]]; then
                    bluetoothctl trust "$mac" 2>/dev/null
                    notify "Connecting…" "Paired! Connecting to $name"
                    bluetoothctl connect "$mac" 2>/dev/null
                    sleep 2
                    local conn_check
                    conn_check=$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Connected:/{print $2; exit}')
                    if [[ "$conn_check" == "yes" ]]; then
                        notify "Connected ✓" "Successfully connected to $name"
                    else
                        notify "Paired ✓" "Paired but couldn't auto-connect to $name"
                    fi
                else
                    notify "Failed ✗" "Could not pair with $name"
                fi
            fi ;;

        *) notify "Nothing selected" "Pick a device or an action" ;;
    esac
}

main() {
    local choice tmp
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    FOOTER=""
    build_menu > "$tmp"
    choice=$(rofi -dmenu -i $ROFI_ARGS \
        -selected-row 0 \
        -hover-select \
        -me-select-entry '' \
        -me-accept-entry MousePrimary \
        -p "$I_BT  Bluetooth" \
        -mesg "$(pango_escape "$FOOTER")" \
        -theme "$THEME" < "$tmp")
    [[ -z "$choice" ]] && exit 0
    handle_selection "$choice"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
