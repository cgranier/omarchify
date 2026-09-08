#!/usr/bin/env bash
# Symlink configs out of the repo, per the repo's "source of truth" principle.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)   # repo root

mkdir -p ~/.config/walker/themes ~/.config/elephant ~/.local/bin \
         ~/.config/autostart ~/.config/systemd/user/app-walker@autostart.service.d

ln -snf "$HERE/config/walker/config.toml"                  ~/.config/walker/config.toml
ln -snf "$HERE/config/walker/themes/omakub-default"        ~/.config/walker/themes/omakub-default
for f in calc desktopapplications symbols; do
  ln -snf "$HERE/config/elephant/$f.toml"                  ~/.config/elephant/$f.toml
done
# every helper in home/bin, so adding one needs no change here
for b in "$HERE"/bin/*; do
  ln -snf "$b" ~/.local/bin/"$(basename "$b")"
done

ln -snf "$HERE/autostart/walker.desktop"                   ~/.config/autostart/walker.desktop
ln -snf "$HERE/systemd/app-walker@autostart.service.d/restart.conf" \
        ~/.config/systemd/user/app-walker@autostart.service.d/restart.conf

# ~/.XCompose is generated self-contained (nested includes proved unreliable to
# debug); the generator also restarts ibus, which caches the table at startup.
"$HERE/bin/omarchify-xcompose-build"
