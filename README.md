<img width="2880" height="1800" alt="preview3" src="https://github.com/user-attachments/assets/ea82c274-56d3-49ab-8373-4a60aae8f89d" />

---

# Arch + Hyprland Dotfiles

A dynamic, wallpaper-driven Hyprland setup for Arch Linux. Change your wallpaper and the
entire system re-themes itself — Waybar, Rofi, Kitty, Hyprland, GTK, Neovim, Zed, VS Code,
the browser, notifications, everything — through a Material You color pipeline built on
[matugen](https://github.com/InioX/matugen).

# Preview

https://github.com/user-attachments/assets/18fc7426-f8b7-4349-ae4f-4c4e70d48b56


## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Post-install](#post-install)
- [Repo structure](#repo-structure)
- [Keybinds](#keybinds)
- [Theming system](#theming-system)
- [Wallpapers](#wallpapers)
- [Changing defaults](#changing-defaults)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

## Overview

| Component    | Tool |
|--------------|------|
| OS           | Arch Linux (rolling) |
| Compositor   | Hyprland (Lua config, 0.55+) |
| Status bar   | Waybar (15 switchable styles) |
| Launcher     | Rofi (drun / run / window + menus) |
| Terminal     | Kitty |
| Notifications| Dunst |
| Shell        | Zsh + Oh My Zsh + autosuggestions |
| Editor       | Neovim (LazyVim) / Zed |
| Wallpaper    | awww + matugen |
| OSD          | SwayOSD |
| Idle/Lock    | hypridle + hyprlock |
| System monitor| btop / fastfetch |

The repo is written for a laptop profile (Intel i5-13500H, Iris Xe, 2880x1800@90, 2x scale).
`config/hypr/hyprland.lua` is modular — it just stitches together `.lua` modules
(`env`, `input`, `look`, `binds`, etc.), each isolated by `require()`. Monitors,
environment and defaults live in their own module and are easy to adjust.

## Features

- **True dynamic theming** — one keybind (Super+R) changes the wallpaper and regenerates a
  Material You palette that propagates to every app that supports colors, live.
- **5 full theme packs** (Noro, Material, Retro, Modern, Glass) — each defines Hyprland
  decoration, a Waybar style, matching Rofi menus and its own wallpaper collection.
  Switch the whole system look from one picker (Super+Ctrl+Shift+Space).
- **Horizontal thumbnail carousel** — the wallpaper picker (Super+Ctrl+Space) and theme
  switcher (Super+Ctrl+Shift+Space) open an instant, centered Rofi carousel of image
  thumbnails (`active-image-carousel.rasi`) that you scroll with the arrow keys.
- **Omarchy-style quality-of-life**: scratchpad, workspace cycling, window groups,
  per-window transparency/gaps toggles, saved window sizes, monitor scaling on the fly,
  cursor zoom, universal Super+C/V clipboard that works in terminals too.
- **Media keys done right** — volume/brightness through SwayOSD overlays, mic mute,
  precise 1% steps, playerctl media controls.
- **Screenshots & recording** — region snip to clipboard, annotate with satty, full-screen
  grab, color picker, OCR extract, wf-recorder capture with a Waybar indicator.
- **Dictation ready** — optional voxtype push-to-talk (F9) with Waybar status.
- **Idle automation** — screensaver at 150s, lock at 300s, lock-on-lid-close.

## Waybar Presets
- noro

  <img width="2880" height="106" alt="noro" src="https://github.com/user-attachments/assets/bb817d20-1630-49a7-9b38-54ba38fedafd" />

- bottom-dock

  <img width="2880" height="112" alt="bottom-dock" src="https://github.com/user-attachments/assets/3fea18eb-8af0-418e-a9e5-989e2831621f" />

- cyber-left

  <img width="108" height="1800" alt="cyber-left" src="https://github.com/user-attachments/assets/3d522af2-df9b-47a6-b6b7-8455cac55294" />

- dynamic-island

  <img width="2880" height="110" alt="dynamic-island" src="https://github.com/user-attachments/assets/f02fdf5d-da00-4039-9a2e-23037ea59bab" />

- floating-bar

  <img width="2880" height="102" alt="floating-bar" src="https://github.com/user-attachments/assets/c72a5be3-647e-452e-98fc-2d35abe6a4c9" />

- glass-left

  <img width="102" height="1800" alt="glass-left" src="https://github.com/user-attachments/assets/64984160-e824-4eed-9368-4755b58edafe" />

- glass-right

  <img width="142" height="1800" alt="glass-right" src="https://github.com/user-attachments/assets/656f6b5e-e2bb-48a6-be0e-3d209cc5bfaf" />

- gnome-left

  <img width="128" height="1800" alt="gnome-left" src="https://github.com/user-attachments/assets/1bbd50f4-ba47-46c0-a293-def8e9005296" />

- island

  <img width="2880" height="120" alt="island" src="https://github.com/user-attachments/assets/30fd44ea-6d69-470a-a828-723c38f71b65" />

- mac

  <img width="2880" height="88" alt="mac" src="https://github.com/user-attachments/assets/58679645-52c7-489f-a3b6-27938701337b" />

- minimal-left

  <img width="112" height="1800" alt="minimal-left" src="https://github.com/user-attachments/assets/a695d7a7-b6bf-41a5-a469-f9b31a1de38d" />

- modern-left

  <img width="100" height="1800" alt="modern-left" src="https://github.com/user-attachments/assets/17d74380-ad91-4b6c-8185-b8f54b26a585" />

- noro

  <img width="2880" height="106" alt="noro" src="https://github.com/user-attachments/assets/49d53a78-d1d2-4091-89f6-1054af181d89" />

- pill

  <img width="2880" height="110" alt="pill" src="https://github.com/user-attachments/assets/15c2fb5d-cfd2-48d5-92a0-980c82d3424a" />

---


## Screenshots

> Drop your captures here; they are referenced by the README.
>
> | File | Shows |
> |------|-------|
> | `screenshots/main.png` | Default Noro desktop with Waybar |
> | `screenshots/rofi.png` | Rofi app launcher |
> | `screenshots/themes.png` | Theme picker / all 5 themes |
> | `screenshots/terminal.png` | Kitty + fastfetch |
> | `screenshots/nvim.png` | Neovim (LazyVim, matugen colors) |
> | `screenshots/control-center.png` | macOS-style control center |
> | `screenshots/lock.png` | hyprlock screen |

## Requirements

### Base system

- A working Arch Linux install (any arch-based distro works, scripts assume `pacman`/`yay`)
- Hyprland 0.55+ (the config uses the new Lua API)

### Packages

Core (pacman):

```
hyprland hypridle hyprlock waybar rofi kitty dunst swayosd
awww matugen (matugen-bin on AUR) fastfetch btop
grim slurp wl-clipboard cliphist hyprpicker wf-recorder satty
brightnessctl pamixer playerctl networkmanager
polkit-gnome xdg-desktop-portal-hyprland
nautilus wiremix tmux fzf starship
```

Fonts and appearance:

```
ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-cjk noto-fonts-emoji
papirus-icon-theme bibata-cursor-theme (bibata-cursor-theme-bin on AUR)
adw-gtk3 flat-remix-gtk-theme (or your preferred dark GTK theme)
qt5ct
```

From AUR (yay):

```
yay -S matugen-bin bibata-cursor-theme-bin
```

Shell and editors:

```
yay -S zsh-autosuggestions
```

- **Oh My Zsh**: `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"` (install with "keep .zshrc" — the repo links its own)
- **Neovim**: `pacman -S neovim` (plugins bootstrap themselves on first run via lazy.nvim)
- **Zed**: install from [zed.dev](https://zed.dev) — the repo only ships settings + theme
- **dictation (optional)**: voxtype, adds F9 push-to-talk when present

### Optional extras the keybinds expect

- `arch-theme-switcher`, `arch-wallpaper-picker`, `arch-menu-images`, `arch-screensaver`,
  `power-profiles`, `menu-emoji`, `menu-calc`, `menu-clipboard`, `ocr-extract`,
  `night-light-toggle`, `capture-satty` — personal helper scripts. The `arch-*` picker
  helpers ship in this repo under `bin/` (deployed to `~/.local/bin` by `install.sh`);
  the rest live in `~/.local/bin` and everything degrades gracefully if a script is
  missing (binds that call them just won't do anything).
- `pywalfox` — live-recolored Firefox/Brave via the pywalfox extension
- `voxtype` — dictation (see keybinds)

## Installation

```bash
git clone https://github.com/rj9884/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The script:

1. Backs up any existing config dirs it replaces (into `~/.config-backup-<timestamp>`)
2. Symlinks every app config from `config/` into `~/.config/`
3. Symlinks shell files (`zshrc`, `bashrc`, `bash_profile`, `dircolors`, `gitconfig`) into `$HOME`
4. Wires the active-theme symlink chain (default theme: **Noro**)
5. Installs the wallpaper collections into `~/.local/share/wallpapers`
6. Runs matugen once so every app starts with the right palette

Re-running is safe: symlinks are refreshed, real files are backed up, nothing is deleted.

> Prefer a different default theme? `ACTIVE_THEME=Material ./install.sh`

## Post-install

1. Log out and log back in selecting the **Hyprland** session.
2. Press `Super+K` any time for a keybind cheatsheet.
3. First Neovim launch will install plugins (LazyVim extras: Go, Markdown, JSON).
4. Set your browser theme via the pywalfox extension if you use Firefox/Brave.

## Repo structure

```
dotfiles/
├── install.sh                  # one-shot setup (safe to re-run)
├── bin/
│   └── arch-*                   # wallpaper/theme pickers (rofi carousel) → ~/.local/bin
├── scripts/
│   └── build-wallpapers.sh     # regenerate the optimized wallpaper set
├── config/
│   ├── hypr/
│   │   ├── hyprland.lua        # entry: requires the modules below
│   │   ├── vars.lua            # shared command strings (terminal, browser, mod, ...)
│   │   ├── env.lua             # monitors + environment variables
│   │   ├── input.lua           # keyboard / mouse / touchpad
│   │   ├── autostart.lua       # startup applications
│   │   ├── look.lua            # animations, layouts, misc / render / debug
│   │   ├── binds.lua           # keybindings
│   │   ├── window-rules.lua    # window rules
│   │   ├── hypridle.conf       # idle: screensaver 150s, lock 300s
│   │   ├── hyprlock.conf       # lock screen (clock + date + input)
│   │   ├── scripts/            # 20 helper scripts (theming, windows, media)
│   │   └── themes/             # 5 theme packs (decoration + gaps per theme)
│   ├── waybar/
│   │   ├── modules.jsonc        # shared module definitions
│   │   ├── scripts/             # wifi/bt/power menus, recorder, updates...
│   │   └── themes/              # 15 bar styles
│   ├── rofi/
│   │   ├── config.rasi          # drun/run/window launcher
│   │   ├── theme.rasi           # dmenu-style picker (matugen colored)
│   │   ├── power-menu.rasi etc. # dashboard menus
│   │   └── themes/              # per-theme launcher/picker/scripts + active-image-carousel.rasi
│   ├── kitty/kitty.conf         # fonts, padding, clipboard passthrough
│   ├── matugen/
│   │   ├── config.toml           # which apps get generated colors
│   │   └── templates/            # 21 color templates (the theming engine)
│   ├── nvim/                     # LazyVim: options, keymaps, matugen colorscheme
│   ├── zed/settings.json
│   ├── btop/btop.conf
│   ├── swayosd/config.toml
│   └── gtk-3.0/ gtk-4.0/         # settings.ini (theme, icons, cursor)
├── shell/
│   ├── zshrc bashrc bash_profile
│   ├── dircolors                 # bright-cyan dirs on dark backgrounds
│   └── gitconfig                 # identity + defaults (no credentials)
└── wallpapers/                   # optimized per-theme collections (glass...retro)
```

## Keybinds

`Super` = the Windows/Command key.

### Essentials

| Bind | Action |
|------|--------|
| Super+Return | Kitty |
| Super+Space | Rofi launcher |
| Super+Shift+B | Browser (helium) |
| Super+Shift+Alt+B | Private browser window |
| Super+Shift+N | Editor (kitty + nvim) |
| Super+Alt+Return | Terminal with tmux |
| Super+Shift+F | File manager (nautilus) |
| Super+W | Close window (graceful) |
| Super+CTRL+L | Lock (hyprlock) |
| Super+Escape | Power menu |
| Super+K | Keybind cheatsheet |

### Theming

| Bind | Action |
|------|--------|
| Super+R | Random wallpaper (full re-theme) |
| Super+CTRL+Space | Wallpaper picker |
| Super+CTRL+SHIFT+Space | **Full theme switcher** (5 packs + wallpaper + waybar style) |
| Super+ALT+W | Waybar style selector (15 styles) |
| Super+period | Emoji picker |
| Super+CTRL+E | Emoji/symbol alt |
| Super+CTRL+Q | Calculator |

### Windows & workspaces

| Bind | Action |
|------|--------|
| Super+H/J/K/L or arrows | Focus (vim-style) |
| Super+Shift+arrows | Swap window |
| Super+T | Toggle float |
| Super+O | Pop out window (float + pin) |
| Super+F / Super+ALT+F | Fullscreen / maximized |
| Super+S | Toggle scratchpad |
| Super+ALT+S | Send to scratchpad |
| Super+G | Toggle group |
| Super+ALT+G | Move out of group |
| Super+ALT+arrows | Move into group |
| Super+J | Toggle split layout (dwindle/master) |
| Super+TAB / Super+Shift+TAB | Next / previous workspace |
| Super+1..0 | Workspace 1-10 |
| Super+Shift+1..0 | Move window to workspace |
| Super+Shift+Space | Cycle waybar visibility |
| Super+BACKSPACE | Toggle window transparency |
| Super+Shift+BACKSPACE | Toggle gaps |
| Super+Home | Restore saved window size |
| Super+ALT+Home | Save window size |
| Super+SLASH / Super+ALT+SLASH | Monitor scale up / down |
| Super+CTRL+Z / reset | Cursor zoom in / reset |

### Screenshots & media

| Bind | Action |
|------|--------|
| Print | Snip region to clipboard |
| Super+Shift+S | Snip + annotate (satty) |
| Super+Shift+Print | Full screen to clipboard |
| Super+Print | Color picker |
| ALT+Print | Screen recording toggle |
| Super+CTRL+Print | OCR extract |
| Super+CTRL+V | Clipboard history |
| XF86 keys | Volume/brightness (via SwayOSD) |
| Shift+XF86Brightness | Max / min brightness |
| ALT+XF86Brightness | Precise 1% steps |
| XF86AudioPlay/Next/Prev | Media controls |
| XF86AudioMicMute | Mic mute |
| XF86TouchpadToggle | Toggle touchpad |

### Notifications

| Bind | Action |
|------|--------|
| Super+comma | Close last notification |
| Super+Shift+comma | Close all |
| Super+CTRL+comma | Pause/resume |
| Super+ALT+comma | Replay last |
| Super+Shift+Alt+comma | History in Rofi |

### Universal clipboard

| Bind | Action |
|------|--------|
| Super+C / Super+V | Copy / paste (works in terminals) |
| Super+X | Cut |

### Dictation (voxtype, if installed)

| Bind | Action |
|------|--------|
| Super+CTRL+X | Toggle dictation |
| F9 (hold) | Push to talk |
| F12 | Cancel / escape submap |

## Theming system

The pipeline, in one line:

```
wallpaper -> awww (set) -> matugen (palette) -> 21 templates -> every app
```

1. **`swww-all.sh <image>`** is the entrypoint (used by every wallpaper script).
2. It sets the wallpaper with a "grow" transition from the cursor position.
3. It runs `matugen image <image> -c ~/.config/matugen/config.toml` which renders the
   21 templates in `config/matugen/templates/` into live config files:
   `~/.config/waybar/colors.css`, `~/.config/hypr/colors.lua`, `~/.config/kitty/colors.conf`,
   GTK css, `~/.config/dunst/dunstrc`, `~/.config/fastfetch/config.jsonc`,
   `~/.config/nvim/lua/matugen-colors.lua`, `~/.config/zed/themes/matugen.json`,
   `~/.config/ghostty/config.ghostty`, swayosd css, btop theme, VS Code colors, a
   Brave/Firefox browser theme, and more.
4. It then pokes each app to reload: `killall -SIGUSR2 waybar`, `killall -SIGUSR1 kitty`
   (and nvim), `hyprctl reload`, restart swayosd, refresh pywalfox.

Because the *generated* files live on disk but are gitignored, a fresh install boots with
the palette the install script generated — and any wallpaper change re-themes everything
in about a second.

### Theme packs vs bar styles

- A **theme pack** (`config/hypr/themes/<name>`) sets Hyprland decoration: rounding, blur,
  shadow, gaps, border colors, layout.
- A **bar style** (`config/waybar/themes/<name>`) is an independent Waybar layout
  (islands, docks, pills, mac-style, minimal...). The global theme switcher pairs each
  pack with a matching default bar style, but you can mix freely with Super+ALT+W.

## Wallpapers

- Live location: `~/.local/share/wallpapers/<theme>/` (XDG data dir — safe from home-dir
  cleanup; all scripts point here)
- Repo copy: `wallpapers/<theme>/` — deduplicated and compressed (105 MB to 54 MB) by
  `scripts/build-wallpapers.sh`
- To rebuild the repo set after adding wallpapers on your system:
  `./scripts/build-wallpapers.sh` (env overrides: `WALLPAPER_SOURCE`, `JPEG_QUALITY`)

## Changing defaults

| Want to change | Edit |
|----------------|------|
| Monitor, scale, refresh | `config/hypr/env.lua` — `hl.monitor(...)` |
| Terminal/browser/file manager | `config/hypr/vars.lua` — "shared command strings" |
| Default theme at install | `ACTIVE_THEME=Material ./install.sh` |
| Fonts | `config/kitty/kitty.conf`, `config/waybar/themes/*/style.css` |
| Idle timings | `config/hypr/hypridle.conf` |
| Which apps get themed | `config/matugen/config.toml` |
| Colors of a given app | matching template in `config/matugen/templates/` |

## Troubleshooting

- **Colors look stale after a wallpaper change** — run `matugen image <wallpaper>
  -c ~/.config/matugen/config.toml` manually and check for template errors.
- **Waybar didn't reload** — `killall -SIGUSR2 waybar` or just restart waybar.
- **Rofi shows default theme** — the `active-*.rasi` symlinks live in `~/.config/rofi/`;
  re-run the theme switcher or `./install.sh` to rebuild the chain.
- **GTK apps don't recolor** — GTK4 apps read css at launch; restart the app (nautilus is
  auto-restarted by the script when open).
- **Keys like XF86TouchpadToggle don't work** — check your laptop's Fn-lock; binds are on
  the raw XF86 symbols.
- **Everything is broken after install** — your old configs are in
  `~/.config-backup-<timestamp>`; restore and open an issue.

## Credits

- [Hyprland](https://hyprland.org) — the compositor
- [matugen](https://github.com/InioX/matugen) — Material You color generation
- [LazyVim](https://www.lazyvim.org) — Neovim distribution
- [Oh My Zsh](https://ohmyz.sh) + zsh-autosuggestions
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) icons,
- [Bibata](https://github.com/ful1e5/Bibata_Cursor) cursors

