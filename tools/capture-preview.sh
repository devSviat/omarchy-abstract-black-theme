#!/usr/bin/env bash
# Capture the theme-switcher thumbnail from the running desktop:
#
#   PREVIEW_WORKSPACE=8 ./tools/capture-preview.sh
#
#   preview.png   the scene Omarchy Menu -> Style -> Theme shows for this theme
#
# The theme is applied for real before the shot (fastfetch prints the active
# theme's name, so a picture taken under the wrong theme is visibly wrong), and
# two floating windows are opened over the lattice wallpaper: fastfetch on the
# left, this theme's hyprland.lua in Neovim on the right. They sit low and wide
# apart so the wallpaper's extruded ribs cross both window edges — that is
# where the blur and the lit rim actually show.
#
# Needs a monitor showing an EMPTY workspace (8 by default). The theme that was
# active before is put back at the end, and the windows are always closed, even
# if a step fails.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO=$PWD
# The repo path is spliced into a Hyprland exec string; allow only plain path
# characters so a space or a quote in it cannot break or extend that command.
[[ $REPO =~ ^[A-Za-z0-9._/+-]+$ ]] || {
  echo "move the checkout to a path without spaces or quotes: $REPO" >&2
  exit 1
}
WS=${PREVIEW_WORKSPACE:-8}
THEME=abstract-black
TAG=ab-preview
PIN_BG=00-dark-background-abstract-network-3d-3840x2160-8324.png

TMP=$(mktemp -d)
ORIGINAL_THEME=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)

preview_pids() {
  local pid
  for pid in $(pgrep -x foot); do
    tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | grep -q "$TAG" && echo "$pid"
  done
  return 0
}

close_windows() {
  local pids
  pids=$(preview_pids)
  [[ -z $pids ]] || kill $pids 2>/dev/null || true
  sleep 1
}

cleanup() {
  close_windows
  local now
  now=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
  if [[ -n $ORIGINAL_THEME && $now != "$ORIGINAL_THEME" ]]; then
    omarchy-theme-set "$ORIGINAL_THEME" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

read -r MONITOR MW MH SCALE < <(hyprctl monitors -j | python3 -c "
import json, sys
m = next((m for m in json.load(sys.stdin) if m['activeWorkspace']['name'] == '$WS'), None)
print(*(m['name'], m['width'], m['height'], m['scale']) if m else '')")
[[ -n ${MONITOR:-} ]] || {
  echo "switch a monitor to workspace $WS first" >&2
  exit 1
}
if ! hyprctl clients -j | python3 -c "import json,sys; sys.exit(any(c['workspace']['name']=='$WS' for c in json.load(sys.stdin)))"; then
  echo "workspace $WS is not empty" >&2
  exit 1
fi

# Window geometry in the monitor's logical space, as fractions of its size, so
# the composition holds whatever the screen. Both windows sit low (40% to 86%
# of the height) and are wide enough (43%) for fastfetch to lay out and print
# the theme's name in full.
read -r LW LH LX LY RW RH RX RY < <(python3 -c "
w = $MW / $SCALE; h = $MH / $SCALE
print(int(w*0.43), int(h*0.46), int(w*0.02), int(h*0.40),
      int(w*0.42), int(h*0.46), int(w*0.56), int(h*0.40))")

open_window() {
  local w=$1 h=$2 x=$3 y=$4
  shift 4
  # `move` in a window rule is relative to the monitor the window opens on.
  hyprctl dispatch "hl.dsp.exec_cmd(\"[workspace $WS silent; float; size $w $h; move $x $y] uwsm-app -- foot -T $TAG -e $*\")" >/dev/null
  sleep 0.8
}

omarchy-theme-set "$THEME" >/dev/null
# Applying a theme advances the wallpaper rotation; the preview is always on
# the lattice wallpaper.
omarchy-theme-bg-set "$HOME/.local/state/omarchy/current/theme/backgrounds/$PIN_BG" >/dev/null 2>&1 || true
sleep 5

open_window "$LW" "$LH" "$LX" "$LY" "sh -c 'fastfetch; sleep 120'"
# -n -R: no swap file and read-only, so killing it leaves nothing behind.
open_window "$RW" "$RH" "$RX" "$RY" "nvim -n -R $REPO/hyprland.lua"
sleep 4

grim -o "$MONITOR" "$TMP/shot.png"
close_windows

# 1800x1012, the size the theme switcher thumbnails are drawn from.
magick "$TMP/shot.png" -resize 1800x -gravity center -extent 1800x1012 \
  -strip -define png:compression-level=9 preview.png

magick identify preview.png
