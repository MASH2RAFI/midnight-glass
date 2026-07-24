#!/bin/bash
# One-shot handler: adapt Midnight Glass when Omarchy changes the wallpaper symlink.
# Triggered by systemd path unit (midnight-glass-wallpaper.path), not a poll loop.

set -euo pipefail

MG_ROOT="${MG_THEME_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass}"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/midnight-glass-adapt.lock"
STATE_FILE="$THEME_DIR/.last-adapted-wallpaper"

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

mg_is_active || exit 0

CUR=$(mg_wallpaper_path || true)
[[ -n $CUR && -f $CUR ]] || exit 0

if [[ -f $STATE_FILE ]] && [[ $CUR == "$(<"$STATE_FILE")" ]]; then
  exit 0
fi

export MIDNIGHT_GLASS_ADAPTING=1
"$THEME_DIR/adapt-from-wallpaper.sh" "$CUR" || true
"$THEME_DIR/sync-theme-assets.sh" || true
unset MIDNIGHT_GLASS_ADAPTING

printf '%s\n' "$CUR" >"$STATE_FILE"
