#!/bin/bash
# Adapt Midnight Glass colors from the current Omarchy wallpaper.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

WALLPAPER=$(mg_wallpaper_path "${1:-}" || true)

if [[ -z $WALLPAPER || ! -f $WALLPAPER ]]; then
  echo "No wallpaper found. Pass an image path or set an Omarchy background." >&2
  exit 1
fi

MAGICK_BIN=$(mg_magick_bin)
[[ -n $MAGICK_BIN ]] || {
  echo "ImageMagick (magick/convert) is required." >&2
  exit 1
}

PALETTE_HASH="$THEME_DIR/.palette-hash"
BEFORE=$([[ -f $PALETTE_HASH ]] && tr -d '[:space:]' <"$PALETTE_HASH" || true)

mapfile -t HEXES < <(
  "$MAGICK_BIN" "$WALLPAPER" -resize 160x160 -colors 48 -unique-colors txt:- 2>/dev/null |
    grep -oE '#[0-9A-Fa-f]{6}' | tr 'a-f' 'A-F'
)

if (( ${#HEXES[@]} < 3 )); then
  echo "Could not extract a palette from: $WALLPAPER" >&2
  exit 1
fi

python3 "$MG_SCRIPTS/adapt_palette.py" "$WALLPAPER" "$THEME_DIR" "${HEXES[@]}"

AFTER=$([[ -f $PALETTE_HASH ]] && tr -d '[:space:]' <"$PALETTE_HASH" || true)
if [[ -n $BEFORE && $BEFORE == "$AFTER" ]]; then
  echo "Palette unchanged; skipping Qt build and unlock assets."
  exit 0
fi

"$THEME_DIR/build-qt-theme.sh"
"$THEME_DIR/generate-unlock-assets.sh" || true
