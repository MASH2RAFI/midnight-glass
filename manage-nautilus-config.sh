#!/bin/bash
# Reversible Nautilus layout, icons, and GTK styling for Midnight Glass.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

ICON_THEME_FILE="$THEME_DIR/icons.theme"
THEME_GTK_CSS="$THEME_DIR/nautilus/gtk.css"
USER_GTK_DIR="$MG_CONFIG/gtk-4.0"
USER_GTK_CSS="$USER_GTK_DIR/gtk.css"
GTK_BACKUP="$THEME_DIR/nautilus/gtk.css.user-backup"
NO_PRIOR_GTK="$THEME_DIR/nautilus/.no-prior-gtk-css"
GSETTINGS_BACKUP="$THEME_DIR/nautilus/gsettings.user-backup"
GSETTINGS_DEFAULT="$THEME_DIR/nautilus/gsettings.omarchy-default"
MARKER="$THEME_DIR/.nautilus-swap-active"
GSETTINGS_PY="$MG_SCRIPTS/nautilus_gsettings.py"

apply_gsettings() {
  python3 "$GSETTINGS_PY" apply "$THEME_DIR"
}

backup_gsettings() {
  python3 "$GSETTINGS_PY" backup "$GSETTINGS_BACKUP"
}

restore_gsettings() {
  python3 "$GSETTINGS_PY" restore "$1"
}

activate_gtk_css() {
  mkdir -p "$USER_GTK_DIR"

  if [[ ! -f $MARKER ]]; then
    if [[ -f $USER_GTK_CSS ]]; then
      cp -a "$USER_GTK_CSS" "$GTK_BACKUP"
    else
      : >"$NO_PRIOR_GTK"
    fi
  fi

  cp "$THEME_GTK_CSS" "$USER_GTK_CSS"
}

copy_gtk_css_if_changed() {
  mkdir -p "$USER_GTK_DIR"
  [[ -f $USER_GTK_CSS ]] && cmp -s "$THEME_GTK_CSS" "$USER_GTK_CSS" && return 1
  cp "$THEME_GTK_CSS" "$USER_GTK_CSS"
}

deactivate_gtk_css() {
  if [[ -f $GTK_BACKUP ]]; then
    cp -a "$GTK_BACKUP" "$USER_GTK_CSS"
  elif [[ -f $NO_PRIOR_GTK ]]; then
    rm -f "$USER_GTK_CSS" "$NO_PRIOR_GTK"
    rmdir "$USER_GTK_DIR" 2>/dev/null || true
  else
    rm -f "$USER_GTK_CSS"
    rmdir "$USER_GTK_DIR" 2>/dev/null || true
  fi
}

activate() {
  command -v gsettings >/dev/null || {
    echo "gsettings is required for Nautilus theming" >&2
    exit 1
  }

  if [[ ! -f $ICON_THEME_FILE || ! -f $THEME_GTK_CSS ]]; then
    echo "Missing Nautilus theme files in $THEME_DIR/nautilus/" >&2
    exit 1
  fi

  [[ -f $MARKER ]] || {
    backup_gsettings
    : >"$MARKER"
  }

  apply_gsettings
  activate_gtk_css
  echo "Applied Midnight Glass Nautilus layout, icons, and styling"
}

refresh() {
  [[ -f $MARKER ]] || return 0
  [[ -f $ICON_THEME_FILE && -f $THEME_GTK_CSS ]] || {
    echo "Missing Nautilus theme files in $THEME_DIR/nautilus/" >&2
    exit 1
  }

  MG_NAUTILUS_CHANGED=0

  if python3 "$GSETTINGS_PY" refresh-icons "$THEME_DIR"; then
    MG_NAUTILUS_CHANGED=1
  fi

  if copy_gtk_css_if_changed; then
    MG_NAUTILUS_CHANGED=1
  fi

  export MG_NAUTILUS_CHANGED
}

deactivate() {
  [[ -f $MARKER ]] || return 0

  if [[ -f $GSETTINGS_BACKUP ]]; then
    restore_gsettings "$GSETTINGS_BACKUP"
  elif [[ -f $GSETTINGS_DEFAULT ]]; then
    restore_gsettings "$GSETTINGS_DEFAULT"
  fi

  deactivate_gtk_css
  rm -f "$MARKER"
  echo "Restored Nautilus settings from before Midnight Glass"
}

status() {
  if [[ -f $MARKER ]]; then
    echo "active"
    echo "  icons: $(mg_read_icon_theme "$ICON_THEME_FILE")"
    echo "  gtk:   $USER_GTK_CSS"
  else
    echo "inactive"
  fi
}

case ${1:-} in
activate) activate ;;
refresh) refresh ;;
deactivate) deactivate ;;
status) status ;;
*)
  echo "Usage: $0 activate|refresh|deactivate|status" >&2
  exit 1
  ;;
esac
