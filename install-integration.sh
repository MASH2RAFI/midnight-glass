#!/bin/bash
# Install Midnight Glass automation (theme-set hook + wallpaper event trigger).

set -euo pipefail

MG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$MG_ROOT/lib/common.sh"

HOOKS_DIR="$MG_CONFIG/omarchy/hooks/theme-set.d"
POST_BOOT_DIR="$MG_CONFIG/omarchy/hooks/post-boot.d"
SERVICE_DIR="$MG_CONFIG/systemd/user"
HANDLER="$THEME_DIR/hooks/on-wallpaper-change.sh"
PATH_UNIT="$SERVICE_DIR/midnight-glass-wallpaper.path"
SERVICE_UNIT="$SERVICE_DIR/midnight-glass-wallpaper.service"
LEGACY_UNIT="$SERVICE_DIR/midnight-glass-background-watch.service"
BG_WATCH_DIR="$MG_CURRENT"

install -d "$HOOKS_DIR" "$POST_BOOT_DIR" "$SERVICE_DIR"

cat >"$HOOKS_DIR/midnight-glass-adapt" <<EOF
#!/bin/bash
exec "$THEME_DIR/hooks/midnight-glass-adapt" "\$@"
EOF
chmod +x "$HOOKS_DIR/midnight-glass-adapt"

cat >"$POST_BOOT_DIR/midnight-glass-waybar-boot" <<EOF
#!/bin/bash
exec "$THEME_DIR/hooks/midnight-glass-waybar-boot" "\$@"
EOF
chmod +x "$POST_BOOT_DIR/midnight-glass-waybar-boot"

chmod +x "$HANDLER"

cat >"$PATH_UNIT" <<EOF
[Unit]
Description=Midnight Glass wallpaper change trigger
After=graphical-session.target

[Path]
PathChanged=$BG_WATCH_DIR
PathModified=$BG_WATCH_DIR

[Install]
WantedBy=default.target
EOF

cat >"$SERVICE_UNIT" <<EOF
[Unit]
Description=Adapt Midnight Glass colors to wallpaper change

[Service]
Type=oneshot
ExecStart=$HANDLER
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)
PassEnvironment=WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE DISPLAY XDG_CURRENT_DESKTOP
EOF

systemctl --user disable --now midnight-glass-background-watch.service >/dev/null 2>&1 || true
rm -f "$LEGACY_UNIT"

systemctl --user daemon-reload

OMARCHY_DEFAULT_SRC="$MG_OMARCHY_PATH/config/waybar/config.jsonc"
if [[ -f $OMARCHY_DEFAULT_SRC ]]; then
  cp "$OMARCHY_DEFAULT_SRC" "$THEME_DIR/waybar.config.omarchy-default.jsonc"
fi

while IFS= read -r script; do
  chmod +x "$script"
done < <(mg_executable_scripts)
chmod +x "$MG_SCRIPTS"/*.py

echo "Installed Midnight Glass integration:"
echo "  theme-set hook     -> $HOOKS_DIR/midnight-glass-adapt"
echo "  post-boot hook     -> $POST_BOOT_DIR/midnight-glass-waybar-boot"
echo "  wallpaper trigger  -> $PATH_UNIT"
echo "  wallpaper handler  -> $HANDLER"
echo ""
echo "Applying theme now..."
export MIDNIGHT_GLASS_ADAPTING=1
"$THEME_DIR/adapt-from-wallpaper.sh"
"$THEME_DIR/apply-nautilus-theme.sh"
"$THEME_DIR/manage-qt-theme.sh" activate
"$THEME_DIR/sync-waybar-layout.sh"
"$THEME_DIR/sync-theme-assets.sh"
mg_start_watcher
unset MIDNIGHT_GLASS_ADAPTING

echo "Done. Midnight Glass is integrated."
