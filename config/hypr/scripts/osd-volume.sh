#!/bin/bash
SINK="@DEFAULT_AUDIO_SINK@"
ACTION="$1"

case "$ACTION" in
    up) wpctl set-volume "$SINK" 5%+ ;;
    down) wpctl set-volume "$SINK" 5%- ;;
    mute-toggle) wpctl set-mute "$SINK" toggle ;;
    mic-toggle) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
esac

VOL=$(wpctl get-volume "$SINK" | awk '{print $2}')
MUTED=$(wpctl get-volume "$SINK" | grep -o "MUTED" || true)

if [ "$MUTED" = "MUTED" ]; then
    ICON="audio-volume-muted"
    TEXT="Muted"
else
    PCT=$(echo "$VOL" | awk '{printf "%d", $1 * 100}')
    if [ "$PCT" -eq 0 ]; then
        ICON="audio-volume-muted"
    elif [ "$PCT" -lt 30 ]; then
        ICON="audio-volume-low"
    elif [ "$PCT" -lt 70 ]; then
        ICON="audio-volume-medium"
    else
        ICON="audio-volume-high"
    fi
    TEXT="${PCT}%"
fi

dunstify -r 998 -u low -i "$ICON" "Volume" "$TEXT" -t 1500
