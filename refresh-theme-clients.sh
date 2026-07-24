#!/bin/bash
# Staged smooth refresh for all open themed clients after a palette sync.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

: "${MG_ASSETS_CHANGED:=1}"
: "${MG_CSS_CHANGED:=0}"
: "${MG_HYPR_CHANGED:=0}"
: "${MG_TERMINAL_CHANGED:=0}"
: "${MG_ICONS_CHANGED:=0}"

if [[ ${MG_CSS_CHANGED:-} == 1 ]]; then
  mg_reload_waybar_style
fi
mg_stage_if_needed

if [[ ${MG_TERMINAL_CHANGED:-} == 1 ]]; then
  mg_refresh_terminals
fi
mg_stage_if_needed

if [[ -f $THEME_DIR/.qt-swap-active && ( ${MG_ASSETS_CHANGED:-} == 1 || ${MG_CSS_CHANGED:-} == 1 ) ]]; then
  "$THEME_DIR/manage-qt-theme.sh" activate >/dev/null 2>&1 || true
fi
mg_stage_if_needed

if [[ ${MG_HYPR_CHANGED:-} == 1 ]]; then
  mg_hyprctl_reload
fi
mg_stage_if_needed

if [[ ${MG_CSS_CHANGED:-}${MG_ICONS_CHANGED:-} == *1* ]]; then
  "$THEME_DIR/refresh-nautilus-theme.sh" >/dev/null 2>&1 || true
fi
