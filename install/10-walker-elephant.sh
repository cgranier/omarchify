#!/usr/bin/env bash
# Walker launcher + Elephant backend. Requires 00-apt-omakasui.sh first.
# apt part runs as root; the systemd part runs as the user.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  apt-get install -y walker elephant \
    elephant-desktopapplications elephant-calc elephant-files elephant-menus \
    elephant-providerlist elephant-runner elephant-symbols elephant-todo \
    elephant-unicode elephant-websearch
  # NOTE: elephant-clipboard is intentionally omitted. It watches via
  # `wl-paste --watch`, which needs wlr-data-control / ext-data-control.
  # Mutter implements neither, so it can never populate on GNOME.
  # See ../docs/decisions.md and https://github.com/omakasui/omabuntu/issues/108
  exit 0
fi

elephant service enable
systemctl --user daemon-reload
systemctl --user start elephant.service
