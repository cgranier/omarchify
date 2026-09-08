#!/usr/bin/env bash
# Clipboard history via GPaste. Chosen over Clipboard Indicator because
# gpaste-client is scriptable, which lets it be bridged into Walker.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  apt-get install -y gnome-shell-extension-gpaste   # pulls gpaste-2 + gir1.2-gpaste-2
  exit 0
fi

gpaste-client start < /dev/null
gsettings set org.gnome.GPaste track-changes true

# The Shell only sees a system extension after it rescans, so `gnome-extensions
# enable` fails right after install; write the key directly instead.
if ! gnome-extensions enable GPaste@gnome-shell-extensions.gnome.org 2>/dev/null; then
  cur=$(gsettings get org.gnome.shell enabled-extensions)
  case $cur in
    *GPaste*) ;;
    *) gsettings set org.gnome.shell enabled-extensions "${cur%]*}, 'GPaste@gnome-shell-extensions.gnome.org']" ;;
  esac
fi
