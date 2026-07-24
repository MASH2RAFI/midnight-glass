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
./apply-nautilus-theme.sh
```

Omarchy opens **Nautilus** (Super+Shift+F), not Dolphin. Midnight Glass applies:

- **Icons** — picks a matching `Yaru-*-dark` icon theme from the wallpaper accent hue; updates live via gsettings when possible
- **Layout** — large icon grid with size/type captions under each icon
- **Glass styling** — dark sidebar, header, and view via `~/.config/gtk-4.0/gtk.css`; colors adapt from the wallpaper and reload when Nautilus is open

### Lock screen / Omarchy Unlocks menu

Omarchy’s **Unlocks** picker (Omarchy menu → Unlock) lists themes that have **`preview-unlock.png`**, not `unlock.png` alone. Midnight Glass generates both on every wallpaper adapt:

- **`unlock-source.png`** — your master OMARCHY logo (edit this to change the shape)
- **`unlock.png`** — Plymouth/SDDM logo, recolored to the adaptive accent
- **`preview-unlock.png`** — 1920×1080 menu preview mockup (background + UI + logo)

Apply a generated unlock to boot/login:

```bash
omarchy-plymouth-set-by-theme midnight-glass
```

Or pick **Midnight Glass** from the Omarchy Unlocks menu after running `./adapt-from-wallpaper.sh` once.

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
adapt-from-wallpaper.sh ──► colors.toml, waybar.css, icons.theme, nautilus/gtk.css, hyprland.conf, terminals
      │
      ▼
sync-theme-assets.sh ─────► omarchy/current/theme + refresh-theme-clients.sh
      │
      ├── refresh-theme-clients.sh ► waybar → terminals → Qt → Hyprland → Nautilus
      └── apply-qt-theme.sh ──────► Kvantum + KDE color scheme (during adapt)
```

**On theme switch**, the `theme-set` hook activates or deactivates Midnight Glass swaps. When you pick another Omarchy theme, your original Waybar config and Qt settings are restored from backups stored inside this theme folder.

**On login**, a post-boot hook re-applies the Waybar layout so workspace numbers are present from the start.

**On wallpaper change**, the watcher re-adapts and runs **`refresh-theme-clients.sh`**, which updates open apps in stages (~80ms apart) so the palette shift feels smooth:

1. **Waybar** — CSS cross-fade (~420ms) via SIGUSR2  
2. **Terminals** — Alacritty / Kitty / Ghostty / Foot reload configs in place  
3. **Qt apps** — Kvantum + KDE color scheme refresh  
4. **Hyprland** — borders, blur, and opacity rules (`hyprctl reload`)  
5. **Nautilus** — animated close/open when already running  

Wallpaper image swaps are still handled by Omarchy’s `swaybg` (instant cut). Hyprland uses longer `matteOut` fade/layer/border animations from `hyprland.conf`.

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
| Lock screen | `unlock.png` (generated), `preview-unlock.png` (menu preview), `unlock-source.png` (master logo) |

---

## Project structure

```
midnight-glass/
├── adapt-from-wallpaper.sh      # Extract palette and rewrite color tokens
├── install-integration.sh       # Install hooks + systemd watcher
├── sync-theme-assets.sh         # Push assets to omarchy/current/theme
├── sync-waybar-layout.sh        # Activate theme Waybar config (layout changes)
├── refresh-theme-clients.sh     # Staged smooth refresh for all open apps
├── refresh-waybar-style.sh      # Waybar SIGUSR2 + CSS cross-fade
├── refresh-nautilus-theme.sh    # Nautilus sync + animated restart
├── run-in-graphical-session.sh  # hyprctl dispatch helper for background services
├── nautilus/restart-for-theme-refresh.sh
├── generate-unlock-assets.sh    # Build unlock.png + preview-unlock.png
├── unlock-source.png            # Master logo (orange OMARCHY pixel art)
├── manage-waybar-config.sh      # Reversible Waybar swap (activate/deactivate)
├── manage-dolphin-config.sh     # Reversible Dolphin layout + icon swap
├── apply-dolphin-theme.sh       # Apply Dolphin layout and icons
├── set-waybar-position.sh       # Switch bar edge + regenerate layout
├── apply-qt-theme.sh            # Build and activate Kvantum/KDE colors
├── manage-qt-theme.sh           # Reversible Qt swap (activate/deactivate)
├── midnight-glass-background-watch
├── hooks/                       # Source hooks (installed by install-integration.sh)
├── backgrounds/                 # Bundled wallpapers
├── dolphin/                     # Dolphin layout + icon backups
├── icons.theme                  # KDE/GNOME icon theme name while active
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
- Falls back to `waybar.config.omarchy-default.jsonc` if the backup is missing or looks like a Midnight Glass layout
- Restores Dolphin layout from `dolphin/dolphinrc.user-backup` (or removes the layout file if Dolphin was never configured before)
- Restores KDE/GNOME icon theme from theme-local backup, or Omarchy default `Yaru-blue`
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
- Only configs that differ from Midnight Glass are backed up (never a left/right dock layout)
- Theme switch restores the top-bar Omarchy default when the backup is invalid
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
