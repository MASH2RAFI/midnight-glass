#!/bin/bash
# Reload Waybar after waybar.css changes without killing the process.
# SIGUSR2 reloads config + imported CSS. Safe from the wallpaper watcher service.

set -euo pipefail

refresh_waybar_style() {
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 -x waybar 2>/dev/null || true
    return 0
  fi

  # Bar is not running — only start when a graphical session is visible.
  if [[ -z ${WAYLAND_DISPLAY:-}${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    return 0
  fi

  if command -v omarchy-restart-waybar >/dev/null; then
    omarchy-restart-waybar
  elif command -v omarchy >/dev/null; then
    omarchy restart waybar
  else
    setsid uwsm-app -- waybar >/dev/null 2>&1 &
  fi
}

refresh_waybar_style
