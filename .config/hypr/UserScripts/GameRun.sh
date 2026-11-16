#!/usr/bin/env bash
# Runs a Windows game for GameLauncher.py:
#   GameRun.sh [--gamescope] NAME EXE        (WINEPREFIX etc. come from the launcher)
# - game mode on for the session (no blur/animations, theme pack paused) unless
#   it already was, and back off when the game exits
# - gamemoderun (CPU governor boost while it runs)
# - --gamescope: inside gamescope at the focused monitor's size and refresh rate
# - the time played is added to ~/.local/state/game-launcher.json
scope=false
[[ ${1:-} == --gamescope ]] && { scope=true; shift; }
name=$1 exe=$2
scripts="$HOME/.config/hypr/scripts"
state="$HOME/.local/state/game-launcher.json"

turned_on=false
if [[ $(hyprctl repl 'hl.get_config("animations.enabled")' 2>/dev/null) == true ]]; then
  "$scripts/GameMode.sh" && turned_on=true
fi

cmd=(gamemoderun umu-run "$exe")
if $scope; then
  read -r w h r < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.width) \(.height) \(.refreshRate | floor)"')
  cmd=(gamescope -W "${w:-1920}" -H "${h:-1080}" -r "${r:-60}" -f --force-grab-cursor -- "${cmd[@]}")
fi

start=$(date +%s)
"${cmd[@]}"
played=$(( $(date +%s) - start ))

mkdir -p "${state%/*}"
[[ -s $state ]] || echo '{}' > "$state"
jq --arg n "$name" --argjson s "$played" --argjson now "$(date +%s)" \
  '.[$n].played = ((.[$n].played // 0) + $s) | .[$n].last = $now' "$state" > "$state.tmp" && mv "$state.tmp" "$state"

$turned_on && "$scripts/GameMode.sh"
exit 0
