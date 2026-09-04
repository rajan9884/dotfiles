-- ──────────────────────────────────────────────
--   Plugins (Hyprland Lua — 0.55+)
--   HyprExpo (exposé overview) is built from the maintained fork
--   https://github.com/sandwichfarm/hyprexpo via bin/build-hyprexpo
--   into ~/.local/lib/hypr/hyprexpo.so (upstream retired the
--   official plugin). Everything here degrades gracefully when the
--   .so is absent — the overview bind just no-ops until built.
-- ──────────────────────────────────────────────

local HOME = os.getenv("HOME")
local EXPO_SO = HOME .. "/.local/lib/hypr/hyprexpo.so"

-- Load the plugin when present; silently skip on a fresh clone.
local expo_loaded = false
do
	local f = io.open(EXPO_SO, "r")
	if f then
		f:close()
		expo_loaded = pcall(hl.plugin.load, EXPO_SO)
	end
end

-- Only set plugin keys when the plugin is actually loaded —
-- Hyprland errors on unknown `plugin:*` keys otherwise.
if not expo_loaded then
	for _, p in ipairs(hl.get_loaded_plugins()) do
		if p.name == "hyprexpo" then
			expo_loaded = true
			break
		end
	end
end

if not expo_loaded then
	return
end

-- HyprExpo appearance (matugen-friendly teal on dark).
hl.config({
	plugin = {
		hyprexpo = {
			columns = 3,
			gap_size = 8,
			bg_col = "rgb(0f1512)",
			workspace_method = "center current",
			label_enable = true,
			border_color_current = "rgb(89d6b9)",
			border_color_hover = "rgb(aabbcc)",
			cancel_key = "escape",
		},
	},
})
