#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Clipboard manager backend for rofi script-mode.
# Mirrors Omarchy's clipboard menu (omarchy.clipboard) without
# quickshell: left list + right preview, newest-first, max 50.
#
# Invoked by menu-clipboard as:
#   rofi -show clipboard -modi "clipboard:<this script>"
#
# Actions (rofi defaults only — no custom kb-* overrides):
#   Enter         paste entry  (Omarchy Enter: copy + Shift+Insert)
#   Ctrl+Enter    copy only    (Omarchy Shift+Enter)
#   Shift+Delete  delete entry and keep menu open (Omarchy Delete)
#   Esc           close (clears filter first, like Omarchy)
#   Type          live fuzzy filter (Omarchy setFilter)
#
# Backend stays cliphist (already capturing via
# `wl-paste --watch cliphist store` in hypr autostart).
# ─────────────────────────────────────────────────────────────
set -u

LIMIT=50
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi/clipboard-images"
TEXT_ICON="text-x-generic"
IMAGE_ICON="image-x-generic"
# Readable mono face for text previews (magick's default serif is
# thin/italic at small sizes; JetBrains Mono drops glyphs under
# pango/caption ligation). Absolute TTF path skips fontconfig
# name lookups; falls back to magick default if absent.
PREVIEW_FONT="/usr/share/fonts/TTF/DejaVuSansMono.ttf"
PREVIEW_FILL='#dee4df'
PREVIEW_BG='#0f1512'
PREVIEW_POINTSIZE=15
mkdir -p "$CACHE_DIR"

# Full `cliphist list` line for a numeric id (empty if gone).
entry_line() {
    cliphist list 2>/dev/null | grep -m1 "^$1"$'\t' || true
}

# Decode a history entry to a file so images survive (no NUL
# truncation in shell vars). Falls back to piping the list line
# when the bare id decode fails.
decode_entry() { # $1=id $2=outfile [$3=list line]
    if cliphist decode "$1" > "$2" 2>/dev/null; then
        return 0
    fi
    local line="${3:-$(entry_line "$1")}"
    [ -n "$line" ] || return 1
    printf '%s' "$line" | cliphist decode > "$2" 2>/dev/null
}

