#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Wi-Fi / Network Menu for Waybar (rofi + nmcli)
#   Uniform rows,
#   hover-highlight, single-click accepts.
#   Low-latency: builds from a single nmcli scan.
# ──────────────────────────────────────────────

THEME="$HOME/.config/rofi/wifi-menu.rasi"
INPUT_THEME="$HOME/.config/rofi/wifi-input.rasi"

I_SIG4=$'\U000F0928'     # md-wifi_strength_4
I_SIG3=$'\U000F0925'     # md-wifi_strength_3
I_SIG2=$'\U000F0922'     # md-wifi_strength_2
I_SIG1=$'\U000F091F'     # md-wifi_strength_1
I_SIG0=$'\U000F092D'     # md-wifi_strength_off
I_WIFIOFF=$'\U000F05AA'  # md-wifi_off
I_WIFIOUT=$'\U000F092F'  # md-wifi_strength_outline
I_LOCK=$'\U000F033E'     # md-lock
I_HIDDEN=$'\U000F0209'   # md-eye_off
I_DETAILS=$'\U000F02FD'  # md-information_outline
I_EDIT=$'\U000F062E'     # md-tune
I_LINKOFF=$'\U000F0338'  # md-link_off
I_NET=$'\U000F1616'      # md-connection
I_CHEVRON=$'\U000F0142'  # md-chevron_right
I_CHECK=$'\U000F012C'    # md-check

FOOTER=""
ACTIVE_WIFI_NAME=""

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

# One nmcli call for everything the menu needs from a scan.
# Emits:  ACTIVE<TAB>ssid<TAB>signal
#         signal<TAB>ssid<TAB>security     (deduped, strongest first)
scan_networks() {
    nmcli -e yes -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list --rescan no 2>/dev/null |
        python3 -c '
import sys, re
def unesc(s): return re.sub(r"\\(.)", r"\1", s)
best = {}
active = None
for line in sys.stdin:
    p = re.split(r"(?<!\\):", line.rstrip("\n"))
    if len(p) < 4:
        continue
    ssid = unesc(p[0]).strip() or "<hidden>"
    sec  = unesc(p[2]).strip()
    try:
        sig = int(p[1])
    except ValueError:
        sig = 0
    if p[3] == "yes" and active is None and ssid != "<hidden>":
        active = (ssid, sig)
    if ssid == "<hidden>":
        continue
    if ssid not in best or sig > best[ssid][0]:
        best[ssid] = (sig, sec)
a_ssid, a_sig = active if active else ("", "0")
print("ACTIVE\x1f%s\x1f%s" % (a_ssid, a_sig))
for ssid, (sig, sec) in sorted(best.items(), key=lambda kv: -kv[1][0]):
    print("%d\x1f%s\x1f%s" % (sig, ssid, sec))
'
}

# One row, always the same shape:  ICON  LABEL……………  ACCESSORY
row() {
    local icon="$1" label="$2" acc="${3:-}"
    printf '%s  %-24s%s\n' "$icon" "$label" "$acc"
}

build_menu() {
    local radio networking
    radio="$(get_radio)"
    networking="$(get_networking)"

    ACTIVE_WIFI_NAME="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null |
        awk -F: '$2=="802-11-wireless"{print $1; exit}')"

    if [[ "$radio" == "disabled" ]]; then
        FOOTER="Wi-Fi is off — click “Turn Wi-Fi ON” to enable"
        row "$I_WIFIOFF" "Turn Wi-Fi ON"
        row "$I_HIDDEN" "Hidden Network…" "$I_CHEVRON"
        row "$I_EDIT" "Edit Connections…" "$I_CHEVRON"
        if [[ "$networking" == "disabled" ]]; then
            row "$I_NET" "Enable Networking"
        else
            row "$I_NET" "Disable Networking"
        fi
        return
    fi

    # Kick a fresh scan in the background so the NEXT menu open is current;
    # this open renders instantly from cached results.
    nmcli dev wifi rescan 2>/dev/null &

    local active_ssid="" active_sig="0" sig ssid sec line
    declare -A _seen=()
    {
        IFS=$'\x1f' read -r _ active_ssid active_sig
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            IFS=$'\x1f' read -r sig ssid sec <<< "$line"
            [[ -z "$ssid" || "$ssid" == "$active_ssid" ]] && continue
            _seen["$ssid"]=1
            local acc=""
            [[ "$sec" == *"WPA"* || "$sec" == *"WEP"* ]] && acc="$I_LOCK"
            row "$(signal_icon "$sig")" "$ssid" "$acc"
        done
    } < <(scan_networks)

    # Fallback: always show saved infrastructure profiles even if the
    # scan cache was empty (driver mid-scan) so menu is never empty.
    # Never re-list the currently active connection as available.
    while IFS= read -r _name; do
        [[ -z "$_name" ]] && continue
        _ssid="$(nmcli -g 802-11-wireless.ssid connection show "$_name" 2>/dev/null)"
        _mode="$(nmcli -g 802-11-wireless.mode connection show "$_name" 2>/dev/null)"
        [[ -z "$_ssid" || "$_ssid" == "$active_ssid" || "$_ssid" == "$ACTIVE_WIFI_NAME" ]] && continue
        [[ -n "${_seen[$_ssid]:-}" ]] && continue
        [[ "$_mode" == "ap" ]] && continue
        _seen["$_ssid"]=1
        row "$I_WIFIOUT" "$_ssid" "$I_LOCK"
    done < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1}')

    # Scan can miss the active BSSID for a second (mid-scan). Fall back
    # to NM's active profile so footer/disconnect never lie.
    _display_active="$active_ssid"
    _display_sig="$active_sig"
    if [[ -z "$_display_active" && -n "$ACTIVE_WIFI_NAME" ]]; then
        _display_active="$ACTIVE_WIFI_NAME"
        _display_sig="?"
    fi

    if [[ -n "$_display_active" ]]; then
        if [[ "$_display_sig" == "?" ]]; then
            FOOTER="$I_CHECK Connected: $_display_active — click a network to switch"
        else
            FOOTER="$I_CHECK Connected: $_display_active (${_display_sig}%) — click a network to switch"
        fi
    else
        FOOTER="No Wi-Fi connection — click a network to connect"
    fi

    if [[ -n "$active_ssid" || -n "$ACTIVE_WIFI_NAME" ]]; then
        row "$I_LINKOFF" "Disconnect"
    fi
    row "$I_HIDDEN" "Hidden Network…" "$I_CHEVRON"
    row "$I_DETAILS" "Connection Details…" "$I_CHEVRON"
    row "$I_EDIT" "Edit Connections…" "$I_CHEVRON"
    row "$I_WIFIOFF" "Turn Wi-Fi OFF"
    if [[ "$networking" == "disabled" ]]; then
        row "$I_NET" "Enable Networking"
    else
        row "$I_NET" "Disable Networking"
    fi
}

