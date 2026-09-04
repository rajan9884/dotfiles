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
        *'arch-wallpaper-picker'*)                 desc="Wallpaper picker" ;;
        *'arch-theme-switcher'*)                   desc="Theme switcher" ;;
        *'capture-screen'*)                        desc="Capture entire screen" ;;
        *'capture-region'*)                        desc="Screenshot" ;;
        *'capture-satty'*)                         desc="Screenshot & annotate" ;;
        *'ocr-extract'*)                           desc="OCR text extraction (region → clipboard)" ;;
        *'menu-clipboard'*)                        desc="Clipboard history" ;;
        *'exec_cmd(browser)'*)                     desc="Open browser" ;;
        *'exec_cmd(file)'*)                        desc="Open file manager" ;;
        *'wifi-menu.sh'*)                          desc="Network menu" ;;
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
    printf '%s' "$1" | sed -E \
        -e 's/mod \.\. " \+/SUPER +/g' \
        -e 's/"//g' \
        -e 's/\bReturn\b/Enter/g' \
        -e 's/\bESCAPE\b/Esc/g' \
        -e 's/\bTAB\b/Tab/g' \
        -e 's/\bcomma\b/,/g' \
        -e 's/\bperiod\b/./g' \
        -e 's/\bminus\b/-/g' \
        -e 's/\bequal\b/=/g' \
        -e 's/\bSLASH\b/\//g' \
        -e 's/\bBACKSPACE\b/Backspace/g' \
        -e 's/\bHome\b/Home/g' \
        -e 's/\bcode:20\b/-/g' \
        -e 's/\bcode:21\b/=/g' \
        -e 's/\bmouse_down\b/Wheel Down/g' \
        -e 's/\bmouse_up\b/Wheel Up/g' \
        -e 's/\bmouse:272\b/Mouse left/g' \
        -e 's/\bmouse:273\b/Mouse right/g' \
        -e 's/\bXF86AudioRaiseVolume\b/Vol+/g' \
        -e 's/\bXF86AudioLowerVolume\b/Vol-/g' \
        -e 's/\bXF86AudioMute\b/Mute/g' \
        -e 's/\bXF86AudioMicMute\b/Mic Mute/g' \
        -e 's/\bXF86AudioNext\b/Next/g' \
        -e 's/\bXF86AudioPrev\b/Prev/g' \
        -e 's/\bXF86AudioPlay\b/Play/g' \
        -e 's/\bXF86AudioPause\b/Pause/g' \
        -e 's/\bXF86MonBrightnessUp\b/Bright+/g' \
        -e 's/\bXF86MonBrightnessDown\b/Bright-/g' \
        -e 's/\bXF86TouchpadToggle\b/Touchpad/g' \
        -e 's/\bXF86TouchpadOn\b/Touchpad On/g' \
        -e 's/\bXF86TouchpadOff\b/Touchpad Off/g' \
        -e 's/\bXF86Calculator\b/Calc/g' \
        -e 's/\bswitch:on:Lid Switch\b/Lid closed/g' \
        -e 's/\bPrint\b/PrtSc/g' \
        -e 's/(^|[^[:alpha:]])left([^[:alpha:]]|$)/\1Left\2/g' \
        -e 's/(^|[^[:alpha:]])right([^[:alpha:]]|$)/\1Right\2/g' \
        -e 's/(^|[^[:alpha:]])up([^[:alpha:]]|$)/\1Up\2/g' \
        -e 's/(^|[^[:alpha:]])down([^[:alpha:]]|$)/\1Down\2/g' \
        -e 's/\bsuper/Super/g' \
        -e 's/\bshift/Shift/g' \
        -e 's/ +/ /g' \
        -e 's/^ *//' -e 's/ *$//'
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

# Order the most useful/commonly-hit bindings first (mirrors Omarchy's
# prioritize_entries), so the menu opens on the essentials instead of an
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

# Emit each entry as a single display line in Omarchy style — the key combo
# left-padded to a fixed column, then " → ", then a short description. rofi
# then shows one roomy row per binding instead of two cramped side-by-side
# columns (which is why the arrow separator was missing before).
format_entries() {
    awk -F '\t' '{ printf "%-35s → %s\n", $1, $2 }'
}

render | prioritize_entries | format_entries | rofi -dmenu -i -p "$PROMPT" -theme "$THEME"