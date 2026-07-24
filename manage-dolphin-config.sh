#!/bin/bash
# Reversible Dolphin layout + KDE/GNOME icon theme swap for Midnight Glass.
#
#   ./manage-dolphin-config.sh activate
#   ./manage-dolphin-config.sh deactivate
#   ./manage-dolphin-config.sh status

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
USER_DOLPHINRC="${XDG_CONFIG_HOME:-$HOME/.config}/dolphinrc"
THEME_DOLPHINRC="$THEME_DIR/dolphin/dolphinrc"
DOLPHIN_BACKUP="$THEME_DIR/dolphin/dolphinrc.user-backup"
NO_PRIOR_DOLPHIN="$THEME_DIR/dolphin/.no-prior-dolphinrc"
ICON_THEME_FILE="$THEME_DIR/icons.theme"
ICON_BACKUP="$THEME_DIR/dolphin/kde.icon-theme.user-backup"
ICON_DEFAULT="$THEME_DIR/dolphin/kde.icon-theme.omarchy-default"
MARKER="$THEME_DIR/.dolphin-swap-active"

read_icon_theme() {
  tr -d '[:space:]' <"$1"
}

apply_icon_theme() {
  local theme=$1

  if command -v kwriteconfig5 >/dev/null; then
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "$theme"
  fi

  if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme "$theme" >/dev/null 2>&1 || true
  fi

  if command -v kbuildsycoca5 >/dev/null; then
    kbuildsycoca5 --noincremental >/dev/null 2>&1 || true
  fi
}

restart_dolphin() {
  if pgrep -x dolphin >/dev/null; then
    pkill -x dolphin || true
    sleep 0.2
    setsid uwsm-app -- dolphin >/dev/null 2>&1 &
  fi
}

activate() {
  if [[ ! -f $THEME_DOLPHINRC ]]; then
    echo "Missing Dolphin layout: $THEME_DOLPHINRC" >&2
    exit 1
  fi

  if [[ ! -f $ICON_THEME_FILE ]]; then
    echo "Missing icon theme file: $ICON_THEME_FILE" >&2
    exit 1
  fi

  if [[ ! -f $MARKER ]]; then
    if [[ -f $USER_DOLPHINRC ]]; then
      cp -a "$USER_DOLPHINRC" "$DOLPHIN_BACKUP"
    else
      : >"$NO_PRIOR_DOLPHIN"
    fi

    if command -v kreadconfig5 >/dev/null; then
      kreadconfig5 --file kdeglobals --group Icons --key Theme >"$ICON_BACKUP" 2>/dev/null || true
    fi

    : >"$MARKER"
  fi

  cp "$THEME_DOLPHINRC" "$USER_DOLPHINRC"
  apply_icon_theme "$(read_icon_theme "$ICON_THEME_FILE")"
  echo "Applied Midnight Glass Dolphin layout and icons"
}

deactivate() {
  if [[ ! -f $MARKER ]]; then
    return 0
  fi

  if [[ -f $DOLPHIN_BACKUP ]]; then
    cp -a "$DOLPHIN_BACKUP" "$USER_DOLPHINRC"
  elif [[ -f $NO_PRIOR_DOLPHIN ]]; then
    rm -f "$USER_DOLPHINRC" "$NO_PRIOR_DOLPHIN"
  fi

  if [[ -f $ICON_BACKUP ]] && [[ -n $(tr -d '[:space:]' <"$ICON_BACKUP") ]]; then
    apply_icon_theme "$(read_icon_theme "$ICON_BACKUP")"
  elif [[ -f $ICON_DEFAULT ]]; then
    apply_icon_theme "$(read_icon_theme "$ICON_DEFAULT")"
  fi

  rm -f "$MARKER"
  restart_dolphin
  echo "Restored Dolphin layout and icons from before Midnight Glass"
}

status() {
  if [[ -f $MARKER ]]; then
    echo "active"
    echo "  layout: $THEME_DOLPHINRC"
    echo "  icons:  $(read_icon_theme "$ICON_THEME_FILE")"
  else
    echo "inactive"
  fi
}

case ${1:-} in
activate) activate ;;
deactivate) deactivate ;;
status) status ;;
*)
  echo "Usage: $0 activate|deactivate|status" >&2
  exit 1
  ;;
esac
