-- ──────────────────────────────────────────────
--   Input (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
hl.config({
	input = {
		kb_layout = "us",
		-- Snappy repeat: kicks in after 250ms at 40/sec
		-- (Hyprland defaults are 600ms / 25-sec and feel laggy on long-press).
		repeat_rate = 40,
		repeat_delay = 250,
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			drag_lock = true,
		},
	},
})
