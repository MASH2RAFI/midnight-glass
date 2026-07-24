#!/bin/bash
# Regenerate and apply the Midnight Glass waybar layout when this theme is active.
# Safe to call at login, on wallpaper changes, and after theme set.

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
THEME_NAME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/current/theme.name"

if [[ ! -f $THEME_NAME_FILE ]]; then
  exit 0
fi

if [[ $(tr '[:upper:]' '[:lower:]' <"$THEME_NAME_FILE") != "midnight-glass" ]]; then
  exit 0
fi

exec "$THEME_DIR/set-waybar-position.sh" "$@"
