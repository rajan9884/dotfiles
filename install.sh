#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   install.sh — one-shot setup: minimal Arch → working Hyprland desktop.
#
#   Order matters (do NOT reorder):
#     0. Preflight: Arch check, root guard, sudo verification & keepalive.
#     1. Packages FIRST: bootstrap archlinux-keyring/git/base-devel, then yay,
#        then repo + AUR packages. Everything below assumes the tools exist.
#     2. Symlink every app config from <repo>/config/ into ~/.config/.
#     3. Symlink shell files (zshrc, bashrc, gitconfig, starship.toml).
#     4. Wire the active-theme symlink chain (default "Noro").
#     5. Install wallpaper collections (with offline asset fallback).
#     6. Symlink ~/.local/bin helpers, rofimoji theme, and systemd user units.
#     7. pactl shim (PipeWire-only machines, volume OSD backend).
#     8. Generate the matugen palette from the active theme's wallpaper.
#     9. Configure system & user services (audio, network, bluetooth, power,
#        groups, xdg-user-dirs, MIME types).
#    10. Verify EVERYTHING and fail loudly if anything is missing.
#
#   Safe to re-run: symlinks refresh, real files back up, packages skip
#   when already installed, verification just re-checks.
# ──────────────────────────────────────────────

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
ACTIVE_THEME="${ACTIVE_THEME:-Noro}"
THEME_LOWER="$(printf '%s' "$ACTIVE_THEME" | tr '[:upper:]' '[:lower:]')"

info()  { printf '  \033[1;32m==>\033[0m %s\n' "$*"; }
warn()  { printf '  \033[1;33m ->\033[0m %s\n' "$*"; }
fail()  { printf '  \033[1;31mXX\033[0m %s\n' "$*" >&2; }

# ── 0. Preflight: Root guard + Arch + sudo ───
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    fail "Do not run install.sh with sudo directly (run as your normal user; it will prompt for sudo when needed)."
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    fail "pacman not found — this installer targets Arch Linux (minimal install is fine)."
    exit 1
fi

# A dangling SUDO_ASKPASS makes every sudo call fail in non-interactive runs.
if [ -n "${SUDO_ASKPASS:-}" ] && [ ! -x "$SUDO_ASKPASS" ]; then
    warn "SUDO_ASKPASS=$SUDO_ASKPASS is not executable, unsetting it"
    unset SUDO_ASKPASS
fi

# Prompt once up front for sudo access and keep it alive in the background.
SUDO_OK=0
if sudo -n -v 2>/dev/null; then
    SUDO_OK=1
elif [ -t 0 ]; then
    if sudo -v; then
        SUDO_OK=1
    fi
fi
if [ "$SUDO_OK" -ne 1 ]; then
    fail "sudo authentication failed or unavailable — re-run with sudo access (packages + services need root)."
    exit 1
fi

