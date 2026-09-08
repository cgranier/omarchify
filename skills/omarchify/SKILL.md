---
name: omarchify
description: >
  REQUIRED for end-user customization of this Ubuntu 24.04 + GNOME 46 (Wayland)
  desktop. Use when editing ~/.config/walker/, ~/.config/elephant/,
  ~/.config/alacritty/, GNOME keybindings or gsettings, clipboard history, web-app
  launchers, screenshots, or the Omarchify menu. Triggers: Walker, Elephant,
  launcher, clipboard, GPaste, Flameshot, screenshot, keybinding, shortcut, web
  app, compose key, GNOME extension, theme, font, night light, workspace. Also use
  when a desktop tool "just doesn't work" on Wayland — the cause is usually a
  Mutter protocol gap, and this skill records which ones.
---

# Omarchify Skill

End-user customization of a GNOME desktop assembled from selected pieces of
[Omabuntu](https://github.com/omakasui/omabuntu) and
[Omarchy](https://github.com/omacom/omarchy), without either project's installer.

Source of truth is the Omarchify checkout (its configs are symlinked into
`~/.config`, so editing them there edits the repo). Read `docs/decisions.md`
before changing anything that looks redundant — several settings encode a
finding. For working *on* the repo rather than using it, read `AGENTS.md`.

## The environment

Ubuntu 24.04.4, GNOME Shell 46, **Wayland**. `ubuntu-xorg.desktop` exists as a
fallback session. Launcher is Walker 2.17 + Elephant 2.22 from the pinned
`packages.omakasui.org` repo. Clipboard history is GPaste, bridged into Walker.
Screenshots are Flameshot 14 from Flathub.

If this machine receives its keyboard and mouse from another over Deskflow,
Synergy or Barrier, check `/proc/bus/input/devices` before blaming GNOME for any
input oddity — and never stop that service, it may be the only input path.

## Check this first when something doesn't work

Mutter implements far fewer Wayland protocols than wlroots or KWin, and the
failures are silent rather than loud. Before debugging a tool, check what it needs:

| Missing protocol | What breaks | Use instead |
|---|---|---|
| `wlr-layer-shell` | overlay surfaces, panels | a normal window |
| `wlr-screencopy` | `grim` and tools built on it | `xdg-desktop-portal` |
| `wlr-data-control` / `ext-data-control` | `wl-paste --watch`, so cliphist / clipman / clipse / elephant-clipboard | a GNOME Shell extension (GPaste) |

Anything from Omarchy that talks to a `wlr-*` protocol needs a GNOME substitute,
not a config tweak. Mutter has no data-control implementation planned, so a newer
Ubuntu will not change that.

## Keybindings

| Key | Action |
|---|---|
| `Super+Space` | Walker |
| `Super+Ctrl+V` | clipboard history in Walker |
| `Ctrl+Print` | Flameshot |
| `Super+Return`, `Ctrl+Alt+T` | Alacritty |
| `Super+Alt+Return` | Alacritty running tmux |
| `Shift+Super+B` / `Shift+Super+Return` | Firefox (`Shift+Alt+Super+B` private) |
| `Shift+Super+F` | Nautilus |
| `Super+Shift+T` | btop |
| `Alt+Super+Space` | Omarchify menu |
| `Super+Escape` | system menu |

Add or remove with `omarchify-keybinding-add <name> <command> <binding> [slug]`
and `omarchify-keybinding-drop [slug]`. Both use named slugs and de-duplicate by
key sequence. **Snapshot `custom-keybindings` before editing it by hand** — a bad
write silently unbinds everything.

Commands in a keybinding must be **absolute paths**; `~/.local/bin` is not in the
GNOME session PATH.

## Helpers

- `omarchify-menu [system|toggle|webapp]` — Walker-driven menu
- `omarchify-webapp-install <name> <url> [icon]` / `-remove` — site as its own app window (needs a Chromium-family browser; Firefox has no `--app`)
- `omarchify-font-list` / `-set <family>` / `omarchify-font-size-set <n>` — Alacritty + GNOME monospace
- `omarchify-keybinding-add` / `-drop`
- `omarchify-xcompose-build` — regenerate `~/.XCompose` and restart ibus
- `walker-clipboard` — GPaste history in Walker

## Walker

Config `~/.config/walker/config.toml`, theme in `~/.config/walker/themes/omakub-default/`.
Prefixes: `/` providerlist, `.` files, `:` symbols, `=` calc, `@` websearch,
`>` runner, `!` todo.

- `as_window = true` is **verified to make no difference** — Walker falls back to a
  normal window by itself. Kept as documentation.
- Walker appears in Alt+Tab and does not close on click-outside. Both are inherent
  to being a normal window; its config has no option for either. Escape closes it.
- Restart with `pkill -x walker` then `setsid walker --gapplication-service &`.

## Clipboard

GPaste's daemon does the tracking. **Every `gpaste-client` call must redirect
`< /dev/null`** — with an inherited stdin it enters its documented "pipe input to
set the clipboard" mode, prints nothing, and looks exactly like an empty history.

## Compose key

Right Alt by default (`xkb-options ['compose:ralt']`), rebuilt by
`omarchify-xcompose-build`. Sequences never resolve on a machine whose input is
injected over Deskflow/Synergy/Barrier — the injected modifier events interrupt
them. See `docs/decisions.md`.

## Things deliberately not installed

`elephant-clipboard` (cannot work on GNOME — reported as
[omabuntu#108](https://github.com/omakasui/omabuntu/issues/108)), the
`core.omakasui.org` repo, and Omakub's menu/theme engine. Don't add them back
without reading `docs/decisions.md`.
