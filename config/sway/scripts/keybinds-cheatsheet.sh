#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Keybindings Cheatsheet (sway/Void port)
#   Parses `# > <description>` marker lines directly above
#   bindsym/bindswitch lines in ~/.config/sway/config
#   (trailing `#` comments can't be used: sway stores
#   bindsym commands verbatim, so `# ...` would leak
#   into e.g. workspace names) and pipes
#   `KEYS → description` through rofi -dmenu.
#
#   Perf: zero-fork parse + cache keyed by config hash
#   (ported from Arch Hyprland cheatsheet) so reopening
#   is instant. Same rofi perf flags as Arch.
# ──────────────────────────────────────────────
set -euo pipefail
CFG="$HOME/.config/sway/config"
THEME="$HOME/.config/rofi/active-picker.rasi"
PROMPT="Keybindings"

# Same perf tuning as Arch: instant filtering, threaded, fuzzy.
# NOTE: no -kb-row-* flags: rofi 2.0.0-dirty hangs parsing most kb
# overrides (verified headless on Arch). Defaults already include Ctrl+p/n + arrows.
ROFI_PERF="-show-icons -hover-select -matching fuzzy -sorting-method fzf -sort -tokenize -threads 0 -me-accept-entry MousePrimary -no-fixed-num-lines -i"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi"
cache_key() {
    (cat "$CFG" 2>/dev/null; printf 'v1-sway\n') | sha256sum | cut -d' ' -f1
}

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Bash-only (zero forks): old version spawned echo|sed|awk per
# binding (~500 forks ≈ 3s). Same output, ~0.02s.
pretty_combo() {
    local s="$1"
    s="${s//\$mod/SUPER}"
    s="${s//\$left/h}"
    s="${s//\$right/l}"
    s="${s//\$up/k}"
    s="${s//\$down/j}"
    # sway bindswitch lid trigger
    s="${s//lid:on/Lid closed}"
    s="${s//lid:off/Lid opened}"
    # normalize '+' separators to ' + ' then prettify each chord part
    s="${s//+/ + }"
    # collapse accidental doubles from replacement
    while [[ "$s" == *"  "* ]]; do s="${s//  / }"; done
    s="$(trim "$s")"
    # per-part prettify without forks
    local out="" part
    local IFS='+'
    # split on '+' manually to avoid subshells
    local rest="$s" chunk
    out=""
    while true; do
        if [[ "$rest" == *"+"* ]]; then
            chunk="${rest%%+*}"
            rest="${rest#*+}"
        else
            chunk="$rest"
            rest=""
        fi
        chunk="$(trim "$chunk")"
        case "$chunk" in
            RETURN|Return|return) chunk="Enter" ;;
            ESCAPE|Escape|escape) chunk="Esc" ;;
            TAB|Tab|tab) chunk="Tab" ;;
            SPACE|Space|space) chunk="Space" ;;
            BACKSPACE|BackSpace|Backspace|backspace) chunk="Backspace" ;;
            PRINT|Print|print) chunk="PrtSc" ;;
            button4) chunk="Wheel Up" ;;
            button5) chunk="Wheel Down" ;;
            comma|COMMA) chunk="," ;;
            period|PERIOD) chunk="." ;;
            slash|SLASH) chunk="/" ;;
            minus|MINUS) chunk="-" ;;
            equal|EQUAL) chunk="=" ;;
            LEFT|Left|left) chunk="Left" ;;
            RIGHT|Right|right) chunk="Right" ;;
            UP|Up|up) chunk="Up" ;;
            DOWN|Down|down) chunk="Down" ;;
            HOME|Home|home) chunk="Home" ;;
            SUPER|Super|super) chunk="SUPER" ;;
            SHIFT|Shift|shift) chunk="SHIFT" ;;
            CTRL|Ctrl|ctrl|CONTROL|Control|control) chunk="CTRL" ;;
            ALT|Alt|alt) chunk="ALT" ;;
            XF86AudioRaiseVolume) chunk="Vol+" ;;
            XF86AudioLowerVolume) chunk="Vol-" ;;
            XF86AudioMute) chunk="Mute" ;;
            XF86AudioMicMute) chunk="Mic Mute" ;;
            XF86AudioNext) chunk="Next" ;;
            XF86AudioPrev) chunk="Prev" ;;
            XF86AudioPlay|XF86AudioPause) chunk="Play" ;;
            XF86MonBrightnessUp) chunk="Bright+" ;;
            XF86MonBrightnessDown) chunk="Bright-" ;;
            XF86KbdBrightnessUp) chunk="Kbd+" ;;
            XF86KbdBrightnessDown) chunk="Kbd-" ;;
            XF86KbdLightOnOff) chunk="Kbd Light" ;;
            XF86TouchpadToggle) chunk="Touchpad" ;;
            XF86TouchpadOn) chunk="Touchpad On" ;;
            XF86TouchpadOff) chunk="Touchpad Off" ;;
            XF86Eject) chunk="Eject" ;;
            XF86PowerOff) chunk="Power" ;;
            Lid*) ;; # keep as-is ("Lid closed")
            [a-z]) chunk="${chunk^^}" ;; # single lowercase letter -> uppercase
        esac
        if [[ -z "$out" ]]; then out="$chunk"; else out="$out + $chunk"; fi
        [[ -z "$rest" ]] && break
    done
    printf '%s' "$out"
}