# Copy a decoded file to the Wayland clipboard, images with
# their MIME type (mirrors omarchy-clipboard-paste-file/text).
copy_out() { # $1=file
    local mime
    mime="$(file -b --mime-type -- "$1" 2>/dev/null || echo text/plain)"
    case "$mime" in
        image/*) wl-copy --type "$mime" < "$1" ;;
        *) wl-copy < "$1" ;;
    esac
}

# Auto-paste into the focused window after rofi exits, like
# Omarchy's `wtype Shift+Insert` history paste. Backgrounded with
# stdio detached so rofi never blocks waiting on our pipe.
auto_paste() {
    ( sleep 0.25; wtype -M shift -k Insert -m shift ) >/dev/null 2>&1 </dev/null &
}

# Paste action: copy entry, close menu (no output), paste.
do_paste() { # $1=id
    local tmp
    tmp="$(mktemp -t clip-pick.XXXXXX)" || exit 0
    if decode_entry "$1" "$tmp"; then
        copy_out "$tmp"
        auto_paste
    fi
    rm -f -- "$tmp"
    exit 0 # no entries printed -> rofi quits
}

# Copy-only action: copy entry, close menu, no auto-paste.
do_copy() { # $1=id (empty = raw typed text)
    if [ -n "$1" ]; then
        local tmp
        tmp="$(mktemp -t clip-pick.XXXXXX)" || exit 0
        decode_entry "$1" "$tmp" && copy_out "$tmp"
        rm -f -- "$tmp"
    else
        printf '%s' "${1:-$TYPED}" | wl-copy
    fi
    exit 0
}

# Cached image file for a history id. Decodes once per id; the
# wipe menu clears this dir (ids can be reused after a wipe).
image_file() { # $1=id $2=list line -> path (empty on failure)
    local cached="$CACHE_DIR/entry-$1.bin"
    if [ ! -s "$cached" ]; then
        decode_entry "$1" "$cached" "$2" || { rm -f -- "$cached"; return 1; }
        [ -s "$cached" ] || { rm -f -- "$cached"; return 1; }
    fi
    local mime
    mime="$(file -b --mime-type -- "$cached" 2>/dev/null || true)"
    case "$mime" in
        image/*) printf '%s' "$cached" ;;
        *) return 1 ;;
    esac
}

# Render an entry's full text into a preview PNG (cached per id).
# The right-half icon-current-entry widget can only show images,
# so text rows get their entire contents rasterized here — what
# you see on the right is the full entry, not just a type icon.
# ~0.25s each (pango layout), so callers batch these in parallel
# and a login pre-warm keeps interactive opens at cache speed.
# Flow decoded text into 1-3 newspaper columns for the preview
# PNG. Tall single-column images shrink to fit the preview
# height and render tiny; columns trade height for width so the
# text actually uses the panel. Tabs expanded first (fold counts
# them as one char but they render wide); pr page length raised
# so long entries aren't split by formfeeds. Gutter is U+2502 —
# plain spaces would collapse under caption:.
columnize() { # $1=decfile $2=cols $3=outfile
    case "$2" in
        3) expand -t 4 -- "$1" | fold -s -w 48 | pr -t -l 10000 -3 -w 150 -S' │ ' > "$3" ;;
        2) expand -t 4 -- "$1" | fold -s -w 48 | pr -t -l 10000 -2 -w 99 -S' │ ' > "$3" ;;
        *) head -c 2000 -- "$1" > "$3" ;;
    esac
}

# Column count + caption width for a decoded text file: single
# column up to ~40 folded lines, two up to ~110, three beyond.
preview_layout() { # $1=decfile -> "cols:size"
    local lines
    lines="$(expand -t 4 -- "$1" | fold -s -w 48 | wc -l)"
    if [ "$lines" -gt 110 ]; then
        printf '3:1360x'
    elif [ "$lines" -gt 40 ]; then
        printf '2:930x'
    else
        printf '1:470x'
    fi
}

render_text_preview() { # $1=id $2=decoded-text-file $3=cols $4=size
    local out="$CACHE_DIR/text-$1.png"
    [ -s "$out" ] && return 0
    local colfile="$tmpdir/col-$1"
    columnize "$2" "$3" "$colfile"
    [ -s "$colfile" ] || return 1
    local -a fontargs=()
    [ -f "$PREVIEW_FONT" ] && fontargs=( -font "$PREVIEW_FONT" )
    # Solid panel background (not transparent) so the preview
    # blends instead of floating like a screenshot, plus a
    # padded border so text never touches the left edge.
    magick -limit thread 1 -background "$PREVIEW_BG" -fill "$PREVIEW_FILL" \
        "${fontargs[@]}" -pointsize "$PREVIEW_POINTSIZE" \
        -size "$4" caption:@"$colfile" \
        -bordercolor "$PREVIEW_BG" -border 22x18 \
        "png32:$out" 2>/dev/null
    [ -s "$out" ] || rm -f -- "$out"
}

# Print the pick list: newest $LIMIT entries, one row each.
# Row info carries the cliphist id (never shown/searched).
# Two passes: gather + decode (fast), then parallel-render any
# missing text previews, then print rows with final icons.
print_list() {
    local line id preview display icon path count=0
    local -a ids=() displays=() icons=()
    local tmpdir
    tmpdir="$(mktemp -d -t clip-list.XXXXXX)" || return 0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        id="${line%%$'\t'*}"
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        preview="${line#*$'\t'}"
        preview="${preview//$'\t'/ }"
        if [[ "$preview" == \[\[\ binary\ data* ]]; then
            display="Image • ${preview#\[\[ binary data }"
            display="${display% \]\]}"
            if path="$(image_file "$id" "$line")"; then
                icon="$path"
            else
                icon="$IMAGE_ICON"
            fi
        elif [[ "$preview" =~ ^(file://)?/[^$'\t']*\.(png|jpe?g|webp|gif|bmp|tiff?)$ ]] \
            && [ -f "${preview#file://}" ]; then
            # Single image file path (Omarchy file-entry preview).
            display="${preview##*/}"
            icon="${preview#file://}"
        else
            display="${preview:0:140}"
            [ -z "${display// }" ] && continue
            # Full contents -> preview PNG (decoded once, rendered
            # in the parallel batch below). Rows print even if the
            # render fails; they just fall back to the type icon.
            icon="$TEXT_ICON"
            if decode_entry "$id" "$tmpdir/dec-$id" "$line" \
                && [ -s "$tmpdir/dec-$id" ] \
                && [ "$(wc -c < "$tmpdir/dec-$id")" -le 6000 ]; then
                local decmime layout
                decmime="$(file -b --mime-type -- "$tmpdir/dec-$id" 2>/dev/null || true)"
                case "$decmime" in
                    text/*|application/json|application/xml)
                        layout="$(preview_layout "$tmpdir/dec-$id")"
                        icon="TEXT:$id:$layout" ;;
                esac
            fi
        fi
        ids+=("$id")
        displays+=("$display")
        icons+=("$icon")
        count=$((count + 1))
        [ "$count" -ge "$LIMIT" ] && break
    done < <(cliphist list 2>/dev/null)
    # Batch-render missing text previews, 16 magick jobs at a time.
    # Cached per id (ids are immutable), so steady-state opens
    # only render brand-new entries.
    local i running=0 rest cols size
    for i in "${!icons[@]}"; do
        if [[ "${icons[$i]}" == TEXT:* ]]; then
            rest="${icons[$i]#TEXT:}"
            id="${rest%%:*}"
            rest="${rest#*:}"
            cols="${rest%%:*}"
            size="${rest#*:}"
            if [ ! -s "$CACHE_DIR/text-$id.png" ]; then
                render_text_preview "$id" "$tmpdir/dec-$id" "$cols" "$size" &
                running=$((running + 1))
                if [ "$running" -ge 16 ]; then
                    wait -n 2>/dev/null || wait
                    running=$((running - 1))
                fi
            fi
        fi
    done
    wait 2>/dev/null
    rm -rf -- "$tmpdir"
    for i in "${!ids[@]}"; do
        icon="${icons[$i]}"
        if [[ "$icon" == TEXT:* ]]; then
            id="${icon#TEXT:}"
            id="${id%%:*}"
            if [ -s "$CACHE_DIR/text-$id.png" ]; then
                icon="$CACHE_DIR/text-$id.png"
            else
                icon="$TEXT_ICON"
            fi
        fi
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' "${displays[$i]}" "$icon" "${ids[$i]}"
    done
    if [ "$count" -eq 0 ]; then
        printf 'Clipboard is empty\0nonselectable\x1ftrue\x1ficon\x1f%s\n' "$TEXT_ICON"
    fi
}

case "${ROFI_RETV:-0}" in
    1) # Enter on a row -> paste (plain Enter always carries info).
        do_paste "${ROFI_INFO:-}"
        ;;
    2) # Ctrl+Enter custom entry -> copy only.
        if [ -n "${ROFI_INFO:-}" ]; then
            do_copy "$ROFI_INFO"
        else
            TYPED="${1:-}"
            do_copy ""
        fi
        ;;
    3) # Shift+Delete on a row -> delete, keep menu open.
        if [ -n "${ROFI_INFO:-}" ]; then
            line="$(entry_line "$ROFI_INFO")"
            [ -n "$line" ] && printf '%s' "$line" | cliphist delete 2>/dev/null
            rm -f -- "$CACHE_DIR/entry-$ROFI_INFO.bin" "$CACHE_DIR/text-$ROFI_INFO.png"
        fi
        print_list
        ;;
    *) # Initial call (0) -> show list.
        print_list
        ;;
esac
