#!/usr/bin/env bash
# Optional: build and install Omawrite, a dead-simple Qt6 Markdown writing app.
#   https://github.com/omacom/omawrite  (MIT)
#
# Upstream ships an Arch package only. This builds from source. Nothing about
# the app is Arch- or Hyprland-specific: it's Qt6 and uses xdg-desktop-portal
# for file dialogs and D-Bus for theme detection.
#
# Two wrinkles on Ubuntu:
#   1. Arch's qt6-declarative is one package; Debian/Ubuntu split it into ~40
#      qml6-module-* packages, so the README's dependency list doesn't translate.
#   2. Ubuntu 24.04 ships Qt 6.4.2, and src/systemtheme.cpp uses Qt::ColorScheme
#      and QStyleHints::colorSchemeChanged, both Qt 6.5+. patches/ guards them.
#      Harmless here: detectDarkMode() asks the portal first and only falls back
#      to the Qt API, and live updates arrive over the portal's SettingChanged.
#
#   sudo install/60-omawrite.sh    # dependencies
#   install/60-omawrite.sh         # clone, patch if needed, build, install
set -euo pipefail

SRC=${OMAWRITE_SRC:-$HOME/src/omawrite}
REPO=https://github.com/omacom/omawrite.git

if [[ $EUID -eq 0 ]]; then
  apt-get install -y \
    build-essential qt6-base-dev qt6-declarative-dev \
    qml6-module-qtquick-controls qml6-module-qtquick-layouts \
    qml6-module-qtquick-window qml6-module-qtquick-dialogs \
    qml6-module-qtquick-templates qml6-module-qtqml-workerscript
  exit 0
fi

command -v qmake6 >/dev/null || { echo "qmake6 missing — run: sudo $0" >&2; exit 1; }
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if [[ -d $SRC/.git ]]; then
  git -C "$SRC" pull --ff-only
else
  mkdir -p "$(dirname "$SRC")"
  git clone "$REPO" "$SRC"
fi
cd "$SRC"

qt_version=$(qmake6 -query QT_VERSION)
if [[ $(printf '%s\n6.5.0\n' "$qt_version" | sort -V | head -1) == "$qt_version" && $qt_version != 6.5.0 ]]; then
  echo "Qt $qt_version < 6.5 — applying compatibility patch"
  git checkout -- src/systemtheme.cpp 2>/dev/null || true
  patch -p1 < "$HERE/patches/omawrite-qt6.4-compat.patch"
else
  echo "Qt $qt_version — no patch needed"
fi

qmake6 omawrite.pro
make -j"$(nproc)"

install -Dm755 omawrite ~/.local/bin/omawrite
install -Dm644 pkgbuild/omawrite.svg ~/.local/share/icons/hicolor/scalable/apps/omawrite.svg
# Exec must be absolute: ~/.local/bin is not in the GNOME session PATH.
sed "s|^Exec=omawrite %f|Exec=$HOME/.local/bin/omawrite %f|" \
  pkgbuild/omawrite.desktop > ~/.local/share/applications/omawrite.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor 2>/dev/null || true

echo "Installed. Bind it if you like, matching Omarchy:"
echo "  omarchify-keybinding-add 'Omawrite' \"\$HOME/.local/bin/omawrite\" '<Super><Shift>w' omawrite"
