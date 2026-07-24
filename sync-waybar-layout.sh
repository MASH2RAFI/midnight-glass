#!/bin/bash
# Regenerate and apply the Midnight Glass waybar layout when this theme is active.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

mg_is_active || exit 0
exec "$THEME_DIR/set-waybar-position.sh" "$@"
