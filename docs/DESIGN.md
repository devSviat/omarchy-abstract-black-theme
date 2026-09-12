# Abstract Black — design record

2026-09-12. The brief, the decisions, and the measurements behind them.

## Brief

A theme "somewhere between" `omarchy-devsviat-theme` and
`omarchy-star-wars-theme`: Star Wars' animation and background blur, DevSviat's
default wallpaper, a palette carried over from Star Wars and improved, a
genuine colour design of its own, and an unlock screen carrying the Omarchy
logo — the mark, not the wordmark — in the theme's colours.

Slug `abstract-black`. One theme; no hyprglass variant.

Wallpapers, both from DevSviat, both shipped as they are:

- `00-dark-background-abstract-network-3d-3840x2160-8324.png` (default)
- `desert-doom-sand-dunes-dark-background-monochrome-landscape-3840x2160-6409.jpg`

## The one finding that shaped everything

Both wallpapers are **achromatic**. Measured with ImageMagick:

| Wallpaper | Mean | Dominant colours |
|---|---|---|
| lattice | `#141417` | `#101112`, `#1d1e21`, `#242529`, `#2f3036` — all within 3 points of neutral |
| dunes | `#171717` | a pure grey ramp: `#060606`, `#171717`, `#2c2c2c`, `#525252`, `#8c8c8c` |

Star Wars derives its whole palette from its wallpaper — the accent is the
steel-blue smoke around the figure, lifted. That method has nothing to work
with here: there is no hue in either image to extract.

So the colour is a decision. Three directions were rendered over the real
wallpapers at real alpha values and compared side by side; the user chose
**Moonlit Steel**: keep the surfaces true neutral black, and let the one colour
in the chrome be the *light* falling on them — a cold silver-blue.

The two rejected directions, recorded so they are not re-proposed: *Ember
Black* (warm amber `#e8a94e`, a sunrise over the dunes) and *Prism Black*
(monochrome UI with a violet→cyan gradient carrying every focus state).

## Palette

```
background #0b0b0b   dark #080808   darker #050505   lighter #171717
foreground #d7dae0   dark #8d9199   light #e8eaee   bright #ffffff
accent #8fb4de   selection #202329   muted #5a5f6b
red #e5545a  green #57d9a3  yellow #ecc46a  blue #5aa2f0
magenta #a67cf0  cyan #5cd0e0  orange #f0894a  brown #8a7a6a
```

Contrast against `background`, computed (WCAG relative luminance):

| Pair | Ratio |
|---|---|
| `foreground` on `background` | 14.1:1 |
| `accent` on `background` | 9.1:1 |
| `dark_foreground` on `background` | 6.2:1 |
| `muted` on `background` | 3.1:1 — comments and disabled text only |
| white on `accent` | 2.2:1 — **too low**, so anything sitting on an accent fill takes `background` as its text colour (9.1:1). This is what `--accent-fg-color` in `gtk.css` does. |

`background` is deliberately one step *below* the lattice wallpaper's `#141416`
rather than equal to it: window transparency (0.90) lets the wallpaper through
on top, and a surface at exactly the wallpaper's value leaves the window with
no edge of its own.

### The backgrounds must be measured, not eyeballed

The first cut of this palette shipped `#0b0b0e` / `#08080b` / `#17181c` — a
blue channel 3 to 5 points above the red one. It looked neutral in isolation
and was not: translucent surfaces stack, and in Files the sidebar
(`--sidebar-bg-color` at 0.45 over `--window-bg-color` at 0.70) came out at
`rgb(24, 25, 32)`, +8 blue, against content at `rgb(15, 15, 17)`, +2 — the +2
being the wallpaper's own. The panel read plainly blue next to it.

The ramp is now dead neutral (R = G = B in all four values), so the only hue in
the chrome is the accent and `selection`. `selection` itself was halved, from
`#232833` (+16 blue) to `#202329` (+9): it is a highlight and the accent's own
shadow, so it keeps a little, but it is also `hyprland_inactive_border` and was
tinting every unfocused window edge.

Rule for anything added later: in a background value, keep blue equal to red,
and check a composited screenshot rather than the hex.

## What is Star Wars', and what is not

Carried over unchanged, because the brief asked for it:

- the four animation curves and **every** speed — only the names differ
  (`ignite`/`retract`/`glide`/`hyperspace` → `lift`/`settle`/`glide`/`shift`)
