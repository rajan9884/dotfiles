#!/usr/bin/env bash
# Toggle floating on the focused window without layout damage.
# Bound to $mod+t (replaces raw `floating toggle`).
# - tiling -> floating: small centered window (900x600) instead of keeping
#   the full tiled height (which overlaps waybar);
# - floating -> tiling: autotiling is frozen (SIGSTOP) for the transaction
#   so sway reinserts the window as a plain sibling instead of wrapping it
#   in a flipped split container — which otherwise turns vertical stacks
#   horizontal and nests splits deeper on every toggle cycle.
# (Freeze pattern ported from maximize-toggle.sh.)
set -u

# Freeze autotiling (if running) for the duration of the toggle: it reacts to
# our focus events by flipping the pending split orientation, which makes
# `floating disable` reinsert the window wrapped in a new split container —
# flipping the layout and nesting splits deeper on every cycle. Paused here,
# resumed on exit via trap.
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
TYPE="$(echo "$ME_JSON" | jq -r '.type // empty')"

if [ "$TYPE" = "floating_con" ]; then
    swaymsg "[con_id=$ME] floating disable" >/dev/null 2>&1
else
    # Single transaction (same pattern as the for_window floating popups in
    # config): back-to-back swaymsg calls race the floating transition and
    # the resize lands on the still-tiled container, so chain with commas.
    swaymsg "[con_id=$ME] floating enable, resize set 900 600, move position center" >/dev/null 2>&1
fi
