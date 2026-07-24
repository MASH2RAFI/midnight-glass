Midnight Glass — Omarchy theme (portable copy)

Install on another Omarchy system:
  1. Copy this folder to ~/.config/omarchy/themes/midnight-glass/
  2. Copy backgrounds/ to ~/.config/omarchy/backgrounds/midnight-glass/
     (or keep backgrounds/ inside the theme folder)
  3. Run: ./install-integration.sh
  4. Run: omarchy theme set "Midnight Glass"

Non-destructive behavior:
  - Waybar layout lives in this folder as waybar.config.jsonc
  - Your original ~/.config/waybar/config.jsonc is backed up once to
    waybar.config.user-backup.jsonc and restored when you switch themes
  - Wallpaper changes use sync-theme-assets.sh (not omarchy theme refresh)
  - Login hook re-applies the layout so workspace numbers are present at startup

What install-integration.sh sets up:
  - Reversible waybar + Qt theme swaps
  - Workspace numbers and battery percentage in all bar positions
  - Wallpaper-driven colors (auto-adapts when you cycle backgrounds)
  - Dolphin / Qt app colors via Kvantum

Optional:
  ~/.config/omarchy/themes/midnight-glass/set-waybar-position.sh right
  ~/.config/omarchy/themes/midnight-glass/adapt-from-wallpaper.sh
