#!/bin/bash
# Build unlock.png (Plymouth/SDDM logo) and preview-unlock.png (Walker menu preview)
# from unlock-source.png and the wallpaper-adapted colors.toml palette.

set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$THEME_DIR/unlock-source.png"
LOGO="$THEME_DIR/unlock.png"
PREVIEW="$THEME_DIR/preview-unlock.png"
COLORS="$THEME_DIR/colors.toml"
OMARCHY_PATH="${OMARCHY_PATH:-$HOME/.local/share/omarchy}"
PLYMOUTH="$OMARCHY_PATH/default/plymouth"

if [[ ! -f $SOURCE && -f $LOGO ]]; then
  cp "$LOGO" "$SOURCE"
fi

[[ -f $SOURCE && -f $COLORS && -d $PLYMOUTH ]] || exit 0

MAGICK_BIN=$(command -v magick || command -v convert || true)
[[ -n $MAGICK_BIN ]] || exit 0

read_color() {
  awk -F'"' -v key="$1" '$1 ~ "^" key " " { print $2; exit }' "$COLORS"
}

BG=$(read_color background)
FG=$(read_color foreground)
ACCENT=$(read_color accent)

[[ -n $BG && -n $FG && -n $ACCENT ]] || exit 0

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Recolor the master logo to the adaptive accent; drop the baked-in black backdrop.
"$MAGICK_BIN" "$SOURCE" -alpha on -fuzz 22% -transparent black \
  -channel RGB +level-colors "$ACCENT","$ACCENT" \
  "$LOGO"

for asset in bullet entry lock progress_bar progress_box; do
  "$MAGICK_BIN" "$PLYMOUTH/$asset.png" \
    -channel RGB +level-colors "$FG","$FG" \
    "$TMP/$asset.png"
done

LOGO_W=$("$MAGICK_BIN" "$LOGO" -format '%w' info:)
LOGO_H=$("$MAGICK_BIN" "$LOGO" -format '%h' info:)
LOGO_X=$(( (1920 - LOGO_W) / 2 ))
LOGO_Y=$(( 540 - LOGO_H / 2 - 80 ))

ENTRY_W=$("$MAGICK_BIN" "$TMP/entry.png" -format '%w' info:)
ENTRY_H=$("$MAGICK_BIN" "$TMP/entry.png" -format '%h' info:)
ENTRY_X=$(( (1920 - ENTRY_W) / 2 ))
ENTRY_Y=$(( LOGO_Y + LOGO_H + 40 ))

LOCK_H=$(( ENTRY_H * 80 / 100 ))
LOCK_W=$(( 84 * LOCK_H / 96 ))
"$MAGICK_BIN" "$TMP/lock.png" -resize "${LOCK_W}x${LOCK_H}" "$TMP/lock-scaled.png"
LOCK_X=$(( ENTRY_X - LOCK_W - 15 ))
LOCK_Y=$(( ENTRY_Y + (ENTRY_H - LOCK_H) / 2 ))

PB_W=$("$MAGICK_BIN" "$TMP/progress_bar.png" -format '%w' info:)
PB_H=$("$MAGICK_BIN" "$TMP/progress_bar.png" -format '%h' info:)
PB_X=$(( (1920 - PB_W) / 2 ))
PB_Y=$(( ENTRY_Y + ENTRY_H / 2 - PB_H / 2 ))
PB_FILL_W=$(( PB_W * 35 / 100 ))
[[ $PB_FILL_W -lt 1 ]] && PB_FILL_W=1
"$MAGICK_BIN" "$TMP/progress_bar.png" -crop "${PB_FILL_W}x${PB_H}+0+0" "$TMP/progress_bar-fill.png"

PROG_BOX_W=$("$MAGICK_BIN" "$TMP/progress_box.png" -format '%w' info:)
PROG_BOX_H=$("$MAGICK_BIN" "$TMP/progress_box.png" -format '%h' info:)
PROG_BOX_X=$(( (1920 - PROG_BOX_W) / 2 ))
PROG_BOX_Y=$(( ENTRY_Y + ENTRY_H / 2 - PROG_BOX_H / 2 ))

"$MAGICK_BIN" -size 1920x1080 "xc:$BG" \
  "$TMP/progress_box.png" -geometry +${PROG_BOX_X}+${PROG_BOX_Y} -composite \
  "$TMP/progress_bar-fill.png" -geometry +${PB_X}+${PB_Y} -composite \
  "$LOGO" -geometry +${LOGO_X}+${LOGO_Y} -composite \
  "$TMP/lock-scaled.png" -geometry +${LOCK_X}+${LOCK_Y} -composite \
  "$TMP/entry.png" -geometry +${ENTRY_X}+${ENTRY_Y} -composite \
  "$PREVIEW"

echo "Generated unlock assets: accent=$ACCENT"
