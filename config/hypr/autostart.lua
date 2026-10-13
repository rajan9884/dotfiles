-- ──────────────────────────────────────────────
--   Autostart (was exec-once) (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
local vars = require("vars")

hl.on("hyprland.start", function()
	-- Void: no systemd user units. Direct execs, Void paths.
	hl.exec_cmd("dbus-update-activation-environment --all")
	-- Single audio stack: pipewire auto-spawns wireplumber + pulse (see sway config).
	hl.exec_cmd("sh -c 'pkill -x pipewire-pulse; pkill -x wireplumber; pkill -x pipewire; sleep 1; exec pipewire'")
	hl.exec_cmd("sh -c 'for i in $(seq 1 60); do s=$(pactl get-default-sink 2>/dev/null) || s=\"\"; case \"$s\" in \"\"|*auto_null*|*Dummy*) sleep 1;; *) wpctl set-mute \"$s\" 0 >/dev/null 2>&1; break;; esac; done'")
	hl.exec_cmd(vars.HOME .. "/.config/hypr/scripts/portal-warmup.sh")
	hl.exec_cmd("sh -c 'B=$(cat \"${XDG_STATE_HOME:-$HOME/.local/state}/backlight\" 2>/dev/null); case \"$B\" in \"\"|*[!0-9]*) ;; *) brightnessctl -c backlight set \"$B\" >/dev/null 2>&1 || true;; esac'")
	hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd(vars.HOME .. "/.config/hypr/scripts/init-wallpaper.sh")
	hl.exec_cmd("hypridle")
	hl.exec_cmd(vars.HOME .. "/.config/hypr/scripts/waybar-launch.sh")
	hl.exec_cmd("sh -c 'pgrep -x swayosd-server >/dev/null || exec swayosd-server'")
	hl.exec_cmd("mako")
	hl.exec_cmd("thunar --daemon 2>/dev/null &") -- volume automount (replaces udiskie) + faster windows
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true")
	hl.exec_cmd("sh -c 'wl-paste --watch cliphist store'")
	hl.exec_cmd(vars.HOME .. "/.local/bin/power-profiles watch")
	hl.exec_cmd(vars.terminal)
end)
