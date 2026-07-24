#!/bin/bash
# Adapt midnight-glass colors from the current Omarchy wallpaper.
# Updates colors.toml, waybar.css tokens, hyprland borders, and terminal glass configs.
# Omarchy-compatible: glass rules stay intact; only color tokens are rewritten.
#
# Usage:
#   ./adapt-from-wallpaper.sh [image]
#   omarchy theme set "Midnight Glass"

set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER="${1:-}"

if [[ -z $WALLPAPER ]]; then
  if [[ -L $HOME/.config/omarchy/current/background ]]; then
    WALLPAPER=$(readlink -f "$HOME/.config/omarchy/current/background")
  elif [[ -f $HOME/.config/omarchy/current/background ]]; then
    WALLPAPER="$HOME/.config/omarchy/current/background"
  fi
fi

if [[ -z $WALLPAPER || ! -f $WALLPAPER ]]; then
  echo "No wallpaper found. Pass an image path or set an Omarchy background." >&2
  exit 1
fi

if ! command -v magick >/dev/null && ! command -v convert >/dev/null; then
  echo "ImageMagick (magick/convert) is required." >&2
  exit 1
fi

MAGICK_BIN=$(command -v magick || command -v convert)

mapfile -t HEXES < <(
  "$MAGICK_BIN" "$WALLPAPER" -resize 160x160 -colors 48 -unique-colors txt:- 2>/dev/null |
    grep -oE '#[0-9A-Fa-f]{6}' | tr 'a-f' 'A-F'
)

if (( ${#HEXES[@]} < 3 )); then
  echo "Could not extract a palette from: $WALLPAPER" >&2
  exit 1
fi

python3 - "$WALLPAPER" "$THEME_DIR" "${HEXES[@]}" <<'PY'
import colorsys, re, sys
from pathlib import Path

wallpaper, theme_dir, *hexes = sys.argv[1:]
theme = Path(theme_dir)

def parse(h):
  h = h.lstrip("#")
  r, g, b = int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255
  hue, sat, val = colorsys.rgb_to_hsv(r, g, b)
  lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
  return h.upper(), lum, sat, hue, (r, g, b)

def to_hex(rgb):
  r, g, b = [max(0, min(255, int(round(c * 255)))) for c in rgb]
  return f"#{r:02X}{g:02X}{b:02X}"

def mix(a, b, t):
  return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))

def lum_of(rgb):
  return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]

def set_lum(rgb, target):
  """Scale RGB toward black/white to hit target luminance."""
  l = lum_of(rgb)
  if abs(l - target) < 1e-6:
    return rgb
  if l < 1e-6:
    return (target, target, target)
  if target < l:
    t = target / l
    return tuple(c * t for c in rgb)
  # lift toward white
  t = (target - l) / (1.0 - l) if l < 1.0 else 1.0
  return mix(rgb, (1.0, 1.0, 1.0), t)

def dull(rgb, sat_scale=0.42, target_lum=None):
  """Desaturate (matte) and optionally retarget luminance."""
  r, g, b = rgb
  h, s, v = colorsys.rgb_to_hsv(r, g, b)
  out = colorsys.hsv_to_rgb(h, min(1.0, s * sat_scale), v)
  if target_lum is not None:
    out = set_lum(out, target_lum)
  return out

def lift(rgb, target_lum):
  return set_lum(rgb, target_lum)

parsed = [parse(h) for h in hexes]
# h,lum,sat,hue,rgb
lightest = max(parsed, key=lambda c: c[1])
max_sat = max(c[2] for c in parsed)
chromatic = max_sat >= 0.18

# Background: darkest sample → mute chroma → deepen (matte charcoal)
bg = min(parsed, key=lambda c: (c[1], c[2]))  # darkest + dullest
bg_rgb = dull(bg[4], sat_scale=0.25, target_lum=min(0.035, max(0.015, bg[1] * 0.55)))

# Foreground: soft, dulled light — readable but not bright white
fg_base = lightest[4] if lightest[1] > 0.2 else (0.78, 0.76, 0.72)
fg_rgb = dull(fg_base, sat_scale=0.35, target_lum=0.72)

