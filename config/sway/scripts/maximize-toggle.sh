#!/usr/bin/env bash
# Toggle maximized window: floating fill that keeps waybar, gaps and borders.
# Unlike `fullscreen`, this does NOT hide the bar or remove gaps.
# Bound to $mod+Alt+f (while $mod+f stays true fullscreen).
set -u

# Freeze autotiling (if running) for the duration of the toggle: it reacts to
# our focus events by flipping the pending split orientation, which makes
# `floating disable` reinsert the window wrapped in a new split container —
# flipping the layout and nesting splits deeper on every cycle. Pausing it
# lets sway reinsert the window cleanly as a plain sibling. Resumed on exit.
TILING_PIDS="$(pgrep -f '[a]utotiling' 2>/dev/null || true)"
if [ -n "${TILING_PIDS:-}" ]; then
    # shellcheck disable=SC2086
    kill -STOP $TILING_PIDS 2>/dev/null || true
    resume_tiling() {
        # shellcheck disable=SC2086
        kill -CONT $TILING_PIDS 2>/dev/null || true
    }
    trap resume_tiling EXIT
fi

TREE="$(swaymsg -t get_tree 2>/dev/null)" || exit 0
ME_JSON="$(echo "$TREE" | jq -c '[.. | objects | select(.focused == true and (.type == "con" or .type == "floating_con"))] | .[0] // empty')"
[ -n "$ME_JSON" ] || exit 0

ME="$(echo "$ME_JSON" | jq -r '.id')"
MARKS="$(echo "$ME_JSON" | jq -r '(.marks // []) | join(",")')"

# Second press: restore tiling.
if [[ "$MARKS" == *"maximized"* ]]; then
    swaymsg "[con_id=$ME] unmark maximized, floating disable" >/dev/null 2>&1 || \
        swaymsg "[con_id=$ME] floating disable" >/dev/null 2>&1
    exit 0
fi

# Never leave true fullscreen behind: Super+Alt+F is maximize, not fullscreen.
swaymsg "[con_id=$ME] fullscreen disable" >/dev/null 2>&1 || true

# Workspace rect containing the focused container (already accounts for bar + outer gaps).
WS_JSON="$(echo "$TREE" | jq -c --argjson me "$ME" '[.. | objects | select(.type == "workspace") | select([.. | objects | select(.id == $me)] | length > 0)] | .[0] // empty')"
W="$(echo "$WS_JSON" | jq -r '.rect.width // empty')"
H="$(echo "$WS_JSON" | jq -r '.rect.height // empty')"
[ -n "${W:-}" ] && [ -n "${H:-}" ] || exit 0

# Shave off the 2px border so the maximized frame sits exactly inside the workspace.
MW=$((W - 4))
MH=$((H - 4))
[ "$MW" -gt 200 ] || MW="$W"
[ "$MH" -gt 200 ] || MH="$H"

# Single transaction (same pattern as the for_window floating popups in
# config): back-to-back swaymsg calls race the floating transition and the
# resize lands on the still-tiled container, so chain with commas.
swaymsg "[con_id=$ME] mark maximized, floating enable, resize set $MW $MH, move position center" >/dev/null 2>&1
