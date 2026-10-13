-- ──────────────────────────────────────────────
--   Window Rules (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
-- Idle inhibit on fullscreen (YouTube/video): hypridle listeners
-- (dim/lock/dpms/suspend) pause while inhibited. Browsers/mpv inhibit
-- via Wayland/D-Bus only when Wayland-native, so force-inhibit any
-- fullscreen surface (sway parity: inhibit_idle fullscreen).
hl.window_rule({
	name = "idle-inhibit-fullscreen",
	match = { class = ".*" },
	idle_inhibit = "fullscreen",
})

hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Catch-all: `center` is a no-op for tiled windows, so this only
-- affects floating ones (dialogs, popouts, toggled floats).
hl.window_rule({
	name = "float-center",
	match = { class = ".*" },
	center = true,
})

hl.window_rule({
	name = "media-float",
	match = { class = "^(imv|mpv)$" },
	float = true,
	center = true,
	size = { 875, 600 },
})

hl.window_rule({
	name = "doc-float",
	match = { class = "^org.pwmt.zathura$" },
	float = true,
	center = true,
	size = { 900, 700 },
})

hl.window_rule({
	name = "thunar-dialog-float",
	match = { class = "^Thunar$", title = ".*(Properties|Rename|Preferences|Bulk Rename).*" },
	float = true,
	center = true,
	size = { 700, 500 },
})

hl.window_rule({
	name = "media-opaque",
	match = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv)$" },
	opacity = "1 1",
})

-- VS Code: a whisper of transparency. Real see-through needs the
-- compositor (per-color alpha inside VS Code alone composites against
-- its own opaque window), so this lives here, not in the theme.
hl.window_rule({
	name = "code-translucent",
	match = { class = "^(code|Code|code-oss)$" },
	opacity = "0.92 0.88",
})

-- Preview only: normal Mousepad windows tile for editing.
-- Space-preview (Thunar custom action) runs `text-preview`: a pager
-- (bat/less) inside foot with app-id "text-preview". A pager is truly
-- read-only — Mousepad's "[Read Only]" still lets you type, so Mousepad
-- is deliberately NOT used for preview.
hl.window_rule({
	name = "text-preview-float",
	match = { class = "^text-preview$" },
	float = true,
	center = true,
	size = { 800, 600 },
})

hl.window_rule({
	name = "webapp-install-float",
	match = { class = "(webapp-install|webapp-remove)" },
	float = true,
	center = true,
	size = { 650, 480 },
})

-- ── Per-app workspaces ─────────────────────────
-- Removed: forcing browsers → 1, webapps → 2, files → 3, notes → 4
-- yanked every new window away from the active workspace, so windows
-- never tiled where you opened them and workspaces 5+ stayed empty.
-- Apps now open on the current workspace (standard tiling).
-- To restore, re-add e.g.:
-- hl.window_rule({ name = "browser-to-ws1",
-- 	match = { class = "^(chromium|helium|helium-browser|brave-browser)$" },
-- 	workspace = 1, })
