#!/bin/bash
# Reversible Midnight Glass waybar layout swap.
#
# All swap state lives in this theme folder only. While Midnight Glass is
# active, ~/.config/waybar/config.jsonc is replaced with waybar.config.jsonc
# from here. Your original config is backed up once and restored when you
# switch to another theme. If the backup is missing or invalid (e.g. a prior
# left-bar layout), waybar.config.omarchy-default.jsonc is used instead.
#
#   ./manage-waybar-config.sh activate
#   ./manage-waybar-config.sh deactivate
#   ./manage-waybar-config.sh status
#   ./manage-waybar-config.sh validate [config-path]

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config.jsonc"
THEME_CONFIG="$THEME_DIR/waybar.config.jsonc"
BACKUP="$THEME_DIR/waybar.config.user-backup.jsonc"
OMARCHY_DEFAULT="$THEME_DIR/waybar.config.omarchy-default.jsonc"
MARKER="$THEME_DIR/.waybar-swap-active"

LEGACY_BACKUP="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config.jsonc.before-midnight-glass"
LEGACY_MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/.midnight-glass-active"

is_theme_layout() {
  python3 - "$1" "$THEME_CONFIG" <<'PY'
import json, sys

path, theme_path = sys.argv[1:3]
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)

try:
    with open(theme_path, encoding="utf-8") as fh:
        theme = json.load(fh)
    if cfg == theme:
        raise SystemExit(0)
except FileNotFoundError:
    theme = None

pos = cfg.get("position")
if pos in ("left", "right") and "width" in cfg:
    raise SystemExit(0)

center = cfg.get("modules-center", [])
if pos in ("left", "right") and center == ["clock"]:
    raise SystemExit(0)

left = cfg.get("modules-left", [])
if theme and left == theme.get("modules-left") and pos == theme.get("position"):
    raise SystemExit(0)

raise SystemExit(1)
PY
}

validate_layout() {
  python3 - "$1" <<'PY'
import json, sys

path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)

left = cfg.get("modules-left", [])
if "hyprland/workspaces" not in left:
    raise SystemExit("hyprland/workspaces missing from modules-left")

ws = cfg.get("hyprland/workspaces", {})
if ws.get("format") != "{id}":
    raise SystemExit('hyprland/workspaces format must be "{id}"')
PY
}

migrate_legacy_state() {
  if [[ -f $LEGACY_BACKUP && ! -f $BACKUP ]]; then
    cp -a "$LEGACY_BACKUP" "$BACKUP"
  fi
  if [[ -f $LEGACY_MARKER && ! -f $MARKER ]]; then
    : >"$MARKER"
  fi
  rm -f "$LEGACY_BACKUP" "$LEGACY_MARKER"
}

restart_waybar() {
  if command -v omarchy-restart-waybar >/dev/null; then
    omarchy-restart-waybar
  elif command -v omarchy >/dev/null; then
    omarchy restart waybar
  elif pgrep -x waybar >/dev/null; then
    pkill -x waybar 2>/dev/null || true
    setsid uwsm-app -- waybar >/dev/null 2>&1 &
  fi
}

restore_target() {
  migrate_legacy_state

  if [[ -f $BACKUP ]] && ! is_theme_layout "$BACKUP"; then
    echo "$BACKUP"
    return 0
  fi

  if [[ -f $OMARCHY_DEFAULT ]]; then
    echo "$OMARCHY_DEFAULT"
    return 0
  fi

  return 1
}

activate() {
  migrate_legacy_state

  if [[ ! -f $THEME_CONFIG ]]; then
    echo "Missing theme waybar config: $THEME_CONFIG" >&2
    echo "Run: $THEME_DIR/set-waybar-position.sh" >&2
    exit 1
  fi

  validate_layout "$THEME_CONFIG"

  if [[ ! -f $MARKER ]]; then
    if [[ -f $USER_CONFIG ]] \
      && ! cmp -s "$USER_CONFIG" "$THEME_CONFIG" 2>/dev/null \
      && ! is_theme_layout "$USER_CONFIG"; then
      cp -a "$USER_CONFIG" "$BACKUP"
    fi
    : >"$MARKER"
  fi

  if [[ -f $USER_CONFIG ]] && cmp -s "$THEME_CONFIG" "$USER_CONFIG"; then
    validate_layout "$USER_CONFIG"
    echo "Waybar already using Midnight Glass layout"
    return 0
  fi

  cp "$THEME_CONFIG" "$USER_CONFIG"
  validate_layout "$USER_CONFIG"
  restart_waybar
  echo "Applied Midnight Glass waybar layout"
}

deactivate() {
  migrate_legacy_state

  if [[ ! -f $MARKER ]]; then
    return 0
  fi

  if target=$(restore_target); then
    cp -a "$target" "$USER_CONFIG"
  fi

  rm -f "$MARKER"
  restart_waybar
  echo "Restored waybar config for non-Midnight-Glass theme"
}

status() {
  migrate_legacy_state
  if [[ -f $MARKER ]]; then
    echo "active"
    echo "  theme config:   $THEME_CONFIG"
    echo "  user backup:    $BACKUP"
    echo "  omarchy default: $OMARCHY_DEFAULT"
    if [[ -f $BACKUP ]] && is_theme_layout "$BACKUP"; then
      echo "  note: backup looks like Midnight Glass; restore will use omarchy default"
    fi
  else
    echo "inactive"
  fi
}

case ${1:-} in
activate) activate ;;
deactivate) deactivate ;;
status) status ;;
validate)
  validate_layout "${2:-$USER_CONFIG}"
  echo "ok: $(basename "${2:-$USER_CONFIG}")"
  ;;
*)
  echo "Usage: $0 activate|deactivate|status|validate [config-path]" >&2
  exit 1
  ;;
esac
