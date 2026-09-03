#!/bin/bash
ACTION="$1"

case "$ACTION" in
    up) brightnessctl set 5%+ ;;
    down) brightnessctl set 5%- ;;
    max) brightnessctl set 100% ;;
    min) brightnessctl set 1% ;;
esac

LEVEL=$(brightnessctl get)
MAX=$(brightnessctl max)
PCT=$((LEVEL * 100 / MAX))

if [ "$PCT" -eq 0 ]; then
    ICON="display-brightness-off"
elif [ "$PCT" -lt 30 ]; then
    ICON="display-brightness-low"
elif [ "$PCT" -lt 70 ]; then
    ICON="display-brightness-medium"
else
    ICON="display-brightness-high"
fi

dunstify -r 997 -u low -i "$ICON" "Brightness" "${PCT}%" -t 1500
