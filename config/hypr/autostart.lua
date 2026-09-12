-- ──────────────────────────────────────────────
--   Autostart (was exec-once) (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
local vars = require("vars")

hl.on("hyprland.start", function()
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("hypridle")
	-- Waybar is owned by its systemd user unit. Never launch a bare
	-- `waybar &` here: it becomes a Hyprland child alongside
	-- waybar.service and stacks a duplicate bar (visible after the
	-- next `hyprctl reload` / wallpaper switch restyles one copy).
	hl.exec_cmd("systemctl --user start waybar.service")
	-- swaync is owned by its systemd user unit (graphical-session.target);
	-- starting a second copy here races it and fails with "already running".
	hl.exec_cmd("systemctl --user start swayosd.service 2>/dev/null || true")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("sleep 3 && /home/rajan/.local/bin/power-profiles autodetect")
	hl.exec_cmd(vars.terminal)
end)
