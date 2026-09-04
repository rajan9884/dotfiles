-- ──────────────────────────────────────────────
--   Look & feel: animations, curves, layouts,
--   misc / render / debug (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────

-- ── Animations ───────────────────────────────
-- Single master switch: flip this one value to turn ALL animations on/off.
local ANIM_ENABLED = true

hl.config({
	animations = {
		enabled = ANIM_ENABLED,
	},
})
-- Bezier + per-leaf styles only take effect when ANIM_ENABLED is true.
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.animation({ leaf = "windows", enabled = ANIM_ENABLED, speed = 3, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = ANIM_ENABLED, speed = 3, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "fade", enabled = ANIM_ENABLED, speed = 3, bezier = "easeOutExpo" })
hl.animation({ leaf = "workspaces", enabled = ANIM_ENABLED, speed = 3, bezier = "easeOutExpo", style = "slide" })

-- ── Layouts ──────────────────────────────────
hl.config({
	dwindle = {
		-- pseudotile removed in 0.55 (use window rule or dispatcher `pseudo` instead)
		preserve_split = true,
	},
	master = {
		new_status = "master",
	},
})

-- ── Misc / Render / Debug ────────────────────
hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		animate_manual_resizes = false,
		initial_workspace_tracking = false,
	},
	render = {
		direct_scanout = true, -- was misc.no_direct_scanout (inverted)
	},
	debug = {
		disable_logs = true,
		-- vfr moved here from misc.vfr (0.55)
		vfr = true,
	},
})
