-- ──────────────────────────────────────────────
--   Shared variables (Hyprland Lua — 0.55+)
--   Each `require()` runs in its own Lua scope, so shared values are
--   exposed by returning a table that consumers pull in via
--   `local V = require("vars")`.
-- ──────────────────────────────────────────────
local HOME = os.getenv("HOME")

return {
	HOME = HOME,
	terminal = "kitty",
	browser = "helium-browser",
	browser_private = "helium-browser --incognito",
	editor = "kitty -e nvim",
	terminal_tmux = "kitty -e tmux",
	menu = "rofi -show drun",
	file = HOME .. "/.local/bin/nautilus-gnome",
	scripts = HOME .. "/.config/hypr/scripts",
	mod = "SUPER",
}
