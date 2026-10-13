# Abstract Black — notes for a new session

An Omarchy 4 theme, slug `abstract-black` (shown as **Abstract Black**). One
theme, no glass variant. Built for near-achromatic black wallpapers: true
neutral black surfaces, Hyprland blur, and a single cold silver-blue accent.

Derived from `~/Projects/omarchy-star-wars-theme` (glass recipe, animation
speeds, shell section layout) and `~/Projects/omarchy-devsviat-theme` (both
wallpapers, the unlock/Plymouth mechanics). That repo's `docs/RESEARCH.md` is
the full account of how Omarchy 4 theming works and is not duplicated here.

The design brief and the reasoning behind each value are in
[`docs/DESIGN.md`](docs/DESIGN.md).

## Two installs: the gallery clone and `tools/install-theme.sh`

The theme is listed in the Omarchy gallery (omacom/omarchy-site), which
installs with `omarchy theme install <url>`. `omarchy-theme-set` treats a
theme directory containing `.git` as an untrusted installed theme and strips
every `*.lua`, the four terminal configs and `vscode.json` from it, then
generates its own from `colors.toml`. The gallery's audit bot rejects a repo
that ships those names, so they live here as `.example`:

- `hyprland.lua.example`, `foot.ini.example`, `ghostty.conf.example`,
  `alacritty.toml.example`, `kitty.conf.example` — the glass itself.
- `shell.{menu,launcher,notifications,popups}.toml.example` — the translucent
  cards. Each has a plain twin at 0.94 for the gallery install, where nothing
  blurs behind the card and the window underneath ran through the menu text.
  **The twins differ only in `background-alpha` and the header comment**;
  change a colour in one and change it in the other.

`./tools/install-theme.sh` builds `~/.config/omarchy/themes/abstract-black` as
a directory of absolute symlinks and links every `<name>.example` in as
`<name>` (the plain twin is then skipped), so this machine runs the full
theme. That directory holds no `.git`, so it stages in full. A gallery user
gets palette, wallpapers, bar and near-opaque cards — no blur, no animations,
opaque terminals. The user-facing account is "Two ways to install" in
README.md; keep it in step with the script. Rerun the script after adding or
renaming a top-level file.

`preview.png` is the gallery install and `preview-full.png` the full one,
linked in as the switcher thumbnail.

## No glass variant, on purpose

The user chose one theme. `hyprland.lua.example` ends with a small guard: if hyprglass
happens to be loaded from `~/.config/hypr/autostart.lua` (it is, on this
machine, for the Star Wars Glass theme), this theme switches it off rather than
inherit its refraction. Do not add a `*-glass` slug without being asked.

## Where the look lives

| Layer | File | Value |
|---|---|---|
| Animations (curves lift / settle / glide / shift) | `hyprland.lua.example` | Star Wars' speeds exactly, renamed; workspaces `slidefade 20%` at 250 ms |
| Blur, shadow, rounding, border | `hyprland.lua.example` | blur 9 x 3 passes, brightness 0.80, vibrancy 0.10, rounding 14 / power 2.5, shadow offset 3,6 |
| Window opacity (non-terminal) | `hyprland.lua.example` | `default-opacity` tag -> `0.9 0.82` |
| Terminal window opacity | `hyprland.lua.example` | `terminal` tag -> `1.0 0.94` |
| Terminal background | `foot.ini.example`, `ghostty.conf.example`, `alacritty.toml.example`, `kitty.conf.example` | alpha 0.72 |
| Shell bar / menus / notifications | `shell.*.toml`, `shell.*.toml.example` | `background-alpha` 0.55 – 0.9 in the full install |
| Blur behind shell layers | `hyprland.lua.example` | `hl.layer_rule`: bar `ignore_alpha 0.15`, full-screen layers `0.55` so only the card blurs, never the scrim |
| GTK / libadwaita apps | `gtk.css` | rgba surfaces |

Three values are deliberately NOT Star Wars', and each is tied to the
wallpapers being achromatic and near-black — see `docs/DESIGN.md` before
changing them: `rounding 14 / power 2.5`, shadow `offset {3, 6}`, and blur
`brightness 0.80 / vibrancy 0.10`.

**The bar is tinted with `lighter_background`, not `background`.** Every other
surface takes `background`. On these wallpapers a bar carrying `background`
composites to roughly what the windows do and the two merge into one dark
field; `#171717` at 0.62 puts it about one step lighter, so it reads as chrome.
This is the opposite of Star Wars, where the bar sits a step deeper.

