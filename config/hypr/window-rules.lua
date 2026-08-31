-- ──────────────────────────────────────────────
--   Window Rules (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})
