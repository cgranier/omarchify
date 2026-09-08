#!/usr/bin/env bash
# Add the Omakasui package repo — the ONLY source of libgtk4-layer-shell0 for noble.
# Deliberately excludes core.omakasui.org (the omakub-* metapackages + distro glue).
# Run as root.
set -euo pipefail

curl -fsSL https://keyrings.omakasui.org/omakasui-packages.gpg.key \
  | gpg --dearmor | tee /usr/share/keyrings/omakasui-packages.gpg > /dev/null
chmod 644 /usr/share/keyrings/omakasui-packages.gpg

codename=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
cat > /etc/apt/sources.list.d/omakasui-packages.list <<LIST
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/omakasui-packages.gpg] https://packages.omakasui.org $codename main
LIST

# Pin: this third-party repo may ONLY supply walker/elephant/layer-shell.
cat > /etc/apt/preferences.d/omakasui-packages <<'PREF'
Package: *
Pin: release o=omakasui
Pin-Priority: 1

Package: walker elephant elephant-* libgtk4-layer-shell0
Pin: release o=omakasui
Pin-Priority: 500
PREF

apt-get update
