#!/usr/bin/env bash
# Capture the theme-switcher thumbnails from the running desktop:
#
#   PREVIEW_WORKSPACE=8 ./tools/capture-preview.sh
#
#   preview.png        the theme as `omarchy theme install` leaves it
#   preview-full.png   the theme from install-theme.sh, with the glass
#
# The theme is applied for real before each shot (fastfetch prints the active
# theme's name, so a picture taken under the wrong theme is visibly wrong), and
# two floating windows are opened over the lattice wallpaper: fastfetch on the
# left, a theme file in Neovim on the right. They are set wide
# apart and roughly centred so the wallpaper's extruded ribs cross both window
# edges — that is where the blur and the lit rim actually show — and so the bar
# stays visible above them.
#
# fastfetch runs with `--logo none`: its default ASCII logo is Omarchy's, in a
# neon green that has nothing to do with this palette and, at this window size,
# swamps it. Without it the pane shows the info block and fastfetch's own
# 16-colour row, which is the theme's ANSI ramp — a better advert for a theme
# than a distro logo.
#
# The theme must be installed by install-theme.sh, and the workspace must be
# EMPTY; the script switches to it itself and switches back to the one you
# were on afterwards. The theme that was active before is also put back, the
# install is rebuilt, and the windows are always closed, even if a step fails.
#
# Switching is `hl.dsp.focus({ workspace = ... })` — Omarchy 4 replaces
# Hyprland's own dispatcher names with a Lua API, so a plain
# `hyprctl dispatch workspace 4` reports `ok` and does nothing.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO=$PWD
INSTALLED=$HOME/.config/omarchy/themes/abstract-black
MARKER=.abstract-black-links
# The theme path is spliced into a Hyprland exec string; allow only plain path
# characters so a space or a quote in it cannot break or extend that command.
[[ $INSTALLED =~ ^[A-Za-z0-9._/+-]+$ ]] || {
  echo "the themes directory has a space or a quote in its path: $INSTALLED" >&2
  exit 1
}
[[ -f $INSTALLED/$MARKER ]] || {
  echo "run ./tools/install-theme.sh first" >&2
  exit 1
}
WS=${PREVIEW_WORKSPACE:-8}
ORIGINAL_WS=$(hyprctl monitors -j | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['activeWorkspace']['name'])")
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
  [[ -z ${ORIGINAL_WS:-} ]] || goto_workspace "$ORIGINAL_WS" || true
  local now
  now=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
  if [[ -n $ORIGINAL_THEME && $now != "$ORIGINAL_THEME" ]]; then
    omarchy-theme-set "$ORIGINAL_THEME" >/dev/null 2>&1 || true
  fi
  [[ ! -d $INSTALLED/.git ]] || "$REPO/tools/install-theme.sh" >/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

# Ask for the workspace and wait for it to actually land: a dispatch can be
# undone a moment later by anything else driving the session.
goto_workspace() {
  local target=$1 i
  for i in 1 2 3 4 5; do
    hyprctl dispatch "hl.dsp.focus({ workspace = \"$target\" })" >/dev/null 2>&1 || true
    sleep 0.6
    [[ $(hyprctl monitors -j | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['activeWorkspace']['name'])") == "$target" ]] && return 0
  done
  return 1
}

goto_workspace "$WS" || {
  echo "could not switch to workspace $WS (something keeps switching it back)" >&2
  exit 1
}

read -r MONITOR MX MY MW MH SCALE < <(hyprctl monitors -j | python3 -c "
import json, sys
m = next((m for m in json.load(sys.stdin) if m['activeWorkspace']['name'] == '$WS'), None)
print(*(m['name'], m['x'], m['y'], m['width'], m['height'], m['scale']) if m else '')")
[[ -n ${MONITOR:-} ]] || {
  echo "switch a monitor to workspace $WS first" >&2
  exit 1
}
if ! hyprctl clients -j | python3 -c "import json,sys; sys.exit(any(c['workspace']['name']=='$WS' for c in json.load(sys.stdin)))"; then
  echo "workspace $WS is not empty" >&2
  exit 1
fi

# Window geometry in the monitor's logical space, as fractions of its size, so
# the composition holds whatever the screen. Both windows span 22% to 80% of
# the height, which leaves the bar clear at the top and wallpaper visible all
# round, and are wide enough (44%) for fastfetch to lay out without wrapping.
# The scene was composed on a 2048-wide logical screen at foot's 9 pt. The
# font scales with the screen, so fastfetch lays out the same on a smaller one.
read -r LW LH LX LY RW RH RX RY FONT_SIZE PX PY < <(python3 -c "
w = $MW / $SCALE; h = $MH / $SCALE
print(int(w*0.44), int(h*0.58), int(w*0.025), int(h*0.22),
      int(w*0.44), int(h*0.58), int(w*0.535), int(h*0.22),
      round(9 * w / 2048, 1), int($MX + w) - 1, int($MY + h) - 1)")

# The pointer shows up in the shot when it rests on this workspace. Parked on
# the last pixel of the monitor, the arrow is drawn off-screen.
park_pointer() {
  hyprctl dispatch "hl.dsp.cursor.move({ x = $PX, y = $PY })" >/dev/null 2>&1 || true
}

open_window() {
  local w=$1 h=$2 x=$3 y=$4
  shift 4
  # `move` in a window rule is relative to the monitor the window opens on.
  hyprctl dispatch "hl.dsp.exec_cmd(\"[workspace $WS silent; float; size $w $h; move $x $y] uwsm-app -- foot -T $TAG -f monospace:size=$FONT_SIZE -e $*\")" >/dev/null
  sleep 0.8
}

# Turn the installed theme into what `omarchy theme install` would leave
# there: a copy of the checkout holding a `.git`, which is the whole of the
# test omarchy-theme-set applies before it filters a theme. The marker lets
# install-theme.sh replace the copy afterwards.
stage_cloned_install() {
  rm -rf "$INSTALLED"
  mkdir -p "$INSTALLED/.git"
  touch "$INSTALLED/$MARKER"
  cp -r "$REPO"/* "$INSTALLED/"
}

shoot() {
  local out=$1 file=$2
  # stderr carries the list of files Omarchy dropped from the cloned copy.
  omarchy-theme-set "$THEME" >/dev/null 2>&1
  # Applying a theme advances the wallpaper rotation; the preview is always on
  # the lattice wallpaper.
  omarchy-theme-bg-set "$HOME/.local/state/omarchy/current/theme/backgrounds/$PIN_BG" >/dev/null 2>&1 || true
  sleep 5

  # -n -R: no swap file and read-only, so killing it leaves nothing behind.
  open_window "$RW" "$RH" "$RX" "$RY" "nvim -n -R $INSTALLED/$file"
  # fastfetch opens last and so holds the focus, with echo off: keys typed
  # during the run then leave no mark in either window.
  open_window "$LW" "$LH" "$LX" "$LY" "sh -c 'fastfetch --logo none; stty -echo; sleep 120'"
  # Long enough for lua_ls to finish loading; its progress line sits in the
  # status bar until then.
  sleep 9

  # omarchy-theme-set hands focus to a window it retints some seconds after it
  # returns, on whatever workspace that window is; come back before shooting.
  goto_workspace "$WS" || true
  # Shoot only if the monitor is on the workspace we set up. Anything else
  # driving the session can switch it back mid-run, and a shot taken then is a
  # picture of whatever the user actually had open — wrong, and not ours to
  # keep.
  local now_ws
  now_ws=$(hyprctl monitors -j | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['activeWorkspace']['name'])")
  if [[ $now_ws != "$WS" ]]; then
    echo "workspace moved to $now_ws during the shot; nothing captured." >&2
    echo "rerun when the session is idle." >&2
    exit 1
  fi

  park_pointer
  grim -o "$MONITOR" "$TMP/shot.png"
  close_windows

  # 1800x1012, the size the theme switcher thumbnails are drawn from. Cut from
  # the top, so a 16:10 panel loses its bottom edge and keeps the bar.
  magick "$TMP/shot.png" -resize 1800x -gravity north -extent 1800x1012 \
    -strip -define png:compression-level=9 "$out"
}

shoot preview-full.png hyprland.lua

# Straight after the full theme, whose hyprland.lua switched hyprglass off: the
# cloned copy has no Lua to do that, and the plugin keeps its last setting.
stage_cloned_install
shoot preview.png colors.toml
"$REPO/tools/install-theme.sh" >/dev/null

magick identify preview.png preview-full.png
