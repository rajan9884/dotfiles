#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Keyboard-backlight OSD via swayosd-server.
#   `cycle` wraps max → off (brightnessctl has no wrap for kbd).
# ──────────────────────────────────────────────
ACTION="$1"
DEV="*kbd*"

# Keybind-launched scripts may run without a session bus (tuigreet session
# without dbus-run-session): recover it from the snapshot file.
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    for _busf in "${XDG_RUNTIME_DIR:-/run/user/1000}/session-bus.address" "$HOME/.cache/session-bus"; do
        if [ -s "$_busf" ]; then
            DBUS_SESSION_BUS_ADDRESS=$(cat "$_busf")
            export DBUS_SESSION_BUS_ADDRESS
            break
        fi
    done
    unset _busf
fi

case "$ACTION" in
    up) brightnessctl --device="$DEV" set 1+ >/dev/null 2>&1 ;;
    down) brightnessctl --device="$DEV" set 1- >/dev/null 2>&1 ;;
    cycle)
        LEVEL=$(brightnessctl --device="$DEV" get 2>/dev/null)
        MAX=$(brightnessctl --device="$DEV" max 2>/dev/null)
        if [[ "$LEVEL" =~ ^[0-9]+$ && "$MAX" =~ ^[0-9]+$ ]] && ((MAX > 0)) && ((LEVEL >= MAX)); then
            brightnessctl --device="$DEV" set 0 >/dev/null 2>&1
        else
            brightnessctl --device="$DEV" set 1+ >/dev/null 2>&1
        fi
        ;;
esac

LEVEL=$(brightnessctl --device="$DEV" get 2>/dev/null)
KBMAX=$(brightnessctl --device="$DEV" max 2>/dev/null)
if [[ "$LEVEL" =~ ^[0-9]+$ && "$KBMAX" =~ ^[0-9]+$ ]] && ((KBMAX > 0)); then
    KBPCT=$(( LEVEL * 100 / KBMAX ))
    (( KBPCT > 100 )) && KBPCT=100
    KBFRAC=$(awk -v l="$LEVEL" -v m="$KBMAX" 'BEGIN{ f=(m>0)?l/m:0; if (f>1) f=1; if (f<0) f=0; printf "%.2f", f }')
    if (( KBPCT > 0 )); then
        KBICON="keyboard-brightness-symbolic"
        KBTEXT="$KBPCT%"
    else
        KBICON="keyboard-brightness-symbolic"
        KBTEXT="Off"
    fi
    timeout 3 swayosd-client --custom-icon "$KBICON" --custom-progress "$KBFRAC" --custom-progress-text "$KBTEXT" 2>/dev/null
else
    timeout 3 swayosd-client --custom-icon keyboard-brightness-symbolic \
        --custom-progress 0 --custom-progress-text "No keyboard" 2>/dev/null
fi
