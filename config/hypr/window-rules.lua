-- ──────────────────────────────────────────────
--   Window Rules (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────
hl.window_rule({
	name = "suppress-maximize",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "media-float",
	match = { class = "^(imv|mpv)$" },
	float = true,
	center = true,
	size = { 875, 600 },
})

hl.window_rule({
	name = "nautilus-preview-float",
	match = { class = "org.gnome.NautilusPreviewer" },
	float = true,
	center = true,
	size = { 875, 600 },
})

hl.window_rule({
	name = "media-opaque",
	match = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$" },
	opacity = "1 1",
})

hl.window_rule({
	name = "previewer-no-default-opacity",
	match = { class = "org.gnome.NautilusPreviewer" },
	tag = "-default-opacity",
})

hl.window_rule({
	name = "webapp-install-float",
	match = { class = "(webapp-install|wifi-share)" },
	float = true,
	center = true,
	size = { 650, 480 },
})

-- ── Per-app workspaces ─────────────────────────
-- Browsers → 1, installed webapps (PWA) → 2, files → 3, notes → 4.
hl.window_rule({
	name = "browser-to-ws1",
	match = { class = "^(chromium|helium|helium-browser|brave-browser)$" },
	workspace = 1,
})

hl.window_rule({
	name = "webapp-to-ws2",
	match = { class = "^chrome-.*__-.*$" },
	workspace = 2,
})

hl.window_rule({
	name = "files-to-ws3",
	match = { class = "^(org.gnome.Nautilus|nautilus)$" },
	workspace = 3,
})

hl.window_rule({
	name = "notes-to-ws4",
	match = { class = "^(obsidian|Obsidian)$" },
	workspace = 4,
})
