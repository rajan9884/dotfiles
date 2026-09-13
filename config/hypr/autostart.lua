-- ──────────────────────────────────────────────
--   Autostart (was exec-once) (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
local vars = require("vars")

hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl --user start polkit-gnome.service 2>/dev/null || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd(vars.HOME .. "/.config/hypr/scripts/init-wallpaper.sh")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start waybar.service 2>/dev/null || waybar &")
	hl.exec_cmd("systemctl --user start swaync.service 2>/dev/null || swaync &")
	hl.exec_cmd("systemctl --user start swayosd.service 2>/dev/null || true")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("sleep 3 && " .. vars.HOME .. "/.local/bin/power-profiles autodetect")
	hl.exec_cmd(vars.terminal)
end)
