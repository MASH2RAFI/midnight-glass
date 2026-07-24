#!/bin/bash
# Copy updated Midnight Glass assets into omarchy/current/theme without running
# a full `omarchy theme refresh` (which can disturb unrelated user configs).

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
CURRENT="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/current/theme"

[[ -d $CURRENT ]] || exit 0

for file in \
  waybar.css \
  hyprland.conf \
  colors.toml \
  alacritty.toml \
  kitty.conf \
  ghostty.conf \
  set-waybar-position.sh \
  manage-waybar-config.sh \
  manage-qt-theme.sh \
  apply-qt-theme.sh \
  sync-theme-assets.sh \
  sync-waybar-layout.sh; do
  [[ -f $THEME_DIR/$file ]] && cp "$THEME_DIR/$file" "$CURRENT/$file"
done

if command -v hyprctl >/dev/null; then
  hyprctl reload >/dev/null 2>&1 || true
fi
