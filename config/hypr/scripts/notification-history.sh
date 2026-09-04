#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Notification History
#   Opens the SwayNC notification center; falls
#   back to dunst history in rofi if swaync is
#   not running (legacy path).
# ──────────────────────────────────────────────

set -euo pipefail

if pgrep -x swaync >/dev/null 2>&1; then
    swaync-client -t -sw
    exit 0
fi

THEME="$HOME/.config/rofi/active-picker.rasi"
PROMPT="Notifications"
CLEAR_LABEL="Clear notification history"

lines="$(dunstctl history 2>/dev/null | jq -r '
    .data[] | .[] | [
        (.summary.data // ""),
        (.appname.data // ""),
        (.body.data // "")
    ] | @tsv
' 2>/dev/null)" || lines=""

if [[ -z "${lines//[[:space:]]/}" ]]; then
    rofi -dmenu -p "$PROMPT" -theme "$THEME" -mesg "No notifications in history" <<< ""
    exit 0
fi

rows="$(while IFS=$'\t' read -r summary app body; do
    app="${app:-Unknown}"
    [ -n "$summary" ] || summary="(no title)"
    body="$(printf '%s' "$body" | tr -s '[:space:]' ' ')"
    printf '%s\t%s — %s\n' "$summary" "$app" "$body"
done <<< "$lines")"

sel="$({ printf '%s\t%s\n' "$CLEAR_LABEL" "history"
        printf '%s\t%s\n' "─────────────────────────" ""
        printf '%s\n' "$rows"
      } | rofi -dmenu -i -p "$PROMPT" -theme "$THEME" -display-columns "1,2" 2>/dev/null)" || sel=""

case "$sel" in
    *"$CLEAR_LABEL"*)
        dunstctl history-clear
        rofi -dmenu -p "$PROMPT" -theme "$THEME" -mesg "Notification history cleared" <<< ""
        ;;
esac