- the blur recipe's shape: size 9, 3 passes, noise 0.015
- the transparency ladder: windows 0.90/0.82, terminals 1.0/0.94 over cell
  alpha 0.72, shell surfaces 0.55–0.9
- the layer-rule gate at `ignore_alpha 0.55`, so a menu frosts its card and
  leaves its scrim sharp
- the shell section files, complete rather than partial

Changed, each because the wallpapers are achromatic and near-black:

| Value | Star Wars | Here | Why |
|---|---|---|---|
| `background` | `#0d0e15` (navy-tinted) | `#0b0b0b` (neutral) | any hue in the surfaces reads as a cast against a grey wallpaper, and stacks across translucent layers |
| `rounding` / `rounding_power` | 10 / 3 | 14 / 2.5 | the lattice is built from generously rounded extrusions; at radius 14 a power of 3 reads as visibly squared-off |
| shadow `offset` | `{0, 5}` | `{3, 6}` | both wallpapers are lit from the upper left and cast down-right; the windows join that light instead of sitting in a symmetric halo |
| blur `brightness` | 0.75 | 0.80 | nothing bright is behind the windows to pull down; lower turns the blur to mud |
| blur `vibrancy` | 0.25 | 0.10 | vibrancy saturates what it blurs, and on an achromatic wallpaper it can only invent a colour cast out of sensor noise and JPEG artifacts |
| bar tint | `background` at 0.7 (a step *deeper* than the windows) | `lighter_background` at 0.62 (a step *lighter*) | see below |

### The bar

Star Wars tints the bar with `background`, because the strip under the bar is
the darkest part of its wallpaper and the tint has to carry the colour alone.

Here the wallpaper is already near-black everywhere, so the same choice makes
the bar and the windows composite to nearly the same value and merge into one
field. Measured over the lattice wallpaper: windows land near `#0d0d0e`, while
`#171717` at 0.62 puts the bar at about `#141515` — one step lighter, so it
reads as chrome resting on the black rather than as a hole cut in it.

Both only apply with the bar's own transparent mode off (Omarchy Menu → Style →
Bar → Transparency); with it on the bar draws no background and no theme tint
can reach it.

## Unlock

`brand/omarchy-logo.svg` is the official Omarchy mark from
https://omarchy.org/brand/ — the labyrinth "O". The brief explicitly asked for
the mark and not `omarchy-wordmark.svg`, and asked for it in the theme's
colours.

The file is a single path with one flat `fill="#9ece6a"`, so
`tools/generate-unlock.sh` swaps that for a top-to-bottom gradient
`#d7e4f8` → `#8fb4de` — the same run of light as `hyprland_active_border`, so
the splash and the window rims are lit identically. The script fails loudly if
the brand file ever stops carrying exactly one such fill.

Size 520 px square. Plymouth's `omarchy.script` centres the logo at its native
size and puts the password entry at `logo.y + logo.height + 40`; at 520 px on a
1080-line screen the entry lands at y=840, comfortably on-screen, and the mark
still reads as a mark rather than a wallpaper. The background stays transparent
because Plymouth fills the screen with flat `background` first and an opaque
rectangle would seam.

`preview-unlock.png` reproduces that layout at 1920×1080. Its presence is what
makes the theme appear under Style → Unlock at all.

The Omarchy mark is a pending trademark of the Omarchy Foundation. It is used
here only to identify Omarchy on the boot splash of an Omarchy theme, and
`LICENSE` says the MIT grant does not extend to it.

## Verified on this machine

Omarchy 4, Hyprland, single panel eDP-1 2560×1600 at scale 1.6.

```
omarchy theme set abstract-black   -> exit 0, stderr empty (nothing stripped)
hyprctl configerrors               -> empty
grep -r '{{' <staged theme>        -> no matches
```

Runtime values read back from the compositor after applying:

```
decoration:rounding        14
decoration:rounding_power  2.5
general:gaps_out           9 9 9 9
decoration:blur:enabled    true
decoration:blur:size       9        passes 3
decoration:blur:brightness 0.8      vibrancy 0.1
```

All eleven animation leaves came back enabled, with this theme's curves at the
intended speeds (`windowsIn` 4.5 `lift` popin 70%, `workspaces` 2.5 `shift`
slidefade 20%, and the rest).

Note for future measurement: a 1 px border never lands on a whole device pixel
at scale 1.6, so `border_size` stays at 2 rather than the thinner rim the
design would otherwise want.
