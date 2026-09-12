#!/usr/bin/env bash
# Build the boot-splash assets from Omarchy's own logo:
#
#   ./tools/generate-unlock.sh
#
#   unlock.png          the logo, recoloured into this theme's palette
#   preview-unlock.png  its picker thumbnail
#
# The source is brand/omarchy-logo.svg, the official Omarchy mark (the one
# from https://omarchy.org/brand/, not the OMARCHY wordmark). It is a single
# path filled with the brand green #9ece6a; the script swaps that flat fill
# for a top-to-bottom gradient in this theme's own light — pale silver
# #d7e4f8 down to the accent #8fb4de — the same run of light the window rim
# carries in hyprland.lua. Change either and change both.
#
# unlock.png is NOT a wallpaper. Omarchy hands it to omarchy-plymouth-set,
# which publishes it as logo.png for Plymouth and the SDDM greeter.
# default/plymouth/omarchy.script draws it centred at its NATIVE size and then
# puts the password entry at logo.y + logo.height + 40, so a full-screen image
# pushes the LUKS prompt off the display. LOGO_SIZE below keeps it to a mark.
# Its background must stay transparent: Plymouth fills the screen with flat
# `background` first, so an opaque rectangle behind the logo seams.
#
# preview-unlock.png is only ever a thumbnail: it is what the picker in
# Omarchy Menu -> Style -> Unlock shows for this theme, and its presence is
# also what makes `omarchy plymouth list` offer the theme at all. It
# reproduces the Plymouth layout at 1920x1080.
#
# No network, ImageMagick + rsvg-convert only, and byte-for-byte reproducible:
# a rerun on an unchanged palette leaves git clean.
set -euo pipefail

cd "$(dirname "$0")/.."

SRC=brand/omarchy-logo.svg
LOGO_SIZE=520

# Kept in step with colors.toml by hand; nothing generates this file.
BACKGROUND="#0b0b0e"
FOREGROUND="#d7dae0"
RIM_TOP="#d7e4f8"
RIM_BOTTOM="#8fb4de"

OMARCHY=${OMARCHY_PATH:-/usr/share/omarchy}
ASSETS=$OMARCHY/default/plymouth

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- unlock.png ---------------------------------------------------------
# The brand file carries exactly one `fill="#9ece6a"`, on its single path, so
# the substitution cannot touch anything else; bail out if that ever changes.
if [[ $(grep -c 'fill="#9ece6a"' "$SRC") -ne 1 ]]; then
  echo "$SRC: expected exactly one fill=\"#9ece6a\" to recolour" >&2
  exit 1
fi

sed -e 's|<svg |<svg data-recoloured="abstract-black" |' \
    -e "s|fill=\"#9ece6a\"|fill=\"url(#rim)\"|" \
    -e "s|><path|><defs><linearGradient id=\"rim\" x1=\"0\" y1=\"0\" x2=\"0\" y2=\"1\"><stop offset=\"0\" stop-color=\"$RIM_TOP\"/><stop offset=\"1\" stop-color=\"$RIM_BOTTOM\"/></linearGradient></defs><path|" \
    "$SRC" >"$TMP/logo.svg"

rsvg-convert --width="$LOGO_SIZE" --height="$LOGO_SIZE" --keep-aspect-ratio \
  --background-color=none "$TMP/logo.svg" -o "$TMP/logo.png"

magick "$TMP/logo.png" -depth 8 -strip -define png:compression-level=9 unlock.png

# --- preview-unlock.png -------------------------------------------------
# Mirrors default/plymouth/omarchy.script: logo centred, entry 40 px below it,
# lock scaled to 80% of the entry height and set 15 px to its left, bullets
# 7 px on a 12 px pitch starting 20 px into the entry.
W=1920
H=1080

read -r LOGO_W LOGO_H < <(magick identify -format '%w %h\n' unlock.png)
LOGO_X=$(((W - LOGO_W) / 2))
LOGO_Y=$(((H - LOGO_H) / 2))

read -r ENTRY_W ENTRY_H < <(magick identify -format '%w %h\n' "$ASSETS/entry.png")
ENTRY_X=$(((W - ENTRY_W) / 2))
ENTRY_Y=$((LOGO_Y + LOGO_H + 40))

LOCK_H=$((ENTRY_H * 8 / 10))
LOCK_W=$((84 * LOCK_H / 96))
LOCK_X=$((ENTRY_X - LOCK_W - 15))
LOCK_Y=$((ENTRY_Y + (ENTRY_H - LOCK_H) / 2))

# omarchy-plymouth-set recolours these three the same way, to `foreground`.
for asset in entry lock bullet; do
  magick "$ASSETS/$asset.png" -channel RGB \
    +level-colors "$FOREGROUND","$FOREGROUND" "$TMP/$asset.png"
done

magick -size ${W}x${H} xc:"$BACKGROUND" \
  unlock.png -geometry +${LOGO_X}+${LOGO_Y} -compose over -composite \
  \( "$TMP/entry.png" \) -geometry +${ENTRY_X}+${ENTRY_Y} -composite \
  \( "$TMP/lock.png" -resize ${LOCK_W}x${LOCK_H}! \) -geometry +${LOCK_X}+${LOCK_Y} -composite \
  "$TMP/stage.png"

BULLET_Y=$((ENTRY_Y + ENTRY_H / 2 - 3))
args=()
for i in 0 1 2 3; do
  args+=(\( "$TMP/bullet.png" -resize 7x7! \)
         -geometry "+$((ENTRY_X + 20 + i * 12))+${BULLET_Y}" -composite)
done

magick "$TMP/stage.png" "${args[@]}" \
  -depth 8 -strip -define png:compression-level=9 preview-unlock.png

magick identify unlock.png preview-unlock.png
