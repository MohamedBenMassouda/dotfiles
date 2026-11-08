#!/usr/bin/env bash
# The desktop theme pack, for scripts (Quickshell has Pack.qml):
#   Pack.sh               name of the chosen pack ("none" = plain desktop)
#   Pack.sh dir           its folder (nothing when none)
#   Pack.sh text KEY      a text line from its pack.json (%u user, %h host), e.g. terminal
#   Pack.sh pause|resume  game mode: everything acts as "none" until resumed
packs="$HOME/.config/quickshell/packs"
paused="${XDG_RUNTIME_DIR:-/tmp}/desktop-pack-paused"
case ${1:-} in
  pause) touch "$paused"; exec qs ipc call panel packPaused true >/dev/null 2>&1 ;;
  resume) rm -f "$paused"; exec qs ipc call panel packPaused false >/dev/null 2>&1 ;;
esac
name=$(cat "$HOME/.local/state/desktop-pack" 2>/dev/null)
name=${name:-spiderman}
dir="$packs/$name"
[[ $name != none && -f $dir/pack.json && ! -e $paused ]] || { name=none dir=; }

case ${1:-} in
  "") echo "$name" ;;
  dir) echo "$dir" ;;
  text)
    [[ -n $dir ]] || exit 0
    jq -r --arg k "$2" '.[$k] // empty' "$dir/pack.json" | sed "s/%u/$USER/g; s/%h/$(cat /etc/hostname)/g"
    ;;
esac
