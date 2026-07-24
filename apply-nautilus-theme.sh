#!/bin/bash
# Apply Midnight Glass to Nautilus (Omarchy's file manager).

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

"$THEME_DIR/manage-nautilus-config.sh" activate
echo "Nautilus updated for Midnight Glass"
