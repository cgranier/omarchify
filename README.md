# Omarchify

Selected pieces of [Omabuntu](https://github.com/omakasui/omabuntu) and
[Omarchy](https://github.com/omacom/omarchy), ported to run on a **stock Ubuntu
24.04 + GNOME 46 (Wayland)** desktop — without adopting either project's
installer, package repos, or theme engine.

Omarchy is Hyprland-first and Omabuntu is its Ubuntu/GNOME sibling. Both are
excellent; this is for people who want *some* of what they offer on a GNOME
desktop they otherwise keep as-is.

## What you get

| Key | |
|---|---|
| `Super+Space` | Walker launcher — apps, web search, and system actions in one search |
| `Super+K` | every keybinding, read live from gsettings; selecting one runs it |
| `Alt+Super+Space` | menu: system, toggles, web apps, clipboard, screenshot, transcode |
| `Super+Escape` | lock / log out / suspend / restart / shut down |
| `Super+Ctrl+V` | clipboard history, inside Walker |
| `Super+Ctrl+Q` / `Super+Ctrl+E` | calculator / emoji picker |
| `Super+Ctrl+L` / `Super+Ctrl+.` | lock / transcode media |
| `Super+Ctrl+A B W D P` | sound / bluetooth / network / display / power settings |
| `Super+Return`, `Ctrl+Alt+T` | terminal |
| `Shift+Super+B`, `Shift+Super+F` | browser, file manager |
| `Super+Ctrl+Shift+A` | your default coding agent in a terminal |
| `Ctrl+Print` | screenshot |
| `Super+Shift+W` | Omawrite, if you built it (see below) |

Plus command-line helpers: `omarchify-webapp-install` (turn a site into a real
app launcher), `omarchify-transcode` (pictures and video via a Walker file
picker), `omarchify-font-set`, `omarchify-keybinding-add/drop`, and a set of
shell functions in `shell/functions.zsh`.

## Requirements

Ubuntu 24.04 on Wayland, GNOME 46. It will likely work on other GNOME versions
but has only been verified there. You need `sudo` and about 500 MB for the
Flatpak runtime Flameshot pulls in.

## Install

```bash
git clone https://github.com/YOU/omarchify.git
cd omarchify
./install.sh
```

Then log out and back in, so the Walker autostart entry and the GPaste extension
load.

`install/60-omawrite.sh` is optional and not run by `install.sh` — it builds
[Omawrite](https://github.com/omacom/omawrite), Omarchy's Markdown writing app,
which ships as an Arch package only:

```bash
sudo install/60-omawrite.sh    # Qt6 dependencies
install/60-omawrite.sh         # clone, patch if needed, build, install
```

It applies `patches/omawrite-qt6.4-compat.patch` automatically when Qt is older
than 6.5, as on Ubuntu 24.04. See the script's header for why.

Steps are independent — read `install/` and run only what you want. Nothing
touches your existing dotfiles; configs are symlinked from this repo into
`~/.config`, so editing them here *is* editing the live config.

### Matching your terminal's colours

Walker's palette is a static file, `config/walker/themes/omakub-default/colors.css`
— Omakub's theme engine, which would generate it per theme, isn't ported. Six
values, mapped the same way Omabuntu's template does; the file explains it.

### Choosing your apps

Keybindings launch whatever you have. Edit `config/apps.conf`, or override per
run:

```bash
TERMINAL=ghostty BROWSER=chromium install/40-gnome-settings.sh
```

Unset values are auto-detected (`alacritty` → `ghostty` → `kitty` →
`gnome-terminal`, and so on).

## Shell functions

`shell/functions.zsh` is opt-in — `source` it from your `~/.zshrc` if you want it:

| | |
|---|---|
| `fip` / `dip` / `lip` | forward remote ports to localhost over SSH, so `localhost:3000` reaches `host:3000` with the secure-context privileges web sockets need |
| `rsw` / `lsw` / `dsw` | rsync a directory to a remote whenever it changes (needs `inotify-tools`) |
| `gwa` / `gwd` | create a git worktree beside the repo and jump in; remove the one you're in |
| `compress` / `decompress` | tar.gz shorthand |

It also aliases `bat` and `fd` to Ubuntu's `batcat` and `fdfind` if the real ones
aren't installed. Only functions Omarchy has that a typical setup lacks are
included; read the header before sourcing, since zsh function/alias collisions
fail loudly.

## Read this before debugging anything

**Mutter implements far fewer Wayland protocols than wlroots or KWin, and the
failures are silent.** Most surprises when porting from Omarchy trace back to it:

| Missing protocol | What breaks | Use instead |
|---|---|---|
| `wlr-layer-shell` | overlay surfaces, panels | a normal window |
| `wlr-screencopy` | `grim` and anything built on it | `xdg-desktop-portal` |
| `wlr-data-control` / `ext-data-control` | `wl-paste --watch`, so cliphist / clipman / clipse / `elephant-clipboard` | a GNOME Shell extension (GPaste) |

`docs/decisions.md` has the full reasoning, including several settings that look
redundant but encode a finding. `docs/troubleshooting.md` covers the symptoms
that come up most — links opening in a text editor, an empty clipboard, a
keybinding that does nothing, and why a stale terminal is the first thing to rule
out.

## What this is not

It does not port Omakub's theme engine, Omarchy's Quickshell bar or agents panel,
the Hyprland tiling and window bindings, or anything Arch-specific. `docs/porting.md`
lists what was considered and why each was kept or dropped.

## Credit

Nearly every good idea here is Omabuntu's or Omarchy's; the work was adapting
them to GNOME and finding out where that breaks. Walker and Elephant are
[abenz1267's](https://github.com/abenz1267/walker). Packages come from
`packages.omakasui.org`, which is also the only source of `libgtk4-layer-shell0`
for Ubuntu noble.

## License

[MIT](LICENSE).

The upstream projects this borrows from have their own licenses: check
[Omabuntu](https://github.com/omakasui/omabuntu),
[Omarchy](https://github.com/omacom/omarchy),
[Walker](https://github.com/abenz1267/walker) and
[Elephant](https://github.com/abenz1267/elephant) before redistributing anything
of theirs. The Walker theme here is adapted from Omabuntu's `omakub-default`, and
`item_symbols*.xml` are Walker's own defaults.
