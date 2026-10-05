#!/usr/bin/env bash
# Open a new terminal (alacritty primary, foot fallback) in the working
# directory of the currently focused window (sway/Void port — uses swaymsg,
# not hyprctl).
# Fast path: one swaymsg + one jq + one ps snapshot, zero forks per process.
# Alacritty launches with --working-directory; no single-instance daemon is
# needed: every launch is a cold start that re-reads the matugen colors.
set -u
dir="$HOME"
pid="$(swaymsg -t get_tree 2>/dev/null | jq -r '.. | objects | select(.focused == true) | .pid // empty' 2>/dev/null | head -n 1 || true)"
if [[ -n "${pid:-}" ]] && [[ "$pid" =~ ^[0-9]+$ ]]; then
    # Build parent->children map + comm table from a single ps snapshot.
    declare -A kids=() comms=()
    while read -r p pp c; do
        [[ "$p" =~ ^[0-9]+$ ]] || continue
        comms[$p]="$c"
        kids[$pp]="${kids[$pp]:-} $p"
    done < <(ps -eo pid=,ppid=,comm= 2>/dev/null || true)
    # BFS from the focused pid; newest shell descendant wins (outermost loop
    # order), falling back to the focused pid's own cwd.
    declare -A seen=()
    queue=("$pid")
    while ((${#queue[@]})); do
        cur=${queue[0]}
        queue=("${queue[@]:1}")
        [[ -n "${seen[$cur]:-}" ]] && continue
        seen[$cur]=1
        # shellcheck disable=SC2086
        for c in ${kids[$cur]:-}; do
            queue+=("$c")
            case "${comms[$c]:-}" in
                zsh|bash|fish)
                    cwd=$(readlink -f "/proc/$c/cwd" 2>/dev/null || true)
                    [[ -n "$cwd" && -d "$cwd" ]] && dir="$cwd"
                    ;;
            esac
        done
    done
    if [[ "$dir" == "$HOME" ]]; then
        cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)
        [[ -n "$cwd" && -d "$cwd" ]] && dir="$cwd"
    fi
fi
# Alacritty first; foot stays as secondary fallback.
if command -v alacritty >/dev/null 2>&1; then
    exec alacritty --working-directory "$dir"
fi
# Foot fallback: prefer footclient when a `foot --server` is running (shares
# fonts/glyph cache); fall back to a plain cold launch otherwise. The plain
# launch re-reads ~/.config/foot/colors.ini, so matugen re-themes always
# apply to new windows (server clients inherit the server's startup palette
# until it restarts — plain foot is therefore the default foot path).
FOOT_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/foot-$WAYLAND_DISPLAY.sock"
if [[ -S "$FOOT_SOCK" ]] && command -v footclient >/dev/null 2>&1 \
    && footclient -D "$dir" >/dev/null 2>&1; then
    exit 0
fi
exec foot -D "$dir"
