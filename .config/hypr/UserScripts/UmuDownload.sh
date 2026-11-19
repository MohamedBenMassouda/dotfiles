#!/usr/bin/env bash
# Prints "MB NAME" (e.g. "363 Proton 11.0-2e") while umu-run downloads something (a new
# Proton or Steam runtime: one-time, several hundred MB), prints nothing otherwise. GameRun.sh and GameLauncher.py
# use it for the sticky "Downloading" flyout. umu writes the download as <archive>.parts
# in a temp folder under $TMPDIR or ~/.cache/umu (umu_proton.py / umu_runtime.py).
shopt -s nullglob dotglob
now=$(date +%s)
for f in "${TMPDIR:-/tmp}"/tmp*/*.parts "${XDG_CACHE_HOME:-$HOME/.cache}"/umu/*/*.parts; do
  (( now - $(stat -c %Y "$f") < 15 )) || continue   # still growing, not a leftover of a cancelled one
  name=${f##*/}
  name=${name%.parts}
  name=${name%%.tar.*}
  name=${name%-x86_64}
  case $name in
    UMU-Proton-*) name="Proton ${name#UMU-Proton-}" ;;
    SteamLinuxRuntime*) name="the Steam runtime" ;;
  esac
  echo "$(( $(stat -c %s "$f") / 1048576 )) $name"
  exit 0
done
