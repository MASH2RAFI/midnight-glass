#!/bin/bash
# Apply Midnight Glass to Nautilus (Omarchy's file manager).
#
#   ./apply-nautilus-theme.sh

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"

"$THEME_DIR/manage-nautilus-config.sh" activate

echo "Nautilus updated for Midnight Glass"
