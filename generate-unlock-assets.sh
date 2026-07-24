#!/bin/bash
# Build unlock.png and preview-unlock.png from unlock-source.png + colors.toml.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

SOURCE="$THEME_DIR/unlock-source.png"
LOGO="$THEME_DIR/unlock.png"
PREVIEW="$THEME_DIR/preview-unlock.png"
COLORS="$THEME_DIR/colors.toml"
PLYMOUTH="$MG_OMARCHY_PATH/default/plymouth"

[[ ! -f $SOURCE && -f $LOGO ]] && cp "$LOGO" "$SOURCE"
[[ -f $SOURCE && -f $COLORS && -d $PLYMOUTH ]] || exit 0

MAGICK_BIN=$(mg_magick_bin)
[[ -n $MAGICK_BIN ]] || exit 0

BG=$(mg_read_color background "$COLORS")
FG=$(mg_read_color foreground "$COLORS")
ACCENT=$(mg_read_color accent "$COLORS")
[[ -n $BG && -n $FG && -n $ACCENT ]] || exit 0

UNLOCK_HASH="$THEME_DIR/.unlock-assets-hash"
HASH="${BG}|${FG}|${ACCENT}"
if [[ -f $UNLOCK_HASH ]] && [[ $HASH == "$(tr -d '[:space:]' <"$UNLOCK_HASH")" ]]; then
  exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

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

printf '%s\n' "$HASH" >"$UNLOCK_HASH"
echo "Generated unlock assets: accent=$ACCENT"
