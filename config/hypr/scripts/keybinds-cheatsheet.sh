#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Keybindings Cheatsheet
#   Parses the live hl.bind() calls from hyprland.lua and pipes an
#   aligned key + description list through rofi -dmenu.
#   Uses the active scripts theme (which @imports matugen colors.rasi).
# ──────────────────────────────────────────────

set -euo pipefail

HYP_DIR="$HOME/.config/hypr"
THEME="$HOME/.config/rofi/active-picker.rasi"
PROMPT="Keybindings"

# Keyboard-driven, instant filtering.
# NOTE: no -kb-row-* flags: rofi 2.0.0-dirty hangs parsing most kb
# overrides (verified headless). Defaults already include Ctrl+p/n + arrows.
ROFI_PERF="-show-icons -hover-select -matching fuzzy -sorting-method fzf -sort -tokenize -threads 0 -me-accept-entry MousePrimary -no-fixed-num-lines -i"

# Cache parsed keybindings keyed by config hash so reopening is
# instant (no re-parse, no fork storm). Same idea here.
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi"
cache_key() {
    (cat "$HYP_DIR"/*.lua 2>/dev/null; printf 'v2\n') | sha256sum | cut -d' ' -f1
}

label() {
    action="$1"
    case "$action" in
        *'window.close()'*)                        desc="Close window" ;;
        *'exec_cmd("hyprlock")'*)                  desc="Lock screen" ;;
        *'window.fullscreen()'*)                   desc="Toggle fullscreen" ;;
        *'window.float('*)                         desc="Toggle window floating/tiling" ;;
        *'window.pseudo()'*)                       desc="Pseudo-tiling" ;;
        *'layout("togglesplit")'*)                 desc="Toggle window split" ;;
        *'send_shortcut'*)
            sc="$(printf '%s' "$action" | sed -n 's/.*key = "\([A-Z]\)".*/\1/p')"
            case "$sc" in
                C) desc="Copy" ;;
                V) desc="Paste" ;;
                X) desc="Cut" ;;
                A) desc="Select all" ;;
                *) desc="" ;;
            esac
            ;;
        *'window.resize'*)                         desc="Resize window" ;;
        *'window.move({ workspace = i'*)           desc="Move window to workspace" ;;
        *'window.drag()'*)                         desc="Drag window (mouse)" ;;
        *'window.cycle_next({ next = false'*)      desc="Previous window" ;;
        *'window.cycle_next()'*)                   desc="Next window" ;;
        *'focus({ direction = "left"'*)            desc="Focus left" ;;
        *'focus({ direction = "right"'*)           desc="Focus right" ;;
        *'focus({ direction = "up"'*)              desc="Focus up" ;;
        *'focus({ direction = "down"'*)            desc="Focus down" ;;
        *'window.swap'*)                             desc="Swap window" ;;
        *'focus({ workspace = "e+1"'*)             desc="Next workspace" ;;
        *'focus({ workspace = "e-1"'*)             desc="Previous workspace" ;;
        *'focus({ workspace = "previous"'*)        desc="Former workspace" ;;
        *'group.toggle()'*)                        desc="Toggle window group" ;;
        *'group.next()'*)                          desc="Next window in group" ;;
        *'group.prev()'*)                          desc="Previous window in group" ;;
        *'into_group'*)                            desc="Move into group" ;;
        *'out_of_group'*)                          desc="Move out of group" ;;
        *'exec_cmd(terminal)'*)                    desc="Open terminal" ;;
        *'exec_cmd(menu)'*)                        desc="App launcher" ;;
        *'terminal-launch.sh'*)                    desc="Open terminal" ;;
        *'arch-wallpaper-picker'*)                desc="Wallpaper picker" ;;
        *'arch-theme-switcher'*)                  desc="Theme switcher" ;;
        *'capture-screen'*)                        desc="Capture entire screen" ;;
        *'capture-region'*)                        desc="Screenshot" ;;
        *'capture-satty'*)                         desc="Screenshot & annotate" ;;
        *'ocr-extract'*)                           desc="OCR text extraction (region → clipboard)" ;;
        *'menu-clipboard'*)                        desc="Clipboard history" ;;
        *'exec_cmd(browser)'*)                     desc="Open browser" ;;
        *'exec_cmd(file)'*)                        desc="Open file manager" ;;
        *'nmtui'*)                                    desc="Network connections" ;;
        *'power-menu.sh'*)                         desc="Power / logout menu" ;;
        *'bluetooth-menu.sh'*)                     desc="Bluetooth menu" ;;
        *'global-theme-selector.sh'*)              desc="Theme switcher" ;;
        *'theme-selector.sh'*)                     desc="Wallpaper switcher" ;;
        *'random-wall.sh'*)                        desc="Random wallpaper" ;;
        *'waybar-selector.sh'*)                    desc="Waybar theme selector" ;;
        *'killall -SIGUSR1 waybar'*)               desc="Toggle top bar" ;;
        *'swaync-client --close-latest'*)        desc="Dismiss notification" ;;
        *'swaync-client --close-all'*)            desc="Dismiss all notifications" ;;
        *'swaync-client --toggle-dnd'*)           desc="Toggle notification silencing" ;;
        *'swaync-client --toggle-panel'*)         desc="Notification center" ;;
        *'notification-history.sh'*)               desc="Notification history" ;;
        *'--output-volume raise'*)                 desc="Volume up" ;;
        *'--output-volume lower'*)                 desc="Volume down" ;;
        *'--output-volume mute-toggle'*)           desc="Toggle mute" ;;
        *'--brightness raise'*)                    desc="Brightness up" ;;
        *'--brightness lower'*)                    desc="Brightness down" ;;
        *'grim -g'*)                               desc="Area screenshot" ;;
        *'grim -'*)                                desc="Full screenshot" ;;
        *'ocr-extract'*)                           desc="OCR text extraction (region → clipboard)" ;;
        *'menu-clipboard'*)                        desc="Clipboard history" ;;
        *'menu-emoji'*)                            desc="Emojis" ;;
        *'keybinds-cheatsheet'*)                   desc="Keybindings cheatsheet" ;;
        *)                                         desc="" ;;
    esac
}