**Every terminal config must ask for blur** (`blur=yes` in foot, and the
matching keys in ghostty/kitty/alacritty). foot is built `+blur` and speaks
`ext-background-effect-v1`; with its default `blur=no` it tells Hyprland not to
blur behind it, so the window is translucent but sharp and no Hyprland setting
can override that. foot reads `alpha` only at startup — a terminal opened
before the theme was applied stays opaque until reopened.

## unlock.png is the Omarchy mark, recoloured

`brand/omarchy-logo.svg` is the official mark from https://omarchy.org/brand/
(the labyrinth "O", **not** the OMARCHY wordmark — the user asked for the logo,
not the text). `tools/generate-unlock.sh` swaps its single flat `#9ece6a` fill
for a top-to-bottom gradient `#d7e4f8` -> `#8fb4de`, the same run of light the
window rim carries, and renders it at 520 px square with a transparent
background.

Style -> Unlock is the **boot splash**, not the lock screen: the Quickshell lock
screen always blurs the current wallpaper and a theme cannot redirect it.
`omarchy.script` draws `unlock.png` centred at its native size and puts the
password entry at `logo.y + logo.height + 40`, so a full-screen image pushes the
LUKS prompt off the display, and an opaque background seams against Plymouth's
flat fill. `preview-unlock.png` is the picker thumbnail; without it the theme is
not listed under Style -> Unlock at all.

Both are byte-for-byte reproducible, so a rerun on an unchanged palette leaves
git clean. The script hard-fails if the brand SVG ever stops carrying exactly
one `fill="#9ece6a"`.

## libadwaita tints its surfaces with the accent

`gtk.css` ends with explicit `background-color` pins on `.sidebar-pane`,
`.navigation-sidebar`, `.content-pane` and `.view`. They are not redundant with
the `--*-bg-color` variables above them: libadwaita 1.9 mixes
`--accent-bg-color` into surface backgrounds from inside its widget rules, so
with a neutral `--sidebar-bg-color` the Files sidebar still measured +8 blue.
Pinning the surfaces as real properties is what fixes it; `docs/DESIGN.md` has
the three-way measurement. Keep each pin equal to the variable it mirrors.

## Things that have already broken once (inherited from the other two themes)

1. **No inline comments in `colors.toml`** — `omacalc` reads it with a parser
   that swallows the rest of the line into the value and then draws a fully
   black window. Same rule kept in `shell.*.toml`.
2. **`shell.<section>.toml` replaces a section, it does not merge.** Every file
   carries the complete section; a dropped key reverts to a QML default, not to
   the template value.
3. **`hyprland.lua.example` and the terminal configs are hand-written**, so their
   colours are not generated. Keep the border values in step with
   `hyprland_active_border` / `hyprland_inactive_border`, and the terminal
   palettes with `colors.toml`.

## After changing anything

```bash
omarchy theme set abstract-black        # stderr must be empty: nothing dropped
hyprctl configerrors                    # must be empty
grep -r '{{' ~/.local/state/omarchy/current/theme/ \
  --exclude-dir=tools --exclude-dir=docs --exclude-dir=brand \
  --exclude=README.md --exclude=CLAUDE.md    # must find nothing
```

Re-applying advances the wallpaper rotation; this machine pins it back with
`~/.local/bin/omarchy-bg-pin`.

Editing `colors.toml` makes `preview.png` and `preview-full.png` stale
(`PREVIEW_WORKSPACE=<n> ./tools/capture-preview.sh`, needs an empty
workspace and Files closed; commit first, Neovim's git signs mark uncommitted lines in the
shot) and `unlock.png` / `preview-unlock.png` stale
(`./tools/generate-unlock.sh`).

The boot splash is applied separately, only on request:

```bash
omarchy-plymouth-set-by-theme abstract-black   # sudo + mkinitcpio, takes a while
```

## Machine context

`gtk.css` only reaches GTK apps through
`~/.config/gtk-4.0/gtk.css -> ~/.local/state/omarchy/current/theme/gtk.css`.
That symlink is machine config, not part of this repo. GTK parses CSS at
startup, so Files needs `nautilus -q` before it repaints.

Git: this repo was initialised on `dev` and has no `main` yet, per the user's
rule that `main` is only ever reached through a pull request.
