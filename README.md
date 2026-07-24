# Midnight Glass

A **wallpaper-adaptive Omarchy theme** with frosted-glass Hyprland decoration, separated Waybar islands, and coordinated colors across terminals, editors, and Qt apps.

Midnight Glass extracts a palette from your active wallpaper and propagates it through Hyprland borders, Waybar, terminal configs, and Dolphin/Kvantum — without running a full `omarchy theme refresh` or clobbering your personal configs.

---

## Features

- **Wallpaper-driven colors** — palette is extracted from the current Omarchy background and written to `colors.toml`, `waybar.css`, Hyprland borders, and terminal themes
- **Glass Hyprland look** — rounded corners, blur, subtle dimming, and layered opacity rules tuned for readable text
- **Separated Waybar islands** — three frosted modules (left / center / right) with workspace numbers and battery percentage
- **Flexible bar position** — top, bottom, left, or right via `waybar.position` or a single command
- **Reversible swaps** — your original Waybar layout and Qt/Kvantum settings are backed up once and restored when you leave the theme
- **Live wallpaper sync** — a lightweight user service re-adapts colors when you cycle backgrounds
- **Bundled wallpapers** — 17 curated backgrounds included under `backgrounds/`
- **Broad app coverage** — Alacritty, Kitty, Ghostty, btop, Neovim (LazyVim), VS Code/Cursor, and Qt apps via Kvantum

---

## Requirements

| Dependency | Used for |
|---|---|
| [Omarchy](https://github.com/basecamp/omarchy) | Theme system, Waybar integration, hooks |
| Hyprland | Window decoration and blur |
| ImageMagick (`magick` or `convert`) | Wallpaper palette extraction |
| Python 3 | Color math and config generation |
| Kvantum (`kvantum-qt5`) | Dolphin and Qt app theming |
| systemd (user session) | Background wallpaper watcher service |

---

## Installation

### 1. Clone the theme

```bash
git clone https://github.com/MASH2RAFI/midnight-glass.git \
  ~/.config/omarchy/themes/midnight-glass
```

Or copy this folder to `~/.config/omarchy/themes/midnight-glass/`.

### 2. Install backgrounds (optional)

Backgrounds ship inside the theme folder. Omarchy can also use them from the shared backgrounds path:

```bash
mkdir -p ~/.config/omarchy/backgrounds
cp -r ~/.config/omarchy/themes/midnight-glass/backgrounds \
  ~/.config/omarchy/backgrounds/midnight-glass
```

### 3. Run the integration installer

This registers Omarchy hooks and the wallpaper watcher service:

```bash
cd ~/.config/omarchy/themes/midnight-glass
./install-integration.sh
```

### 4. Activate the theme

```bash
omarchy theme set "Midnight Glass"
```

---

## Usage

### Switch wallpapers

Use Omarchy’s normal wallpaper controls. When Midnight Glass is active, colors update automatically via the background watcher.

To adapt manually from a specific image:

```bash
./adapt-from-wallpaper.sh /path/to/wallpaper.jpg
./sync-theme-assets.sh
```

### Change Waybar position

```bash
# One-shot
./set-waybar-position.sh right

# Or edit waybar.position, then apply
./set-waybar-position.sh
```

Supported edges: `top`, `bottom`, `left`, `right`.

### Apply Qt / Dolphin colors

Usually handled automatically. To rebuild and activate manually:

```bash
./apply-qt-theme.sh
```

### Check swap status

```bash
./manage-waybar-config.sh status
```

---

## How it works

```
Wallpaper change
      │
      ▼
adapt-from-wallpaper.sh ──► colors.toml, waybar.css, hyprland.conf, terminals
      │
      ▼
sync-theme-assets.sh ─────► omarchy/current/theme (no full theme refresh)
      │
      ├── sync-waybar-layout.sh ──► reversible Waybar config swap
      └── apply-qt-theme.sh ──────► Kvantum + KDE color scheme
```

**On theme switch**, the `theme-set` hook activates or deactivates Midnight Glass swaps. When you pick another Omarchy theme, your original Waybar config and Qt settings are restored from backups stored inside this theme folder.

**On login**, a post-boot hook re-applies the Waybar layout so workspace numbers are present from the start.

**On wallpaper change**, the `midnight-glass-background-watch` user service detects the new background and re-runs adaptation.

---

## What gets themed

| Component | File(s) |
|---|---|
| Hyprland | `hyprland.conf` |
| Waybar layout | `waybar.config.jsonc` |
| Waybar style | `waybar.css` |
| Color palette | `colors.toml` |
| Alacritty | `alacritty.toml` |
| Kitty | `kitty.conf` |
| Ghostty | `ghostty.conf` |
| btop | `btop.theme` |
| Neovim / LazyVim | `neovim.lua` |
| VS Code / Cursor | `vscode.json` |
| Qt / Dolphin | `qt/MidnightGlass/` (generated via Kvantum) |
| Icons | `icons.theme` |
| Lock screen | `unlock.png` |

---

## Project structure

```
midnight-glass/
├── adapt-from-wallpaper.sh      # Extract palette and rewrite color tokens
├── install-integration.sh       # Install hooks + systemd watcher
├── sync-theme-assets.sh         # Push assets to omarchy/current/theme
├── sync-waybar-layout.sh        # Activate theme Waybar config
├── manage-waybar-config.sh      # Reversible Waybar swap (activate/deactivate)
├── set-waybar-position.sh       # Switch bar edge + regenerate layout
├── apply-qt-theme.sh            # Build and activate Kvantum/KDE colors
├── manage-qt-theme.sh           # Reversible Qt swap (activate/deactivate)
├── midnight-glass-background-watch
├── hooks/                       # Source hooks (installed by install-integration.sh)
├── backgrounds/                 # Bundled wallpapers
├── qt/MidnightGlass/            # Generated Qt/Kvantum theme files
├── hyprland.conf
├── waybar.config.jsonc
├── waybar.css
├── waybar.position
└── colors.toml
```

---

## Switching away from Midnight Glass

```bash
omarchy theme set "<another theme>"
```

The theme-set hook automatically:

- Restores your original `~/.config/waybar/config.jsonc` from `waybar.config.user-backup.jsonc`
- Restores Kvantum and KDE color settings from theme-local backups
- Deactivates the Midnight Glass layout and Qt swaps

To stop the wallpaper watcher:

```bash
systemctl --user disable --now midnight-glass-background-watch.service
```

---

## Non-destructive design

Midnight Glass is built to stay out of your way:

- Waybar and Qt backups live **inside this theme folder**, not scattered across `~/.config`
- Theme assets sync with `sync-theme-assets.sh` instead of `omarchy theme refresh`, avoiding unrelated config resets
- Glass Hyprland rules ship with the theme so other Omarchy themes remain untouched when switching
- Only color tokens are rewritten during adaptation — layout and glass structure stay intact

---

## Troubleshooting

**Colors did not update after a wallpaper change**

```bash
systemctl --user status midnight-glass-background-watch.service
./adapt-from-wallpaper.sh
./sync-theme-assets.sh
```

**Waybar layout looks wrong after login**

```bash
./sync-waybar-layout.sh
```

**Qt apps / Dolphin still use old colors**

```bash
./apply-qt-theme.sh
```

Ensure Kvantum is installed and `KvArcDark` is available at `/usr/share/Kvantum/KvArcDark/`.

**ImageMagick missing**

Install ImageMagick so `magick` or `convert` is on your `PATH`.

---

## Credits

Created by [@MASH2RAFI](https://github.com/MASH2RAFI) for [Omarchy](https://github.com/basecamp/omarchy) on Hyprland.
