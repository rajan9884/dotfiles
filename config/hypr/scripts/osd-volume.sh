#!/bin/bash
# ──────────────────────────────────────────────
#   Volume OSD via swayosd-server (compact native OSD).
#   pactl makes the change (exact 5% steps, 150% ceiling);
#   swayosd-client renders icon + bar + percentage text.
# ──────────────────────────────────────────────
ACTION="$1"
SINK="@DEFAULT_SINK@"
MAX=150

case "$ACTION" in
    up) pactl set-sink-volume "$SINK" +5% ;;
    down) pactl set-sink-volume "$SINK" -5% ;;
    mute-toggle) pactl set-sink-mute "$SINK" toggle ;;
    mic-toggle) swayosd-client --input-volume mute-toggle; exit 0 ;;
esac

PCT=$(pactl get-sink-volume "$SINK" | grep -oP '\d+(?=%)' | head -1)
if [ "$PCT" -gt "$MAX" ]; then
    pactl set-sink-volume "$SINK" "$MAX%"
    PCT=$MAX
fi

if pactl get-sink-mute "$SINK" | grep -q yes; then
    ICON="audio-volume-muted"
    TEXT="Muted"
elif [ "$PCT" -ge 70 ]; then
    ICON="audio-volume-high"
    TEXT="$PCT%"
elif [ "$PCT" -ge 35 ]; then
    ICON="audio-volume-medium"
    TEXT="$PCT%"
else
    ICON="audio-volume-low"
    TEXT="$PCT%"
fi

FRAC=$(awk -v p="$PCT" -v m="$MAX" 'BEGIN{ f=p/m; if (f>1) f=1; printf "%.2f", f }')
swayosd-client --custom-icon "$ICON" --custom-progress "$FRAC" --custom-progress-text "$TEXT"