# Accent: muted midtone from wallpaper (avoid neon)
acc_cands = [c for c in parsed if 0.12 < c[1] < 0.75]
if chromatic and acc_cands:
  # Prefer moderate saturation (matte), not the most vivid pixel
  accent_src = max(
    acc_cands,
    key=lambda c: (1.0 - abs(c[2] - 0.45)) * (1.0 - abs(c[1] - 0.42)),
  )
  ac_rgb = dull(accent_src[4], sat_scale=0.48, target_lum=0.48)
else:
  base = lightest[4] if lightest[1] > bg[1] + 0.02 else (0.5, 0.5, 0.52)
  ac_rgb = dull(base, sat_scale=0.2, target_lum=0.48)

# Selection: dark muted mid
sel_cands = sorted(parsed, key=lambda c: abs(c[1] - 0.18))
sel_rgb = dull(sel_cands[0][4], sat_scale=0.4, target_lum=0.16)
if abs(lum_of(sel_rgb) - lum_of(bg_rgb)) < 0.06:
  sel_rgb = dull(mix(bg_rgb, fg_rgb, 0.2), sat_scale=0.35, target_lum=0.16)

# Status / ansi: same matte treatment
if chromatic and acc_cands:
  by_chroma = sorted(acc_cands, key=lambda c: c[2] * c[1], reverse=True)
  mid_rgb = dull(by_chroma[min(1, len(by_chroma) - 1)][4], sat_scale=0.45, target_lum=0.42)
  warn_rgb = dull(by_chroma[0][4], sat_scale=0.5, target_lum=0.55)
  crit_rgb = dull(mix(ac_rgb, (0.75, 0.28, 0.22), 0.5), sat_scale=0.55, target_lum=0.42)
else:
  mid_rgb = dull(mix(ac_rgb, fg_rgb, 0.2), sat_scale=0.3, target_lum=0.42)
  warn_rgb = dull(ac_rgb, sat_scale=0.35, target_lum=0.55)
  crit_rgb = dull((0.7, 0.32, 0.28), sat_scale=0.6, target_lum=0.42)

bg_h, fg_h, ac_h, sel_h = to_hex(bg_rgb), to_hex(fg_rgb), to_hex(ac_rgb), to_hex(sel_rgb)
warn, crit, mid = to_hex(warn_rgb), to_hex(crit_rgb), to_hex(mid_rgb)
ac_s, mid_s, sel_s = ac_h[1:], mid[1:], sel_h[1:]

(theme / "colors.toml").write_text(f"""# Palette adapted from the active wallpaper (see adapt-from-wallpaper.sh)
accent = "{ac_h}"
cursor = "{fg_h}"
foreground = "{fg_h}"
background = "{bg_h}"
selection_foreground = "{fg_h}"
selection_background = "{sel_h}"

color0 = "{bg_h}"
color1 = "{crit}"
color2 = "{warn}"
color3 = "{mid}"
color4 = "{ac_h}"
color5 = "{crit}"
color6 = "{mid}"
color7 = "{fg_h}"
color8 = "{sel_h}"
color9 = "{crit}"
color10 = "{warn}"
color11 = "{mid}"
color12 = "{ac_h}"
color13 = "{crit}"
color14 = "{fg_h}"
color15 = "#FFFFFF"
""")

waybar = theme / "waybar.css"
if waybar.exists():
  css = waybar.read_text()
  css = re.sub(r"(@define-color foreground )#[0-9A-Fa-f]{6};", rf"\g<1>{fg_h};", css, count=1)
  css = re.sub(r"(@define-color background )#[0-9A-Fa-f]{6};", rf"\g<1>{bg_h};", css, count=1)
  css = re.sub(r"(@define-color accent )#[0-9A-Fa-f]{6};", rf"\g<1>{ac_h};", css, count=1)
  css = re.sub(
    r"(window#waybar #custom-screenrecording-indicator\.active,\nwindow#waybar #custom-idle-indicator\.active,\nwindow#waybar #custom-notification-silencing-indicator\.active,\nwindow#waybar #custom-voxtype\.recording \{\n  color: )#[0-9A-Fa-f]{6};",
    rf"\g<1>{mid};",
    css,
    count=1,
  )
  css = re.sub(r"(window#waybar #battery\.warning \{\n  color: )#[0-9A-Fa-f]{6};", rf"\g<1>{warn};", css, count=1)
  css = re.sub(
    r"(window#waybar #battery\.critical:not\(\.charging\) \{\n  color: )#[0-9A-Fa-f]{6};",
    rf"\g<1>{crit};",
    css,
    count=1,
  )
  waybar.write_text(css)

