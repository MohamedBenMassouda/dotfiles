#!/usr/bin/env bash
# Spotifast starts at full volume every launch (its Soloist player always starts at 100%).
# This remembers Spotifast's volume while it plays and puts it back when it starts again.
# Started at login (configs/Startup_Apps.lua); one copy only (the lock file).
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/player-volume.lock"
flock -n 9 || exit 0

PLAYER=spotifast
SAVED="$HOME/.local/state/spotifast-volume"
mkdir -p "${SAVED%/*}"

restore() {   # Soloist can ignore the first change while it's still starting: try twice
  for wait in 2 4; do
    sleep "$wait"
    playerctl -p "$PLAYER" volume "$(cat "$SAVED")" 2>/dev/null
  done
}

fresh=true
# --follow prints the volume on every change, and an empty line when the player closes
playerctl -p "$PLAYER" --follow volume 2>/dev/null | while read -r volume; do
  if [[ -z $volume ]]; then
    fresh=true
    continue
  fi
  if $fresh; then
    fresh=false
    if [[ -s $SAVED ]] && [[ $volume == 1* ]]; then   # just started at full: put the saved level back
      restore
      continue
    fi
  fi
  echo "$volume" > "$SAVED"
done
