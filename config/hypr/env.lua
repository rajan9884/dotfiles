-- ──────────────────────────────────────────────
--   Monitors & Environment (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────

-- ── Monitor ──────────────────────────────────
hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 2 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- ── Environment ──────────────────────────────
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
