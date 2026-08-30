#!/usr/bin/env bash

# ──────────────────────────────────────────────
#   Waybar Updates Module
#   Pacman + AUR update checker
# ──────────────────────────────────────────────

# Check for official repository updates
PACMAN_UPDATES=$(checkupdates 2>/dev/null)

# Check for AUR updates
AUR_UPDATES=$(yay -Qua 2>/dev/null)

# Count updates
PACMAN_COUNT=$(printf '%s\n' "$PACMAN_UPDATES" | grep -c '[^[:space:]]')
AUR_COUNT=$(printf '%s\n' "$AUR_UPDATES" | grep -c '[^[:space:]]')

# Total updates
TOTAL_COUNT=$((PACMAN_COUNT + AUR_COUNT))

# ── Updates available ─────────────────────────
if [ "$TOTAL_COUNT" -gt 0 ]; then

    jq -cn \
        --arg text "$TOTAL_COUNT" \
        --arg tooltip "Pacman Updates ($PACMAN_COUNT):
$PACMAN_UPDATES

AUR Updates ($AUR_COUNT):
$AUR_UPDATES" \
        '{
            text: $text,
            tooltip: $tooltip,
            class: "updates-available"
        }'

# ── No updates ────────────────────────────────
else

    jq -cn '{
        text: "0",
        tooltip: "System is up to date",
        class: "updates-none"
    }'

fi