connect_network() {
    local ssid="$1"
    # Prefer saved profile — required for WPA-EAP (srmap-byod).
    # `nmcli dev wifi connect` creates a NEW PSK profile and will
    # always fail / re-prompt password on enterprise networks.
    if nmcli -t -f NAME connection show 2>/dev/null | grep -Fxq -- "$ssid"; then
        notify "Connecting…" "Connecting to $ssid"
        if nmcli connection up "$ssid" 2>&1 | grep -qiE "success|already"; then
            notify "Connected ✓" "Connected to $ssid"
            return 0
        fi
        # If saved profile failed, check why before prompting PSK.
        local keymgmt
        keymgmt="$(nmcli -g 802-11-wireless-security.key-mgmt connection show "$ssid" 2>/dev/null)"
        if [[ "$keymgmt" == *wpa-eap* ]]; then
            notify "Failed ✗" "Saved $ssid (802.1X) failed — check identity/password in Edit Connections"
            return 1
        fi
        # PSK saved profile failed (wrong key?) — fall through to password prompt.
    else
        notify "Connecting…" "Connecting to $ssid"
        if nmcli dev wifi connect "$ssid" 2>/dev/null; then
            notify "Connected ✓" "Connected to $ssid"
            return 0
        fi
    fi

    local pw
    pw="$(rofi -dmenu -password -p "Password for $ssid" -theme "$INPUT_THEME")"
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
    ssid="$(rofi -dmenu -p "Hidden network SSID" -theme "$INPUT_THEME")"
    [[ -z "$ssid" ]] && return
    connect_network "$ssid"
}

connection_details() {
    local iface ssid
    iface="$(wifi_iface)"
    ssid="$(nmcli -e no -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
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

pango_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '%s' "$s"
}

handle_selection() {
    local choice="$1"
    # trim trailing whitespace so padded rows match their exact labels
    choice="${choice%"${choice##*[![:space:]]}"}"

    case "$choice" in
        "$I_WIFIOFF  Turn Wi-Fi ON")
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

        "$I_HIDDEN  Hidden Network…"*)
            hidden_network
            sleep 1
            main ;;

        "$I_DETAILS  Connection Details…"*)
            connection_details ;;

        "$I_EDIT  Edit Connections…"*)
            if command -v nm-connection-editor >/dev/null 2>&1; then
                nm-connection-editor
            else
                notify "Not installed" "Install network-manager-applet for the editor"
            fi ;;

        "$I_LINKOFF  Disconnect")
            if [[ -z "$ACTIVE_WIFI_NAME" ]]; then
                notify "Nothing to disconnect" "No active Wi-Fi connection"
            else
                nmcli connection down "$ACTIVE_WIFI_NAME" 2>/dev/null
                notify "Disconnected" "Disconnected from $ACTIVE_WIFI_NAME"
            fi
            sleep 1
            main ;;

        "$I_SIG4"*|"$I_SIG3"*|"$I_SIG2"*|"$I_SIG1"*|"$I_SIG0"*)
            # a network row:  SIGICON  ssid  [LOCK]
            local ssid
            ssid="$(python3 - "$choice" <<'PY'
import sys, re
s = sys.argv[1]
toks = [t for t in re.split(r"\s{2,}", s) if t]
name = toks[1] if len(toks) >= 2 else (toks[0] if toks else "")
print(re.sub(r"\\(.)", r"\1", name))
PY
)"
            [[ -z "$ssid" ]] && return
            connect_network "$ssid"
            sleep 1
            main ;;

        *)
            notify "Nothing selected" "Pick a network or an action"
            ;;
    esac
}

main() {
    local choice tmp
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    FOOTER=""
    build_menu > "$tmp"
    # hover highlights rows, single left click accepts them (no more dead clicks)
    choice="$(rofi -dmenu -i \
        -selected-row 0 \
        -hover-select \
        -me-select-entry '' \
        -me-accept-entry MousePrimary \
        -p "$I_SIG4  Wi-Fi" \
        -mesg "$(pango_escape "$FOOTER")" \
        -theme "$THEME" < "$tmp")"
    [[ -z "$choice" ]] && exit 0
    handle_selection "$choice"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi