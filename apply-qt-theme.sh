#!/bin/bash
# Build and activate the Midnight Glass Qt/Kvantum theme.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

"$THEME_DIR/build-qt-theme.sh"
"$THEME_DIR/manage-qt-theme.sh" activate

echo "Applied Qt/KDE theme: MidnightGlass"
