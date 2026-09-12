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
-- Timing: closes are faster than opens (snappy feel), layers/scratchpad glide.
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.animation({ leaf = "windows", enabled = ANIM_ENABLED, speed = 3, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = ANIM_ENABLED, speed = 5.5, bezier = "easeOutExpo", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = ANIM_ENABLED, speed = 4, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "fade", enabled = ANIM_ENABLED, speed = 4, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeOut", enabled = ANIM_ENABLED, speed = 5, bezier = "easeOutExpo" })
hl.animation({ leaf = "workspaces", enabled = ANIM_ENABLED, speed = 3, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = ANIM_ENABLED, speed = 3.5, bezier = "easeOutExpo", style = "slidevert" })
hl.animation({ leaf = "layers", enabled = ANIM_ENABLED, speed = 4, bezier = "easeOutExpo", style = "slide" })

-- ── Focus clarity: dim + slightly fade inactive windows ──
-- Merges per-key with the theme's decoration block (rounding/blur/shadow
-- live in themes/*/theme.lua); verified via `hyprctl getoption`.
hl.config({
	decoration = {
		dim_inactive = true,
		dim_strength = 0.12,
		dim_special = 0.0,
		inactive_opacity = 0.93,
	},
})

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
