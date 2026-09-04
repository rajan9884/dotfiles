#!/bin/bash
# ──────────────────────────────────────────────
#   Volume OSD via swayosd-server (compact native OSD).
#   swayosd-client changes the volume AND shows the OSD —
#   no more giant notification popups.
# ──────────────────────────────────────────────
ACTION="$1"

case "$ACTION" in
    up) swayosd-client --output-volume +5 --max-volume 150 ;;
    down) swayosd-client --output-volume -5 --max-volume 150 ;;
    mute-toggle) swayosd-client --output-volume mute-toggle ;;
    mic-toggle) swayosd-client --input-volume mute-toggle ;;
esac
