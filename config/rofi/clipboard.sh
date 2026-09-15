#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Clipboard manager backend for rofi script-mode.
# Left list + right preview, newest-first, max 50.
#
# Invoked by menu-clipboard as:
#   rofi -show clipboard -modi "clipboard:<this script>"
#
# Actions (rofi defaults only — no custom kb-* overrides):
#   Enter         paste entry (copy + Shift+Insert)
#   Ctrl+Enter    copy only
#   Shift+Delete  delete entry and keep menu open
#   Esc           close (clears filter first)
#   Type          live fuzzy filter
#
# Backend stays cliphist (already capturing via
# `wl-paste --watch cliphist store` in hypr autostart).
#
# Speed design: rofi re-runs this script on every keystroke
# while filtering, so the list pass must be instant (<100ms):
# rows print from `cliphist list` lines + cache-existence tests
# only — no decoding, no `file`, no magick in the hot path.
# Missing previews render in a detached background batch after
# the list prints (first open shows type icons; new entries
# gain previews on later opens). Preview PNGs are single-column
# 430px wide so they map ~1:1 onto the 470px preview widget —
# multi-column wide renders shrank to unreadable in it.
# ─────────────────────────────────────────────────────────────
set -u

LIMIT=50
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi/clipboard-images"
TEXT_ICON="text-x-generic"
IMAGE_ICON="image-x-generic"
PREVIEW_FILL='#dee4df'
PREVIEW_BG='#0f1512'
PREVIEW_POINTSIZE=15
# Preview canvas: content width + border ~= 470px preview widget.
PREVIEW_W=430
PREVIEW_H=400
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
# their MIME type (paste file vs text).
copy_out() { # $1=file
    local mime
    mime="$(file -b --mime-type -- "$1" 2>/dev/null || echo text/plain)"
    case "$mime" in
        image/*) wl-copy --type "$mime" < "$1" ;;
        *) wl-copy < "$1" ;;
    esac
}

# Auto-paste into the focused window after rofi exits, via
# `wtype Shift+Insert` history paste. Backgrounded with
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

# Render an entry's full text into a preview PNG (cached per id).
# Single column at preview-widget width: caption wraps + clips to
# the fixed canvas, so long entries show their head at readable
# size instead of shrinking. Font resolved via fontconfig —
# hardcoded /usr/share/fonts paths don't exist on Arch (fontconfig handles it).
render_text_preview() { # $1=id $2=decoded-text-file $3=font
    local out="$CACHE_DIR/pv-$1.png"
    [ -s "$out" ] && return 0
    local -a fontargs=()
    [ -n "${3:-}" ] && [ -f "$3" ] && fontargs=( -font "$3" )
    expand -t 4 -- "$2" 2>/dev/null | head -c 4000 |
        magick -limit thread 1 -background "$PREVIEW_BG" -fill "$PREVIEW_FILL" \
            "${fontargs[@]}" -pointsize "$PREVIEW_POINTSIZE" \
            -size "${PREVIEW_W}x${PREVIEW_H}" caption:@- \
            -bordercolor "$PREVIEW_BG" -border 20x16 \
            "png32:$out" 2>/dev/null
    [ -s "$out" ] || rm -f -- "$out"
}

# Background cache warmer: decodes + renders previews for entries
# missing them. Runs detached after the list prints; guarded by a
# lock so concurrent rofi keystroke-invocations don't pile up.
# One-time v2 migration: drops the old multi-column text-*.png
# renders (wrong size for the preview widget) and stale image
# markers, keeping the decoded entry-*.bin files.
warm_cache_bg() {
    local lock="$CACHE_DIR/.warm.lock"
    exec 9>"$lock" 2>/dev/null || return 0
    flock -n 9 2>/dev/null || return 0
    if [ ! -f "$CACHE_DIR/.v2" ]; then
        rm -f -- "$CACHE_DIR"/text-*.png "$CACHE_DIR"/is-image-*
        touch -- "$CACHE_DIR/.v2"
    fi
    local font line id preview dec mime size
    font="$(fc-match -f '%{file}\n' 'DejaVu Sans Mono' 2>/dev/null | head -n 1)"
    dec="$(mktemp -t clip-warm.XXXXXX)" || return 0
    local count=0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        id="${line%%$'\t'*}"
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        preview="${line#*$'\t'}"
        if [[ "$preview" == \[\[\ binary\ data* ]]; then
            if [ ! -s "$CACHE_DIR/entry-$id.bin" ]; then
                decode_entry "$id" "$dec" "$line" || continue
                [ -s "$dec" ] || continue
                mime="$(file -b --mime-type -- "$dec" 2>/dev/null || true)"
                case "$mime" in
                    image/*) cp -- "$dec" "$CACHE_DIR/entry-$id.bin"
                             touch -- "$CACHE_DIR/is-image-$id" ;;
                esac
            elif [ ! -f "$CACHE_DIR/is-image-$id" ]; then
                mime="$(file -b --mime-type -- "$CACHE_DIR/entry-$id.bin" 2>/dev/null || true)"
                case "$mime" in image/*) touch -- "$CACHE_DIR/is-image-$id" ;; esac
            fi
        else
            [ -s "$CACHE_DIR/pv-$id.png" ] || {
                decode_entry "$id" "$dec" "$line" || continue
                [ -s "$dec" ] || continue
                size="$(wc -c < "$dec")"
                [ "$size" -le 6000 ] || continue
                mime="$(file -b --mime-type -- "$dec" 2>/dev/null || true)"
                case "$mime" in
                    text/*|application/json|application/xml)
                        render_text_preview "$id" "$dec" "$font" ;;
                esac
            }
        fi
        count=$((count + 1))
        [ "$count" -ge "$LIMIT" ] && break
    done < <(cliphist list 2>/dev/null)
    rm -f -- "$dec"
}

# Print the pick list: newest $LIMIT entries, one row each.
# Hot path — cache-existence tests + shell builtins only, zero
# decoding and zero forks per row, so filter keystrokes stay
# instant. Rows print even when their preview isn't rendered yet;
# they just use the type icon until the background warmer catches
# up. Display is first-line-only with a length/line-count suffix
# (multi-line entries used to leak raw newlines into rows).
print_list() {
    # Rows stream to a temp file (they contain NUL separators, which
    # bash variables cannot hold) so the dynamic prompt with the
    # entry count can print first.
    local tmp line id preview first stripped display icon count=0 extra total_len
    tmp="$(mktemp -t clip-list.XXXXXX)" || return 0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        id="${line%%$'\t'*}"
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        preview="${line#*$'\t'}"
        preview="${preview//$'\t'/ }"
        if [[ "$preview" == \[\[\ binary\ data* ]]; then
            display="Image • ${preview#\[\[ binary data }"
            display="${display% \]\]}"
            if [ -s "$CACHE_DIR/entry-$id.bin" ] && [ -f "$CACHE_DIR/is-image-$id" ]; then
                icon="$CACHE_DIR/entry-$id.bin"
            else
                icon="$IMAGE_ICON"
            fi
        elif [[ "$preview" =~ ^(file://)?/[^$'\t']*\.(png|jpe?g|webp|gif|bmp|tiff?)$ ]] \
            && [ -f "${preview#file://}" ]; then
            # Single image file path (file-entry preview).
            display="File • ${preview##*/}"
            icon="${preview#file://}"
        else
            # First line only; collapse CRs; note truncation + extra lines.
            first="${preview%%$'\n'*}"
            first="${first//$'\r'/}"
            stripped="${preview//$'\n'/}"
            extra=$(( ${#preview} - ${#stripped} ))
            total_len=${#preview}
            display="${first:0:120}"
            [ "${#first}" -gt 120 ] && display+="…"
            [ "$extra" -gt 0 ] && display+="  ↵$((extra + 1)) lines"
            [ "$total_len" -gt 6000 ] && display+="  (${total_len} chars)"
            [ -z "${display// }" ] && continue
            if [ -s "$CACHE_DIR/pv-$id.png" ]; then
                icon="$CACHE_DIR/pv-$id.png"
            else
                icon="$TEXT_ICON"
            fi
        fi
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' "$display" "$icon" "$id" >> "$tmp"
        count=$((count + 1))
        [ "$count" -ge "$LIMIT" ] && break
    done < <(cliphist list 2>/dev/null)
    if [ "$count" -eq 0 ]; then
        rm -f -- "$tmp"
        printf 'Clipboard is empty\0nonselectable\x1ftrue\x1ficon\x1f%s\n' "$TEXT_ICON"
    else
        # Dynamic prompt with entry count (rofi script-mode directive).
        printf '\0prompt\x1fClipboard · %s\n' "$count"
        cat -- "$tmp"
        rm -f -- "$tmp"
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
            rm -f -- "$CACHE_DIR/entry-$ROFI_INFO.bin" \
                "$CACHE_DIR/pv-$ROFI_INFO.png" \
                "$CACHE_DIR/is-image-$ROFI_INFO"
        fi
        print_list
        ;;
    *) # Initial call (0) -> show list, warm missing previews.
        # $1 carries the filter text on keystroke re-invocations;
        # only the true initial open (empty $1) spawns the warmer.
        print_list
        if [ -z "${1:-}" ]; then
            ( warm_cache_bg ) >/dev/null 2>&1 </dev/null &
            disown 2>/dev/null || true
        fi
        ;;
esac
