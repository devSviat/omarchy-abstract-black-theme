#!/usr/bin/env bash
# Install the theme from this checkout:
#
#   ./tools/install-theme.sh
#
#   ~/.config/omarchy/themes/abstract-black -> symlink to this repo
#
# A symlink, deliberately. omarchy-theme-set treats a theme directory holding
# `.git` as installed from a repo and strips every *.lua, the four terminal
# configs and vscode.json from it — which here is the blur, the animations and
# all of the terminal transparency. A symlink fails that check and stages in
# full, so never `omarchy theme install` this theme.
#
# The link is absolute: omarchy-theme-set stages with `cp -r`, which copies
# symlinks verbatim, so a relative link would point nowhere once staged in
# ~/.local/state/omarchy/current/theme.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO=$PWD
THEMES=$HOME/.config/omarchy/themes
LINK=$THEMES/abstract-black

if [[ -e $LINK && ! -L $LINK ]]; then
  echo "refusing to replace $LINK: it is a real directory, not a symlink" >&2
  exit 1
fi

mkdir -p "$THEMES"
ln -sfn "$REPO" "$LINK"

echo "abstract-black -> $(readlink "$LINK")"
echo
echo "Apply it with:  omarchy theme set abstract-black"
