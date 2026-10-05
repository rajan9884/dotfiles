#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   mako status for Waybar (DND indicator — no panel)
#   bell = notifications on · bell-off = silenced
# ──────────────────────────────────────────────
set -euo pipefail
if ! makoctl mode >/dev/null 2>&1; then
    jq -cn '{text: "󰂚", tooltip: "mako not running", class: "no-notifications"}'
    exit 0
fi
if makoctl mode 2>/dev/null | grep -qx 'do-not-disturb'; then
    jq -cn '{text: "󰂛", tooltip: "Silenced (click to unsilence, right-click clears all)", class: "dnd"}'
else
    jq -cn '{text: "󰂚", tooltip: "Notifications on (click to silence, right-click clears all)", class: "no-notifications"}'
fi
