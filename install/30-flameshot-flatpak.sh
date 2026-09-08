#!/usr/bin/env bash
# Flameshot from Flathub. Ubuntu's 12.1.0 deb cannot capture on GNOME 45+:
# the portal must show a consent dialog, and GNOME only lets the *focused*
# app raise one, which a tray/hotkey-triggered tool never is.
# Pre-granting the portal permission is what actually fixes it.
set -euo pipefail

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y --noninteractive flathub org.flameshot.Flameshot

# Skip the portal access dialog entirely.
flatpak permission-set screenshot screenshot org.flameshot.Flameshot yes

echo "If the Ubuntu deb is still installed, remove it:  sudo apt remove flameshot"
