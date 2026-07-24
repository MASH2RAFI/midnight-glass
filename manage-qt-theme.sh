#!/bin/bash
# Reversible Qt/Kvantum theme swap for Midnight Glass.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

KV_NAME="MidnightGlass"
QT_DIR="$THEME_DIR/qt"
GENERATED_KV="$QT_DIR/$KV_NAME"
KV_ROOT="$MG_CONFIG/Kvantum/kvantum.kvconfig"
USER_KV_DIR="$MG_CONFIG/Kvantum/$KV_NAME"
SCHEME_DIR="$MG_CONFIG/color-schemes"
SCHEME_FILE="$SCHEME_DIR/$KV_NAME.colors"
MARKER="$THEME_DIR/.qt-swap-active"
KV_ROOT_BACKUP="$QT_DIR/kvantum.kvconfig.user-backup"
SCHEME_BACKUP="$QT_DIR/kdeglobals.colorscheme.user-backup"

activate() {
  if [[ ! -f $GENERATED_KV/$KV_NAME.kvconfig || ! -f $GENERATED_KV/$KV_NAME.colors ]]; then
    echo "Missing generated Qt theme in $GENERATED_KV" >&2
    echo "Run: $THEME_DIR/build-qt-theme.sh" >&2
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

  local kv_changed=0 scheme_changed=0 root_changed=0

  ln -sfn "$(readlink -f "$GENERATED_KV/$KV_NAME.svg")" "$USER_KV_DIR/$KV_NAME.svg"

  if ! cmp -s "$GENERATED_KV/$KV_NAME.kvconfig" "$USER_KV_DIR/$KV_NAME.kvconfig" 2>/dev/null; then
    cp "$GENERATED_KV/$KV_NAME.kvconfig" "$USER_KV_DIR/$KV_NAME.kvconfig"
    kv_changed=1
  fi

  if ! cmp -s "$GENERATED_KV/$KV_NAME.colors" "$SCHEME_FILE" 2>/dev/null; then
    cp "$GENERATED_KV/$KV_NAME.colors" "$SCHEME_FILE"
    scheme_changed=1
  fi

  if ! [[ -f $KV_ROOT ]] || ! grep -q "^theme=$KV_NAME\$" "$KV_ROOT" 2>/dev/null; then
    cat >"$KV_ROOT" <<EOF
[General]
theme=$KV_NAME
EOF
    root_changed=1
  fi

  if command -v kwriteconfig5 >/dev/null; then
    local current_scheme
    current_scheme=$(kreadconfig5 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)
    if [[ $current_scheme != "$KV_NAME" ]]; then
      kwriteconfig5 --file kdeglobals --group General --key ColorScheme "$KV_NAME"
      scheme_changed=1
    fi
  fi

  if [[ $kv_changed == 0 && $scheme_changed == 0 && $root_changed == 0 ]]; then
    return 0
  fi

  if command -v kbuildsycoca5 >/dev/null; then
    if [[ ${MIDNIGHT_GLASS_ADAPTING:-} == 1 ]]; then
      kbuildsycoca5 >/dev/null 2>&1 || true
    else
      kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
    fi
  fi
}

deactivate() {
  [[ -f $MARKER ]] || return 0

  if [[ -f $KV_ROOT_BACKUP ]]; then
    cp -a "$KV_ROOT_BACKUP" "$KV_ROOT"
  fi

  if [[ -f $SCHEME_BACKUP ]] && command -v kwriteconfig5 >/dev/null; then
    PREV_SCHEME=$(tr -d '\n' <"$SCHEME_BACKUP")
    [[ -n $PREV_SCHEME ]] && kwriteconfig5 --file kdeglobals --group General --key ColorScheme "$PREV_SCHEME"
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