hypr = theme / "hyprland.conf"
if hypr.exists():
  conf = hypr.read_text()
  conf = re.sub(
    r"\$activeBorderColor = rgba\([0-9A-Fa-f]{6}ee\) rgba\([0-9A-Fa-f]{6}cc\) 45deg",
    f"$activeBorderColor = rgba({ac_s}ee) rgba({mid_s}cc) 45deg",
    conf,
    count=1,
  )
  conf = re.sub(
    r"\$inactiveBorderColor = rgba\([0-9A-Fa-f]{6}aa\)",
    f"$inactiveBorderColor = rgba({sel_s}aa)",
    conf,
    count=1,
  )
  conf = re.sub(
    r"(shadow \{[\s\S]*?color = )rgba\([0-9A-Fa-f]{6}22\)",
    rf"\g<1>rgba({ac_s}22)",
    conf,
    count=1,
  )
  hypr.write_text(conf)

(theme / "alacritty.toml").write_text(f"""# Midnight Glass — colors + background-only transparency (text stays opaque)

[window]
opacity = 0.40

[colors.primary]
background = "{bg_h}"
foreground = "{fg_h}"

[colors.cursor]
text = "{bg_h}"
cursor = "{fg_h}"

[colors.vi_mode_cursor]
text = "{bg_h}"
cursor = "{fg_h}"

[colors.search.matches]
foreground = "{bg_h}"
background = "{mid}"

[colors.search.focused_match]
foreground = "{bg_h}"
background = "{crit}"

[colors.footer_bar]
foreground = "{bg_h}"
background = "{fg_h}"

[colors.selection]
text = "{fg_h}"
background = "{sel_h}"

[colors.normal]
black = "{bg_h}"
red = "{crit}"
green = "{warn}"
yellow = "{mid}"
blue = "{ac_h}"
magenta = "{crit}"
cyan = "{mid}"
white = "{fg_h}"

[colors.bright]
black = "{sel_h}"
red = "{crit}"
green = "{warn}"
yellow = "{mid}"
blue = "{ac_h}"
magenta = "{crit}"
cyan = "{fg_h}"
white = "#FFFFFF"
""")

(theme / "kitty.conf").write_text(f"""# Midnight Glass — colors + background-only transparency (text stays opaque)
background_opacity 0.40
dynamic_background_opacity yes

foreground {fg_h}
background {bg_h}
selection_foreground {fg_h}
selection_background {sel_h}

cursor {fg_h}
cursor_text_color {bg_h}

active_border_color {ac_h}
active_tab_background {ac_h}

color0 {bg_h}
color1 {crit}
color2 {warn}
color3 {mid}
color4 {ac_h}
color5 {crit}
color6 {mid}
color7 {fg_h}
color8 {sel_h}
color9 {crit}
color10 {warn}
color11 {mid}
color12 {ac_h}
color13 {crit}
color14 {fg_h}
color15 #FFFFFF
""")

(theme / "ghostty.conf").write_text(f"""# Midnight Glass — colors + background-only transparency (text stays opaque)
background-opacity = 0.40

background = {bg_h}
foreground = {fg_h}
cursor-color = {fg_h}
selection-background = {sel_h}
selection-foreground = {fg_h}

palette = 0={bg_h}
palette = 1={crit}
palette = 2={warn}
palette = 3={mid}
palette = 4={ac_h}
palette = 5={crit}
palette = 6={mid}
palette = 7={fg_h}
palette = 8={sel_h}
palette = 9={crit}
palette = 10={warn}
palette = 11={mid}
palette = 12={ac_h}
palette = 13={crit}
palette = 14={fg_h}
palette = 15=#FFFFFF
""")

print(f"Adapted midnight-glass from: {wallpaper}")
print(f"  mode={'chromatic' if chromatic else 'grayscale-fallback'}")
print(f"  background={bg_h}  foreground={fg_h}  accent={ac_h}  selection={sel_h}")
print('Run: omarchy theme set "Midnight Glass"  (or ./install-integration.sh once)')
PY

"$THEME_DIR/apply-qt-theme.sh"
