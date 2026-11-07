#!/usr/bin/env bash
# Start/stop recording the focused monitor with gpu-screen-recorder (uses the GPU encoder).
# Saves to ~/Videos/Recordings. Press the same key again to stop.
set -euo pipefail

icon="$HOME/.config/swaync/images/ja.png"
dir="$HOME/Videos/Recordings"

# match the full command: the process name is cut to 15 chars, so -x never matched
if pkill -SIGINT -f '^gpu-screen-recorder'; then
  qs ipc call osd toast record-off "Recording saved" "$dir" >/dev/null 2>&1 || notify-send -e -u low -i "$icon" " Recording saved" "$dir"
  exit 0
fi

command -v gpu-screen-recorder >/dev/null || {
  notify-send -u normal -i "$icon" " Recording" "Install gpu-screen-recorder first"; exit 1; }

mkdir -p "$dir"
monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
out="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"

qs ipc call osd toast record "Recording $monitor" "SUPER+SHIFT+R or the bar's red dot to stop" >/dev/null 2>&1 ||
  notify-send -e -u low -i "$icon" " Recording $monitor" "Press SUPER+SHIFT+R to stop"
exec gpu-screen-recorder -w "$monitor" -f 60 -a default_output -o "$out"