# Keep sudo alive throughout installation
while true; do sudo -n true 2>/dev/null; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# Install packages in batch first for speed; fallback to one at a time if
# a single failure occurs (conflict, removed package, build error).
FAILED_PKGS=""
install_pkgs() {
    local installer="$1"; shift
    [ $# -eq 0 ] && return 0
    # Try installing all in batch first for speed
    # shellcheck disable=SC2086
    if $installer --noconfirm --needed "$@" 2>/dev/null; then
        info "installed $# packages"
        return 0
    fi
    # Fallback to individual package install if batch fails
    local pkg
    for pkg in "$@"; do
        [ -n "$pkg" ] || continue
        # shellcheck disable=SC2086
        if $installer --noconfirm --needed "$pkg"; then
            info "installed $pkg"
        else
            FAILED_PKGS="$FAILED_PKGS $pkg"
            warn "FAILED: $pkg (continuing with the rest)"
        fi
    done
}

pkglist_lines() {
    grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' "$1" | LC_ALL=C sort -u
}

# ── 1. Packages FIRST ────────────────────────
echo
echo "==> [1/10] Installing packages (bootstrap → repo → AUR)"
# Minimal Arch requires fresh keyrings and base build tools first
sudo pacman -Syu --noconfirm --needed archlinux-keyring git base-devel \
    && info "base tools ready (archlinux-keyring + git + base-devel)" \
    || { fail "pacman bootstrap failed — check mirrors/network, then re-run ./install.sh"; exit 1; }

# 1b. yay bootstrap
if ! command -v yay >/dev/null 2>&1; then
    info "bootstrapping yay AUR helper..."
    YAY_BUILD="$(mktemp -d)"
    if git clone https://aur.archlinux.org/yay-bin.git "$YAY_BUILD" >/dev/null 2>&1 \
        && (cd "$YAY_BUILD" && makepkg -si --noconfirm >/dev/null 2>&1); then
        info "yay bootstrapped successfully"
    else
        fail "yay bootstrap failed — check makepkg dependencies or network, then re-run ./install.sh"
        rm -rf "$YAY_BUILD"
        exit 1
    fi
    rm -rf "$YAY_BUILD"
else
    info "yay already present"
fi
command -v yay >/dev/null 2>&1 || { fail "yay still missing after bootstrap — aborting"; exit 1; }

# 1c. Repo packages (from pkglist/native.txt)
if [ -f "$REPO_ROOT/pkglist/native.txt" ]; then
    # shellcheck disable=SC2086
    MISSING="$(LC_ALL=C comm -23 <(pkglist_lines "$REPO_ROOT/pkglist/native.txt") <(pacman -Qq | LC_ALL=C sort) | tr '\n' ' ')"
    if [ -n "$MISSING" ]; then
        info "installing $(printf '%s' "$MISSING" | wc -w) missing repo packages"
        # shellcheck disable=SC2086
        install_pkgs "sudo pacman -S" $MISSING
    else
        info "all pkglist repo packages already installed"
    fi
else
    fail "pkglist/native.txt not found in repo — aborting"
    exit 1
fi

# 1d. AUR packages (from pkglist/foreign.txt)
if [ -f "$REPO_ROOT/pkglist/foreign.txt" ]; then
    # shellcheck disable=SC2086
    MISSING_AUR="$(LC_ALL=C comm -23 <(pkglist_lines "$REPO_ROOT/pkglist/foreign.txt") <(pacman -Qqm | LC_ALL=C sort) | tr '\n' ' ')"
    if [ -n "$MISSING_AUR" ]; then
        info "installing $(printf '%s' "$MISSING_AUR" | wc -w) missing AUR packages"
        # shellcheck disable=SC2086
        install_pkgs "yay -S" $MISSING_AUR
    else
        info "all pkglist AUR packages already installed"
    fi
else
    fail "pkglist/foreign.txt not found in repo — aborting"
    exit 1
fi

if [ -n "$FAILED_PKGS" ]; then
    fail "these packages need manual attention (conflict/build error):$FAILED_PKGS"
    # shellcheck disable=SC2086
    fail "retry with: yay -S --needed $FAILED_PKGS"
    fail "fix them, then re-run ./install.sh (it resumes where it left off)"
    exit 1
fi

# Update font cache so new fonts are immediately available
command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true

# ── 2. App configs → ~/.config ───────────────
link_config() {
    local name="$1"
    local src="$REPO_ROOT/config/$name"
    local dst="$HOME/.config/$name"

    [ -d "$src" ] || { warn "skip $name (not in repo)"; return; }
    mkdir -p "$HOME/.config"

    if [ -L "$dst" ]; then
        rm "$dst"                                   # refresh existing symlink
    elif [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/$name"
        warn "backed up existing $name -> $BACKUP_DIR/$name"
    fi
    ln -s "$src" "$dst"
    info "linked $name"
}

APPS=(
    hypr
    waybar
    rofi
    kitty
    btop
    matugen
    nvim
    swaync
    gtk-3.0
    gtk-4.0
)

GENERATED_APPS=(
    fastfetch
    ghostty
    helium-theme
    swaync
)

echo
echo "==> [2/10] Linking app configs into ~/.config"
for app in "${APPS[@]}"; do
    link_config "$app"
done

for app in "${GENERATED_APPS[@]}"; do
    mkdir -p "$HOME/.config/$app"
    info "prepared $app (config generated by matugen)"
done

# ── 3. Shell files → $HOME / ~/.config ───────
link_home() {
    local name="$1"
    local dotname=".$1"
    local src="$REPO_ROOT/shell/$name"
    local dst="$HOME/$dotname"

    [ -f "$src" ] || { warn "skip $name (not in repo)"; return; }

    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/$dotname"
        warn "backed up existing $dotname -> $BACKUP_DIR/$dotname"
    fi
    ln -s "$src" "$dst"
    info "linked $dotname"
}

link_config_file() {
    local name="$1"
    local dst="$HOME/.config/$2"
    local src="$REPO_ROOT/shell/$name"

    [ -f "$src" ] || { warn "skip $name (not in repo)"; return; }
    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        rm "$dst"
    elif [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
        warn "backed up existing $dst -> $BACKUP_DIR/"
    fi
    ln -s "$src" "$dst"
    info "linked $dst"
}

echo
echo "==> [3/10] Linking shell files"
link_home zshrc
link_home bashrc
link_home gitconfig
link_config_file starship.toml starship.toml

# ── 4. Active theme symlink chain ────────────
echo
echo "==> [4/10] Setting active theme: $ACTIVE_THEME"
HYPR_CFG="$HOME/.config/hypr"
WAYBAR_CFG="$HOME/.config/waybar"
ROFI_CFG="$HOME/.config/rofi"

if [ -f "$HYPR_CFG/themes/$THEME_LOWER/theme.conf" ]; then
    ln -sf "$HYPR_CFG/themes/$THEME_LOWER/theme.conf" "$HYPR_CFG/theme.conf"
    ln -sf "$HYPR_CFG/themes/$THEME_LOWER/theme.lua"  "$HYPR_CFG/theme.lua"
    ln -sf "$WAYBAR_CFG/themes/$THEME_LOWER/config.jsonc" "$WAYBAR_CFG/config.jsonc"
    ln -sf "$WAYBAR_CFG/themes/$THEME_LOWER/style.css"    "$WAYBAR_CFG/style.css"
    ln -sf "$ROFI_CFG/themes/$THEME_LOWER/launcher.rasi"  "$ROFI_CFG/active-launcher.rasi"
    ln -sf "$ROFI_CFG/themes/$THEME_LOWER/scripts.rasi"   "$ROFI_CFG/active-scripts.rasi"
    ln -sf "$ROFI_CFG/themes/$THEME_LOWER/picker.rasi"    "$ROFI_CFG/active-picker.rasi"
    printf '%s\n' "$ACTIVE_THEME" > "$HYPR_CFG/.active-theme"
    info "theme chain linked ($THEME_LOWER)"
else
    fail "theme '$ACTIVE_THEME' not found in $HYPR_CFG/themes — aborting (pick one of: $(ls "$HYPR_CFG/themes" | tr '\n' ' '))"
    exit 1
fi

# ── 5. Wallpapers → ~/.local/share/wallpapers ─
echo
echo "==> [5/10] Installing wallpaper collections"
WALL_SRC="${WALLPAPER_SOURCE:-$HOME/.local/share/wallpapers-upstream}"
WALL_REPO="https://github.com/rajan9884/wallpapers.git"
WALL_DST="$HOME/.local/share/wallpapers"
mkdir -p "$WALL_DST"

if [ -d "$WALL_SRC/.git" ]; then
    git -C "$WALL_SRC" pull --ff-only >/dev/null 2>&1 \
        && info "wallpaper repo updated" \
        || warn "wallpaper repo pull failed, using cached copy"
elif [ -e "$WALL_SRC" ]; then
    warn "wallpaper source exists but is not a git repo, using it as-is: $WALL_SRC"
else
    if git clone --depth 1 "$WALL_REPO" "$WALL_SRC" >/dev/null 2>&1; then
        info "wallpaper repo cloned"
    else
        warn "wallpaper repo clone failed (offline or network error), using bundled fallback"
    fi
fi

WALL_OK=1
for theme in glass material modern noro retro; do
    mkdir -p "$WALL_DST/$theme"
    if [ -d "$WALL_SRC/$theme" ] && [ -n "$(ls -A "$WALL_SRC/$theme" 2>/dev/null)" ]; then
        cp -p "$WALL_SRC/$theme"/* "$WALL_DST/$theme/" 2>/dev/null || true
        info "wallpapers: $theme ($(ls "$WALL_DST/$theme" | wc -l) files)"
    elif [ -f "$REPO_ROOT/assets/fallback-wallpaper.jpg" ]; then
        cp -p "$REPO_ROOT/assets/fallback-wallpaper.jpg" "$WALL_DST/$theme/nord-wallpaper.jpg"
        warn "seeded fallback wallpaper for $theme"
    else
        fail "wallpapers: '$theme' missing from $WALL_SRC"
        WALL_OK=0
    fi
done
[ "$WALL_OK" -eq 1 ] || { fail "wallpaper install incomplete — aborting"; exit 1; }

# ── 6. Helpers, rofimoji, systemd units ──────
echo
echo "==> [6/10] Linking user helper scripts into ~/.local/bin"
mkdir -p "$HOME/.local/bin"
find "$REPO_ROOT/config/hypr/scripts"   -type f -exec chmod +x {} \; 2>/dev/null || true
find "$REPO_ROOT/config/waybar/scripts" -type f -exec chmod +x {} \; 2>/dev/null || true
find "$REPO_ROOT/config/rofi/scripts"   -type f -exec chmod +x {} \; 2>/dev/null || true

for helper in "$REPO_ROOT/bin"/*; do
    [ -f "$helper" ] || continue
    chmod +x "$helper"
    ln -sf "$helper" "$HOME/.local/bin/$(basename "$helper")"
    info "helper: $(basename "$helper")"
done

# Wire rofimoji theme
mkdir -p "$HOME/.local/share/rofimoji/themes"
if [ -f "$REPO_ROOT/config/rofi/themes/emoji-grid.rasi" ]; then
    ln -sf "$HOME/.config/rofi/themes/emoji-grid.rasi" "$HOME/.local/share/rofimoji/themes/emoji-grid.rasi"
    info "rofimoji theme linked"
fi

# Deploy systemd user service units
mkdir -p "$HOME/.config/systemd/user"
for unit in waybar.service swayosd.service polkit-gnome.service \
            power-profiles-autoswitch.service power-profiles-autoswitch.path; do
    if [ -f "$REPO_ROOT/scripts/systemd/$unit" ]; then
        cp -p "$REPO_ROOT/scripts/systemd/$unit" "$HOME/.config/systemd/user/$unit"
        info "deployed user unit: $unit"
    fi
done
systemctl --user daemon-reload >/dev/null 2>&1 || true

# ── 7. pactl shim (PipeWire-only machines) ───
echo
echo "==> [7/10] Checking pactl (volume OSD backend)"
if command -v pactl >/dev/null 2>&1 && [ "$(command -v pactl)" != "$HOME/.local/bin/pactl" ]; then
    info "real pactl present, no shim needed"
else
    command -v wpctl >/dev/null 2>&1 || { fail "wpctl missing (wireplumber should have been installed in step 1) — re-run ./install.sh"; exit 1; }
    cat > "$HOME/.local/bin/pactl" <<'SHIM'
#!/usr/bin/env bash
# pactl shim (Arch/PipeWire) — installed by dotfiles/install.sh.
SINK="@DEFAULT_AUDIO_SINK@"
case "${1:-}" in
  set-sink-volume)
    case "${3:-}" in
      +*) wpctl set-volume "$SINK" "${3#+}+" ;;   # +5%  -> 5%+
      -*) wpctl set-volume "$SINK" "${3#-}-" ;;   # -5%  -> 5%-
      *)  pct="${3%%%}"
          awk -v p="$pct" 'BEGIN{ printf "%.2f", p/100 }' | xargs -I{} wpctl set-volume "$SINK" {} ;;
    esac ;;
  set-sink-mute) wpctl set-mute "$SINK" "${3:-toggle}" ;;
  get-sink-volume)
    wpctl get-volume "$SINK" | awk '{ printf "Volume: %d%%\n", $2*100 }' ;;
  get-sink-mute)
    if wpctl get-volume "$SINK" | grep -q MUTED; then echo "Mute: yes"; else echo "Mute: no"; fi ;;
  *) echo "pactl shim: unsupported args: $*" >&2; exit 1 ;;
esac
SHIM
    chmod +x "$HOME/.local/bin/pactl"
    info "pactl shim installed (~/.local/bin/pactl → wpctl)"
fi

# ── 8. Initial palette via matugen ───────────
echo
echo "==> [8/10] Generating initial color palette"
command -v matugen >/dev/null 2>&1 || { fail "matugen missing after step 1 — re-run ./install.sh"; exit 1; }
WALL="$(find "$WALL_DST/$THEME_LOWER" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | sort | head -n 1)"
[ -n "$WALL" ] || { fail "no wallpaper found for theme '$THEME_LOWER' in $WALL_DST/$THEME_LOWER"; exit 1; }
matugen image "$WALL" -c "$HOME/.config/matugen/config.toml" --source-color-index 0 \
    && info "palette generated from $WALL" \
    || { fail "matugen failed on $WALL — run it manually after first login"; exit 1; }

# ── 9. System & hardware configuration ────────
echo
echo "==> [9/10] Configuring system, audio, hardware groups and services"

# 9a. Standard XDG User directories
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update
    info "xdg user directories initialized"
fi
mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Pictures/Screenrecordings" "$HOME/Downloads" "$HOME/.cache"

# 9b. Hardware user groups for brightness and swayosd
sudo usermod -aG video,input "$USER" 2>/dev/null && info "added $USER to video and input groups" || true

# 9c. PipeWire user services
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service >/dev/null 2>&1 \
    && info "PipeWire audio services enabled" || true

# 9d. NetworkManager & Bluetooth system services
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable NetworkManager.service >/dev/null 2>&1 && info "NetworkManager enabled" || true
    sudo systemctl enable bluetooth.service >/dev/null 2>&1 && info "bluetooth service enabled" || true
    if command -v powerprofilesctl >/dev/null 2>&1; then
        sudo systemctl enable --now power-profiles-daemon.service >/dev/null 2>&1 && info "power-profiles-daemon active" || true
    fi
    if [ -f "$REPO_ROOT/scripts/systemd/powertop.service" ]; then
        sudo cp -p "$REPO_ROOT/scripts/systemd/powertop.service" /etc/systemd/system/powertop.service
        sudo systemctl daemon-reload
        sudo systemctl enable --now powertop >/dev/null 2>&1 && info "powertop autotune active" || warn "powertop skipped"
    fi
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw default deny incoming >/dev/null 2>&1 || true
        sudo ufw default allow outgoing >/dev/null 2>&1 || true
        sudo ufw --force enable >/dev/null 2>&1 && info "ufw active" || true
    fi
fi

# 9e. Enable power profiles autoswitch user path unit
systemctl --user enable --now power-profiles-autoswitch.path >/dev/null 2>&1 && info "power-profiles autoswitch active" || true

# 9f. Set default image viewer to imv
if [ -f "$HOME/.config/mimeapps.list" ]; then
    sed -i 's#=org\.gnome\.eog\.desktop#=imv.desktop#g; s#=eog\.desktop#=imv.desktop#g' "$HOME/.config/mimeapps.list"
    for m in image/jpeg image/png image/gif image/webp image/bmp image/x-ms-bmp image/tiff; do
        xdg-mime default imv.desktop "$m" 2>/dev/null || true
    done
    info "image MIME types set to imv.desktop"
fi

# ── 10. Verify EVERYTHING ────────────────────
echo
echo "==> [10/10] Verifying install"
PROBLEMS=0
need_cmd() {
    if command -v "$1" >/dev/null 2>&1; then
        info "ok: $1"
    else
        fail "MISSING: $1 ($2)"
        PROBLEMS=$((PROBLEMS + 1))
    fi
}
need_cmd hyprland "sudo pacman -S --needed hyprland"
need_cmd awww-daemon "sudo pacman -S --needed awww"
need_cmd matugen "sudo pacman -S --needed matugen"
need_cmd waybar "sudo pacman -S --needed waybar"
need_cmd rofi "sudo pacman -S --needed rofi"
need_cmd kitty "sudo pacman -S --needed kitty"
need_cmd starship "sudo pacman -S --needed starship"
need_cmd zsh "sudo pacman -S --needed zsh"
need_cmd nvim "sudo pacman -S --needed neovim"
need_cmd yay "bootstrap failed — see step 1"
if command -v pactl >/dev/null 2>&1 || [ -x "$HOME/.local/bin/pactl" ]; then
    info "ok: pactl (or ~/.local/bin/pactl shim)"
else
    fail "MISSING: pactl — real (pulseaudio, conflicts with pipewire-pulse!) or shim at ~/.local/bin/pactl"
    PROBLEMS=$((PROBLEMS + 1))
fi
need_cmd wpctl "sudo pacman -S --needed wireplumber"
need_cmd nm-applet "sudo pacman -S --needed network-manager-applet"
need_cmd swayosd-client "sudo pacman -S --needed swayosd"
need_cmd yazi "sudo pacman -S --needed yazi"
need_cmd fzf "sudo pacman -S --needed fzf"
need_cmd zoxide "sudo pacman -S --needed zoxide"
need_cmd atuin "sudo pacman -S --needed atuin"
need_cmd herdr "yay -S --needed herdr"
need_cmd gum "sudo pacman -S --needed gum"
need_cmd chromium "sudo pacman -S --needed chromium"
need_cmd fastfetch "sudo pacman -S --needed fastfetch"
need_cmd btop "sudo pacman -S --needed btop"

for theme in glass material modern noro retro; do
    if [ -n "$(ls -A "$WALL_DST/$theme" 2>/dev/null)" ]; then
        info "ok: wallpapers/$theme"
    else
        fail "EMPTY: $WALL_DST/$theme (re-run step 5 or set WALLPAPER_SOURCE)"
        PROBLEMS=$((PROBLEMS + 1))
    fi
done

for link in "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/rofi" \
            "$HOME/.config/kitty" "$HOME/.config/matugen" "$HOME/.zshrc" \
            "$HOME/.bashrc" "$HOME/.config/starship.toml" \
            "$HYPR_CFG/theme.conf" "$HYPR_CFG/theme.lua" \
            "$WAYBAR_CFG/config.jsonc" "$WAYBAR_CFG/style.css"; do
    if [ -e "$link" ] || [ -L "$link" ]; then
        info "ok: $link"
    else
        fail "MISSING LINK: $link (re-run ./install.sh)"
        PROBLEMS=$((PROBLEMS + 1))
    fi
done

# Matugen must have produced palettes
for gen in "$HOME/.config/waybar/colors.css" "$HOME/.config/kitty/colors.conf" \
           "$HOME/.config/rofi/colors.rasi" "$HOME/.config/hypr/colors.conf"; do
    if [ -s "$gen" ]; then
        info "ok: generated $gen"
    else
        fail "NOT GENERATED: $gen (run: matugen image <wallpaper> -c ~/.config/matugen/config.toml)"
        PROBLEMS=$((PROBLEMS + 1))
    fi
done

# Shells must at least parse
command -v bash >/dev/null 2>&1 && bash -n "$HOME/.bashrc" \
    && info "ok: bashrc parses" \
    || { fail "bashrc does not parse"; PROBLEMS=$((PROBLEMS + 1)); }
if command -v zsh >/dev/null 2>&1; then
    zsh -n "$HOME/.zshrc" && info "ok: zshrc parses" \
        || { fail "zshrc does not parse"; PROBLEMS=$((PROBLEMS + 1)); }
fi

echo
if [ "$PROBLEMS" -gt 0 ]; then
    fail "Done with $PROBLEMS problem(s) — fix them with the commands above, then re-run ./install.sh"
    exit 1
fi
echo "Done! The desktop is fully installed and configured."
echo "Log out and select Hyprland (or launch via uwsm / Hyprland) to begin."
if [ -d "$BACKUP_DIR" ]; then
    echo "Backups of replaced files are in: $BACKUP_DIR"
fi
exit 0
