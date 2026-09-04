#!/bin/bash
# Keyboard backlight control via brightnessctl (kbd backlight) with an OSD.
ACTION="$1"

case "$ACTION" in
    up) brightnessctl --device='*kbd*' set 1+ ;;
    down) brightnessctl --device='*kbd*' set 1- ;;
    cycle) brightnessctl --device='*kbd*' set +1% ;;
esac

LEVEL=$(brightnessctl --device='*kbd*' get 2>/dev/null)
MAX=$(brightnessctl --device='*kbd*' max 2>/dev/null)

if [[ -n $LEVEL && -n $MAX && "$MAX" -gt 0 ]]; then
    PCT=$((LEVEL * 100 / MAX))
else
    PCT=""
fi

ICON="keyboard-brightness"
TEXT=${PCT:+${PCT}%}
[[ -z $TEXT ]] && TEXT="Keyboard backlight"

dunstify -r 996 -u low -i "$ICON" "Keyboard backlight" "$TEXT" -t 1500
