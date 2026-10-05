#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   scratchpad-toggle — run a scratchpad command.
#   (Thin wrapper so all scratchpad binds share one entry point;
#   Arch parity: Hyprland applies no extra dim to its special
#   workspace (dim_special = 0.0) — the steady default_dim_inactive
#   0.12 from the sway config is the whole effect, so nothing is
#   touched here after the command runs.)
#   Usage: scratchpad-toggle.sh <sway command...>
#   e.g.   scratchpad-toggle.sh scratchpad show
#          scratchpad-toggle.sh '[con_mark="music"] scratchpad show'
#          scratchpad-toggle.sh move scratchpad
#          scratchpad-toggle.sh 'mark music; move scratchpad'
# ──────────────────────────────────────────────
set -u
swaymsg "$*" >/dev/null 2>&1 || true
