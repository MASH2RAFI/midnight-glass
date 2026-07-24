#!/bin/bash
# Sync Nautilus GTK CSS + icons, then animated restart when open.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

MARKER="$THEME_DIR/.nautilus-swap-active"
RESTART="$THEME_DIR/nautilus/restart-for-theme-refresh.sh"

[[ -f $MARKER ]] || exit 0

"$THEME_DIR/manage-nautilus-config.sh" refresh
[[ ${MG_NAUTILUS_CHANGED:-} == 1 ]] || exit 0
pgrep -x nautilus >/dev/null 2>&1 || exit 0

mg_run_in_session "$RESTART"
