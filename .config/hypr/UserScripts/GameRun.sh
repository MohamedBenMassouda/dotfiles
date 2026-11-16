#!/usr/bin/env bash
# Runs a game for GameLauncher.py:
#   GameRun.sh [--gamescope] [--hud] NAME COMMAND...   (e.g. umu-run game.exe, or the Eden
#                                                emulator; WINEPREFIX etc. come from the launcher)
# - game mode on for the session (no blur/animations, theme pack paused) unless
#   it already was, and back off when the game exits
# - gamemoderun (CPU governor boost while it runs)
# - --gamescope: inside gamescope at the focused monitor's size and refresh rate
# - --hud: MangoHud overlay (fps, frame times, CPU/GPU temperature and load, RAM/VRAM)
# - the time played is added to ~/.local/state/game-launcher.json
scope=false hud=false
while [[ ${1:-} == --* ]]; do
  case $1 in --gamescope) scope=true ;; --hud) hud=true ;; esac
  shift
done
export MANGOHUD_CONFIG="fps,frametime,frame_timing=1,cpu_temp,gpu_temp,cpu_stats,gpu_stats,ram,vram,position=top-left"
name=$1; shift
scripts="$HOME/.config/hypr/scripts"
state="$HOME/.local/state/game-launcher.json"

turned_on=false
if [[ $(hyprctl repl 'hl.get_config("animations.enabled")' 2>/dev/null) == true ]]; then
  "$scripts/GameMode.sh" && turned_on=true
fi

cmd=(gamemoderun "$@")
$hud && ! $scope && cmd=(mangohud "${cmd[@]}")
if $scope; then
  read -r w h r < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.width) \(.height) \(.refreshRate | floor)"')
  hudopt=()
  $hud && hudopt=(--mangoapp)
  cmd=(gamescope -W "${w:-1920}" -H "${h:-1080}" -r "${r:-60}" -f --force-grab-cursor "${hudopt[@]}" -- "${cmd[@]}")
fi

# flyout with the game's icon (GAME_ICON from the launcher) and a line from the
# theme pack ("Swinging into …" for Spider-Man)
say() {  # say KIND FALLBACK SUBTITLE
  local line extra='{}'
  line=$("$scripts/Pack.sh" quip "$1")
  line=${line:-$2}
  [[ -f ${GAME_ICON:-} ]] && extra=$(jq -nc --arg i "$GAME_ICON" '{image: $i}')
  qs ipc call osd rich game "${line//\{game\}/$name}" "$3" "$extra" >/dev/null 2>&1
}
say gameStart "Starting {game}" "$name"

start=$(date +%s)
"${cmd[@]}"
played=$(( $(date +%s) - start ))

h=$(( played / 3600 )) m=$(( played % 3600 / 60 ))
say gameEnd "Back from {game}" "$name · $( (( h )) && echo "$h h ")$m min played"

mkdir -p "${state%/*}"
[[ -s $state ]] || echo '{}' > "$state"
jq --arg n "$name" --argjson s "$played" --argjson now "$(date +%s)" \
  '.[$n].played = ((.[$n].played // 0) + $s) | .[$n].last = $now' "$state" > "$state.tmp" && mv "$state.tmp" "$state"

$turned_on && "$scripts/GameMode.sh"
exit 0
