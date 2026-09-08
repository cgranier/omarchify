# GNOME extensions

Audited against Omabuntu's
`install/config/gnome/extensions.sh` (dev).

## Installed

| Extension | From Omabuntu's list? | State |
|---|---|---|
| `tactile@lundal.io` | yes | active |
| `just-perfection-desktop@just-perfection` | yes | active |
| `space-bar@luchrioh` | yes | active |
| `undecorate@sun.wxg@gmail.com` | yes | active |
| `tophat@fflewddur.github.io` | yes | active |
| `AlphabeticalAppGrid@stuarthayhurst` | yes | active |
| `quick-settings-tweaks@qwreey` | yes | active |
| `icon-launcher@omakasui.org` | yes | active |
| `rounded-window-corners@fxgn` | yes | active |
| `GPaste@gnome-shell-extensions.gnome.org` | no — added here for clipboard history | enabled, loads next login |
| `ding`, `ubuntu-dock`, `ubuntu-appindicators`, `tiling-assistant` | Omabuntu **disables** these | active (kept) |

**Not installed** from Omabuntu's list: `blur-my-shell@aunetx`,
`gnome-ui-tune@itstime.tech`.

## Settings vs Omabuntu's defaults

Most match exactly — tactile's 4x2 grid, all four `just-perfection` keys, all four
`space-bar` keys, `tophat` disk + network-usage-unit, and three of the four
`rounded-window-corners` keys **including** its `blacklist = ['dev.benz.walker']`,
which is why Walker gets square corners. A machine that has had Omabuntu's extension config applied will already match most of it.

Deliberate-looking divergences, left alone:

| Setting | Here | Omabuntu |
|---|---|---|
| `tactile gap-size` | 2 | 10 |
| `tophat show-icons` / `show-cpu` / `show-mem` / `show-fs` | true | false |
| `rounded-window-corners-reborn border-width` | 0 | 2 |

Omabuntu's tophat config is deliberately minimal (network only); this machine
shows the full set. Both are preferences, not bugs.

**Repaired:** `icon-launcher custom-command` was empty, so the topbar button did
nothing — it pointed at `omakub-menu`, which doesn't exist here. Now set to
`walker`.

## Gotcha

`AlphabeticalAppGrid` first looked misconfigured because plain `gsettings` can't
see its schema. It isn't compiled into `/usr/share/glib-2.0/schemas` — Omabuntu
does that with a `sudo cp` + `glib-compile-schemas` step we skipped. Read it with:

```bash
gsettings --schemadir ~/.local/share/gnome-shell/extensions/AlphabeticalAppGrid@stuarthayhurst/schemas \
  get org.gnome.shell.extensions.alphabetical-app-grid folder-order-position   # -> 'end', matches
```

Any extension setting that reads as "SCHEMA MISSING" needs the same treatment
before concluding anything.
