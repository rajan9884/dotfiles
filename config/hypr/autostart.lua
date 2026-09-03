-- ──────────────────────────────────────────────
--   Autostart (was exec-once) (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
local vars = require("vars")

hl.on("hyprland.start", function()
	hl.exec_cmd("sleep 1 && hyprlock")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("waybar")
	hl.exec_cmd("dunst")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("sleep 3 && /home/rajan/.local/bin/power-profiles autodetect")
	hl.exec_cmd(vars.terminal)
end)
