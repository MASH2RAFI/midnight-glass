#!/bin/bash
# Reload Waybar CSS via SIGUSR2 (uses CSS transitions in waybar.css).

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

mg_reload_waybar_style
