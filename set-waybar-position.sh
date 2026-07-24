#!/bin/bash
# Switch Midnight Glass waybar edge: top | bottom | left | right
#
# Writes waybar.config.jsonc in this theme folder only, then activates it
# while Midnight Glass is the current theme. Your original waybar config is
# backed up once and restored when you switch to another theme.
#
# Variable file:
#   ~/.config/omarchy/themes/midnight-glass/waybar.position
#
# Usage:
#   ./set-waybar-position.sh           # apply value from waybar.position
#   ./set-waybar-position.sh left      # set variable + apply

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
POS_FILE="$THEME_DIR/waybar.position"
THEME_CONFIG="$THEME_DIR/waybar.config.jsonc"
CURRENT_THEME_NAME="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/current/theme.name"

if [[ -n ${1:-} ]]; then
  POS=$(echo "$1" | tr '[:upper:]' '[:lower:]')
else
  POS=$(
    grep -v '^[[:space:]]*#' "$POS_FILE" |
      tr -s '[:space:]' '\n' |
      grep -E '^(top|bottom|left|right)$' |
      head -n 1 |
      tr '[:upper:]' '[:lower:]'
  )
fi

case $POS in
top | bottom | left | right) ;;
*)
  echo "Invalid position: ${POS:-<empty>}" >&2
  echo "Use: top | bottom | left | right" >&2
  echo "See comments in: $POS_FILE" >&2
  exit 1
  ;;
esac

cat >"$POS_FILE" <<EOF
# Waybar screen edge — change the value below, then run:
#   ./set-waybar-position.sh
# Or in one step:
#   ./set-waybar-position.sh <direction>
#
# Directions:
#   top     — bar along the top edge (horizontal islands)
#   bottom  — bar along the bottom edge (horizontal islands)
#   left    — stacked glass islands on the left edge
#   right   — stacked glass islands on the right edge
#
# Only the first bare word below is read (lines starting with # are ignored).

$POS
EOF

python3 - "$THEME_CONFIG" "$POS" <<'PY'
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
pos = sys.argv[2]
vertical = pos in ("left", "right")

center_modules = (
    ["clock"]
    if vertical
    else [
        "clock",
        "custom/weather",
        "custom/update",
        "custom/voxtype",
        "custom/screenrecording-indicator",
        "custom/idle-indicator",
        "custom/notification-silencing-indicator",
    ]
)

modules_right = [
    "group/tray-expander",
    "bluetooth",
    "network",
    "pulseaudio",
    "cpu",
    "memory",
    "battery",
]

if vertical:
    clock = {
        "rotate": 90 if pos == "left" else 270,
        "format": "{:%a %d  %I:%M %p}",
        "format-alt": "{:%b %d  %I:%M %p}",
        "tooltip": True,
        "on-click-right": "omarchy-launch-floating-terminal-with-presentation omarchy-tz-select",
    }
    cpu = {
        "interval": 2,
        "format": "󰍛\n{usage}%",
        "tooltip": True,
        "on-click": "omarchy-launch-or-focus-tui btop",
        "on-click-right": "alacritty",
    }
    memory = {
        "interval": 3,
        "format": "󰘚\n{percentage}%",
        "tooltip-format": "RAM {used:0.1f}G / {total:0.1f}G",
        "on-click": "omarchy-launch-or-focus-tui btop",
    }
    battery = {
        "format": "{icon}\n{capacity}%",
        "format-discharging": "{icon}\n{capacity}%",
        "format-charging": "{icon}\n{capacity}%",
        "format-plugged": "\n{capacity}%",
        "format-icons": {
            "charging": ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"],
            "default": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
        },
        "format-full": "󰂅\n{capacity}%",
        "tooltip-format-discharging": "{power:>1.0f}W↓ {capacity}%",
        "tooltip-format-charging": "{power:>1.0f}W↑ {capacity}%",
        "interval": 5,
        "on-click": "omarchy-menu power",
        "on-click-right": 'notify-send -u low "$(omarchy-battery-status)"',
        "states": {"warning": 20, "critical": 10},
    }
    expand_icon = ""
    bar_width = 40
else:
    clock = {
        "format": "{:L%A %I:%M %p}",
        "format-alt": "{:L%d %B W%V %Y}",
        "tooltip": False,
        "on-click-right": "omarchy-launch-floating-terminal-with-presentation omarchy-tz-select",
    }
    cpu = {
        "interval": 2,
        "format": "󰍛 {usage}%",
        "tooltip": True,
        "on-click": "omarchy-launch-or-focus-tui btop",
        "on-click-right": "alacritty",
    }
    memory = {
        "interval": 3,
        "format": "󰘚 {percentage}%",
        "tooltip-format": "RAM {used:0.1f}G / {total:0.1f}G",
        "on-click": "omarchy-launch-or-focus-tui btop",
    }
    battery = {
        "format": "{icon} {capacity}%",
        "format-discharging": "{icon} {capacity}%",
        "format-charging": "{icon} {capacity}%",
        "format-plugged": " {capacity}%",
        "format-icons": {
            "charging": ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"],
            "default": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
        },
        "format-full": "󰂅 {capacity}%",
        "tooltip-format-discharging": "{power:>1.0f}W↓ {capacity}%",
        "tooltip-format-charging": "{power:>1.0f}W↑ {capacity}%",
        "interval": 5,
        "on-click": "omarchy-menu power",
        "on-click-right": 'notify-send -u low "$(omarchy-battery-status)"',
        "states": {"warning": 20, "critical": 10},
    }
    expand_icon = ""
    bar_width = None

