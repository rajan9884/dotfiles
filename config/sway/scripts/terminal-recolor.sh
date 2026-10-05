#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Live-recolor running terminals after a matugen switch.
#   Alacritty is primary (foot kept as fallback): neither picks up a new
#   palette in already-open windows (alacritty has no live config reload;
#   foot SIGUSR1/2 only flips between the dark/light themes loaded at
#   startup), so push the fresh matugen palette to every open terminal
#   via OSC escape sequences —
#     OSC 10 = foreground, OSC 11 = background, OSC 12 = cursor,
#     OSC 4  = 16-color ANSI palette (what TUIs like htop/btop/fzf use).
#   The sequences are consumed by the terminal emulator itself, so they
#   are safe to send even when a fullscreen TUI is running (redraw with
#   Ctrl-L if anything looks stale). tmux/screen panes do NOT forward
#   OSC 4 outward — those need a tmux restart.
# ──────────────────────────────────────────────
set -euo pipefail

# Primary source: alacritty's matugen colors; fall back to foot's.
ALA_FILE="$HOME/.config/alacritty/colors.toml"
FOOT_FILE="$HOME/.config/foot/colors.ini"

declare -A C=()
if [ -f "$ALA_FILE" ]; then
    # TOML: `name = "#rrggbb"` under [colors.normal] (0-7) /
    # [colors.bright] (8-15) / [colors.primary] / [colors.cursor].
    section=""
    while IFS= read -r line; do
        line="${line//[[:space:]]/}"
        case "$line" in
            "[colors.primary]"|"[colors.cursor]") section="meta"; continue ;;
            "[colors.normal]") section="n"; continue ;;
            "[colors.bright]") section="b"; continue ;;
            "["*"]") section=""; continue ;;
        esac
        [[ "$line" == *"="* ]] || continue
        key="${line%%=*}"; value="${line#*=}"
        value="${value//\"/}"; value="${value//#/}"
        [[ "$value" =~ ^[0-9a-fA-F]{6}$ ]] || continue
        case "$section:$key" in
            meta:background) C[background]="$value" ;;
            meta:foreground) C[foreground]="$value" ;;
            meta:cursor) CURSOR_TOML="$value" ;;
            n:black) C[regular0]="$value" ;; n:red) C[regular1]="$value" ;;
            n:green) C[regular2]="$value" ;; n:yellow) C[regular3]="$value" ;;
            n:blue) C[regular4]="$value" ;; n:magenta) C[regular5]="$value" ;;
            n:cyan) C[regular6]="$value" ;; n:white) C[regular7]="$value" ;;
            b:black) C[bright0]="$value" ;; b:red) C[bright1]="$value" ;;
            b:green) C[bright2]="$value" ;; b:yellow) C[bright3]="$value" ;;
            b:blue) C[bright4]="$value" ;; b:magenta) C[bright5]="$value" ;;
            b:cyan) C[bright6]="$value" ;; b:white) C[bright7]="$value" ;;
        esac
    done < "$ALA_FILE"
    CURSOR_RAW="${CURSOR_TOML:-}"
elif [ -f "$FOOT_FILE" ]; then
    while IFS='=' read -r key value; do
        # Trim whitespace; skip sections/comments/blanks.
        key="${key//[[:space:]]/}"
        value="${value//[[:space:]]/}"
        [[ "$key" =~ ^(foreground|background|regular[0-7]|bright[0-7])$ ]] || continue
        [[ "$value" =~ ^[0-9a-fA-F]{6}$ ]] || continue
        C["$key"]="$value"
    done < <(grep -E '^(foreground|background|regular[0-7]|bright[0-7])=' "$FOOT_FILE" || true)
    # foot's `cursor=<fg> <bg>` is a two-value key (first field = cursor).
    CURSOR_RAW="$(grep -E '^cursor=' "$FOOT_FILE" | head -1 | cut -d= -f2 | awk '{print $1}' || true)"
else
    exit 0
fi

[ -n "${C[foreground]:-}" ] && [ -n "${C[background]:-}" ] || exit 0

ESC=$'\e'
BEL=$'\a'
SEQ=""

# Foreground / background / cursor (foot's two-value form handled above;
# alacritty's [colors.cursor] cursor key lands in CURSOR_RAW directly).
SEQ+="${ESC}]10;#${C[foreground]}${BEL}"
SEQ+="${ESC}]11;#${C[background]}${BEL}"
if [[ "${CURSOR_RAW:-}" =~ ^[0-9a-fA-F]{6}$ ]]; then
    SEQ+="${ESC}]12;#${CURSOR_RAW}${BEL}"
fi

# 16-color palette: regularN -> 0-7, brightN -> 8-15 (only complete pairs).
for i in 0 1 2 3 4 5 6 7; do
    [ -n "${C[regular$i]:-}" ] && SEQ+="${ESC}]4;$i;#${C[regular$i]}${BEL}"
done
for i in 0 1 2 3 4 5 6 7; do
    [ -n "${C[bright$i]:-}" ] && SEQ+="${ESC}]4;$((i + 8));#${C[bright$i]}${BEL}"
done

# Broadcast to every writable pty (payload has no newlines, so ONLCR
# translation can't garble it; emulators swallow unknown OSC safely).
count=0
for pts in /dev/pts/[0-9]*; do
    [ -w "$pts" ] || continue
    printf '%s' "$SEQ" > "$pts" 2>/dev/null && count=$((count + 1)) || true
done

echo "terminal-recolor: pushed palette to $count pty(ies)" >> "$HOME/.cache/sway-wall.log"
exit 0
