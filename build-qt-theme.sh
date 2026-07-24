#!/bin/bash
# Generate Kvantum + KDE color files from colors.toml (no user-wide activation).

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

COLORS_FILE="$THEME_DIR/colors.toml"
KV_NAME="MidnightGlass"
QT_DIR="$THEME_DIR/qt"
GENERATED_KV="$QT_DIR/$KV_NAME"
BASE_KV="/usr/share/Kvantum/KvArcDark/KvArcDark.kvconfig"
BASE_SVG="/usr/share/Kvantum/KvArcDark/KvArcDark.svg"

[[ -f $COLORS_FILE ]] || {
  echo "Missing colors.toml: $COLORS_FILE" >&2
  exit 1
}

[[ -f $BASE_KV && -f $BASE_SVG ]] || {
  echo "Kvantum base theme KvArcDark not found (install kvantum-qt5)." >&2
  exit 1
}

mkdir -p "$GENERATED_KV"
ln -sfn "$BASE_SVG" "$GENERATED_KV/$KV_NAME.svg"

python3 "$MG_SCRIPTS/build_qt_theme.py" \
  "$COLORS_FILE" "$BASE_KV" \
  "$GENERATED_KV/$KV_NAME.kvconfig" "$GENERATED_KV/$KV_NAME.colors" "$KV_NAME"
