#!/bin/sh
# Gated single-instance waybar launcher.
# Used by sway's autostart AND sway-wall.sh's fallback — both used to fire
# at boot within a second of each other, stacking two bars.
# 1. Gate: wait for a real PipeWire default sink (launching earlier leaves
#    the pulseaudio module permanently hidden).
# 2. Mutex: flock -n serializes concurrent callers; pgrep is rechecked
#    inside the lock so only one bar ever starts. Non-blocking on purpose:
#    the winner's bar inherits the lock fd for its lifetime, so a blocking
#    flock would hang the loser forever — the loser just exits instead.
LOCK="${XDG_RUNTIME_DIR:-/tmp}/waybar-launch.lock"
for i in $(seq 1 60); do
    s=$(pactl get-default-sink 2>/dev/null) || s=""
    case "$s" in
        ""|*auto_null*) sleep 0.5;;
        *) break;;
    esac
done
flock -n "$LOCK" sh -c 'pgrep -x waybar >/dev/null 2>&1 || setsid waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css >/dev/null 2>&1 < /dev/null &' || true
