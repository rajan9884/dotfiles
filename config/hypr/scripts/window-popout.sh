#!/usr/bin/env bash
# "Pop out" the active window: float it and pin it above other windows.
# Running again un-floats and un-pins it.
set -euo pipefail

hyprctl dispatch togglefloating active >/dev/null
hyprctl dispatch pin active >/dev/null