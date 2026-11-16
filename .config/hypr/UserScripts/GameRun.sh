#!/usr/bin/env bash
# Runs a game for GameLauncher.py:
#   GameRun.sh [--gamescope] [--hud] NAME COMMAND...   (e.g. umu-run game.exe, or the Eden
#                                                emulator; WINEPREFIX etc. come from the launcher)
# - game mode on for the session (no blur/animations, theme pack paused) unless
#   it already was, and back off when the game exits
# - gamemoderun (CPU governor boost while it runs)
# - --gamescope: inside gamescope at the focused monitor's size and refresh rate
# - MangoHud (fps, frame times, CPU/GPU temperature and load, RAM/VRAM) is always
#   loaded, hidden; Alt+R in the game shows / hides it (like NVIDIA's overlay), --hud starts it shown
# - the time played is added to ~/.local/state/game-launcher.json
scope=false hud=false
while [[ ${1:-} == --* ]]; do
  case $1 in --gamescope) scope=true ;; --hud) hud=true ;; esac
  shift
done
# toggle_hud: MangoHud reads the key itself while the game window has focus
export MANGOHUD_CONFIG="toggle_hud=Alt_L+r,fps,frametime,frame_timing=1,cpu_temp,gpu_temp,cpu_stats,gpu_stats,ram,vram,position=top-left"
$hud || MANGOHUD_CONFIG+=",no_display"
name=$1; shift
scripts="$HOME/.config/hypr/scripts"
state="$HOME/.local/state/game-launcher.json"

turned_on=false
if [[ $(hyprctl repl 'hl.get_config("animations.enabled")' 2>/dev/null) == true ]]; then
  "$scripts/GameMode.sh" && turned_on=true
fi

cmd=(mangohud gamemoderun "$@")
if $scope; then
  read -r w h r < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.width) \(.height) \(.refreshRate | floor)"')
  cmd=(gamescope -W "${w:-1920}" -H "${h:-1080}" -r "${r:-60}" -f --force-grab-cursor -- "${cmd[@]}")
fi

# flyout with the game's icon (GAME_ICON from the launcher) and a line from the
# theme pack ("Swinging into …" for Spider-Man)
line() {  # line KIND FALLBACK: a pack line with the game's name in it
  local l
  l=$("$scripts/Pack.sh" quip "$1")
  l=${l:-$2}
  echo "${l//\{game\}/$name}"
}
say() {  # say TITLE SUBTITLE [sticky]
  local extra
  extra=$(jq -nc --arg i "${GAME_ICON:-}" --argjson s "${3:-false}" \
    '{sticky: $s} + (if ($i != "" and ($i | test("^/"))) then {image: $i} else {} end)')
  qs ipc call osd rich game "$1" "$2" "$extra" >/dev/null 2>&1
}

# is PID the game process or one of its children (gamescope, Proton, Wine…)?
ours() {
  local p=$1
  while [[ -n $p && $p -gt 1 ]]; do
    [[ $p == "$gpid" ]] && return 0
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
  return 1
}

start=$(date +%s)
opened=false
"${cmd[@]}" &
gpid=$!

# loading: the flyout stays up (counting) until a window of the game appears,
# or the game exits first
first=$(jq -r --arg n "$name" '.[$n].played // 0' "$state" 2>/dev/null || echo 0)
hint=""; [[ ${first:-0} == 0 ]] && hint=" · first launch can take a minute"
title=$(line gameStart "Starting {game}")
say "$title" "Loading…$hint" true
while kill -0 "$gpid" 2>/dev/null; do
  sleep 1
  opened=false
  while read -r pid; do ours "$pid" && { opened=true; break; }; done < <(hyprctl clients -j | jq -r '.[].pid')
  $opened && break
  t=$(( $(date +%s) - start ))
  (( t % 3 == 0 )) && say "$title" "Loading… ${t} s$hint" true
done
qs ipc call osd dismissKind game >/dev/null 2>&1

wait "$gpid"
played=$(( $(date +%s) - start ))
if ! $opened && (( played < 20 )); then
  say "$name closed while loading" "It didn't open a window. Try Alt+Enter (without gamescope)"
  $turned_on && "$scripts/GameMode.sh"
  exit 0
fi

h=$(( played / 3600 )) m=$(( played % 3600 / 60 ))
say "$(line gameEnd "Back from {game}")" "$name · $( (( h )) && echo "$h h ")$m min played"

mkdir -p "${state%/*}"
[[ -s $state ]] || echo '{}' > "$state"
jq --arg n "$name" --argjson s "$played" --argjson now "$(date +%s)" \
  '.[$n].played = ((.[$n].played // 0) + $s) | .[$n].last = $now' "$state" > "$state.tmp" && mv "$state.tmp" "$state"

$turned_on && "$scripts/GameMode.sh"
exit 0
