#!/usr/bin/env bash
# The desktop theme pack, for scripts (Quickshell has Pack.qml):
#   Pack.sh               name of the chosen pack ("none" = plain desktop)
#   Pack.sh dir           its folder (nothing when none)
#   Pack.sh text KEY      a text line from its pack.json (%u user, %h host), e.g. terminal
#   Pack.sh quip KIND     a random line from its pack.json "quips" (nothing when none)
#   Pack.sh pause|resume  game mode: everything acts as "none" until resumed
packs="$HOME/.config/quickshell/packs"
paused="${XDG_RUNTIME_DIR:-/tmp}/desktop-pack-paused"
# game mode also caps the CPU's top speed (pause and resume are its on/off, from GameMode.sh
# and UserConfigs/AutoGameMode.lua): 80% keeps the laptop cooler (it reached 89°C) for almost
# no FPS. Needs system/tmpfiles.d/cpu-game-cap.conf installed, else it's skipped.
cpu_cap=/sys/devices/system/cpu/intel_pstate/max_perf_pct
GAME_CPU_PERCENT=80
case ${1:-} in
  pause) touch "$paused"; [[ -w $cpu_cap ]] && echo "$GAME_CPU_PERCENT" > "$cpu_cap"
         exec qs ipc call panel packPaused true >/dev/null 2>&1 ;;
  resume) rm -f "$paused"; [[ -w $cpu_cap ]] && echo 100 > "$cpu_cap"
          exec qs ipc call panel packPaused false >/dev/null 2>&1 ;;
esac
name=$(cat "$HOME/.local/state/desktop-pack" 2>/dev/null)
name=${name:-spiderman}
dir="$packs/$name"
[[ $name != none && -f $dir/pack.json && ! -e $paused ]] || { name=none dir=; }

case ${1:-} in
  "") echo "$name" ;;
  dir) echo "$dir" ;;
  quip)
    [[ -n $dir ]] || exit 0
    n=$(jq -r --arg k "$2" '.quips[$k] // [] | length' "$dir/pack.json")
    (( n > 0 )) && jq -r --arg k "$2" --argjson i $((RANDOM % n)) '.quips[$k][$i]' "$dir/pack.json"
    ;;
  text)
    [[ -n $dir ]] || exit 0
    jq -r --arg k "$2" '.[$k] // empty' "$dir/pack.json" | sed "s/%u/$USER/g; s/%h/$(cat /etc/hostname)/g"
    ;;
esac
