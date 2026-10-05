#!/usr/bin/env bash
# Absolute-direction resize for sway tiling.
# Usage: resize-smart.sh width|height shrink|grow <px>
#   width shrink  = divider moves LEFT  (left pane narrows, right grows)
#   width grow    = divider moves RIGHT (left pane widens, right shrinks)
#   height shrink = divider moves UP    (top pane narrows, bottom grows)
#   height grow   = divider moves DOWN  (top pane widens, bottom shrinks)
# Sway's native `resize shrink|grow width|height` is relative to the focused
# container, so the same key feels inverted when focus is on the right/bottom
# window (Hyprland's resizeactive is absolute). This wrapper targets the pane
# branch at the constraining split and inverts the operation when focus sits
# on a right/bottom branch, restoring absolute keys. Targeting the branch
# (not the window) also keeps resize working through single-child wrapper
# containers left behind by autotiling (resizing the window directly inside a
# perpendicular wrapper errors with "Cannot resize any further").
set -euo pipefail

AXIS="${1:-}"; DIR="${2:-}"; AMOUNT="${3:-}"
if [[ "$AXIS" != width && "$AXIS" != height ]] || [[ "$DIR" != shrink && "$DIR" != grow ]] || ! [[ "$AMOUNT" =~ ^[0-9]+$ ]]; then
  echo "Usage: $(basename "$0") width|height shrink|grow <px>" >&2
  exit 1
fi

# shellcheck disable=SC2086
read -r INVERT TARGET < <(swaymsg -t get_tree 2>/dev/null | python3 -c '
import json, sys
axis = sys.argv[1]
print("no 0")

def done(invert, target):
    print(("yes" if invert else "no") + " " + str(target))
    sys.exit(0)

try:
    tree = json.load(sys.stdin)
except Exception:
    sys.exit(0)

def find_focused(node, ancestors):
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        r = find_focused(child, ancestors + [node])
        if r:
            return r
    if node.get("focused") and node.get("type") in ("con", "floating_con"):
        return ancestors + [node]
    return None

path = find_focused(tree, [])
if not path or len(path) < 2:
    sys.exit(0)

focused = path[-1]
# Floating windows resize symmetrically; keep native behavior.
for i in range(len(path) - 1):
    if focused in path[i].get("floating_nodes", []):
        sys.exit(0)
if focused.get("type") == "floating_con":
    sys.exit(0)

def arrangement(kids):
    xs = {k.get("rect", {}).get("x") for k in kids}
    ys = {k.get("rect", {}).get("y") for k in kids}
    if len(xs) > 1 and len(ys) == 1:
        return "horizontal"
    if len(ys) > 1 and len(xs) == 1:
        return "vertical"
    if len(xs) > 1 and len(ys) > 1:
        spanx = max(k["rect"]["x"] + k["rect"]["width"] for k in kids) - min(k["rect"]["x"] for k in kids)
        spany = max(k["rect"]["y"] + k["rect"]["height"] for k in kids) - min(k["rect"]["y"] for k in kids)
        return "horizontal" if spanx >= spany else "vertical"
    return "single"

# Walk up: first workspace-or-below ancestor whose tiling children constrain
# this axis decides. Outputs/root are separate screens, never a divider.
for i in range(len(path) - 2, -1, -1):
    parent = path[i]
    if parent.get("type") not in ("workspace", "con"):
        break
    branch = path[i + 1]
    kids = [k for k in parent.get("nodes", []) if k.get("rect")]
    if len(kids) < 2:
        continue
    arr = arrangement(kids)
    try:
        if axis == "width" and arr == "horizontal":
            ordered = sorted(kids, key=lambda k: (k["rect"]["x"], k["rect"]["y"]))
            idx = next(j for j, k in enumerate(ordered) if k["id"] == branch["id"])
            done(idx > 0, branch["id"])
        if axis == "height" and arr == "vertical":
            ordered = sorted(kids, key=lambda k: (k["rect"]["y"], k["rect"]["x"]))
            idx = next(j for j, k in enumerate(ordered) if k["id"] == branch["id"])
            done(idx > 0, branch["id"])
    except (StopIteration, KeyError):
        continue
' "$AXIS" | tail -n 1)
INVERT="${INVERT:-no}"
TARGET="${TARGET:-0}"

FINAL_DIR="$DIR"
if [[ "$INVERT" == "yes" ]]; then
  if [[ "$DIR" == shrink ]]; then FINAL_DIR="grow"; else FINAL_DIR="shrink"; fi
fi

if [[ "$TARGET" != "0" ]]; then
  swaymsg "[con_id=$TARGET] resize $FINAL_DIR $AXIS $AMOUNT px" >/dev/null
else
  swaymsg "resize $FINAL_DIR $AXIS $AMOUNT px" >/dev/null
fi
