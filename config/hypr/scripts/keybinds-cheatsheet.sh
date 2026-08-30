#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Keybindings Cheatsheet
#   Parses the live hl.bind() calls from hyprland.lua and pipes an
#   aligned key + description list through rofi -dmenu.
#   Uses the active scripts theme (which @imports matugen colors.rasi).
# ──────────────────────────────────────────────

set -euo pipefail

LUA="$HOME/.config/hypr/hyprland.lua"
THEME="$HOME/.config/rofi/active-picker.rasi"
PROMPT="Keybindings"

label() {
    action="$1"
    case "$action" in
        *'window.close()'*)                        desc="Close window" ;;
        *'exec_cmd("hyprlock")'*)                  desc="Lock screen" ;;
        *'window.fullscreen()'*)                   desc="Toggle fullscreen" ;;
        *'window.float('*)                         desc="Toggle floating" ;;
        *'window.pseudo()'*)                       desc="Pseudo-tiling" ;;
        *'layout("togglesplit")'*)                 desc="Toggle split" ;;
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
        *'dunstctl close -a'*)                     desc="Dismiss notification" ;;
        *'dunstctl close-all'*)                    desc="Dismiss all notifications" ;;
        *'dunstctl close'*)                        desc="Dismiss notification" ;;
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
        *'menu-emoji'*)                            desc="Emoji & symbol picker" ;;
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
        -e 's/\bSLASH\b/\/+/g' \
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
    done < <(grep -h 'hl\.bind(' "$LUA")

    printf '%s\t%s\n' "SUPER + 1-9 / 0"          "Switch to workspace"
    printf '%s\t%s\n' "SUPER + SHIFT + 1-9 / 0"  "Move window to workspace"
    printf '%s\t%s\n' "SUPER + SHIFT + ALT + 1-9 / 0" "Move window silently"
    printf '%s\t%s\n' "SUPER + ALT + 1-5"        "Switch to group window"
    printf '%s\t%s\n' "History viewer"           "First entry clears all history"
}

render | rofi -dmenu -i -display-columns "1,2" -p "$PROMPT" -theme "$THEME"