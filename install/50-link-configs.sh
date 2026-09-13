#!/usr/bin/env bash
# Symlink configs out of the repo, per the repo's "source of truth" principle.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

mkdir -p ~/.config/walker/themes ~/.config/elephant ~/.local/bin \
         ~/.config/systemd/user

ln -snf "$HERE/config/walker/config.toml"                  ~/.config/walker/config.toml
ln -snf "$HERE/config/walker/themes/omakub-default"        ~/.config/walker/themes/omakub-default
for f in calc desktopapplications symbols; do
  ln -snf "$HERE/config/elephant/$f.toml"                  ~/.config/elephant/$f.toml
done
# every helper in home/bin, so adding one needs no change here
for b in "$HERE"/bin/*; do
  ln -snf "$b" ~/.local/bin/"$(basename "$b")"
done

# A real user service, not an autostart .desktop: GNOME wraps those in a
# transient scope that cannot carry Restart=.
ln -snf "$HERE/systemd/walker.service" ~/.config/systemd/user/walker.service
systemctl --user daemon-reload
systemctl --user enable walker.service

# ~/.XCompose is generated self-contained (nested includes proved unreliable to
# debug); the generator also restarts ibus, which caches the table at startup.
"$HERE/bin/omarchify-xcompose-build"
