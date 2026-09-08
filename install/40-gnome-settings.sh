#!/usr/bin/env bash
# GNOME-side settings. This layer is invisible in app configs and is the part
# most easily missed when cherry-picking from Omabuntu.
#
# Safe to re-run: it rewrites the whole custom-keybindings list each time.
#
# Application choices come from config/apps.conf, or the environment, or are
# auto-detected. See that file to change them.
set -euo pipefail

# Compose key: 'compose:ralt' by default, 'none' to leave xkb-options alone.
case ${OMARCHIFY_COMPOSE:-compose:ralt} in
  none) OMARCHIFY_COMPOSE_OPT="[]" ;;
  *)    OMARCHIFY_COMPOSE_OPT="['${OMARCHIFY_COMPOSE:-compose:ralt}']" ;;
esac

# --- window management (from Omabuntu install/config/gnome/) ---
gsettings set org.gnome.mutter center-new-windows true       # else Walker opens off-centre
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.keybindings close                        "['<Super>w']"
gsettings set org.gnome.desktop.wm.keybindings maximize                     "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings begin-resize                 "['<Super>BackSpace']"
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen            "['<Shift>F11']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source          "['<Shift><Super>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super><Alt>space']"
# Compose on Right Alt (Omabuntu uses compose:caps; Right Alt keeps Caps Lock and
# is far less prone to stray presses, since Compose swallows the keys after it).
# Set OMARCHIFY_COMPOSE=none to skip, or to any xkb option e.g. compose:caps.
#
# Caveat: if this machine receives its input from another over Deskflow/Synergy/
# Barrier, compose sequences will never resolve — the injected modifier events
# interrupt them. See docs/decisions.md.
gsettings set org.gnome.desktop.input-sources xkb-options                   "${OMARCHIFY_COMPOSE_OPT}"
for i in 1 2 3 4 5 6; do
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
done
for i in 1 2 3 4 5 6 7 8 9; do
  gsettings set org.gnome.shell.keybindings switch-to-application-$i "['<Alt>$i']"
done
# free these up for the custom bindings below
for k in terminal home www help; do
  gsettings set org.gnome.settings-daemon.plugins.media-keys "$k" "[]"
done

# --- application choices ------------------------------------------------------
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=/dev/null
[[ -f $HERE/config/apps.conf ]] && source "$HERE/config/apps.conf"

first_present() { for c in "$@"; do command -v "$c" >/dev/null 2>&1 && { echo "$c"; return; }; done; }

TERMINAL=${TERMINAL:-$(first_present alacritty ghostty kitty gnome-terminal xdg-terminal-exec)}
BROWSER=${BROWSER:-$(first_present firefox chromium google-chrome brave-browser)}
FILE_MANAGER=${FILE_MANAGER:-$(first_present nautilus nemo thunar dolphin)}
EDITOR_CMD=${EDITOR_CMD:-$(first_present nvim vim helix)}
ACTIVITY=${ACTIVITY:-$(first_present btop htop top)}
PASSWORD_MANAGER=${PASSWORD_MANAGER-$(first_present 1password bitwarden keepassxc)}
BROWSER_NEW_WINDOW=${BROWSER_NEW_WINDOW:---new-window}
case $BROWSER in
  chromium*|google-chrome*|brave*|vivaldi*) BROWSER_PRIVATE=${BROWSER_PRIVATE:---incognito} ;;
  *)                                        BROWSER_PRIVATE=${BROWSER_PRIVATE:---private-window} ;;
esac
[[ -n $TERMINAL ]] || { echo "No terminal found; set TERMINAL in config/apps.conf" >&2; exit 1; }

# how to run a command inside the terminal
case $TERMINAL in
  gnome-terminal) TERM_EXEC="$TERMINAL --" ;;
  *)              TERM_EXEC="$TERMINAL -e" ;;
esac

