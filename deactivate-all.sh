#!/bin/bash
# Restore your original Waybar, Nautilus, and Qt settings after leaving Midnight Glass.
#
#   ./deactivate-all.sh
#
# Run this if remnants remain after switching themes (e.g. left bar layout, Nautilus CSS).

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

mg_deactivate_all
echo "Midnight Glass deactivated — Waybar, Nautilus, Qt, and the wallpaper watcher are restored."
