#!/bin/bash
# Run a command inside the active Hyprland session.
# Used by background services (wallpaper watcher) that lack uwsm-app context.

set -euo pipefail

bootstrap_graphical_env() {
  if [[ -z ${XDG_RUNTIME_DIR:-} ]]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
  fi

  if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-}${WAYLAND_DISPLAY:-} ]] && command -v systemctl >/dev/null; then
    while IFS='=' read -r key value; do
      case "$key" in
        HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP)
          [[ -n $value ]] && export "$key=$value"
          ;;
      esac
    done < <(systemctl --user show-environment 2>/dev/null || true)
  fi

  if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} && -d ${XDG_RUNTIME_DIR}/hypr ]]; then
    local sig
    sig=$(find "${XDG_RUNTIME_DIR}/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | head -1)
    [[ -n $sig ]] && export HYPRLAND_INSTANCE_SIGNATURE=$sig
  fi

  if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
    for w in wayland-1 wayland-0; do
      if [[ -S ${XDG_RUNTIME_DIR}/$w ]]; then
        export WAYLAND_DISPLAY=$w
        break
      fi
    done
  fi
}

run_in_graphical_session() {
  local cmd=$1
  bootstrap_graphical_env

  if command -v hyprctl >/dev/null && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl dispatch exec -- bash -lc "$cmd" >/dev/null 2>&1 && return 0
  fi

  if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    bash -lc "$cmd" >/dev/null 2>&1 &
    return 0
  fi

  return 1
}

if (($# == 0)); then
  echo "Usage: $0 <command>" >&2
  exit 1
fi

run_in_graphical_session "$*"
