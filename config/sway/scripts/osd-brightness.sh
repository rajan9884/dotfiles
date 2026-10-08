#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Brightness OSD via swayosd-server (compact native OSD).
#   brightnessctl makes the change (exact 5% steps, backlight
#   class only); swayosd-client renders icon + bar +
#   percentage text. (swayosd's own ±N math is percent-based
#   and asymmetric — not trustworthy here.)
#   Runit-safe: ensures swayosd-server is running (no systemd).
# ──────────────────────────────────────────────
ACTION="$1"

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

# 1. Server must be up or no OSD appears at all.
if ! pgrep -x swayosd-server >/dev/null 2>&1; then
    swayosd-server >/dev/null 2>&1 &
    sleep 0.4
fi

case "$ACTION" in
    up) brightnessctl -c backlight set 5%+ >/dev/null 2>&1 ;;
    down) brightnessctl -c backlight set 5%- >/dev/null 2>&1 ;;
    max) brightnessctl -c backlight set 100% >/dev/null 2>&1 ;;
    min) brightnessctl -c backlight set 1% >/dev/null 2>&1 ;;
esac

INFO=$(brightnessctl -c backlight -m 2>/dev/null | head -1)
if [[ -z "$INFO" ]]; then
    timeout 3 swayosd-client --custom-icon display-brightness-off-symbolic \
        --custom-progress 0 --custom-progress-text "No backlight" 2>/dev/null
    exit 0
fi
CUR=$(printf '%s' "$INFO" | cut -d, -f3)
MAXV=$(printf '%s' "$INFO" | cut -d, -f5)
PCT=$(printf '%s' "$INFO" | cut -d, -f4 | tr -d '%')
[[ "$CUR" =~ ^[0-9]+$ ]] || CUR=0
[[ "$MAXV" =~ ^[0-9]+$ && "$MAXV" != "0" ]] || MAXV=100
[[ "$PCT" =~ ^[0-9]+$ ]] || PCT=0
FRAC=$(awk -v c="$CUR" -v m="$MAXV" 'BEGIN{ f=(m>0)?c/m:0; if (f>1) f=1; if (f<0) f=0; printf "%.2f", f }')

if (( PCT >= 70 )); then
    BICON="display-brightness-high-symbolic"
elif (( PCT >= 35 )); then
    BICON="display-brightness-medium-symbolic"
elif (( PCT > 0 )); then
    BICON="display-brightness-low-symbolic"
else
    BICON="display-brightness-off-symbolic"
fi

timeout 3 swayosd-client --custom-icon "$BICON" --custom-progress "$FRAC" --custom-progress-text "$PCT%" 2>/dev/null
# Persist raw value for login restore (see sway config backlight-restore).
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}" 2>/dev/null
printf '%s\n' "$CUR" > "${XDG_STATE_HOME:-$HOME/.local/state}/backlight" 2>/dev/null || true
