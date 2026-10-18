#!/usr/bin/env bash
# Install the theme, in full, from this checkout:
#
#   ./tools/install-theme.sh
#
#   ~/.config/omarchy/themes/abstract-black   preview.png -> preview-full.png
#
# A real directory of absolute symlinks into this repo, so every file is still
# the repo's own.
#
# A `<name>.example` file is linked in as `<name>`, replacing the plain file of
# that name if there is one. That is how the glass gets in: hyprland.lua and
# the terminal configs exist here only as `.example`, because omarchy-theme-set
# drops them from a theme cloned by `omarchy theme install`, and the
# shell.*.toml.example files are the translucent cards that need the blur
# hyprland.lua sets up.
#
# The links are absolute: omarchy-theme-set stages with `cp -r`, which copies
# symlinks verbatim, so a relative link would point nowhere once staged in
# ~/.local/state/omarchy/current/theme.
#
# `.git` must never be linked in: omarchy-theme-set treats a theme directory
# holding `.git` as installed from a repo and strips every *.lua from it.
#
# unlock.png is copied, not linked: omarchy-plymouth-set refuses a symlinked
# logo, so "Set unlock" fails on a link.
#
# Rerun after adding or renaming a top-level file in the repo, or after
# changing unlock.png.
set -euo pipefail
shopt -s nullglob dotglob

cd "$(dirname "$0")/.."
REPO=$PWD
THEMES=$HOME/.config/omarchy/themes
DIR=$THEMES/abstract-black
MARKER=.abstract-black-links

# Replace the theme only if it is ours: a symlink, or a directory this script
# built (it carries the marker file).
if [[ -L $DIR ]]; then
  rm "$DIR"
elif [[ -d $DIR ]]; then
  if [[ ! -f $DIR/$MARKER ]]; then
    echo "refusing to replace $DIR: it was not created by this script" >&2
    echo "if it came from \`omarchy theme install\`, remove it first: omarchy theme remove abstract-black" >&2
    exit 1
  fi
  rm -rf "$DIR"
fi

mkdir -p "$DIR"
touch "$DIR/$MARKER"

for entry in "$REPO"/*; do
  name=${entry##*/}
  case $name in
    .git | .gitignore | CLAUDE.md | preview.png | preview-full.png) continue ;;
    unlock.png) cp "$entry" "$DIR/$name" ;;
    *.example) ln -s "$entry" "$DIR/${name%.example}" ;;
    *) [[ -e $entry.example ]] || ln -s "$entry" "$DIR/$name" ;;
  esac
done
ln -s "$REPO/preview-full.png" "$DIR/preview.png"

echo "abstract-black -> $DIR ($(find "$DIR" -maxdepth 1 -type l | wc -l) links)"
echo
echo "Apply it with:  omarchy theme set abstract-black"
