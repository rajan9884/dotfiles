-- ── Static decoration (wallpaper-driven) ──
-- Single fixed look: gaps, rounding, blur, shadow.
-- Border colors come from matugen (colors.lua), regenerated from
-- the active wallpaper in ~/.local/share/wallpapers/Wallpaper/.

local colors = nil
pcall(function()
	colors = require("colors")
end)
local ab = (colors and colors.active_border) or (type(active_border) == "string" and active_border) or "85d6c1"
local ib = (colors and colors.inactive_border) or (type(inactive_border) == "string" and inactive_border) or "3f4946"

hl.config({
	decoration = {
		rounding = 12,
		blur = {
			enabled = false,
			size = 6,
			passes = 3,
		},
		shadow = {
			enabled = true,
			range = 8,
			render_power = 2,
			color = "rgba(00000028)",
		},
	},
	general = {
		gaps_in = 4,
		gaps_out = 12,
		border_size = 2,
		col = {
			active_border = "rgb(" .. ab .. ")",
			inactive_border = "rgb(" .. ib .. ")",
		},
		layout = "dwindle",
		allow_tearing = false,
	},
})
