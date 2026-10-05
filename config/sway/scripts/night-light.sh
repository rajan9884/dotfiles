#!/usr/bin/env bash
# Night light via wlsunset (sway/Void port of night-light-toggle).
# Bound to SUPER+CTRL+N. Toggle: warm 4000K on, off otherwise.
set -euo pipefail
if pgrep -x wlsunset >/dev/null; then
    pkill -x wlsunset
    notify-send "Night Light" "Disabled"
else
    wlsunset -t 4000 -T 6500 &
    disown
    notify-send "Night Light" "Enabled (4000K)"
fi
