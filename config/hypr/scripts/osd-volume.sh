#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Volume OSD via swayosd-server (compact native OSD).
#   pactl makes the change (exact 5% steps, 150% ceiling);
#   swayosd-client renders icon + bar + percentage text.
#   Runit-safe: ensures swayosd-server is running (no systemd),
#   timeouts every audio call so a stuck pipewire can't hang keys.
# ──────────────────────────────────────────────
ACTION="$1"
SINK="@DEFAULT_SINK@"
MAX=150

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

run_timeout() { timeout 3 "$@" 2>/dev/null; }

case "$ACTION" in
    up)
        run_timeout pactl set-sink-volume "$SINK" +5% \
        || run_timeout wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down)
        run_timeout pactl set-sink-volume "$SINK" -5% \
        || run_timeout wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute-toggle)
        run_timeout pactl set-sink-mute "$SINK" toggle \
        || run_timeout wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    mic-toggle)
        run_timeout swayosd-client --input-volume mute-toggle
        exit 0 ;;
esac

PCT=$(run_timeout pactl get-sink-volume "$SINK" | grep -oP '\d+(?=%)' | head -1)
# Fallback: wpctl reports "Volume: 0.75" (fraction) or "0.75 [MUTED]".
if [[ -z "$PCT" ]]; then
    FRAC_RAW=$(run_timeout wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oP '\d+\.\d+' | head -1)
    if [[ -n "$FRAC_RAW" ]]; then
        PCT=$(awk -v f="$FRAC_RAW" 'BEGIN{ printf "%d", f*100 }')
    fi
fi

# Audio stack unreachable: still show an OSD so the key feels alive.
if [[ -z "$PCT" ]]; then
    run_timeout swayosd-client --custom-icon audio-volume-muted-symbolic \
        --custom-progress 0 --custom-progress-text "No audio"
    exit 0
fi

if [ "$PCT" -gt "$MAX" ]; then
    run_timeout pactl set-sink-volume "$SINK" "$MAX%" \
    || run_timeout wpctl set-volume @DEFAULT_AUDIO_SINK@ "$MAX%"
    PCT=$MAX
fi

if run_timeout pactl get-sink-mute "$SINK" | grep -q yes \
    || run_timeout wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -qi '\[MUTED\]'; then
    ICON="audio-volume-muted-symbolic"
    TEXT="Muted"
elif [ "$PCT" -ge 70 ]; then
    ICON="audio-volume-high-symbolic"
    TEXT="$PCT%"
elif [ "$PCT" -ge 35 ]; then
    ICON="audio-volume-medium-symbolic"
    TEXT="$PCT%"
else
    ICON="audio-volume-low-symbolic"
    TEXT="$PCT%"
fi

FRAC=$(awk -v p="$PCT" -v m="$MAX" 'BEGIN{ f=p/m; if (f>1) f=1; if (f<0) f=0; printf "%.2f", f }')
run_timeout swayosd-client --custom-icon "$ICON" --custom-progress "$FRAC" --custom-progress-text "$TEXT"
