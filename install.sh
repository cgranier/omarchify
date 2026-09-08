#!/usr/bin/env bash
# Omarchify installer. Run from the repo root:  ./install.sh
#
# Steps are also runnable individually — see install/. Each says in its header
# whether it wants root, the user, or both.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$HERE"

[[ $EUID -eq 0 ]] && { echo "Run as your normal user; it will call sudo where needed." >&2; exit 1; }

. /etc/os-release
[[ ${ID:-} == ubuntu ]] || echo "warning: built and tested on Ubuntu; ${PRETTY_NAME:-this} may differ."
[[ ${XDG_SESSION_TYPE:-} == wayland ]] || echo "warning: expects a Wayland session."

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }

step "Package repo (adds packages.omakasui.org, pinned)"
sudo install/00-apt-omakasui.sh

step "Walker + Elephant"
sudo install/10-walker-elephant.sh
install/10-walker-elephant.sh

step "GPaste (clipboard history)"
sudo install/20-gpaste.sh
install/20-gpaste.sh

step "Flameshot from Flathub"
install/30-flameshot-flatpak.sh

step "GNOME settings and keybindings"
install/40-gnome-settings.sh

step "Link configs into ~/.config"
install/50-link-configs.sh

cat <<'DONE'

Done. Log out and back in for the autostart entry and GNOME extension to load.

  Super+Space          launcher
  Super+K              every keybinding (selecting one runs it)
  Alt+Super+Space      menu
  Super+Ctrl+V         clipboard history

Optional:
  cp config/xcompose/personal.example config/xcompose/personal   # then edit
  source shell/functions.zsh                                     # extra shell helpers
DONE