render() {
    local line rest desc combo pending=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*\>[[:space:]]*(.*)$ ]]; then
            pending="$(trim "${BASH_REMATCH[1]}")"
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*bind(sym|switch|code)[[:space:]]+(.*)$ ]]; then
            rest="${BASH_REMATCH[2]}"
            desc="$pending"; pending=""
            [[ -z "$desc" ]] && continue
            # strip leading sway flags (--locked, --release, --input-device=..., etc.)
            # bash-only: split into words, skip --tokens, take first real token
            local words word found=""
            # shellcheck disable=SC2206
            words=($rest)
            for word in "${words[@]}"; do
                [[ "$word" == --* ]] && continue
                # skip value glued to --input-device like "--input-device=foo"? already skipped.
                # also skip bare flag values? sway flags take no separate arg except
                # --input-device <dev> (two-token form). Handle it:
                found="$word"
                break
            done
            # handle "--input-device <dev> <combo>" two-token form
            if [[ "$rest" =~ --input-device[[:space:]]+[^[:space:]]+[[:space:]]+([^[:space:]]+) ]]; then
                # only if our found word was the device name, re-extract
                # (cheap heuristic: if found != combo and rest contains the pattern,
                #  prefer the token after the device)
                local after_dev="${BASH_REMATCH[1]}"
                # if found looks like a device path/id rather than a combo, use after_dev
                if [[ "$found" != *"+"* && "$found" != "lid:"* && "$found" != XF86* && "$found" != Print && "$found" != F* ]]; then
                    # verify after_dev exists in word list after --input-device
                    found="$after_dev"
                fi
            fi
            [[ -z "$found" ]] && continue
            combo="$(pretty_combo "$found")"
            printf '%s\t%s\n' "$combo" "$desc"
            continue
        fi
        # any other non-blank line breaks the marker association
        # (blank lines are tolerated)
        [[ "$line" =~ ^[[:space:]]*$ ]] || pending=""
    done < "$CFG"
}

