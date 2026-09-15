#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   Power / Controls Menu for Waybar
#   Uniform rows,
#   hover-highlight, single-click accepts.
# ──────────────────────────────────────────────

THEME="$HOME/.config/rofi/power-menu.rasi"

POSITION="$1"
ROFI_ARGS=""
if [[ "$POSITION" == "left" ]]; then
    ROFI_ARGS="-location 7 -xoffset 60 -yoffset -20"
fi

I_LOCK=$'\U000F033E'     # md-lock
I_LOGOUT=$'\U000F0343'    # md-logout
I_SLEEP=$'\U000F0904'     # md-power_sleep
I_REBOOT=$'\U000F0709'    # md-restart
I_SHUTDOWN=$'\U000F0425'  # md-power
I_YES=$'\U000F012C'       # md-check
I_CANCEL=$'\U000F0159'    # md-close_circle

notify() {
    local dur=4000
    if [[ "$1" == "-t" ]]; then dur="$2"; shift 2; fi
    notify-send -a "Power" -i system-shutdown -t "$dur" "$1" "$2"
}

row() {
    local icon="$1" label="$2" acc="${3:-}"
    printf '%s  %-24s%s\n' "$icon" "$label" "$acc"
}

pango_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '%s' "$s"
}

build_menu() {
    row "$I_LOCK" "Lock"
    row "$I_LOGOUT" "Logout"
    row "$I_SLEEP" "Sleep (suspend)"
    row "$I_REBOOT" "Reboot"
    row "$I_SHUTDOWN" "Shutdown"
}

confirm_action() {
    local action="$1"
    local choice
    choice=$(printf '%s\n%s' \
        "$(printf '%s  %-24s' "$I_YES" "Yes, $action")" \
        "$(printf '%s  %-24s' "$I_CANCEL" "Cancel")" \
        | rofi -dmenu -i $ROFI_ARGS \
            -selected-row 0 -hover-select \
            -me-select-entry '' -me-accept-entry MousePrimary \
            -p "  Confirm?" -theme "$THEME")
    [[ "$choice" == *"Yes"* ]] && return 0 || return 1
}

handle_selection() {
    local choice="$1"
    choice="${choice%"${choice##*[![:space:]]}"}"

    case "$choice" in
        "$I_LOCK  Lock")
            hyprlock & ;;

        "$I_LOGOUT  Logout")
            if confirm_action "logout"; then
                hyprctl dispatch "hl.dsp.exit()"
            fi ;;

        "$I_SLEEP  Sleep (suspend)")
            if confirm_action "suspend"; then
                systemctl suspend
            fi ;;

        "$I_REBOOT  Reboot")
            systemctl reboot ;;

        "$I_SHUTDOWN  Shutdown")
            if confirm_action "shutdown"; then
                systemctl poweroff
            fi ;;

        *) notify "Nothing selected" "Pick a power action" ;;
    esac
}

main() {
    local choice tmp
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    build_menu > "$tmp"
    choice=$(rofi -dmenu -i $ROFI_ARGS \
        -selected-row 0 \
        -hover-select \
        -me-select-entry '' \
        -me-accept-entry MousePrimary \
        -p "$I_SHUTDOWN  Power" \
        -mesg "$(pango_escape "Choose an action")" \
        -theme "$THEME" < "$tmp")
    [[ -z "$choice" ]] && exit 0
    handle_selection "$choice"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
