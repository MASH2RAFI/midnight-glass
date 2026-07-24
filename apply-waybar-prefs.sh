#!/bin/bash
# Deprecated compatibility shim.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/set-waybar-position.sh" "$@"
