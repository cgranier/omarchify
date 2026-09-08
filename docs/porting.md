# What else is worth porting

Omabuntu ships ~140 `bin/` helpers, Omarchy ~260. Most of Omarchy's are Hyprland
or Arch plumbing. This is what actually crosses to GNOME, assessed 2026-09-07.

Omabuntu's helpers are already GNOME-native, so "porting" them mostly means
resolving their `omakub-*` internal dependencies (`omakub-hook`,
`omakub-notification-send`, `omakub-state`) or inlining what they do.

## Done

- **Web apps** — `home/bin/omarchify-webapp-{install,remove}` +
  `omarchify-launch-webapp`, adapted from `omarchy-webapp-install`.
  See "Adaptations that mattered" below.

- **Keybinding helpers** — `home/bin/omarchify-keybinding-{add,drop}`.
  Two deliberate improvements over `omakub-gnome-keybinding-add`: named slugs
  (`…/custom-keybindings/walker/`) instead of `custom0`, `custom1`…, and
  duplicate detection that scans *every* registered path. Upstream's regex is
  `custom\K[0-9]+`, so it cannot see named slugs at all and would silently
  double-bind against ours. (`install/40-gnome-settings.sh` was already
  idempotent — it rewrites the whole list — so these are for ad-hoc use.)
- **XCompose** — `config/xcompose/{compose,personal}`, deployed by
  `50-link-configs.sh`. Omabuntu's emoji + typography set, with personal entries
  split into their own file. Compose is on Right Alt by default; see `decisions.md` for the Deskflow caveat. **ibus caches the compose
  table at startup**, so writing `~/.XCompose` has no effect until `ibus restart`
  (Omabuntu has `omakub-restart-xcompose` for exactly this); apps also need
  restarting to pick it up.

- **Font management** — `omarchify-font-{list,set,size-set}`. Adapted from
  `omakub-font-set`, which targets terminals only; ours also updates GNOME's
  `monospace-font-name`, and validates the family against `fc-list` first.
- **Minimal menu** — `omarchify-menu` plus `-select` / `-input`, on
  `walker --dmenu` (and its `--inputonly` mode for text entry). System actions,
  toggles (night light / DND / dark mode), web app install+remove, clipboard,
  screenshot. All GNOME-native; none of Omakub's theme engine.

- **Transcode** — `omarchify-transcode` plus `omarchify-menu-file` (a Walker file
  picker, newest first). Pictures via ImageMagick, video via ffmpeg, output URI
  copied to the clipboard. Also on the menu.

- **Shell functions** — `shell/functions.zsh`, from Omarchy's `default/bash/fns`.
  Only what `.zshrc_shared` lacks: `fip`/`dip`/`lip` (SSH port forwarding),
  `rsw`/`lsw`/`dsw` (rsync-on-change watchers, needs `inotify-tools`),
  `gwa`/`gwd` (git worktrees — renamed from Omarchy's `ga`/`gd`, which collide with oh-my-zsh's git plugin), `compress`/`decompress`, and `bat`/`fd` aliases for
  Ubuntu's `batcat`/`fdfind`. Deliberately **not sourced** — it belongs in
  `home/.zshrc_shared` during the revamp.

## Worth doing next

## Bigger, but it is the actual "feel"

**Extending the menu** — the minimal version is in place. What Omabuntu has that
it lacks: theme switching, background picker, and the share menu, all of which
need Omakub's theme engine.

**OCR text extraction** (`omarchy-capture-text-extraction`) — select a region,
get its text on the clipboard. The capture half uses grim+slurp and must be
rebuilt on the portal. `tesseract-ocr` is in Ubuntu. Real work, real payoff.

## Not portable

- **`omarchy-hyprland-*` (~15)** plus the waybar / mako / hypridle / hyprlock /
  swayosd refreshers — GNOME provides these differently.
- **`omarchy-hw-*` (~18)** — Arch kernel quirks for specific laptops.
- **Gaming installers (~12), `omarchy-snapshot` (btrfs), limine / sddm,
  pacman + AUR machinery** — Arch-specific packaging.
- **Voxtype** (voice typing) — injecting keystrokes on GNOME Wayland means the
  RemoteDesktop portal, the road Deskflow takes. Disproportionate.

## Dependency note

Several helpers use `gum` for interactive prompts. It is **not** in Ubuntu's
archive — the only source is `packages.omakasui.org`, which our pinning holds at
priority 1:

```
gum | 2.0.0-1+noble | 1 | https://packages.omakasui.org noble/main
```

All of them also have non-interactive argument modes that skip `gum`, which is
what install scripts want anyway. `omarchify-webapp-install` follows that
pattern: it uses `gum` if present, otherwise requires arguments.

## Adaptations that mattered (web apps)

Three things that testing caught, and that any further port will hit too:

1. **`~/.local/bin` is NOT in the GNOME session PATH** (only `/usr/local/bin`
   is), so a `.desktop` `Exec=` naming a bare command silently fails to launch
   from the app grid or Walker. The installer resolves an absolute path.
   **This bites twice.** An absolute `Exec=` or keybinding command is necessary
   but not sufficient: the script then calls its *own siblings* by bare name and
   they are equally unreachable, so it dies silently with nothing in the journal.
   Every `omarchify-*` helper therefore starts with
   `PATH="$(cd "$(dirname "$(readlink -f "$0")")" && pwd):$HOME/.local/bin:$PATH"`.
   Keep that line when adding new ones.
2. **`uwsm-app` had to go** — Omarchy launches through it; it is a Hyprland/uwsm
   session helper with no GNOME equivalent. The browser is invoked directly.
3. **Walker caches window dimensions** on first `gapplication-service`
   activation; later calls asking for a different size are silently capped to the
   first. A 295-wide menu followed by an 800-wide file picker gives you a
   295-wide picker. `omarchify-launch-walker` restarts Walker when the requested
   dimensions change — the same workaround `omakub-launch-walker` uses. Route any
   new Walker invocation through it rather than calling `walker` directly.
4. **A missing favicon must not abort the install.** Google's favicon endpoint
   404s for plenty of domains (`example.com` among them). Omarchy prompts for a
   replacement URL interactively; the non-interactive port falls back to the
   themed `web-browser` icon and warns.

Also: Firefox has no equivalent of `--app`, so web apps require a
Chromium-family browser. This machine uses the Chromium snap.
