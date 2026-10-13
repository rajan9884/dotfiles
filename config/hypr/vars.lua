-- ──────────────────────────────────────────────
--   Shared variables (Hyprland Lua — 0.55+)
--   Each `require()` runs in its own Lua scope, so shared values are
--   exposed by returning a table that consumers pull in via
--   `local V = require("vars")`.
-- ──────────────────────────────────────────────
local HOME = os.getenv("HOME")

return {
	HOME = HOME,
	terminal = "alacritty", -- Void primary (matches sway $term; foot is fallback)
	terminal_alt = "foot", -- secondary fallback
	browser = HOME .. "/.local/bin/helium-browser",
	browser_private = HOME .. "/.local/bin/helium-browser --incognito",
	editor = "alacritty -e nvim",
	terminal_tmux = "alacritty -e tmux",
	menu = "rofi -show drun -theme ~/.config/rofi/active-launcher.rasi",
	file = HOME .. "/.local/bin/thunar-cwd",
	scripts = HOME .. "/.config/hypr/scripts",
	mod = "SUPER",
}
