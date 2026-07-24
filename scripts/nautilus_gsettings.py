#!/usr/bin/env python3
"""Nautilus gsettings backup, apply, and restore for Midnight Glass."""

from __future__ import annotations

import pathlib
import subprocess
import sys

PREFS = {
    ("org.gnome.desktop.interface", "icon-theme"): None,
    ("org.gnome.nautilus.preferences", "default-folder-viewer"): "icon-view",
    ("org.gnome.nautilus.preferences", "default-sort-order"): "name",
    ("org.gnome.nautilus.preferences", "default-sort-in-reverse-order"): "false",
    ("org.gnome.nautilus.icon-view", "default-zoom-level"): "large",
    ("org.gnome.nautilus.icon-view", "captions"): "['size', 'type', 'none']",
    ("org.gnome.nautilus.list-view", "use-tree-view"): "false",
    ("org.gnome.nautilus.list-view", "default-visible-columns"): "['name', 'size', 'date_modified']",
}


def apply(theme_dir: pathlib.Path) -> None:
    icon_theme = (theme_dir / "icons.theme").read_text().strip()
    values = dict(PREFS)
    values[("org.gnome.desktop.interface", "icon-theme")] = icon_theme
    for (schema, key), value in values.items():
        subprocess.run(["gsettings", "set", schema, key, value], check=True)


def refresh_icons(theme_dir: pathlib.Path) -> bool:
    icon_theme = (theme_dir / "icons.theme").read_text().strip()
    current = subprocess.check_output(
        ["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"],
        text=True,
    ).strip().strip("'")
    if current == icon_theme:
        return False
    subprocess.run(
        ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", icon_theme],
        check=True,
    )
    return True


def backup(out_path: pathlib.Path) -> None:
    lines = []
    for schema, key in PREFS:
        value = subprocess.check_output(["gsettings", "get", schema, key], text=True).strip()
        lines.append(f"{schema}\t{key}\t{value}")
    out_path.write_text("\n".join(lines) + "\n")


def restore(source: pathlib.Path) -> None:
    if not source.exists():
        return
    for line in source.read_text().splitlines():
        if not line.strip():
            continue
        schema, key, value = line.split("\t", 2)
        subprocess.run(["gsettings", "set", schema, key, value], check=True)


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("usage: nautilus_gsettings.py apply|backup|restore <paths...>")

    cmd = sys.argv[1]
    if cmd == "apply":
        apply(pathlib.Path(sys.argv[2]))
    elif cmd == "refresh-icons":
        changed = refresh_icons(pathlib.Path(sys.argv[2]))
        raise SystemExit(0 if changed else 2)
    elif cmd == "backup":
        backup(pathlib.Path(sys.argv[2]))
    elif cmd == "restore":
        restore(pathlib.Path(sys.argv[2]))
    else:
        raise SystemExit(f"unknown command: {cmd}")


if __name__ == "__main__":
    main()
