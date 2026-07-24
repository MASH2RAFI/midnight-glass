#!/bin/bash
# Reversible Midnight Glass Qt/KDE (Dolphin) theme swap.
#
# Generated Kvantum + KDE color files live under this theme folder. User-wide
# Qt settings are backed up once and restored when leaving Midnight Glass.
#
#   ./manage-qt-theme.sh activate
#   ./manage-qt-theme.sh deactivate

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
KV_NAME="MidnightGlass"
QT_DIR="$THEME_DIR/qt"
GENERATED_KV="$QT_DIR/$KV_NAME"
KV_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/kvantum.kvconfig"
USER_KV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/$KV_NAME"
SCHEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/color-schemes"
SCHEME_FILE="$SCHEME_DIR/$KV_NAME.colors"
MARKER="$THEME_DIR/.qt-swap-active"
KV_ROOT_BACKUP="$QT_DIR/kvantum.kvconfig.user-backup"
SCHEME_BACKUP="$QT_DIR/kdeglobals.colorscheme.user-backup"

activate() {
  if [[ ! -f $GENERATED_KV/$KV_NAME.kvconfig || ! -f $GENERATED_KV/$KV_NAME.colors ]]; then
    echo "Missing generated Qt theme in $GENERATED_KV" >&2
    echo "Run: $THEME_DIR/apply-qt-theme.sh" >&2
    exit 1
  fi

  mkdir -p "$QT_DIR" "$USER_KV_DIR" "$SCHEME_DIR"

  if [[ ! -f $MARKER ]]; then
    [[ -f $KV_ROOT ]] && cp -a "$KV_ROOT" "$KV_ROOT_BACKUP"
    if command -v kreadconfig5 >/dev/null; then
      kreadconfig5 --file kdeglobals --group General --key ColorScheme >"$SCHEME_BACKUP" 2>/dev/null || true
    fi
    : >"$MARKER"
  fi

  ln -sfn "$(readlink -f "$GENERATED_KV/$KV_NAME.svg")" "$USER_KV_DIR/$KV_NAME.svg"
  cp "$GENERATED_KV/$KV_NAME.kvconfig" "$USER_KV_DIR/$KV_NAME.kvconfig"
  cp "$GENERATED_KV/$KV_NAME.colors" "$SCHEME_FILE"

  cat >"$KV_ROOT" <<EOF
[General]
theme=$KV_NAME
EOF

  if command -v kwriteconfig5 >/dev/null; then
    kwriteconfig5 --file kdeglobals --group General --key ColorScheme "$KV_NAME"
  fi

  if command -v kbuildsycoca5 >/dev/null; then
    kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
  fi
}

deactivate() {
  if [[ ! -f $MARKER ]]; then
    return 0
  fi

  if [[ -f $KV_ROOT_BACKUP ]]; then
    cp -a "$KV_ROOT_BACKUP" "$KV_ROOT"
  fi

  if [[ -f $SCHEME_BACKUP ]] && command -v kwriteconfig5 >/dev/null; then
    PREV_SCHEME=$(tr -d '\n' <"$SCHEME_BACKUP")
    if [[ -n $PREV_SCHEME ]]; then
      kwriteconfig5 --file kdeglobals --group General --key ColorScheme "$PREV_SCHEME"
    fi
  fi

  if command -v kbuildsycoca5 >/dev/null; then
    kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
  fi

  rm -f "$MARKER"
  echo "Restored Qt/KDE theme settings from before Midnight Glass"
}

case ${1:-} in
activate) activate ;;
deactivate) deactivate ;;
*)
  echo "Usage: $0 activate|deactivate" >&2
  exit 1
  ;;
esac
