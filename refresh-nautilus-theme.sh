#!/bin/bash
# Sync Nautilus GTK CSS and icon theme after a wallpaper adapt, then restart
# Nautilus in the Hyprland session when it is already open.

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
MARKER="$THEME_DIR/.nautilus-swap-active"
RESTART="$THEME_DIR/nautilus/restart-for-theme-refresh.sh"

[[ -f $MARKER ]] || exit 0

"$THEME_DIR/manage-nautilus-config.sh" refresh

if ! pgrep -x nautilus >/dev/null 2>&1; then
  exit 0
fi

"$THEME_DIR/run-in-graphical-session.sh" "$RESTART"
