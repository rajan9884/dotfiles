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

    # Suffix match on the label: immune to icon-font substitutions or
    # stray padding rofi may introduce around the row text.
    case "$choice" in
        *Lock)
            swaylock & ;;

        *Logout)
            if confirm_action "logout"; then
                swaymsg exit
            fi ;;

        *suspend*)
            if confirm_action "suspend"; then
                if ! err=$(systemctl suspend 2>&1); then
                    notify "Suspend failed" "${err:-exit code $?}"
                fi
            fi ;;

        *Reboot)
            if ! err=$(systemctl reboot 2>&1); then
                notify "Reboot failed" "${err:-exit code $?}"
            fi ;;

        *Shutdown)
            if confirm_action "shutdown"; then
                if ! err=$(systemctl poweroff 2>&1); then
                    notify "Shutdown failed" "${err:-exit code $?}"
                fi
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
