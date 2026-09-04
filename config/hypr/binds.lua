-- ──────────────────────────────────────────────
--   Keybinds (Hyprland Lua — 0.55+)
--   Shared command strings come from vars.lua.
-- ──────────────────────────────────────────────
local vars = require("vars")

local mod = vars.mod
local scripts = vars.scripts

-- Default programs
-- New terminal inherits the focused window's working directory; falls back
-- to vars.terminal (kitty) in $HOME when no focused cwd can be resolved.
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(scripts .. "/terminal-launch.sh"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd(vars.menu))
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd(vars.browser))
hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd(vars.browser), { description = "Open browser" })
hl.bind(mod .. " + SHIFT + ALT + B", hl.dsp.exec_cmd(vars.browser_private), { description = "Open private browser" })
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd(vars.editor), { description = "Open editor" })
hl.bind(mod .. " + ALT + Return", hl.dsp.exec_cmd(vars.terminal_tmux), { description = "Open tmux" })
hl.bind(mod .. " + ALT + K", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/menu-tmux-keybindings"), { description = "Tmux keybindings" })
hl.bind(mod .. " + SHIFT + ALT + M", hl.dsp.exec_cmd("cliamp"), { description = "Music player (cliamp)" })
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("lazydocker"), { description = "Docker (lazydocker)" })
hl.bind(mod .. " + SHIFT + O", hl.dsp.exec_cmd("obsidian"), { description = "Open Obsidian" })
hl.bind(mod .. " + CTRL + T", hl.dsp.exec_cmd("kitty -e btop"), { description = "System monitor (btop)" })

