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

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now midnight-glass-background-watch.service

chmod +x "$THEME_DIR/adapt-from-wallpaper.sh" \
  "$THEME_DIR/apply-qt-theme.sh" \
  "$THEME_DIR/apply-waybar-prefs.sh" \
  "$THEME_DIR/manage-qt-theme.sh" \
  "$THEME_DIR/manage-waybar-config.sh" \
  "$THEME_DIR/set-waybar-position.sh" \
  "$THEME_DIR/sync-theme-assets.sh" \
  "$THEME_DIR/sync-waybar-layout.sh" \
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
unset MIDNIGHT_GLASS_ADAPTING

echo "Done. Waybar layout is reversible; workspace numbers persist at login and on wallpaper changes."
