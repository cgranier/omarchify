# Troubleshooting

## First question: did you test in a process that predates the change?

Most of the confusing failures here come down to a stale environment, not a bad
setting. A long-lived terminal, tmux session, or app carries the environment and
config it started with:

- `~/.XCompose` is read **at app startup** — restart the app, and `ibus restart`
  too, since ibus caches the compose table.
- A terminal opened before you changed a session-level setting will not see it.
- Walker caches window dimensions in its `gapplication-service`; restart it with
  `pkill -x walker` (or use `omarchify-launch-walker`, which handles this).

Before debugging further, retry in a **freshly launched** terminal or app.

## Links open in a text editor instead of a browser

Symptom: `gh auth login`, or any command that opens a URL, dumps HTML source into
a text editor. Walker's websearch results and web-app launchers fail the same way.

Cause: no application is registered for `text/html` and the `http`/`https`
schemes, so `xdg-open` has nothing to hand the URL to. Check:

```bash
xdg-settings get default-web-browser
xdg-mime query default text/html
xdg-mime query default x-scheme-handler/https
```

Empty output means nothing is registered. Fix it:

```bash
# list candidates
ls /usr/share/applications /var/lib/snapd/desktop/applications ~/.local/share/applications \
  | grep -iE 'firefox|chromium|chrome|brave'

xdg-settings set default-web-browser firefox_firefox.desktop
for m in text/html x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about; do
  xdg-mime default firefox_firefox.desktop "$m"
done
```

Use the exact `.desktop` filename — snap-packaged Firefox is
`firefox_firefox.desktop`, not `firefox.desktop`. Then test in a **new** terminal:

```bash
xdg-open https://example.com
```

Two things that make this confusing to diagnose:

- **`XDG_DATA_DIRS` matters.** Snap apps live in `/var/lib/snapd/desktop`, and if
  that isn't on the path `xdg-mime` sees, the query returns empty even when
  `mimeapps.list` is correct. A non-graphical shell (ssh, a service) often has it
  unset entirely. Compare with the session's:
  `tr '\0' '\n' < /proc/$(pgrep -x gnome-shell | head -1)/environ | grep XDG_DATA_DIRS`
- **`gh` has its own setting**, which overrides all of the above:
  `gh config set browser firefox`, or `BROWSER=firefox gh auth login`.

## Clipboard history is always empty

Expected on GNOME for anything built on `wl-paste --watch` — Mutter implements
neither `wlr-data-control` nor `ext-data-control`, so cliphist, clipman, clipse
and `elephant-clipboard` cannot work. Use GPaste, which `install/20-gpaste.sh`
sets up and `walker-clipboard` reads. See `decisions.md`.

If GPaste itself returns nothing, check that every `gpaste-client` call redirects
stdin: with an inherited stdin it enters its "pipe input to set the clipboard"
mode, prints nothing, and looks exactly like an empty history.

```bash
gpaste-client history < /dev/null
```

## Compose sequences never resolve

If this machine receives its keyboard from another over Deskflow, Synergy or
Barrier, compose cannot work — injected modifier events interrupt the sequence.
Confirm with `/proc/bus/input/devices`: no keyboard-capable device means every
keystroke arrives over the network. Set `OMARCHIFY_COMPOSE=none`. See
`decisions.md`.

## A keybinding does nothing

`~/.local/bin` is **not** in the GNOME session PATH. A keybinding command must be
an absolute path — and so must any sibling command the script it launches calls.
Every `omarchify-*` helper prepends its own directory to `PATH` for this reason.
Test with the real session environment:

```bash
SESSION_PATH=$(tr '\0' '\n' < /proc/$(pgrep -x gnome-shell | head -1)/environ | grep ^PATH= | cut -d= -f2-)
env -i HOME="$HOME" PATH="$SESSION_PATH" XDG_RUNTIME_DIR=/run/user/1000 \
  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" bash -c '~/.local/bin/omarchify-menu'
```

## Screenshots fail with "Unable to capture screen"

GNOME 45+ only lets the **focused** app raise a portal consent dialog, and a
tray- or hotkey-triggered tool never is. Pre-grant the permission so no dialog is
needed:

```bash
flatpak permission-set screenshot screenshot org.flameshot.Flameshot yes
```

## sourcing shell/functions.zsh fails with a parse error

zsh refuses to define a function over an existing alias and fails at *parse*
time, so one collision takes the whole file down. oh-my-zsh's git plugin is the
usual culprit. Find it with `zsh -ic 'alias NAME; whence -w NAME'` and rename
ours, not yours.
