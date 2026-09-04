#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Notification History
#   Opens the SwayNC notification center.
# ──────────────────────────────────────────────

set -euo pipefail

THEME="$HOME/.config/rofi/active-picker.rasi"

if pgrep -x swaync >/dev/null 2>&1; then
    swaync-client -t -sw
    exit 0
fi

rofi -dmenu -p "Notifications" -theme "$THEME" -mesg "SwayNC is not running" <<< ""
exit 0
