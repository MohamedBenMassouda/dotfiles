#!/usr/bin/env bash
# WaybarCava.sh — safer single-instance handling, cleanup, and robustness
# Original concept by JaKooLit; this variant focuses on lifecycle hardening.

set -euo pipefail

# Ensure cava exists
if ! command -v cava >/dev/null 2>&1; then
  echo "cava not found in PATH" >&2
  exit 1
fi

# 0..7 → ▁▂▃▄▅▆▇█
bar="▁▂▃▄▅▆▇█"
dict="s/;//g"
bar_length=${#bar}
for ((i = 0; i < bar_length; i++)); do
  dict+=";s/$i/${bar:$i:1}/g"
done

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"

# No single-instance guard here on purpose. waybar execs this module more than
# once and reads each copy's stdout separately, so killing "duplicates" blanks
# a live widget. The old pidfile guard also could not work: it tracked the
# wrapper's pid, and killing the wrapper left cava orphaned. The leak is fixed
# by the EXIT trap below instead - each wrapper reaps its own cava, so nothing
# accumulates across waybar reloads.
rm -f "$RUNTIME_DIR/waybar-cava.pid"

# Unique temp config + cleanup on exit
config_file="$(mktemp "$RUNTIME_DIR/waybar-cava.XXXXXX.conf")"
cleanup() {
  [[ -n "${cava_pid:-}" ]] && kill "$cava_pid" 2>/dev/null
  rm -f "$config_file"
}
trap cleanup EXIT INT TERM

cat >"$config_file" <<EOF
[general]
framerate = 30
bars = 10

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Stream cava output and translate digits 0..7 to bar glyphs.
# Process substitution (not a pipe) so $! is cava's own pid - a pipeline would
# give us sed's pid instead, and killing sed leaves cava running.
cava -p "$config_file" > >(sed -u "$dict") &
cava_pid=$!
wait "$cava_pid"
