#!/bin/bash
# Reload open apps after palette sync — staged so changes feel smooth, not abrupt.
# Called from sync-theme-assets.sh after files are copied to omarchy/current/theme.

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
STAGE_SEC=${MIDNIGHT_GLASS_STAGE_SEC:-0.08}

stage() {
  sleep "$STAGE_SEC"
}

refresh_terminals() {
  local current="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/current/theme"

  if [[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml ]]; then
    touch "${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"
    [[ -f $current/alacritty.toml ]] && touch "$current/alacritty.toml"
  fi

  if pgrep -x kitty >/dev/null 2>&1; then
    killall -SIGUSR1 kitty 2>/dev/null || true
  fi

  if pgrep -x ghostty >/dev/null 2>&1; then
    killall -SIGUSR2 ghostty 2>/dev/null || true
  fi

  if pgrep -x foot >/dev/null 2>&1 && command -v footclient >/dev/null; then
    footclient -p reload 2>/dev/null || true
  fi
}

refresh_qt() {
  [[ -f $THEME_DIR/.qt-swap-active ]] || return 0
  "$THEME_DIR/manage-qt-theme.sh" activate >/dev/null 2>&1 || true
}

refresh_hyprland() {
  command -v hyprctl >/dev/null || return 0
  hyprctl reload >/dev/null 2>&1 || true
}

# 1) Waybar — CSS transitions cross-fade (~420ms)
"$THEME_DIR/refresh-waybar-style.sh" >/dev/null 2>&1 || true
stage

# 2) Terminals — reload configs in place (no window kill)
refresh_terminals
stage

# 3) Qt/Kvantum — push updated scheme to open Qt apps
refresh_qt
stage

# 4) Hyprland — borders, blur, opacity rules
refresh_hyprland
stage

# 5) Nautilus — animated close/open when already running
"$THEME_DIR/refresh-nautilus-theme.sh" >/dev/null 2>&1 || true
