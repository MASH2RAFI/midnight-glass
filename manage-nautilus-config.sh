#!/bin/bash
# Reversible Nautilus (Omarchy file manager) layout, icons, and GTK styling.
#
#   ./manage-nautilus-config.sh activate
#   ./manage-nautilus-config.sh deactivate
#   ./manage-nautilus-config.sh status

set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/themes/midnight-glass"
ICON_THEME_FILE="$THEME_DIR/icons.theme"
THEME_GTK_CSS="$THEME_DIR/nautilus/gtk.css"
USER_GTK_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
USER_GTK_CSS="$USER_GTK_DIR/gtk.css"
GTK_BACKUP="$THEME_DIR/nautilus/gtk.css.user-backup"
NO_PRIOR_GTK="$THEME_DIR/nautilus/.no-prior-gtk-css"
GSETTINGS_BACKUP="$THEME_DIR/nautilus/gsettings.user-backup"
GSETTINGS_DEFAULT="$THEME_DIR/nautilus/gsettings.omarchy-default"
MARKER="$THEME_DIR/.nautilus-swap-active"

read_icon_theme() {
  tr -d '[:space:]' <"$1"
}

apply_gsettings() {
  python3 - "$THEME_DIR" "apply" <<'PY'
import pathlib, subprocess, sys

theme_dir = pathlib.Path(sys.argv[1])
icon_theme = (theme_dir / "icons.theme").read_text().strip()

prefs = {
    ("org.gnome.desktop.interface", "icon-theme"): icon_theme,
    ("org.gnome.nautilus.preferences", "default-folder-viewer"): "icon-view",
    ("org.gnome.nautilus.preferences", "default-sort-order"): "name",
    ("org.gnome.nautilus.preferences", "default-sort-in-reverse-order"): "false",
    ("org.gnome.nautilus.icon-view", "default-zoom-level"): "large",
    ("org.gnome.nautilus.icon-view", "captions"): "['size', 'type', 'none']",
    ("org.gnome.nautilus.list-view", "use-tree-view"): "false",
    ("org.gnome.nautilus.list-view", "default-visible-columns"): "['name', 'size', 'date_modified']",
}

for (schema, key), value in prefs.items():
    subprocess.run(["gsettings", "set", schema, key, value], check=True)
PY
}

backup_gsettings() {
  python3 - "$GSETTINGS_BACKUP" <<'PY'
import pathlib, subprocess, sys

out = pathlib.Path(sys.argv[1])
keys = [
    ("org.gnome.desktop.interface", "icon-theme"),
    ("org.gnome.nautilus.preferences", "default-folder-viewer"),
    ("org.gnome.nautilus.preferences", "default-sort-order"),
    ("org.gnome.nautilus.preferences", "default-sort-in-reverse-order"),
    ("org.gnome.nautilus.icon-view", "default-zoom-level"),
    ("org.gnome.nautilus.icon-view", "captions"),
    ("org.gnome.nautilus.list-view", "use-tree-view"),
    ("org.gnome.nautilus.list-view", "default-visible-columns"),
]

lines = []
for schema, key in keys:
    value = subprocess.check_output(["gsettings", "get", schema, key], text=True).strip()
    lines.append(f"{schema}\t{key}\t{value}")

out.write_text("\n".join(lines) + "\n")
PY
}

restore_gsettings() {
  local source=$1
  python3 - "$source" <<'PY'
import pathlib, subprocess, sys

path = pathlib.Path(sys.argv[1])
if not path.exists():
    raise SystemExit(0)

for line in path.read_text().splitlines():
    if not line.strip():
        continue
    schema, key, value = line.split("\t", 2)
    subprocess.run(["gsettings", "set", schema, key, value], check=True)
PY
}

activate_gtk_css() {
  mkdir -p "$USER_GTK_DIR"

  if [[ ! -f $MARKER ]]; then
    if [[ -f $USER_GTK_CSS ]]; then
      cp -a "$USER_GTK_CSS" "$GTK_BACKUP"
    else
      : >"$NO_PRIOR_GTK"
    fi
  fi

  cp "$THEME_GTK_CSS" "$USER_GTK_CSS"
}

deactivate_gtk_css() {
  if [[ -f $GTK_BACKUP ]]; then
    cp -a "$GTK_BACKUP" "$USER_GTK_CSS"
  elif [[ -f $NO_PRIOR_GTK ]]; then
    rm -f "$USER_GTK_CSS" "$NO_PRIOR_GTK"
    rmdir "$USER_GTK_DIR" 2>/dev/null || true
  fi
}

activate() {
  command -v gsettings >/dev/null || {
    echo "gsettings is required for Nautilus theming" >&2
    exit 1
  }

  if [[ ! -f $ICON_THEME_FILE || ! -f $THEME_GTK_CSS ]]; then
    echo "Missing Nautilus theme files in $THEME_DIR/nautilus/" >&2
    exit 1
  fi

  if [[ ! -f $MARKER ]]; then
    backup_gsettings
    : >"$MARKER"
  fi

  apply_gsettings
  activate_gtk_css
  echo "Applied Midnight Glass Nautilus layout, icons, and styling"
}

refresh() {
  if [[ ! -f $MARKER ]]; then
    return 0
  fi

  if [[ ! -f $ICON_THEME_FILE || ! -f $THEME_GTK_CSS ]]; then
    echo "Missing Nautilus theme files in $THEME_DIR/nautilus/" >&2
    exit 1
  fi

  apply_gsettings
  activate_gtk_css
}

deactivate() {
  if [[ ! -f $MARKER ]]; then
    return 0
  fi

  if [[ -f $GSETTINGS_BACKUP ]]; then
    restore_gsettings "$GSETTINGS_BACKUP"
  elif [[ -f $GSETTINGS_DEFAULT ]]; then
    restore_gsettings "$GSETTINGS_DEFAULT"
  fi

  deactivate_gtk_css
  rm -f "$MARKER"
  echo "Restored Nautilus settings from before Midnight Glass"
}

status() {
  if [[ -f $MARKER ]]; then
    echo "active"
    echo "  icons: $(read_icon_theme "$ICON_THEME_FILE")"
    echo "  gtk:   $USER_GTK_CSS"
  else
    echo "inactive"
  fi
}

case ${1:-} in
activate) activate ;;
refresh) refresh ;;
deactivate) deactivate ;;
status) status ;;
*)
  echo "Usage: $0 activate|refresh|deactivate|status" >&2
  exit 1
  ;;
esac
