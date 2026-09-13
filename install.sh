#!/usr/bin/env bash
# ──────────────────────────────────────────────
#   install.sh — one-shot setup: minimal Arch → working Hyprland desktop.
#
#   Order matters (do NOT reorder):
#     0. Preflight: Arch + sudo. Fatal without them — a half-installed
#        desktop is worse than a clear error.
#     1. Packages FIRST: bootstrap git/base-devel, then yay, then every
#        repo + AUR package from pkglist/. Everything below assumes the
#        tools exist (git for the wallpaper clone, matugen for palettes…).
#     2. Symlink every app config from <repo>/config/ into ~/.config/.
#     3. Symlink shell files (zshrc, bashrc, gitconfig, starship.toml).
#     4. Wire the active-theme symlink chain (default "Noro").
#     5. Clone the wallpaper repo, install per-theme sets into
#        ~/.local/share/wallpapers (where matugen + pickers point).
#     6. Install ~/.local/bin helpers + rofi/rofimoji extras.
#     7. pactl shim (PipeWire-only machines, see below).
#     8. Generate the matugen palette from the active theme's wallpaper.
#     9. Resilience services (ufw/cronie/powertop/timeshift) + imv MIME.
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

# ── 0. Preflight: Arch + sudo ────────────────
if ! command -v pacman >/dev/null 2>&1; then
    fail "pacman not found — this installer targets Arch Linux (minimal install is fine)."
    exit 1
fi
# A dangling SUDO_ASKPASS (e.g. left over from another dotfiles setup) makes
# every sudo call fail in non-interactive runs, so drop it if unusable.
if [ -n "${SUDO_ASKPASS:-}" ] && [ ! -x "$SUDO_ASKPASS" ]; then
    warn "SUDO_ASKPASS=$SUDO_ASKPASS is not executable, unsetting it"
    unset SUDO_ASKPASS
fi
# One-go install needs root for pacman/systemctl. Cache credentials once up
# front (prompts in a terminal); abort with a clear error otherwise instead
# of limping through a broken half-install.
SUDO_OK=0
if sudo -n -v 2>/dev/null; then
    SUDO_OK=1                                   # cached credentials / NOPASSWD
elif [ -t 0 ]; then
    if sudo -v; then                            # interactive: ask once up front
        SUDO_OK=1
    fi
fi
if [ "$SUDO_OK" -ne 1 ]; then
    fail "sudo authentication failed or unavailable — re-run with sudo access (packages + services need root)."
    exit 1
fi

