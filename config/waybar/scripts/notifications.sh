#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Notification count for Waybar (SwayNC)
# ──────────────────────────────────────────────
set -euo pipefail

count="$(swaync-client -c -sw 2>/dev/null || echo 0)"
count="${count//[^0-9]/}"
[ -z "$count" ] && count=0

if ((count > 0)); then
    jq -cn --argjson n "$count" '{text: ("󰂚 " + ($n | tostring)), tooltip: "Notifications (click to open center)", class: "has-notifications"}'
else
    jq -cn '{text: "󰂚", tooltip: "No notifications", class: "no-notifications"}'
fi