hl.bind(mod .. " + W", hl.dsp.window.close()) -- was killactive (graceful close)
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" })) -- was fullscreen, 0
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle window floating/tiling" }) -- togglefloating
hl.bind(mod .. " + P", hl.dsp.window.pseudo(), { description = "Pseudo window" }) -- pseudo
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratchpad"), { description = "Toggle scratchpad" })
hl.bind(mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), { description = "Move window to scratchpad" })
-- Dedicated scratchpads: music + terminal (SUPER+S stays the general one)
hl.bind(mod .. " + ALT + M", hl.dsp.workspace.toggle_special("music"), { description = "Toggle music scratchpad" })
hl.bind(mod .. " + CTRL + ALT + M", hl.dsp.window.move({ workspace = "special:music", follow = false }), { description = "Move window to music scratchpad" })
hl.bind(mod .. " + CTRL + Return", hl.dsp.workspace.toggle_special("terminal"), { description = "Toggle terminal scratchpad" })
hl.bind(mod .. " + CTRL + SHIFT + Return", hl.dsp.window.move({ workspace = "special:terminal", follow = false }), { description = "Move window to terminal scratchpad" })
-- Workspace overview (HyprExpo; no-op until bin/build-hyprexpo has run)
hl.bind(mod .. " + grave", hl.dsp.exec_cmd("hyprctl dispatch hyprexpo:expo toggle"), { description = "Workspace overview" })
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"), { description = "Toggle window split" }) -- togglesplit (layoutmsg)
hl.bind(mod .. " + SHIFT + F", hl.dsp.exec_cmd(vars.file))
hl.bind(mod .. " + SHIFT + ALT + F", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/nautilus-cwd"), { description = "File manager (cwd)" })
hl.bind(mod .. " + CTRL + Space", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/arch-wallpaper-picker"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd(scripts .. "/random-wall.sh"))

hl.bind(
	mod .. " + CTRL + SHIFT + Space",
	hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/arch-theme-switcher")
)

hl.bind(mod .. " + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

-- Window grouping
hl.bind(mod .. " + G", hl.dsp.group.toggle(), { description = "Toggle window group" })
hl.bind(mod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Move window out of group" })
hl.bind(mod .. " + ALT + left", hl.dsp.window.move({ into_group = "l" }), { description = "Move window into group (left)" })
hl.bind(mod .. " + ALT + right", hl.dsp.window.move({ into_group = "r" }), { description = "Move window into group (right)" })
hl.bind(mod .. " + ALT + up", hl.dsp.window.move({ into_group = "u" }), { description = "Move window into group (up)" })
hl.bind(mod .. " + ALT + down", hl.dsp.window.move({ into_group = "d" }), { description = "Move window into group (down)" })
hl.bind(mod .. " + ALT + TAB", hl.dsp.group.next(), { description = "Next window in group" })
hl.bind(mod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev(), { description = "Previous window in group" })
hl.bind(mod .. " + CTRL + left", hl.dsp.group.prev(), { description = "Focus previous in group" })
hl.bind(mod .. " + CTRL + right", hl.dsp.group.next(), { description = "Focus next in group" })
hl.bind(mod .. " + ALT + mouse_up", hl.dsp.group.prev(), { description = "Previous window in group" })
hl.bind(mod .. " + ALT + mouse_down", hl.dsp.group.next(), { description = "Next window in group" })
for idx = 1, 5 do
	hl.bind(
		mod .. " + ALT + " .. tostring(idx),
		hl.dsp.group.active({ index = idx }),
		{ description = "Switch to group window " .. idx }
	)
end

-- Workspace navigation (Omarchy-style)
hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
hl.bind(mod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
hl.bind(mod .. " + CTRL + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "Former workspace" })

-- Monitor navigation
hl.bind("CTRL + ALT + TAB", hl.dsp.focus({ monitor = "+1" }), { description = "Focus on next monitor" })
hl.bind("CTRL + SHIFT + ALT + TAB", hl.dsp.focus({ monitor = "-1" }), { description = "Focus on previous monitor" })

-- Layout / window helpers
hl.bind(mod .. " + L", hl.dsp.exec_cmd(scripts .. "/workspace-layout-toggle.sh"), { description = "Toggle workspace layout" })
hl.bind(mod .. " + O", hl.dsp.exec_cmd(scripts .. "/window-popout.sh"), { description = "Pop window out (float & pin)" })
hl.bind(mod .. " + Home", hl.dsp.exec_cmd(scripts .. "/window-size-save.sh restore"), { description = "Restore saved window size" })
hl.bind(mod .. " + ALT + Home", hl.dsp.exec_cmd(scripts .. "/window-size-save.sh save"), { description = "Save window size" })
hl.bind(mod .. " + BACKSPACE", hl.dsp.exec_cmd(scripts .. "/window-transparency-toggle.sh"), { description = "Toggle window transparency" })
hl.bind(mod .. " + SHIFT + BACKSPACE", hl.dsp.exec_cmd(scripts .. "/window-gaps-toggle.sh"), { description = "Toggle window gaps" })
hl.bind(mod .. " + SLASH", hl.dsp.exec_cmd(scripts .. "/monitor-scaling.sh up"), { description = "Monitor scaling up" })
hl.bind(mod .. " + ALT + SLASH", hl.dsp.exec_cmd(scripts .. "/monitor-scaling.sh down"), { description = "Monitor scaling down" })
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/window-close-all"), { locked = true, description = "Close all windows" })

hl.bind(mod .. " + CTRL + W", hl.dsp.exec_cmd("~/.config/waybar/scripts/wifi-menu.sh"))
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/waybar/scripts/power-menu.sh"))
hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("~/.config/waybar/scripts/power-menu.sh"), { description = "Power / logout menu" })
hl.bind(mod .. " + CTRL + B", hl.dsp.exec_cmd("~/.config/waybar/scripts/bluetooth-menu.sh"), { description = "Bluetooth menu" })
hl.bind(mod .. " + ALT + C", hl.dsp.exec_cmd(vars.HOME .. "/.config/waybar/scripts/control-center.sh"), { description = "Control center" })
hl.bind(mod .. " + CTRL + N", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/night-light-toggle"), { description = "Toggle nightlight" })
hl.bind(mod .. " + CTRL + I", hl.dsp.exec_cmd(scripts .. "/idle-toggle.sh"), { description = "Toggle idle lock" })
hl.bind(mod .. " + CTRL + E", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/menu-emoji"), { description = "Emojis" })
hl.bind(mod .. " + CTRL + Q", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/menu-calc"), { description = "Calculator" })
hl.bind("XF86Calculator", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/menu-calc"), { locked = true, description = "Calculator" })

-- Cursor zoom (persistent, like Omarchy)
hl.bind(mod .. " + CTRL + Z", function() local z = hl.get_config("cursor.zoom_factor") or 1; hl.config({ cursor = { zoom_factor = z + 1 } }) end, { description = "Zoom in" })
hl.bind(mod .. " + CTRL + ALT + Z", function() hl.config({ cursor = { zoom_factor = 1 } }) end, { description = "Reset zoom" })

-- Dictation (voxtype) — binds register automatically once installed
local voxtype_ok = (function()
	local p = io.popen("command -v voxtype 2>/dev/null")
	if not p then return false end
	local found = p:read("*l") ~= nil
	p:close()
	return found
end)()
if voxtype_ok then
	hl.bind(mod .. " + CTRL + X", hl.dsp.exec_cmd("voxtype record toggle"), { description = "Toggle dictation" })
	hl.bind("F9", hl.dsp.exec_cmd("voxtype record start"), { description = "Start dictation (push-to-talk)" })
	hl.bind("F9", hl.dsp.exec_cmd("voxtype record stop"), { release = true, description = "Stop dictation (push-to-talk)" })

	-- voxtype compositor integration (was conf.d/voxtype-submap.conf)
	-- F12 cancels/suppresses when voxtype switches to these submaps
	hl.define_submap("voxtype_recording", function()
		hl.bind("F12", hl.dsp.exec_cmd("voxtype record cancel"), { description = "Cancel dictation" })
		hl.bind("F12", hl.dsp.submap("reset"), { description = "Return to normal" })
	end)
	hl.define_submap("voxtype_suppress", function()
		hl.bind("F12", hl.dsp.submap("reset"), { description = "Emergency escape" })
		for _, mk in ipairs({ "SUPER_L", "SUPER_R", "Control_L", "Control_R", "Alt_L", "Alt_R", "Shift_L", "Shift_R" }) do
			hl.bind(mk, hl.dsp.exec_cmd("true"))
		end
	end)
end

hl.bind(mod .. " + ALT + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/waybar-selector.sh"))
hl.bind(mod .. " + ALT + SHIFT + W", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/webapp-install-prompt"), { description = "Install web app (paste link)" })
hl.bind(mod .. " + ALT + SHIFT + X", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/webapp-remove-prompt"), { description = "Remove web app" })
hl.bind(mod .. " + ALT + Q", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/wifi-share-prompt"), { description = "Share WiFi via QR" })

hl.bind(mod .. " + SHIFT + Space", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"), { locked = true })

hl.bind(mod .. " + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind(mod .. " + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })

-- Move focus (Vim-style)
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Swap windows with neighbors (Super + Shift + Arrow)
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "down" }))

-- Move active workspace to a monitor
hl.bind(mod .. " + SHIFT + ALT + left", hl.dsp.workspace.move({ monitor = "l" }), { description = "Move workspace to left monitor" })
hl.bind(mod .. " + SHIFT + ALT + right", hl.dsp.workspace.move({ monitor = "r" }), { description = "Move workspace to right monitor" })
hl.bind(mod .. " + SHIFT + ALT + up", hl.dsp.workspace.move({ monitor = "u" }), { description = "Move workspace to up monitor" })
hl.bind(mod .. " + SHIFT + ALT + down", hl.dsp.workspace.move({ monitor = "d" }), { description = "Move workspace to down monitor" })

-- ── Universal Copy / Paste / Cut / Select-All ──

hl.bind(
	mod .. " + A",
	hl.dsp.send_shortcut({
		mods = "CTRL",
		key = "A",
	})
)

-- Notifications (SwayNC) ---------------------------------------------------
hl.bind("SUPER + comma", hl.dsp.exec_cmd("swaync-client --close-latest"), { locked = true })
hl.bind("SUPER + SHIFT + comma", hl.dsp.exec_cmd("swaync-client --close-all"), { locked = true })
hl.bind("SUPER + CTRL + comma", hl.dsp.exec_cmd("swaync-client --toggle-dnd"), { locked = true, description = "Toggle notification silencing" })
hl.bind("SUPER + ALT + comma", hl.dsp.exec_cmd("swaync-client --toggle-panel"), { locked = true, description = "Notification center" })
hl.bind(
	"SUPER + SHIFT + ALT + comma",
	hl.dsp.exec_cmd(vars.HOME .. "/.config/hypr/scripts/notification-history.sh"),
	{ locked = true, description = "Notification history" }
)

-- Emoji picker & keybindings cheat sheet (rofi themes pull matugen colors)
hl.bind(mod .. " + period", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/menu-emoji"))
hl.bind(mod .. " + K", hl.dsp.exec_cmd(scripts .. "/keybinds-cheatsheet.sh"))

-- Switch workspaces (1–10; keys 1–9 and 0)
for i = 1, 10 do
	hl.bind(mod .. " + " .. tostring(i % 10), hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. tostring(i % 10), hl.dsp.window.move({ workspace = i }))
	hl.bind(
		mod .. " + SHIFT + ALT + " .. tostring(i % 10),
		hl.dsp.window.move({ workspace = i, follow = false })
	)
end

-- Scroll through workspaces (mouse wheel)
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mouse (was bindm)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume & brightness (media keys) — bindel/bindl → { repeating, locked }
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(scripts .. "/osd-volume.sh up"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(scripts .. "/osd-volume.sh down"),
	{ repeating = true, locked = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(scripts .. "/osd-volume.sh mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(scripts .. "/osd-volume.sh mic-toggle"), { locked = true, description = "Mute microphone" })
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd(scripts .. "/osd-brightness.sh up"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(scripts .. "/osd-brightness.sh down"),
	{ repeating = true, locked = true }
)
hl.bind("SHIFT + XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "/osd-brightness.sh max"), { locked = true, description = "Brightness maximum" })
hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/osd-brightness.sh min"), { locked = true, description = "Brightness minimum" })
hl.bind("ALT + XF86MonBrightnessUp", hl.dsp.exec_cmd(scripts .. "/osd-brightness.sh up"), { locked = true, repeating = true, description = "Brightness up (precise)" })
hl.bind("ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/osd-brightness.sh down"), { locked = true, repeating = true, description = "Brightness down (precise)" })

hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(scripts .. "/osd-volume.sh up"), { locked = true, repeating = true, description = "Volume up (precise)" })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd(scripts .. "/osd-volume.sh down"), { locked = true, repeating = true, description = "Volume down (precise)" })

-- Media controls (playerctl)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play / pause" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play / pause" })
hl.bind("ALT + XF86AudioPlay", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("ALT + SHIFT + XF86AudioPlay", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })

-- Keyboard backlight (brightnessctl kbd)
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(scripts .. "/osd-keyboard-brightness.sh up"), { locked = true, repeating = true, description = "Keyboard brightness up" })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(scripts .. "/osd-keyboard-brightness.sh down"), { locked = true, repeating = true, description = "Keyboard brightness down" })
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd(scripts .. "/osd-keyboard-brightness.sh cycle"), { locked = true, description = "Keyboard backlight cycle" })

-- Eject media / power
hl.bind("XF86Eject", hl.dsp.exec_cmd("eject"), { locked = true, description = "Eject media" })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("~/.config/waybar/scripts/power-menu.sh"), { locked = true, description = "Power menu" })

-- Touchpad toggles
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(scripts .. "/touchpad-toggle.sh toggle"), { locked = true, description = "Toggle touchpad" })
hl.bind("XF86TouchpadOn", hl.dsp.exec_cmd(scripts .. "/touchpad-toggle.sh on"), { locked = true, description = "Enable touchpad" })
hl.bind("XF86TouchpadOff", hl.dsp.exec_cmd(scripts .. "/touchpad-toggle.sh off"), { locked = true, description = "Disable touchpad" })

-- Lid switch (lock on close)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(scripts .. "/lid-close.sh"), { locked = true, description = "Lock on lid close" })

-- Screenshot (requires grim + slurp/wl-copy) — silent, clipboard + PNG file
hl.bind("Print", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/capture-region"), { description = "Screenshot" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/capture-satty"), { description = "Screenshot (region)" })
hl.bind(mod .. " + Print", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"), { description = "Color picker" })
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/capture-screen"), { description = "Capture entire screen" })
hl.bind("ALT + Print", hl.dsp.exec_cmd(scripts .. "/screen-record.sh"), { description = "Screenrecording" })
hl.bind("SUPER + CTRL + Print", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/ocr-extract"))

-- Clipboard history (cliphist)
hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd(vars.HOME .. "/.local/bin/menu-clipboard"))

-- ── Universal Clipboard (omarchy-style, terminal-aware) ─────────────
-- Send the chord with explicit mods straight to the focused surface, so the
-- physically held SUPER doesn't merge into the injected key at the seat
-- (which is what breaks plain wtype injection). The down/up split works around
-- Hyprland send_shortcut sometimes leaving synthetic key state stuck or
-- repeating (that's what caused trailing "v"s).
-- https://github.com/hyprwm/Hyprland/discussions/14099

local function send_shortcut_once(mods, key)
	return function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

		hl.timer(function()
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
		end, { timeout = 50, type = "oneshot" })
	end
end

local terminal_classes = {
	"kitty", "alacritty", "foot", "wezterm", "ghostty", "rio", "ptyxis",
	"konsole", "xfce4-terminal", "gnome-terminal", "gnome-console",
	"urxvt", "urxvtc", "xterm", "st",
}

local function active_window_is_terminal()
	local window = hl.get_active_window()
	if not window then
		return false
	end

	local tags = type(window.tags) == "table" and window.tags or { window.tags }
	for _, tag in ipairs(tags) do
		if tostring(tag):gsub("%*$", "") == "terminal" then
			return true
		end
	end

	for _, class in ipairs(terminal_classes) do
		if tostring(window.class or ""):lower() == class then
			return true
		end
	end

	return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
	return function()
		if active_window_is_terminal() then
			send_shortcut_once(terminal_mods, terminal_key)()
		else
			send_shortcut_once(default_mods, default_key)()
		end
	end
end

hl.bind("SUPER + C", universal_clipboard_shortcut("CTRL", "C", "CTRL", "Insert"), { description = "Universal copy" })
hl.bind("SUPER + V", universal_clipboard_shortcut("CTRL", "V", "SHIFT", "Insert"), { description = "Universal paste" })
hl.bind("SUPER + X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })
