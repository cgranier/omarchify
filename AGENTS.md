# Working on omarchify

Conventions for this repo, in the spirit of Omabuntu's and Omarchy's `AGENTS.md`.
Most of what follows was learned by getting it wrong first; the reasons are in
[docs/decisions.md](docs/decisions.md).

## Style

Adopted from Omabuntu/Omarchy so ported code stays recognisable:

- Two spaces for indentation, no tabs
- Bash 5 conditionals: `[[ ]]` for string/file tests, `(( ))` for numeric
- Inside `[[ ]]` don't quote variables, but do quote string literals: `[[ $branch == "dev" ]]`
- Quote paths with spaces rather than escaping: `"$DIR/My App.desktop"`
- `set -euo pipefail` in standalone scripts; `install/*.sh` are run directly, not sourced

One deliberate divergence: **`#!/usr/bin/env bash` is used here**, not their
`#!/bin/bash`. These scripts are not part of a distro with a guaranteed layout.

## Naming

All user-facing helpers are `omarchify-*`, mirroring `omakub-*` / `omarchy-*`.
Prefixes carry the same meanings: `launch-`, `install-`, `toggle-`, `menu-`.
`walker-clipboard` predates the convention and keeps its name.

Install scripts are `NN-topic.sh`, run in numeric order, and say in a header
comment whether they want root, user, or both.

## The PATH trap — read this before adding a helper

**`~/.local/bin` is not in the GNOME session PATH** (only `/usr/local/bin` is).
This bites twice, and the second bite is silent:

1. A `.desktop` `Exec=` or a GNOME keybinding command must be an **absolute path**,
   or it never launches.
2. The script then calls *its own siblings* by bare name, and they are equally
   unreachable — it dies with nothing in the journal.

Every `omarchify-*` helper therefore begins with:

```bash
PATH="$(cd "$(dirname "$(readlink -f "$0")")" && pwd):$HOME/.local/bin:$PATH"
```

Keep that line when adding one. Test with the real session PATH, not your shell's:

```bash
SESSION_PATH=$(tr '\0' '\n' < /proc/$(pgrep -x gnome-shell | head -1)/environ | grep ^PATH= | cut -d= -f2-)
env -i HOME="$HOME" PATH="$SESSION_PATH" XDG_RUNTIME_DIR=/run/user/1000 \
  DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" bash -c '~/.local/bin/omarchify-thing'
```

## Verify against the running system, not the docs

Everything here was captured from a working machine. When changing something:

- **Snapshot before mutating live state.** `gsettings get ... > /tmp/before` first.
  A bad `gsettings set` on `custom-keybindings` silently unbinds every shortcut.
- **Parse GVariant by extracting quoted strings**, never by deleting characters:
  `grep -o "'[^']*'" | tr -d "'"`. `tr -d "[]@as "` deletes the letters `a` and `s`
  and turns `settings-daemon` into `etting-demon`. That happened.
- **The interactive shell here is zsh**, where `path` is a special variable tied to
  `PATH`. `while read -r kw path` wipes your PATH mid-script. Use bash for scripts
  and avoid `path` as a variable name.
- **`dpkg` alone under-reports.** `alacritty` is a snap, `fzf` and `starship` are
  hand-installed. Check `command -v` too.
- **Extension schemas may not be globally compiled.** A setting reading as
  "SCHEMA MISSING" usually needs `gsettings --schemadir <ext>/schemas` before you
  conclude anything.

## Shell functions collide with oh-my-zsh

Many setups load oh-my-zsh with `plugins=(git tmux)`, so a large set of short
git aliases already exists — `ga='git add -A'`, `gd='git diff'` among them. **zsh
refuses to define a function over an existing alias**, and it fails at *parse*
time, so one collision kills the whole file and every function after it. Check a
name before adding a function to `shell/functions.zsh`:

```bash
zsh -ic 'alias NAME; whence -w NAME'
```

## Mutter's protocol gaps

Before porting anything from Omarchy, check what Wayland protocol it needs.
Mutter implements far fewer than wlroots, and the failures are silent:

| Missing | Breaks | Use instead |
|---|---|---|
| `wlr-layer-shell` | overlay surfaces | a normal window (Walker falls back on its own) |
| `wlr-screencopy` | `grim`, screenshot tools | `xdg-desktop-portal` |
| `wlr-data-control` / `ext-data-control` | `wl-paste --watch`, all clipboard managers | a GNOME Shell extension (GPaste) |

Anything talking to a `wlr-*` protocol needs a GNOME substitute, not a config tweak.

## Committing

Atomic commits, one coherent change each.
State what was verified and how — several things here look redundant but encode a
finding, and a commit message is where that survives.
