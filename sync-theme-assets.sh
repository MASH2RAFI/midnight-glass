#!/bin/bash
# Copy theme assets to omarchy/current/theme, then refresh open clients smoothly.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

[[ -d $MG_CURRENT_THEME ]] || exit 0

ASSET_FILES=(
  waybar.css hyprland.conf colors.toml icons.theme
  alacritty.toml kitty.conf ghostty.conf
  unlock.png preview-unlock.png
)

SCRIPT_FILES=(
  set-waybar-position.sh manage-waybar-config.sh
  manage-qt-theme.sh manage-nautilus-config.sh
  apply-nautilus-theme.sh apply-qt-theme.sh build-qt-theme.sh
  sync-theme-assets.sh sync-waybar-layout.sh refresh-theme-clients.sh
)

MG_ASSETS_CHANGED=0
MG_CSS_CHANGED=0
MG_HYPR_CHANGED=0
MG_TERMINAL_CHANGED=0
MG_ICONS_CHANGED=0

sync_asset() {
  local file=$1 flag=$2
  [[ -f $THEME_DIR/$file ]] || return 0
  if mg_copy_if_changed "$THEME_DIR/$file" "$MG_CURRENT_THEME/$file"; then
    MG_ASSETS_CHANGED=1
    printf -v "$flag" 1
  fi
}

for file in "${ASSET_FILES[@]}"; do
  case "$file" in
    waybar.css) sync_asset "$file" MG_CSS_CHANGED ;;
    hyprland.conf) sync_asset "$file" MG_HYPR_CHANGED ;;
    alacritty.toml|kitty.conf|ghostty.conf) sync_asset "$file" MG_TERMINAL_CHANGED ;;
    icons.theme) sync_asset "$file" MG_ICONS_CHANGED ;;
    *) sync_asset "$file" MG_ASSETS_CHANGED ;;
  esac
done

for file in "${SCRIPT_FILES[@]}"; do
  mg_copy_if_changed "$THEME_DIR/$file" "$MG_CURRENT_THEME/$file" || true
done

[[ $MG_ASSETS_CHANGED == 1 ]] || exit 0

export MG_ASSETS_CHANGED MG_CSS_CHANGED MG_HYPR_CHANGED MG_TERMINAL_CHANGED MG_ICONS_CHANGED
"$THEME_DIR/refresh-theme-clients.sh" >/dev/null 2>&1 || true
