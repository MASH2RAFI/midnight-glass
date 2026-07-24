# Midnight Glass

Wallpaper-adaptive Omarchy theme with frosted-glass Hyprland decoration, separated Waybar islands, and coordinated colors across terminals, Nautilus, and Qt apps.

All automation is **non-destructive**: your original Waybar layout and app settings are backed up inside this theme folder and restored when you switch away.

---

## Quick start

```bash
cd ~/.config/omarchy/themes/midnight-glass
./install-integration.sh
omarchy theme set "Midnight Glass"
```

---

## Architecture

```
hooks/                          Omarchy integration entry points
├── midnight-glass-adapt        theme-set: adapt + activate swaps
├── midnight-glass-waybar-boot  post-boot: ensure waybar layout
└── on-wallpaper-change.sh       One-shot adapt handler (systemd triggered)

lib/common.sh                   Shared helpers (paths, refresh, session)

scripts/                        Python logic
├── adapt_palette.py            Wallpaper → colors.toml + token rewrites
├── build_qt_theme.py             colors.toml → Kvantum/KDE files
└── nautilus_gsettings.py       Nautilus gsettings backup/apply/restore

User-facing commands
├── adapt-from-wallpaper.sh     Extract palette + regenerate themed files
├── sync-theme-assets.sh        Copy to omarchy/current/theme + refresh clients
├── refresh-theme-clients.sh    Staged smooth reload (waybar → terminals → Qt → hypr → nautilus)
├── install-integration.sh      Install hooks + systemd watcher
├── set-waybar-position.sh      Generate + apply waybar layout
├── manage-{waybar,qt,nautilus}-config.sh   Reversible config swaps
├── apply-{nautilus,qt}-theme.sh           Activate themed app configs
├── build-qt-theme.sh           Generate Qt/Kvantum files only
└── generate-unlock-assets.sh   Plymouth unlock menu previews
```

### Wallpaper change flow

Omarchy updates `~/.config/omarchy/current/background` when you cycle wallpapers. A **systemd path unit** watches `~/.config/omarchy/current/` (the symlink target change does not reliably trigger inotify on the link itself) and runs `on-wallpaper-change.sh` once per change:

1. `midnight-glass-wallpaper.path` — fires on symlink change  
2. `on-wallpaper-change.sh` — `adapt-from-wallpaper.sh` + `sync-theme-assets.sh`  
3. `refresh-theme-clients.sh` — staged smooth reload of open apps  

The path unit is **enabled only while Midnight Glass is active** (started/stopped by the theme-set hook).

```bash
systemctl --user status midnight-glass-wallpaper.path
journalctl --user -u midnight-glass-wallpaper.service -f
```

Tune staging: `MIDNIGHT_GLASS_STAGE_SEC=0.15` (skipped automatically during wallpaper adapts).

### Resource efficiency

The theme avoids redundant work at each layer:

| Layer | Optimization |
|-------|----------------|
| **Watcher** | systemd path unit (event-driven, no poll loop) |
| **Adapt** | `.palette-hash` skips file writes, Qt build, and unlock ImageMagick when colors are unchanged |
| **Unlock assets** | `.unlock-assets-hash` skips ~15 ImageMagick calls when bg/fg/accent match |
| **Sync** | `cmp` before copy; skips client refresh entirely when no assets changed |
| **Refresh** | Reloads only what changed (Waybar CSS, terminals, Hyprland, Qt, Nautilus) |
| **Qt** | Skips `kbuildsycoca5` when installed files are identical; incremental rebuild during adapts |
| **Nautilus** | Refresh updates icon/CSS only when different; skips restart when nothing changed |

During wallpaper adapts, staging sleeps are skipped (`MIDNIGHT_GLASS_ADAPTING=1`). For manual refreshes you can also set `MIDNIGHT_GLASS_FAST_REFRESH=1`.

---

## Waybar

- Layout: `waybar.config.jsonc` (generated from `waybar.position`)
- Style: `waybar.css` with glass islands and 420ms color transitions
- Reversible swap: `manage-waybar-config.sh` backs up your config to `waybar.config.user-backup.jsonc`

```bash
./set-waybar-position.sh left    # or top | bottom | right
./manage-waybar-config.sh status
```

---

## Nautilus (Omarchy file manager)

- Icons: adaptive `Yaru-*-dark` from wallpaper hue (`icons.theme`)
- Layout: large icon view via gsettings
- Glass CSS: `nautilus/gtk.css` → `~/.config/gtk-4.0/gtk.css`

```bash
./apply-nautilus-theme.sh
./manage-nautilus-config.sh status
```

---

## Qt / Kvantum

Generated under `qt/MidnightGlass/` from `colors.toml`. Reversible via `manage-qt-theme.sh`.

```bash
./apply-qt-theme.sh              # build + activate
./build-qt-theme.sh              # generate only
```

---

## Lock screen / Unlocks menu

Omarchy’s **Unlocks** picker requires **`preview-unlock.png`**. Generated alongside `unlock.png` from `unlock-source.png`:

```bash
./generate-unlock-assets.sh
omarchy-plymouth-set-by-theme midnight-glass
```

---

## Static assets (not wallpaper-adapted)

These ship with the theme but are **not** rewritten by `adapt-from-wallpaper.sh`:

- `btop.theme`, `neovim.lua`, `vscode.json`

---

## Deprecated shims

- `apply-dolphin-theme.sh` → `apply-nautilus-theme.sh`
- `apply-waybar-prefs.sh` → `set-waybar-position.sh`

---

## Switching away

When you pick another Omarchy theme, the theme-set hook should run `deactivate-all` automatically (Waybar layout, Nautilus CSS/icons, Qt/Kvantum, wallpaper watcher).

If remnants remain (left bar, glass Nautilus, old colors):

```bash
~/.config/omarchy/themes/midnight-glass/deactivate-all.sh
```

Then re-apply your current theme so Omarchy refreshes its own assets:

```bash
omarchy theme set "$(cat ~/.config/omarchy/current/theme.name)"
```

Re-install integration after theme updates so hooks use the correct paths:

```bash
~/.config/omarchy/themes/midnight-glass/install-integration.sh
```

---

## Requirements

| Dependency | Purpose |
|---|---|
| Omarchy + Hyprland | Theme system, compositor |
| ImageMagick | Palette extraction, unlock assets |
| Python 3 | Color math, gsettings, Qt generation |
| Kvantum | Qt app theming |
| systemd (user) | Wallpaper watcher |
