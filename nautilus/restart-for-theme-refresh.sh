#!/bin/bash
# Smooth Nautilus restart: Hyprland windowsOut/windowsIn, then relaunch.
# Timing matches matteOut curves in hyprland.conf (windowsOut ~0.55s, windowsIn ~0.65s).

set -euo pipefail

NAUTILUS_CLASS="org.gnome.Nautilus"
CLOSE_WAIT=${MIDNIGHT_GLASS_NAUTILUS_CLOSE_SEC:-0.65}
OPEN_WAIT=${MIDNIGHT_GLASS_NAUTILUS_OPEN_SEC:-0.05}

if ! pgrep -x nautilus >/dev/null 2>&1; then
  exit 0
fi

if command -v hyprctl >/dev/null && command -v jq >/dev/null \
  && hyprctl clients -j | jq -e --arg c "$NAUTILUS_CLASS" '.[] | select(.class==$c)' >/dev/null 2>&1; then
  hyprctl dispatch killwindow "class:$NAUTILUS_CLASS" 2>/dev/null || true
  sleep "$CLOSE_WAIT"
else
  nautilus --quit 2>/dev/null || true
fi

pkill -x nautilus 2>/dev/null || true

for _ in $(seq 1 40); do
  pgrep -x nautilus >/dev/null || break
  sleep 0.05
done

if pgrep -x nautilus >/dev/null; then
  pkill -9 -x nautilus 2>/dev/null || true
  sleep 0.1
fi

uwsm-app -- nautilus >/dev/null 2>&1 &
sleep "$OPEN_WAIT"
