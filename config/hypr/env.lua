-- ──────────────────────────────────────────────
--   Monitors & Environment (Hyprland Lua — 0.55+)
-- ──────────────────────────────────────────────

-- ── Monitor ──────────────────────────────────
-- Samsung ATNA40YK11-0 OLED: 10-bit, BT2020, ST2084 PQ (verified via edid-decode).
-- HDR state lives in ~/.cache/hypr-hdr-state ("hdr"/"sdr"), written only by
-- scripts/hdr-toggle.sh. Wallpaper switches run `hyprctl reload`, which
-- re-applies this file — reading the state here keeps the keybind as the
-- only thing that flips HDR. Default when the file is absent: hdr.
local _hdr_state_file = (os.getenv("HOME") or "") .. "/.cache/hypr-hdr-state"
local _hdr_on = true
do
	local _f = io.open(_hdr_state_file, "r")
	if _f then
		local _s = _f:read("*l") or ""
		_f:close()
		_hdr_on = (_s ~= "sdr")
	end
end
if _hdr_on then
	hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 2, bitdepth = 10, cm = "hdr", supports_hdr = 1, supports_wide_color = 1 })
else
	hl.monitor({ output = "eDP-1", mode = "2880x1800@90", position = "0x0", scale = 2, bitdepth = 8, cm = "srgb" })
end
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- ── Environment ──────────────────────────────
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- ── Pure Wayland Session (Strictly No X11 / XWayland) ──
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
-- Void / Intel Iris Xe (13th Gen Raptor Lake, iHD driver)
hl.env("LIBVA_DRIVER_NAME", "iHD")
