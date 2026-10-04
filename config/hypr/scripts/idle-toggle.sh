#!/usr/bin/env bash
# Caffeine-like toggle for Hyprland + hypridle (and logind sleep).
#
#   idle-toggle.sh [toggle|on|off|status]
#
# - No arg / toggle : flip state (keeps old `idle-toggle.sh` behaviour,
#                     so the existing SUPER+CTRL+I bind keeps working).
# - on / off        : force enable / disable caffeine.
# - status          : print Waybar JSON for custom/caffeine.
#
# Caffeine ON  = hypridle stopped (no dim/lock/dpms/suspend timers)
#                + a `systemd-inhibit --what=idle:sleep` lock held so
#                logind / other daemons can't auto-sleep either.
# Caffeine OFF = inhibit released + hypridle restarted.
set -euo pipefail

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
PIDFILE="$RUNTIME/hypr-caffeine-inhibit.pid"
SIGNAL=8 # must match "signal" of custom/caffeine in Waybar

is_active() {
	! pgrep -x hypridle >/dev/null
}

kill_stale_inhibit() {
	if [[ -f "$PIDFILE" ]]; then
		local pid
		pid="$(cat "$PIDFILE" 2>/dev/null || true)"
		if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
			kill "$pid" 2>/dev/null || true
		fi
		rm -f "$PIDFILE"
	fi
	# Belt and braces: kill any leftover inhibitor we started previously.
	pkill -f "systemd-inhibit --what=idle:sleep --who=caffeine" 2>/dev/null || true
}

refresh_waybar() {
	pkill -RTMIN+"$SIGNAL" waybar 2>/dev/null || true
	pkill -RTMIN+"$SIGNAL" .waybar-wrapped 2>/dev/null || true
}

caffeine_on() {
	if is_active; then
		# Already on — make sure a stale inhibit PID isn't lying around.
		if [[ ! -f "$PIDFILE" ]]; then
			kill_stale_inhibit
			setsid systemd-inhibit --what=idle:sleep --who=caffeine --why="Caffeine enabled (idle lock off)" sleep infinity >/dev/null 2>&1 < /dev/null &
			echo "$!" >"$PIDFILE"
			disown 2>/dev/null || true
		fi
		return 0
	fi
	pkill -x hypridle 2>/dev/null || true
	kill_stale_inhibit
	# Hold logind idle+sleep while hypridle is down (setsid so the
	# lock survives the short-lived toggle process).
	setsid systemd-inhibit --what=idle:sleep --who=caffeine --why="Caffeine enabled (idle lock off)" sleep infinity >/dev/null 2>&1 < /dev/null &
	echo "$!" >"$PIDFILE"
	disown 2>/dev/null || true
	notify-send -a Caffeine "Caffeine enabled" "Auto-lock, dim, screen-off and auto-suspend are OFF" 2>/dev/null || true
	refresh_waybar
}

caffeine_off() {
	if ! is_active && [[ ! -f "$PIDFILE" ]]; then
		return 0
	fi
	kill_stale_inhibit
	if ! pgrep -x hypridle >/dev/null; then
		setsid hypridle >/dev/null 2>&1 < /dev/null &
		disown 2>/dev/null || true
	fi
	notify-send -a Caffeine "Caffeine disabled" "Auto-lock, dim, screen-off and auto-suspend are ON" 2>/dev/null || true
	refresh_waybar
}

caffeine_status() {
	if is_active; then
		jq -cn '{text: "󰅶", class: "active", tooltip: "Caffeine ON — idle lock, dim, screen-off and auto-suspend disabled (click to allow sleep)"}'
	else
		jq -cn '{text: "󰶐", class: "inactive", tooltip: "Caffeine OFF — idle lock and auto-suspend enabled (click to prevent sleep)"}'
	fi
}

case "${1:-toggle}" in
	on | enable) caffeine_on ;;
	off | disable) caffeine_off ;;
	status) caffeine_status ;;
	toggle | "")
		if is_active; then
			caffeine_off
		else
			caffeine_on
		fi
		;;
	*)
		echo "Usage: $(basename "$0") [toggle|on|off|status]" >&2
		exit 1
		;;
esac
