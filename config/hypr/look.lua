-- ──────────────────────────────────────────────
--   Look & feel: animations, curves, layouts,
--   misc / render / debug (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────

-- ── Animations ───────────────────────────────
hl.config({
	animations = {
		enabled = false,
	},
})
-- Bezier (was inside animations { bezier = ... })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
-- Animations per leaf (were: animation = windows, 1, 3, easeOutExpo, popin 80% etc.)
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "easeOutExpo" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutExpo", style = "slide" })

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
