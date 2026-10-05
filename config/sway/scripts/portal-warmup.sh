#!/usr/bin/env bash
# Pre-start xdg-desktop-portal backends once PipeWire is ready.
#
# At boot the wlr backend can be dbus-activated before pipewire is up,
# exit(1) ("couldn't connect to context" / "failed to initialize
# screencast"), and stay down until first use. Waiting for the PipeWire
# socket here and then activating the backends guarantees screen sharing
# and portal screenshots work from the first request with no log spam.
# Runs detached from sway's autostart (see sway/config); silent on success.
set -u

RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Snapshot the session bus address so keybind-launched scripts (osd-*)
# can recover it in sessions started without dbus-run-session.
if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    printf '%s\n' "$DBUS_SESSION_BUS_ADDRESS" > "$RUNTIME/session-bus.address" 2>/dev/null || true
    chmod 600 "$RUNTIME/session-bus.address" 2>/dev/null || true
fi
for _ in $(seq 1 30); do
    [ -S "$RUNTIME/pipewire-0" ] && break
    sleep 0.5
done

start_backend() {
    dbus-send --session --print-reply --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus.StartServiceByName \
        "string:$1" uint32:0 >/dev/null 2>&1 || true
}

start_backend org.freedesktop.impl.portal.desktop.wlr
start_backend org.freedesktop.impl.portal.desktop.gtk
