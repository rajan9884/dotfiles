#!/usr/bin/env bash
# Swap the focused tiling window with its visual neighbor in the given
# direction, preserving the layout (unlike `move <dir>`, which can pop the
# window out of its autotiling split and re-tile it, e.g. two side-by-side
# windows ending up stacked).
#
# Usage: swap-directional.sh left|right|up|down
# Falls back to `move <dir>` when there is no neighbor that way (single
# window, workspace edge) or the focused window is floating/fullscreen.
set -u

dir="${1:-}"
case "$dir" in
    left|right|up|down) ;;
    *) echo "Usage: $0 left|right|up|down" >&2; exit 1 ;;
esac

TREE="$(swaymsg -t get_tree 2>/dev/null)" || exit 0
ME_JSON="$(echo "$TREE" | jq -c '[.. | objects | select(.focused == true and .type == "con")] | .[0] // empty')"
[ -n "$ME_JSON" ] || exit 0

ME="$(echo "$ME_JSON" | jq -r '.id')"
FS="$(echo "$ME_JSON" | jq -r '.fullscreen_mode // 0')"
FLOATING="$(echo "$TREE" | jq --argjson me "$ME" '[.. | objects | select(.type == "workspace") | .floating_nodes | .. | objects | select(.id == $me)] | length')"

if [ "$FS" != "0" ] || [ "$FLOATING" != "0" ]; then
    swaymsg "move $dir" >/dev/null 2>&1 || true
    exit 0
fi

FX="$(echo "$ME_JSON" | jq -r '.rect.x')"
FY="$(echo "$ME_JSON" | jq -r '.rect.y')"
FW="$(echo "$ME_JSON" | jq -r '.rect.width')"
FH="$(echo "$ME_JSON" | jq -r '.rect.height')"
TOL=24

NEIGHBOR="$(echo "$TREE" | jq -r \
    --arg dir "$dir" --argjson me "$ME" \
    --argjson fx "$FX" --argjson fy "$FY" \
    --argjson fw "$FW" --argjson fh "$FH" --argjson tol "$TOL" '
    [.. | objects | select(.type == "workspace" and .name != "__i3_scratch")
     | select([.. | objects | select(.id == $me)] | length > 0)
     | .nodes | .. | objects
     | select(.type == "con" and .id != $me
              and ((.nodes // []) | length) == 0
              and (.pid != null or .app_id != null)
              and ((.fullscreen_mode // 0) == 0))
     | {id, x: .rect.x, y: .rect.y, w: .rect.width, h: .rect.height}
     | select(
         ($dir == "right" and (.x - ($fx + $fw) <= $tol) and (.x - ($fx + $fw) >= -$tol)
          and .y < ($fy + $fh) and (.y + .h) > $fy)
         or ($dir == "left" and ((.x + .w) - $fx <= $tol) and ((.x + .w) - $fx >= -$tol)
          and .y < ($fy + $fh) and (.y + .h) > $fy)
         or ($dir == "down" and (.y - ($fy + $fh) <= $tol) and (.y - ($fy + $fh) >= -$tol)
          and .x < ($fx + $fw) and (.x + .w) > $fx)
         or ($dir == "up" and ((.y + .h) - $fy <= $tol) and ((.y + .h) - $fy >= -$tol)
          and .x < ($fx + $fw) and (.x + .w) > $fx)
       )
    ]
    | if length == 0 then empty
      elif $dir == "right" then sort_by([.x, -(([.y + .h, $fy + $fh] | min) - ([.y, $fy] | max))]) | .[0].id
      elif $dir == "left" then sort_by([-((.x + .w)), -(([.y + .h, $fy + $fh] | min) - ([.y, $fy] | max))]) | .[0].id
      elif $dir == "down" then sort_by([.y, -(([.x + .w, $fx + $fw] | min) - ([.x, $fx] | max))]) | .[0].id
      else sort_by([-((.y + .h)), -(([.x + .w, $fx + $fw] | min) - ([.x, $fx] | max))]) | .[0].id
      end')"

if [ -n "$NEIGHBOR" ]; then
    swaymsg "[con_id=$ME] focus" >/dev/null 2>&1
    swaymsg "swap container with con_id $NEIGHBOR" >/dev/null 2>&1
else
    swaymsg "move $dir" >/dev/null 2>&1 || true
fi
