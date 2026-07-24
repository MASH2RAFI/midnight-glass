#!/bin/bash
# Midnight Glass shared library.
# Set MG_ROOT to the theme directory, then: source "$MG_ROOT/lib/common.sh"

[[ -n ${MG_LIB_SOURCED:-} ]] && return 0
MG_LIB_SOURCED=1

: "${MG_ROOT:?Set MG_ROOT to the midnight-glass theme directory before sourcing lib/common.sh}"
THEME_DIR=$MG_ROOT

MG_THEME_SLUG="midnight-glass"
MG_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
MG_OMARCHY_PATH="${OMARCHY_PATH:-$HOME/.local/share/omarchy}"
MG_CURRENT="$MG_CONFIG/omarchy/current"
MG_CURRENT_THEME="$MG_CURRENT/theme"
MG_THEME_NAME_FILE="$MG_CURRENT/theme.name"
MG_BG_LINK="$MG_CURRENT/background"
MG_STAGE_SEC="${MIDNIGHT_GLASS_STAGE_SEC:-0.08}"
MG_NAUTILUS_CLASS="org.gnome.Nautilus"
MG_SCRIPTS="$THEME_DIR/scripts"

mg_is_active() {
  [[ -f $MG_THEME_NAME_FILE ]] \
    && [[ $(tr '[:upper:]' '[:lower:]' <"$MG_THEME_NAME_FILE") == "$MG_THEME_SLUG" ]]
}

mg_wallpaper_path() {
  local explicit=${1:-}
  if [[ -n $explicit && -f $explicit ]]; then
    printf '%s\n' "$explicit"
    return 0
  fi
  if [[ -L $MG_BG_LINK ]]; then
    readlink -f "$MG_BG_LINK"
  elif [[ -f $MG_BG_LINK ]]; then
    printf '%s\n' "$MG_BG_LINK"
  fi
}

mg_magick_bin() {
  command -v magick || command -v convert || true
}

mg_read_color() {
  awk -F'"' -v key="$1" '$1 ~ "^" key " " { print $2; exit }' "$2"
}

mg_stage() {
  sleep "$MG_STAGE_SEC"
}

mg_stage_if_needed() {
  [[ ${MIDNIGHT_GLASS_FAST_REFRESH:-}${MIDNIGHT_GLASS_ADAPTING:-} == 1 ]] || mg_stage
}

# Copy when content differs. Returns 0 if copied, 1 if unchanged or missing source.
mg_copy_if_changed() {
  local src=$1 dst=$2
  [[ -f $src ]] || return 1
  [[ -f $dst ]] && cmp -s "$src" "$dst" && return 1
  cp "$src" "$dst"
}

mg_bootstrap_graphical_env() {
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

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

mg_run_in_session() {
  mg_bootstrap_graphical_env

  if command -v hyprctl >/dev/null && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl dispatch exec -- bash -lc "$1" >/dev/null 2>&1 && return 0
  fi

  if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
    bash -lc "$1" >/dev/null 2>&1 &
    return 0
  fi

  return 1
}

mg_reload_waybar_style() {
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 -x waybar 2>/dev/null || true
  fi
}

mg_restart_waybar() {
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 -x waybar 2>/dev/null || true
    return 0
  fi

  mg_bootstrap_graphical_env
  [[ -n ${WAYLAND_DISPLAY:-}${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0

  if command -v omarchy-restart-waybar >/dev/null; then
    omarchy-restart-waybar
  elif command -v omarchy >/dev/null; then
    omarchy restart waybar
  else
    setsid uwsm-app -- waybar >/dev/null 2>&1 &
  fi
}

mg_restart_waybar_layout() {
  if command -v omarchy-restart-waybar >/dev/null; then
    omarchy-restart-waybar
  elif command -v omarchy >/dev/null; then
    omarchy restart waybar
  elif pgrep -x waybar >/dev/null; then
    pkill -x waybar 2>/dev/null || true
    setsid uwsm-app -- waybar >/dev/null 2>&1 &
  fi
}

mg_hyprctl_reload() {
  command -v hyprctl >/dev/null || return 0
  hyprctl reload >/dev/null 2>&1 || true
}

mg_refresh_terminals() {
  if [[ -f $MG_CONFIG/alacritty/alacritty.toml ]]; then
    touch "$MG_CONFIG/alacritty/alacritty.toml"
    [[ -f $MG_CURRENT_THEME/alacritty.toml ]] && touch "$MG_CURRENT_THEME/alacritty.toml"
  fi

  pgrep -x kitty >/dev/null 2>&1 && killall -SIGUSR1 kitty 2>/dev/null || true
  pgrep -x ghostty >/dev/null 2>&1 && killall -SIGUSR2 ghostty 2>/dev/null || true

  if pgrep -x foot >/dev/null 2>&1 && command -v footclient >/dev/null; then
    footclient -p reload 2>/dev/null || true
  fi
}

mg_read_icon_theme() {
  tr -d '[:space:]' <"$1"
}

mg_start_watcher() {
  systemctl --user enable --now midnight-glass-wallpaper.path >/dev/null 2>&1 || true
}

mg_stop_watcher() {
  systemctl --user disable --now midnight-glass-wallpaper.path >/dev/null 2>&1 || true
}

mg_deactivate_all() {
  "$THEME_DIR/manage-waybar-config.sh" deactivate || true
  "$THEME_DIR/manage-qt-theme.sh" deactivate || true
  "$THEME_DIR/manage-nautilus-config.sh" deactivate || true
  mg_stop_watcher
}

mg_executable_scripts() {
  find "$THEME_DIR" -maxdepth 2 -type f -name '*.sh' ! -path '*/.git/*' -print
}
