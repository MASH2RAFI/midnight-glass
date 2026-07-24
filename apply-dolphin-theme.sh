#!/bin/bash
# Deprecated wrapper — Omarchy uses Nautilus, not Dolphin.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/apply-nautilus-theme.sh"