# Install packages one at a time so a single failure (conflict, removed
# package, build error) never aborts the rest. Failed names are collected
# in FAILED_PKGS and reported at the end with an exact retry command.
FAILED_PKGS=""
install_pkgs() {
    local installer="$1"; shift
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
# Print the pkglist file as clean sorted LINES (no blanks/comments) —
# keep it line-based and in BYTE order (LC_ALL=C): comm compares bytes, and
# locale collation (en_US.UTF-8 ignores "-") would leave comm confused.
pkglist_lines() {
    grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#' "$1" | LC_ALL=C sort -u
}

# ── 1. Packages FIRST ────────────────────────
# Minimal Arch has almost nothing: no git (wallpaper clone needs it), no
# compiler (yay/makepkg needs it), no Hyprland at all. Install in layers:
#   1a. git + base-devel (clone + build tools for everything below)
#   1b. yay (AUR helper; every foreign.txt package needs it)
#   1c. all missing repo packages from pkglist/native.txt
#   1d. all missing AUR packages from pkglist/foreign.txt
echo
echo "==> [1/10] Installing packages (git/base-devel → yay → repo → AUR)"
sudo pacman -Syu --noconfirm --needed git base-devel \
    && info "base tools ready (git + base-devel)" \
    || { fail "pacman bootstrap failed — check mirrors/network, then re-run ./install.sh"; exit 1; }

# 1b. yay bootstrap: yay-bin is an AUR package, so it can't install itself.
# Build it once from the AUR; afterwards plain `yay -S` handles the rest
# (including yay-bin upgrades, harmless no-op via --needed).
if ! command -v yay >/dev/null 2>&1; then
    YAY_BUILD="$(mktemp -d)"
    if git clone https://aur.archlinux.org/yay-bin.git "$YAY_BUILD" >/dev/null 2>&1 \
        && (cd "$YAY_BUILD" && makepkg -si --noconfirm >/dev/null 2>&1); then
        info "yay bootstrapped"
    else
        fail "yay bootstrap failed — install it manually (git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si), then re-run ./install.sh"
        rm -rf "$YAY_BUILD"
        exit 1
    fi
    rm -rf "$YAY_BUILD"
else
    info "yay already present"
fi
command -v yay >/dev/null 2>&1 || { fail "yay still missing after bootstrap — aborting"; exit 1; }

# 1c. Repo packages: install only what's missing (comm against installed).
if [ -f "$REPO_ROOT/pkglist/native.txt" ]; then
    # shellcheck disable=SC2086
    MISSING="$(LC_ALL=C comm -23 <(pkglist_lines "$REPO_ROOT/pkglist/native.txt") <(pacman -Qq | LC_ALL=C sort) | tr '\n' ' ')"
    if [ -n "$MISSING" ]; then
        info "installing $(printf '%s' "$MISSING" | wc -w) missing repo packages (incl. hyprland + portals)"
        # shellcheck disable=SC2086
        install_pkgs "sudo pacman -S" $MISSING
    else
        info "all pkglist repo packages already installed"
    fi
else
    fail "pkglist/native.txt not found in repo — aborting (cannot know what to install)"
    exit 1
fi

# 1d. AUR packages: matugen-bin, waybar-git, herdr, fonts, cursor theme…
if [ -f "$REPO_ROOT/pkglist/foreign.txt" ]; then
    # shellcheck disable=SC2086
    MISSING_AUR="$(LC_ALL=C comm -23 <(pkglist_lines "$REPO_ROOT/pkglist/foreign.txt") <(pacman -Qqm | LC_ALL=C sort) | tr '\n' ' ')"
    if [ -n "$MISSING_AUR" ]; then
        info "installing $(printf '%s' "$MISSING_AUR" | wc -w) missing AUR packages (incl. matugen-bin, waybar-git)"
        # shellcheck disable=SC2086
        install_pkgs "yay -S" $MISSING_AUR
    else
        info "all pkglist AUR packages already installed"
    fi
else
    fail "pkglist/foreign.txt not found in repo — aborting (cannot know what to install)"
    exit 1
fi

if [ -n "$FAILED_PKGS" ]; then
    fail "these packages need manual attention (conflict/build error):$FAILED_PKGS"
    # shellcheck disable=SC2086
    fail "retry with: yay -S --needed $FAILED_PKGS"
    fail "fix them, then re-run ./install.sh (it resumes where it left off)"
    exit 1
fi

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

# App dirs versioned in this repo.
APPS=(
    hypr
    waybar
    rofi
    kitty
    btop
    matugen
    nvim
    zed
    swaync
    gtk-3.0
    gtk-4.0
)

# Apps whose only config is generated by matugen at runtime — just make sure
# the dir exists so the templates have somewhere to write.
# (swaync ships a versioned config.json; its style.css is matugen-generated.)
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

# Generated-only apps: ensure their ~/.config dirs exist (matugen writes here).
for app in "${GENERATED_APPS[@]}"; do
    mkdir -p "$HOME/.config/$app"
    info "prepared $app (config generated by matugen)"
done

# ── 3. Shell files → $HOME / ~/.config ───────
link_home() {
    local name="$1"                 # name inside repo shell/
    local dotname=".$1"             # name in $HOME
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
# Single file with a different destination: repo shell/<name> → ~/.config/<dst>.
link_config_file() {
    local name="$1"                 # name inside repo shell/
    local dst="$HOME/.config/$2"   # destination relative to ~/.config
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
# Wallpapers live in their own repo (keeps this one small). Clone it once,
# then copy only the per-theme collection dirs — the pickers scan one level
# deep, so extra top-level dirs (optimized/) must not leak in.
# matugen + swww-all.sh + the rofi pickers all read ~/.local/share/wallpapers.
echo
echo "==> [5/10] Installing wallpaper collections"
WALL_SRC="${WALLPAPER_SOURCE:-$HOME/.local/share/wallpapers-upstream}"
WALL_REPO="https://github.com/rajan9884/wallpapers.git"
if [ -d "$WALL_SRC/.git" ]; then
    git -C "$WALL_SRC" pull --ff-only >/dev/null 2>&1 \
        && info "wallpaper repo updated" \
        || warn "wallpaper repo pull failed, using cached copy"
elif [ -e "$WALL_SRC" ]; then
    warn "wallpaper source exists but is not a git repo, using it as-is: $WALL_SRC"
else
    git clone --depth 1 "$WALL_REPO" "$WALL_SRC" >/dev/null 2>&1 \
        && info "wallpaper repo cloned" \
        || { fail "wallpaper repo clone failed — check network, then re-run ./install.sh (or set WALLPAPER_SOURCE=/path/to/wallpapers)"; exit 1; }
fi
WALL_DST="$HOME/.local/share/wallpapers"
mkdir -p "$WALL_DST"
WALL_OK=1
for theme in glass material modern noro retro; do
    if [ -d "$WALL_SRC/$theme" ]; then
        mkdir -p "$WALL_DST/$theme"
        cp -p "$WALL_SRC/$theme"/* "$WALL_DST/$theme/" 2>/dev/null || true
        info "wallpapers: $theme ($(ls "$WALL_DST/$theme" | wc -l) files)"
    else
        fail "wallpapers: '$theme' missing from $WALL_SRC"
        WALL_OK=0
    fi
done
[ "$WALL_OK" -eq 1 ] || { fail "wallpaper install incomplete — aborting"; exit 1; }

# ── 6. Helpers → ~/.local/bin + rofi extras ──
echo
echo "==> [6/10] Installing user helper scripts into ~/.local/bin"
mkdir -p "$HOME/.local/bin"
find "$REPO_ROOT/config/hypr/scripts"  -type f -exec chmod +x {} \; 2>/dev/null || true
find "$REPO_ROOT/config/waybar/scripts" -type f -exec chmod +x {} \; 2>/dev/null || true
find "$REPO_ROOT/config/rofi/scripts"  -type f -exec chmod +x {} \; 2>/dev/null || true
for helper in "$REPO_ROOT/bin"/*; do
    [ -f "$helper" ] || continue
    cp -p "$helper" "$HOME/.local/bin/$(basename "$helper")"
    chmod +x "$HOME/.local/bin/$(basename "$helper")"
    info "helper: $(basename "$helper")"
done

echo
echo "==> Installing rofi image-carousel theme + rofimoji themes"
ROFI_SRC="$REPO_ROOT/config/rofi/themes/active-image-carousel.rasi"
ROFI_DST="$HOME/.config/rofi/themes/active-image-carousel.rasi"
mkdir -p "$HOME/.config/rofi/themes"
if [ -f "$ROFI_SRC" ]; then
    # rofi is symlinked to the repo, so the source may already BE the target —
    # cp would fail with "same file" and abort the whole install under set -e.
    if [ "$ROFI_SRC" -ef "$ROFI_DST" ]; then
        info "rofi image-carousel theme already in place (repo is symlinked)"
    else
        cp -p "$ROFI_SRC" "$ROFI_DST"
        info "rofi image-carousel theme installed"
    fi
else
    warn "rofi image-carousel theme not found in repo"
fi
ROFIMOJI_SRC="$REPO_ROOT/rofimoji/themes"
ROFIMOJI_DST="$HOME/.local/share/rofimoji/themes"
if [ -d "$ROFIMOJI_SRC" ]; then
    mkdir -p "$ROFIMOJI_DST"
    cp -p "$ROFIMOJI_SRC"/*.rasi "$ROFIMOJI_DST/" 2>/dev/null || true
    info "rofimoji themes installed ($(ls "$ROFIMOJI_DST"/*.rasi 2>/dev/null | wc -l) files)"
else
    warn "rofimoji themes not found in repo"
fi

# ── 7. pactl shim (PipeWire-only machines) ───
# config/hypr/scripts/osd-volume.sh drives volume via `pactl`. On Arch,
# pactl ships in the `pulseaudio` package, which CONFLICTS with
# pipewire-pulse — installing it would rip out PipeWire. So when no real
# pactl exists, drop a wpctl-backed shim (same verbs, same output shapes)
# into ~/.local/bin. Untouched when a real pactl is present (e.g. on systems
# where pulseaudio is installed instead of PipeWire).
echo
echo "==> [7/10] Checking pactl (volume OSD backend)"
if command -v pactl >/dev/null 2>&1 && [ "$(command -v pactl)" != "$HOME/.local/bin/pactl" ]; then
    info "real pactl present, no shim needed"
else
    command -v wpctl >/dev/null 2>&1 || { fail "wpctl missing (wireplumber should have been installed in step 1) — re-run ./install.sh"; exit 1; }
    cat > "$HOME/.local/bin/pactl" <<'SHIM'
#!/usr/bin/env bash
# pactl shim (Arch/PipeWire) — installed by dotfiles/install.sh.
# Real pactl lives in the `pulseaudio` package, which conflicts with
# pipewire-pulse, so this wpctl-backed shim covers exactly the verbs
# config/hypr/scripts/osd-volume.sh uses. If you ever install real
# pactl, delete this file.
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
# config/matugen/config.toml inputs point at ~/.config/matugen/templates/*
# (symlinked to the repo in step 2) and outputs at ~/.config/* — both ready.
echo
echo "==> [8/10] Generating initial color palette"
command -v matugen >/dev/null 2>&1 || { fail "matugen missing after step 1 — re-run ./install.sh"; exit 1; }
WALL="$(find "$WALL_DST/$THEME_LOWER" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | sort | head -n 1)"
[ -n "$WALL" ] || { fail "no wallpaper found for theme '$THEME_LOWER' in $WALL_DST/$THEME_LOWER"; exit 1; }
matugen image "$WALL" -c "$HOME/.config/matugen/config.toml" --source-color-index 0 \
    && info "palette generated from $WALL" \
    || { fail "matugen failed on $WALL — run it manually after first login"; exit 1; }

# ── 9. System resilience services ─────────────
echo
echo "==> [9/10] Enabling resilience services (ufw, cronie, powertop)"
sudo ufw default deny incoming >/dev/null 2>&1 || true
sudo ufw default allow outgoing >/dev/null 2>&1 || true
sudo ufw --force enable >/dev/null 2>&1 && info "ufw active" || warn "ufw enable skipped"
sudo systemctl enable --now cronie >/dev/null 2>&1 && info "cronie active" || warn "cronie skipped"
if [ -f "$REPO_ROOT/scripts/systemd/powertop.service" ]; then
    sudo cp -p "$REPO_ROOT/scripts/systemd/powertop.service" /etc/systemd/system/powertop.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now powertop >/dev/null 2>&1 && info "powertop autotune active" || warn "powertop skipped"
fi

# ── 9b. Default image viewer ─────────────────
echo
echo "==> Setting default image viewer (imv)"
if [ -f "$HOME/.config/mimeapps.list" ]; then
    sed -i 's#=org\.gnome\.eog\.desktop#=imv.desktop#g; s#=eog\.desktop#=imv.desktop#g' "$HOME/.config/mimeapps.list"
    for m in image/jpeg image/png image/gif image/webp image/bmp image/x-ms-bmp image/tiff; do
        xdg-mime default imv.desktop "$m" 2>/dev/null || true
    done
    info "image MIME types set to imv.desktop"
else
    warn "~/.config/mimeapps.list not found; image MIME defaults unchanged"
fi

# ── 1b/1c bookkeeping: refresh pkglist + timeshift ──
if ! pacman -Q timeshift >/dev/null 2>&1; then
    sudo pacman -S --noconfirm --needed timeshift || warn "timeshift install skipped (ext4 snapshots need it)"
fi
mkdir -p "$REPO_ROOT/pkglist"
pacman -Qqen | LC_ALL=C sort -u > "$REPO_ROOT/pkglist/native.txt"
pacman -Qqem | LC_ALL=C sort -u > "$REPO_ROOT/pkglist/foreign.txt"
info "package lists refreshed (commit them to keep the backup current)"

# ── 10. Verify EVERYTHING ────────────────────
# One-go means proven, not hoped. Any failure below exits nonzero with the
# exact fix — no silent half-working desktop.
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
need_cmd matugen "yay -S --needed matugen-bin"
need_cmd waybar "yay -S --needed waybar-git"
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

# Matugen must have produced palettes (waybar colors land here; empty = broken theme).
for gen in "$HOME/.config/waybar/colors.css" "$HOME/.config/kitty/colors.conf" \
           "$HOME/.config/rofi/colors.rasi" "$HOME/.config/hypr/colors.conf"; do
    if [ -s "$gen" ]; then
        info "ok: generated $gen"
    else
        fail "NOT GENERATED: $gen (run: matugen image <wallpaper> -c ~/.config/matugen/config.toml)"
        PROBLEMS=$((PROBLEMS + 1))
    fi
done

# Shells must at least parse (guards against a bad edit breaking every terminal).
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
echo "Done. Log out and select Hyprland at the greeter to use the new setup."
if [ -d "$BACKUP_DIR" ]; then
    echo "Backups of replaced files are in: $BACKUP_DIR"
fi
exit 0