# Prefer the explicit description= from the bind opts; fall back to label().
bind_desc() {
    local line="$1" action="$2"
    local re='(description|desc)[[:space:]]*=[[:space:]]*"([^"]*)"'
    desc=""
    if [[ "$line" =~ $re ]]; then
        desc="${BASH_REMATCH[2]}"
    else
        label "$action"
    fi
}

pretty_key() {
    # Bash-only (zero forks): the old version spawned a 40-expression
    # `sed` per binding (~155 forks ≈ most of the 0.4s). Same output.
    local s="$1"
    s="${s//mod .. \" +/SUPER +}"
    s="${s//\"/}"
    s="${s//Return/Enter}"
    s="${s//ESCAPE/Esc}"
    s="${s//TAB/Tab}"
    s="${s//comma/,}"
    s="${s//period/.}"
    s="${s//minus/-}"
    s="${s//equal/=}"
    s="${s//SLASH//}"
    s="${s//BACKSPACE/Backspace}"
    s="${s//code:20/-}"
    s="${s//code:21/=}"
    s="${s//mouse_down/Wheel Down}"
    s="${s//mouse_up/Wheel Up}"
    s="${s//mouse:272/Mouse left}"
    s="${s//mouse:273/Mouse right}"
    s="${s//XF86AudioRaiseVolume/Vol+}"
    s="${s//XF86AudioLowerVolume/Vol-}"
    s="${s//XF86AudioMute/Mute}"
    s="${s//XF86AudioMicMute/Mic Mute}"
    s="${s//XF86AudioNext/Next}"
    s="${s//XF86AudioPrev/Prev}"
    s="${s//XF86AudioPlay/Play}"
    s="${s//XF86AudioPause/Pause}"
    s="${s//XF86MonBrightnessUp/Bright+}"
    s="${s//XF86MonBrightnessDown/Bright-}"
    s="${s//XF86TouchpadToggle/Touchpad}"
    s="${s//XF86TouchpadOn/Touchpad On}"
    s="${s//XF86TouchpadOff/Touchpad Off}"
    s="${s//XF86Calculator/Calc}"
    s="${s//switch:on:Lid Switch/Lid closed}"
    s="${s//Print/PrtSc}"
    s="${s// super/Super}"
    s="${s// shift/Shift}"
    s="${s//  +/ }"
    # trim
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

render() {
    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ "$line" =~ ^hl\.bind\( ]] || continue
        [[ "$line" == *" .. i"* || "$line" == *' .. tostring'* ]] && continue
        # Only single-line binds are parsed; multi-line blocks use label() via the
        # first line's action, so describe them through bind_desc() below when absent.

        body="${line#hl.bind(}"
        raw_key="${body%%,*}"
        rest="${body#*,}"

        key="$(pretty_key "$raw_key")"
        bind_desc "$line" "$rest"

        # Long-running option tables on their own line hold no description; the
        # label() fallback above already covered the most common ones.
        [[ -n "$desc" ]] || continue
        printf '%s\t%s\n' "$key" "$desc"
    done < <(grep -h 'hl\.bind(' "$HYP_DIR"/*.lua)

    printf '%s\t%s\n' "SUPER + 1-9 / 0"          "Switch to workspace"
    printf '%s\t%s\n' "SUPER + SHIFT + 1-9 / 0"  "Move window to workspace"
    printf '%s\t%s\n' "SUPER + SHIFT + ALT + 1-9 / 0" "Move window silently"
    printf '%s\t%s\n' "SUPER + ALT + 1-5"        "Switch to group window"
    printf '%s\t%s\n' "History viewer"           "First entry clears all history"
}

# Order the most useful/commonly-hit bindings first (priority-ordered entries), so the menu opens on the essentials instead of an
# arbitrary file-order dump. Lower priority number = shown first.
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
        if (desc ~ /Toggle fullscreen/)        prio = 6
        if (desc ~ /Toggle.*floating/)         prio = 7
        if (desc ~ /Toggle window group/)      prio = 8
        if (desc ~ /Toggle.*split/)            prio = 9
        if (desc ~ /Switch to workspace/)      prio = 10
        if (desc ~ /Move window to workspace/) prio = 11
        if (desc ~ /Move window silently/)     prio = 12
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
        if (desc ~ /Toggle nightlight/)        prio = 43
        if (desc ~ /Toggle idle/)              prio = 44
        if (desc ~ /Toggle window (transparency|gaps)/) prio = 45
        if (desc ~ /Monitor scaling/)          prio = 46
        if (desc ~ /Notification/)             prio = 47
        if (desc ~ /Save window size|Restore/) prio = 48
        if (desc ~ /Close all windows/)        prio = 49
        printf "%d\t%s\t%s\n", prio, key, desc
    }' |
    sort -t $'\t' -k1,1n -k2,2 |
    cut -f2-
}

# Emit each entry as a single display line in menu style — the key combo
# left-padded to a fixed column, then " → ", then a short description. rofi
# then shows one roomy row per binding instead of two cramped side-by-side
# columns (which is why the arrow separator was missing before).
format_entries() {
    awk -F '\t' '{ printf "%-35s → %s\n", $1, $2 }'
}

build_entries_uncached() {
    render | prioritize_entries | format_entries
}

output_entries() {
    local key cache_file tmp_file
    key=$(cache_key)
    cache_file="$CACHE_DIR/keybinds-${key}.list"
    if [[ -s "$cache_file" ]]; then
        cat "$cache_file"
    elif mkdir -p "$CACHE_DIR" 2>/dev/null; then
        tmp_file=$(mktemp "$CACHE_DIR/keybinds.XXXXXX") || { build_entries_uncached; return; }
        if build_entries_uncached >"$tmp_file"; then
            mv "$tmp_file" "$cache_file"
            find "$CACHE_DIR" -maxdepth 1 -type f -name 'keybinds-*.list' ! -name "keybinds-${key}.list" -delete 2>/dev/null || true
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
    output_entries | rofi -dmenu $ROFI_PERF -p "$PROMPT" -theme "$THEME"
fi