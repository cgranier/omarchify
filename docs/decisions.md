# Decisions and findings

Verified on Ubuntu 24.04.4 · GNOME Shell 46 · Wayland

## The one thing that explains most of this

**Mutter implements far fewer Wayland protocols than wlroots or KWin.** Omarchy is
Hyprland-first and Omabuntu is a port of that design to GNOME, so tools carried
across keep landing on protocols that do not exist here. Three separate features
failed today for this single reason:

| Missing protocol | What broke | Resolution |
|---|---|---|
| `wlr-layer-shell` | Walker can't be an overlay surface | Falls back to a normal window on its own |
| `wlr-screencopy` | `grim` is useless | Use the portal (Flameshot/flatpak) |
| `wlr-data-control` **and** `ext-data-control` | `wl-paste --watch` fails, so no clipboard history | GNOME Shell–extension manager (GPaste) |

Verified locally: `strings /usr/lib/x86_64-linux-gnu/libmutter-14.so.0 | grep -i
data.control` returns nothing. Upstream has no data-control implementation and none
planned — <https://gitlab.gnome.org/GNOME/mutter/-/work_items/524> — so a newer
Ubuntu will not change this.

**Rule of thumb:** anything from those repos that talks to a `wlr-*` protocol needs
a GNOME substitute, not a config tweak.

## Why these choices

**Only `packages.omakasui.org`, never `core.omakasui.org`.** The packages repo has
the actual software; core has the `omakub-*` metapackages and distro glue. The
packages repo is also the only source of `libgtk4-layer-shell0` for noble — Ubuntu
ships no GTK4 layer-shell package at all. Pinned to priority 1 for everything and
500 for `walker`/`elephant*`/`libgtk4-layer-shell0` so a general-purpose third-party
repo can't shadow the Ubuntu archive.

**GPaste over Clipboard Indicator** — solely because `gpaste-client` is scriptable.
That is what allows `home/bin/walker-clipboard` to keep clipboard history inside
Walker instead of becoming a second, disconnected popup. Clipboard Indicator is
lighter and better looking but has no CLI, which is a dead end here.

**Flameshot from Flathub, not apt.** Ubuntu's 12.1.0 requests captures through the
portal, which must show a consent dialog; GNOME 45+ only lets the *focused* app
raise one, and a tray/hotkey tool never is. Journal evidence:

```
xdg-desktop-por[…]: Failed to show access dialog: AccessDenied:
    Only the focused app is allowed to show a system access dialog
org.flameshot.Flameshot.desktop[…]: flameshot: error: Unable to capture screen
```

The actual fix was pre-granting the permission so no dialog is needed:
`flatpak permission-set screenshot screenshot org.flameshot.Flameshot yes`.
Moving to Flathub 14 was an upgrade, not the fix.

**`elephant-clipboard` deliberately not installed.** See the table above. Reported
upstream as <https://github.com/omakasui/omabuntu/issues/108> (Omabuntu ships it on
its own GNOME target, where it fails silently). The `$` clipboard prefix was removed
from the Walker config to match.

## Settings that look redundant but aren't

**`center-new-windows true`** — this is a *global Mutter* setting from Omabuntu's
`install/config/gnome/settings.sh`, not a Walker setting. Without it Walker opens
off-centre. This was the clearest cost of cherry-picking: the GNOME-gsettings layer
is invisible if you only take packages and app configs. Note it centres *every* new
window, not just Walker.

**Theme `@import`** — Omabuntu's `style.css` imports
`~/.config/omakub/current/theme/walker.css`, part of Omakub's live-theme engine.
Replaced with a static `colors.css` (Yaru-dark). Also pinned the font to
`"JetBrainsMono Nerd Font", monospace`: their theme asks for generic `monospace`,
which resolves to Ubuntu Sans Mono here and renders the `󰍉` placeholder as tofu.

**`walker-clipboard` redirects every `gpaste-client` call from `/dev/null`** — with
an inherited stdin, gpaste-client enters its documented "pipe input to set the
clipboard" mode, prints nothing, and looks exactly like an empty history. This
cost an hour. Do not remove those redirects.

**The bridge matches on value, not index** — so it doesn't depend on whether
Walker's `--index` is 0- or 1-based, which was never established.

## Verified non-issues

**`as_window = true` makes no difference.** A/B tested: Walker falls back to a
normal window by itself when the compositor lacks layer shell, which is why
Omabuntu never sets it. Kept as documentation, not as a fix.

**Walker appears in Alt+Tab and doesn't close on click-outside.** Inherent to being
a normal window. Walker's config struct (29 fields, read from the binary) has no
focus-loss or skip-taskbar option, and `click_to_close` only fires on Walker's own
surface — which under layer shell covers the screen but as a window is just the
644px box. Omabuntu behaves identically. **Escape** closes it, and `Super+Space`
toggles it shut. Accepted; a Shell extension could fix it but isn't worth maintaining.

## Not carried over

`default/elephant/*.lua` (the Omabuntu Menu: theme switcher, background picker,
unlocks). They shell out to `omakub-*` binaries and read `~/.config/omakub/`;
adopting them means adopting Omakub's theme system. Omarchy's `Super+C`/`Super+V`
universal copy/paste also can't port — they use Hyprland's `sendshortcut`, which
GNOME has no equivalent for.

## Compose key, and a trap worth knowing

Omabuntu sets `xkb-options ['compose:caps']`. This ships `compose:ralt` instead:
Caps Lock stays Caps Lock, and Compose swallows every key after it until a
sequence resolves, so a key you press by accident is a worse choice than one you
don't. Set `OMARCHIFY_COMPOSE=compose:caps` (or `none`) to change it.

**If this machine receives its keyboard from another over Deskflow, Synergy or
Barrier, compose will never work** — no matter which key you bind. Those tools
re-synchronise modifier state around each injected key, and the resulting events
interrupt the sequence. The symptom is that the compose key swallows your
keystrokes and nothing is ever produced, including for stock sequences like
`Compose - - -`.

Diagnosing that cost an evening. What finally showed it was `xev`: one keypress
returned a repeating storm of `Control_L`, `Shift_L`, `Meta_L`,
`ISO_Level3_Shift`, `Alt_L`. If input on a machine behaves strangely, check
`/proc/bus/input/devices` early — if there's no keyboard-capable device listed,
every keystroke is arriving over the network and that is where to look.
