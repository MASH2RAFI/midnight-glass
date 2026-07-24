#!/bin/bash
# Deprecated: prefs are generated in waybar.config.jsonc by set-waybar-position.sh
#
#   ./apply-waybar-prefs.sh

set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "apply-waybar-prefs.sh now delegates to set-waybar-position.sh (non-destructive theme config)." >&2
exec "$THEME_DIR/set-waybar-position.sh"