config = {
    "reload_style_on_change": True,
    "layer": "top",
    "position": pos,
    "spacing": 0,
    "modules-left": ["custom/omarchy", "hyprland/workspaces"],
    "modules-center": center_modules,
    "modules-right": modules_right,
    "hyprland/workspaces": {
        "on-click": "activate",
        "format": "{id}",
        "sort-by-number": True,
        "persistent-workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": [],
        },
    },
    "custom/omarchy": {
        "format": "<span font='omarchy'>\ue900</span>",
        "on-click": "omarchy-menu",
        "on-click-right": "xdg-terminal-exec",
        "tooltip-format": "Omarchy Menu\n\nSuper + Alt + Space",
    },
    "custom/update": {
        "format": "",
        "exec": "omarchy-update-available",
        "on-click": "omarchy-launch-floating-terminal-with-presentation omarchy-update",
        "tooltip-format": "Omarchy update available",
        "signal": 7,
        "interval": 21600,
    },
    "cpu": cpu,
    "memory": memory,
    "clock": clock,
    "custom/weather": {
        "exec": "$OMARCHY_PATH/default/waybar/weather.sh",
        "return-type": "json",
        "interval": 60,
        "tooltip": False,
        "on-click": 'notify-send -u low "$(omarchy-weather-status)"',
    },
    "network": {
        "format-icons": ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"],
        "format": "{icon}",
        "format-wifi": "{icon}",
        "format-ethernet": "󰀂",
        "format-disconnected": "󰤮",
        "tooltip-format-wifi": "{essid} ({frequency} GHz)",
        "tooltip-format-ethernet": "Connected",
        "tooltip-format-disconnected": "Disconnected",
        "interval": 3,
        "spacing": 1,
        "on-click": "omarchy-launch-wifi",
    },
    "battery": battery,
    "bluetooth": {
        "format": "",
        "format-off": "󰂲",
        "format-disabled": "󰂲",
        "format-connected": "󰂱",
        "format-no-controller": "",
        "tooltip-format": "Devices connected: {num_connections}",
        "on-click": "omarchy-launch-bluetooth",
    },
    "pulseaudio": {
        "format": "{icon}",
        "on-click": "omarchy-launch-audio",
        "on-click-right": "pamixer -t",
        "tooltip-format": "Playing at {volume}%",
        "scroll-step": 5,
        "format-muted": "",
        "format-icons": {
            "headphone": "",
            "headset": "",
            "default": ["", "", ""],
        },
    },
    "group/tray-expander": {
        "orientation": "inherit",
        "drawer": {
            "transition-duration": 600,
            "children-class": "tray-group-item",
        },
        "modules": ["custom/expand-icon", "tray"],
    },
    "custom/expand-icon": {
        "format": expand_icon,
        "tooltip": False,
        "on-scroll-up": "",
        "on-scroll-down": "",
        "on-scroll-left": "",
        "on-scroll-right": "",
    },
    "custom/screenrecording-indicator": {
        "on-click": "omarchy-capture-screenrecording",
        "exec": "$OMARCHY_PATH/default/waybar/indicators/screen-recording.sh",
        "signal": 8,
        "return-type": "json",
    },
    "custom/idle-indicator": {
        "on-click": "omarchy-toggle-idle",
        "exec": "$OMARCHY_PATH/default/waybar/indicators/idle.sh",
        "signal": 9,
        "return-type": "json",
    },
    "custom/notification-silencing-indicator": {
        "on-click": "omarchy-toggle-notification-silencing",
        "exec": "$OMARCHY_PATH/default/waybar/indicators/notification-silencing.sh",
        "signal": 10,
        "return-type": "json",
    },
    "custom/voxtype": {
        "exec": "omarchy-voxtype-status",
        "return-type": "json",
        "format": "{icon}",
        "format-icons": {
            "idle": "",
            "recording": "󰍬",
            "transcribing": "󰔟",
        },
        "tooltip": True,
        "on-click-right": "omarchy-voxtype-config",
        "on-click": "omarchy-voxtype-model",
    },
    "tray": {
        "icon-size": 12,
        "spacing": 17,
    },
}

if vertical:
    config["width"] = bar_width
else:
    config["height"] = 32

out.write_text(json.dumps(config, indent=2) + "\n")

left = config["modules-left"]
if "hyprland/workspaces" not in left:
  raise SystemExit("BUG: hyprland/workspaces missing from modules-left")
if "clock" not in config["modules-center"]:
  raise SystemExit("BUG: clock missing from modules-center")

print(f"Wrote {out} (position={pos})")
PY

CURRENT_THEME=""
[[ -f $CURRENT_THEME_NAME ]] && CURRENT_THEME=$(tr '[:upper:]' '[:lower:]' <"$CURRENT_THEME_NAME")

if [[ $CURRENT_THEME == "midnight-glass" ]]; then
  ACTIVATE_OUT=$("$THEME_DIR/manage-waybar-config.sh" activate 2>&1) || true
  printf '%s\n' "$ACTIVATE_OUT"

  # activate restarts waybar when the layout file changed; otherwise reload CSS only.
  if [[ $ACTIVATE_OUT == *"Applied Midnight Glass waybar layout"* ]]; then
    :
  else
    "$THEME_DIR/refresh-waybar-style.sh" >/dev/null 2>&1 || true
  fi
fi

echo "waybar position -> $POS"
echo "Edit $POS_FILE or run: $0 <top|bottom|left|right>"