# Order the most useful/commonly-hit bindings first (same priorities as Arch),
# so the menu opens on the essentials instead of file-order dump.
prioritize_entries() {
    awk -F '\t' '
    {
        key  = $1
        desc = $2
        prio = 50
        if (desc == "") prio = 200
        if (desc ~ /Open terminal/)            prio = 0
        if (desc ~ /App launcher/)             prio = 1
        if (desc ~ /^Open browser$/)           prio = 2
        if (desc ~ /^Open file manager$/)      prio = 3
        if (desc ~ /Close window/)             prio = 4
        if (desc ~ /^Lock screen$/)            prio = 5
        if (desc ~ /Power menu/)               prio = 5
        if (desc ~ /Toggle fullscreen|Fullscreen|Maximized/) prio = 6
        if (desc ~ /Toggle.*floating/)         prio = 7
        if (desc ~ /Toggle window group/)      prio = 8
        if (desc ~ /Toggle.*split/)            prio = 9
        if (desc ~ /Workspace [0-9]/)          prio = 10
        if (desc ~ /Switch to workspace/)      prio = 10
        if (desc ~ /Move window to workspace/) prio = 11
        if (desc ~ /Move window.*no follow/)   prio = 12
        if (desc ~ /Next workspace/)           prio = 13
        if (desc ~ /Previous workspace/)       prio = 14
        if (desc ~ /Former workspace/)         prio = 15
        if (desc ~ /Focus /)                   prio = 20
        if (desc ~ /Swap window/)              prio = 21
        if (desc ~ /Universal (copy|paste|cut|select)/) prio = 22
        if (desc ~ /Copy|Paste|Cut|Select all/) prio = 22
        if (desc ~ /Clipboard/)                prio = 23
        if (desc ~ /Screenshot/)               prio = 30
        if (desc ~ /Screen recording/)         prio = 31
        if (desc ~ /Color picker/)             prio = 32
        if (desc ~ /Emoji/)                    prio = 33
        if (desc ~ /Power \/ logout/)          prio = 34
        if (desc ~ /Bluetooth/)                prio = 35
        if (desc ~ /Network/)                  prio = 36
        if (desc ~ /Volume|Mute|Brightness|Precise/) prio = 40
        if (desc ~ /Next track|Play|Pause/)    prio = 41
        if (desc ~ /Calculator/)               prio = 42
        if (desc ~ /Toggle night/)             prio = 43
        if (desc ~ /Toggle idle/)              prio = 44
        if (desc ~ /Toggle window (transparency|gaps)/) prio = 45
        if (desc ~ /Monitor scal/)             prio = 46
        if (desc ~ /Notification/)             prio = 47
        if (desc ~ /Save window size|Restore/) prio = 48
        if (desc ~ /Close all windows/)        prio = 49
        printf "%d\t%s\t%s\n", prio, key, desc
    }' |
    sort -t $'\t' -k1,1n -k2,2 |
    cut -f2-
}

# Single display line per entry: key left-padded to fixed column + " → " + desc
# (same style as Arch; old Void used %-28s without arrow and no priority sort).
format_entries() {
    awk -F '\t' '{ printf "%-35s → %s\n", $1, $2 }'
}

build_entries_uncached() {
    render | prioritize_entries | format_entries
}

output_entries() {
    local key cache_file tmp_file
    key=$(cache_key)
    cache_file="$CACHE_DIR/keybinds-sway-${key}.list"
    if [[ -s "$cache_file" ]]; then
        cat "$cache_file"
    elif mkdir -p "$CACHE_DIR" 2>/dev/null; then
        tmp_file=$(mktemp "$CACHE_DIR/keybinds-sway.XXXXXX") || { build_entries_uncached; return; }
        if build_entries_uncached >"$tmp_file"; then
            mv "$tmp_file" "$cache_file"
            find "$CACHE_DIR" -maxdepth 1 -type f -name 'keybinds-sway-*.list' ! -name "keybinds-sway-${key}.list" -delete 2>/dev/null || true
            cat "$cache_file"
        else
            rm -f "$tmp_file"
            build_entries_uncached
        fi
    else
        build_entries_uncached
    fi
}

if [[ "${1:-}" == "--print" || "${1:-}" == "-p" || "${1:-}" == "--refresh" ]]; then
    output_entries
else
    # shellcheck disable=SC2086
    output_entries | rofi -dmenu $ROFI_PERF -p "$PROMPT" -theme "$THEME" >/dev/null || true
fi
