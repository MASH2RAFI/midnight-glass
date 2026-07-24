#!/bin/bash
# Install Midnight Glass automation (theme-set hook + wallpaper watcher).
#
# Usage:
#   ./install-integration.sh

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
HOOKS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks/theme-set.d"
POST_BOOT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks/post-boot.d"
SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_FILE="$SERVICE_DIR/midnight-glass-background-watch.service"

install -d "$HOOKS_DIR" "$POST_BOOT_DIR" "$SERVICE_DIR"
install -m 755 "$THEME_DIR/hooks/midnight-glass-adapt" "$HOOKS_DIR/midnight-glass-adapt"
install -m 755 "$THEME_DIR/hooks/midnight-glass-waybar-boot" "$POST_BOOT_DIR/midnight-glass-waybar-boot"
install -m 755 "$THEME_DIR/hooks/midnight-glass-background-watch" "$THEME_DIR/midnight-glass-background-watch"

cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=Midnight Glass wallpaper color adaptation
After=graphical-session.target

[Service]
ExecStart=$THEME_DIR/midnight-glass-background-watch
Restart=always
RestartSec=3
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)
PassEnvironment=WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE DISPLAY XDG_CURRENT_DESKTOP

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now midnight-glass-background-watch.service

OMARCHY_DEFAULT_SRC="${OMARCHY_PATH:-$HOME/.local/share/omarchy}/config/waybar/config.jsonc"
if [[ -f $OMARCHY_DEFAULT_SRC ]]; then
  cp "$OMARCHY_DEFAULT_SRC" "$THEME_DIR/waybar.config.omarchy-default.jsonc"
fi

chmod +x "$THEME_DIR/adapt-from-wallpaper.sh" \
  "$THEME_DIR/apply-dolphin-theme.sh" \
  "$THEME_DIR/apply-nautilus-theme.sh" \
  "$THEME_DIR/apply-qt-theme.sh" \
  "$THEME_DIR/apply-waybar-prefs.sh" \
  "$THEME_DIR/manage-dolphin-config.sh" \
  "$THEME_DIR/manage-nautilus-config.sh" \
  "$THEME_DIR/manage-qt-theme.sh" \
  "$THEME_DIR/manage-waybar-config.sh" \
  "$THEME_DIR/set-waybar-position.sh" \
  "$THEME_DIR/sync-theme-assets.sh" \
  "$THEME_DIR/sync-waybar-layout.sh" \
  "$THEME_DIR/refresh-theme-clients.sh" \
  "$THEME_DIR/refresh-waybar-style.sh" \
  "$THEME_DIR/refresh-nautilus-theme.sh" \
  "$THEME_DIR/run-in-graphical-session.sh" \
  "$THEME_DIR/nautilus/restart-for-theme-refresh.sh" \
  "$THEME_DIR/generate-unlock-assets.sh" \
  "$THEME_DIR/install-integration.sh"

echo "Installed Midnight Glass integration:"
echo "  theme-set hook  -> $HOOKS_DIR/midnight-glass-adapt"
echo "  post-boot hook  -> $POST_BOOT_DIR/midnight-glass-waybar-boot"
echo "  wallpaper watch -> $SERVICE_FILE"
echo ""
echo "Applying theme now..."
export MIDNIGHT_GLASS_ADAPTING=1
"$THEME_DIR/adapt-from-wallpaper.sh"
"$THEME_DIR/sync-theme-assets.sh"
"$THEME_DIR/sync-waybar-layout.sh"
"$THEME_DIR/apply-qt-theme.sh"
"$THEME_DIR/apply-nautilus-theme.sh"
unset MIDNIGHT_GLASS_ADAPTING

echo "Done. Waybar, Nautilus, and Qt colors track Midnight Glass reversibly."