# --- custom keybindings ---
BASE=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings
add() { local s="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BASE/$4/"
  gsettings set "$s" name "$1"; gsettings set "$s" command "$2"; gsettings set "$s" binding "$3"; }

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
"['$BASE/walker/', '$BASE/walker-clipboard/', '$BASE/flameshot/', '$BASE/terminal/', \
'$BASE/terminal-alt/', '$BASE/tmux/', '$BASE/browser/', '$BASE/browser-alt/', \
'$BASE/browser-private/', '$BASE/files/', '$BASE/btop/', \
'$BASE/menu/', '$BASE/menu-system/', '$BASE/agent/', '$BASE/calc/', \
'$BASE/emoji/', '$BASE/lock/', '$BASE/transcode/', '$BASE/sound/', '$BASE/bluetooth/', \
'$BASE/network/', '$BASE/display/', '$BASE/power/', '$BASE/editor/', '$BASE/onepassword/', \
'$BASE/keybindings/']"

# ours
add 'Walker'            'walker'                                             '<Super>space'          walker
add 'Clipboard history' "$HOME/.local/bin/walker-clipboard"                  '<Super><Control>v'     walker-clipboard
add 'Flameshot'         'sh -c -- "flatpak run org.flameshot.Flameshot gui"' '<Control>Print'        flameshot

# adapted from Omabuntu (omakub-* helper wrappers replaced with direct commands)
add 'Terminal'          "$TERMINAL"                                          '<Super>Return'         terminal
add 'Terminal'          "$TERMINAL"                                          '<Control><Alt>t'       terminal-alt
add 'Tmux'              "$TERM_EXEC bash -c 'tmux attach || tmux new -s Work'" '<Super><Alt>Return'   tmux
add 'Browser'           "$BROWSER $BROWSER_NEW_WINDOW"                        '<Shift><Super>b'       browser
add 'Browser'           "$BROWSER $BROWSER_NEW_WINDOW"                        '<Shift><Super>Return'  browser-alt
add 'Browser (private)' "$BROWSER $BROWSER_PRIVATE"                           '<Shift><Alt><Super>b'  browser-private
add 'File manager'      "$FILE_MANAGER --new-window"                          '<Shift><Super>f'       files
add 'Activity'          "$TERM_EXEC $ACTIVITY"                                '<Super><Shift>t'       btop
add 'Omarchify menu'    "$HOME/.local/bin/omarchify-menu"                     '<Alt><Super>space'     menu
add 'System menu'       "$HOME/.local/bin/omarchify-menu system"              '<Super>Escape'         menu-system
add 'Coding agent'      "$HOME/.local/bin/omarchify-launch-agent"             '<Super><Control><Shift>a' agent

# from Omarchy's hotkeys manual, mapped to GNOME equivalents
add 'Calculator'        'walker -m calc'                                     '<Super><Control>q'      calc
add 'Emoji picker'      'walker -m symbols'                                  '<Super><Control>e'      emoji
add 'Lock screen'       'loginctl lock-session'                              '<Super><Control>l'      lock
add 'Transcode'         "$HOME/.local/bin/omarchify-transcode"               '<Super><Control>period' transcode
add 'Sound settings'    'gnome-control-center sound'                         '<Super><Control>a'      sound
add 'Bluetooth settings' 'gnome-control-center bluetooth'                    '<Super><Control>b'      bluetooth
add 'Network settings'  'gnome-control-center wifi'                          '<Super><Control>w'      network
add 'Display settings'  'gnome-control-center display'                       '<Super><Control>d'      display
add 'Power settings'    'gnome-control-center power'                         '<Super><Control>p'      power
add 'Editor'            "$TERM_EXEC $EDITOR_CMD"                             '<Super><Shift>n'        editor
[[ -n $PASSWORD_MANAGER ]] && \
add 'Password manager'  "$PASSWORD_MANAGER"                                  '<Super><Shift>slash'    passwords
add 'Keybindings'       "$HOME/.local/bin/omarchify-menu-keybindings"        '<Super>k'               keybindings

# Not adopted, and why — see ../docs/decisions.md:
#   omakub-menu / theme / background / share / transcode / reminders  -> need Omakub's menu system
#   Apple display brightness (Ctrl+F1/F2)                             -> needs asdcontrol + Apple monitor
#   Docker (lazydocker), Music (spotify), Editor (omakub-launch-editor) -> software not installed
#   Night light toggle (Super+Ctrl+N)                                 -> declined; one-liner if wanted:
#     gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled <true|false>
