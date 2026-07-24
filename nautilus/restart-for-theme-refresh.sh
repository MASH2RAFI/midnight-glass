#!/bin/bash
# Smooth Nautilus restart using Hyprland window animations.

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

CLOSE_WAIT=${MIDNIGHT_GLASS_NAUTILUS_CLOSE_SEC:-0.65}

pgrep -x nautilus >/dev/null 2>&1 || exit 0

if command -v hyprctl >/dev/null && command -v jq >/dev/null \
  && hyprctl clients -j | jq -e --arg c "$MG_NAUTILUS_CLASS" '.[] | select(.class==$c)' >/dev/null 2>&1; then
  hyprctl dispatch killwindow "class:$MG_NAUTILUS_CLASS" 2>/dev/null || true
  sleep "$CLOSE_WAIT"
else
  nautilus --quit 2>/dev/null || true
fi

pkill -x nautilus 2>/dev/null || true

for _ in $(seq 1 20); do
  pgrep -x nautilus >/dev/null || break
  sleep 0.05
done

pgrep -x nautilus >/dev/null && pkill -9 -x nautilus 2>/dev/null || true

uwsm-app -- nautilus >/dev/null 2>&1 &
