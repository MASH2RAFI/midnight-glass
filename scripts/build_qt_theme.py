#!/usr/bin/env python3
"""Build Kvantum + KDE color files from colors.toml."""

import re, sys
from pathlib import Path

colors_file, base_kv, out_kv, out_scheme, scheme_name = sys.argv[1:6]

def load_colors(path: Path) -> dict[str, str]:
  colors: dict[str, str] = {}
  for line in path.read_text().splitlines():
    line = line.split("#", 1)[0].strip()
    if not line or "=" not in line:
      continue
    key, value = line.split("=", 1)
    key = key.strip()
    value = value.strip().strip('"').strip("'")
    if value.startswith("#"):
      colors[key] = value.upper()
  return colors

def rgb(hex_color: str) -> str:
  h = hex_color.lstrip("#")
  return f"{int(h[0:2], 16)},{int(h[2:4], 16)},{int(h[4:6], 16)}"

def alpha_hex(hex_color: str, alpha: str) -> str:
  return f"{hex_color}{alpha}"

c = load_colors(Path(colors_file))
bg = c.get("background", "#060707")
fg = c.get("foreground", "#A3BDBD")
ac = c.get("accent", "#5F8282")
panel = c.get("selection_background", c.get("color8", "#212B2B"))
mid = c.get("color3", ac)
warn = c.get("color2", ac)
crit = c.get("color1", "#7B6764")
ok = c.get("color10", warn)
hover = c.get("color4", ac)

general_colors = f"""[GeneralColors]
window.color={bg}
base.color={panel}
alt.base.color={bg}
button.color={panel}
light.color={panel}
mid.light.color={panel}
dark.color={bg}
mid.color={panel}
highlight.color={ac}
inactive.highlight.color={hover}
text.color={alpha_hex(fg.lstrip('#'), 'd8')}
window.text.color={fg}
button.text.color={fg}
disabled.text.color={alpha_hex(fg.lstrip('#'), '45')}
tooltip.text.color={fg}
highlight.text.color={bg}
link.color={ac}
link.visited.color={crit}
progress.indicator.text.color={fg}
"""

base = Path(base_kv).read_text()
if "[GeneralColors]" in base:
  base = re.sub(r"\[GeneralColors\][\s\S]*?(?=\n\[|\Z)", general_colors.rstrip() + "\n", base, count=1)
else:
  base = general_colors + "\n" + base

fg_plain = fg.lstrip("#")
kv = re.sub(r"transparent_dolphin_view=false", "transparent_dolphin_view=true", base, count=1)
kv = re.sub(r"layout_margin=\d+", "layout_margin=6", kv, count=1)
kv = re.sub(r"layout_spacing=\d+", "layout_spacing=4", kv, count=1)
kv = re.sub(r"toolbar_icon_size=\d+", "toolbar_icon_size=22", kv, count=1)
kv = re.sub(r"small_icon_size=\d+", "small_icon_size=16", kv, count=1)
kv = re.sub(r"large_icon_size=\d+", "large_icon_size=32", kv, count=1)
kv = re.sub(
  r"(\[ItemView\][\s\S]*?text\.normal\.color=)#[0-9A-Fa-f]{6,8}",
  rf"\g<1>#{fg_plain}c8",
  kv,
  count=1,
)
kv = re.sub(
  r"(\[HeaderSection\][\s\S]*?text\.focus\.color=)#[0-9A-Fa-f]{6}",
  rf"\g<1>{ac}",
  kv,
  count=1,
)
Path(out_kv).write_text(kv)

def section(name: str, bg_hex: str, fg_hex: str = fg, accent_hex: str = ac) -> str:
  bg_rgb, fg_rgb, accent_rgb = rgb(bg_hex), rgb(fg_hex), rgb(accent_hex)
  h = fg_hex.lstrip("#")
  fr, fg, fb = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
  inactive = f"{int(fr * 0.72)},{int(fg * 0.72)},{int(fb * 0.72)}"
  return f"""[{name}]
BackgroundAlternate={bg_rgb}
BackgroundNormal={bg_rgb}
DecorationFocus={rgb(ac)}
DecorationHover={rgb(hover)}
ForegroundActive={fg_rgb}
ForegroundInactive={inactive}
ForegroundLink={accent_rgb}
ForegroundNegative={rgb(crit)}
ForegroundNeutral={rgb(mid)}
ForegroundNormal={fg_rgb}
ForegroundPositive={rgb(ok)}
ForegroundVisited={rgb(crit)}
"""

scheme = "\n".join(
  [
    section("Colors:Button", panel),
    section("Colors:Selection", ac, bg, ac),
    section("Colors:Tooltip", panel),
    section("Colors:View", bg),
    section("Colors:Window", bg),
    section("Colors:Header", panel),
    f"""[General]
ColorScheme={scheme_name}
Name={scheme_name}
shadeSortColumn=true

[KDE]
contrast=0

[WM]
activeBackground={rgb(bg)}
activeBlend={rgb(bg)}
activeForeground={rgb(fg)}
inactiveBackground={rgb(bg)}
inactiveBlend={rgb(bg)}
inactiveForeground={rgb(panel)}
""",
  ]
)

Path(out_scheme).write_text(scheme)