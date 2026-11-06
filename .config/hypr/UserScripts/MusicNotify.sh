#!/usr/bin/env bash
# Notify on track change, with album art.
#
# Spotify (and most MPRIS players) send no desktop notification of their own,
# and their mpris:artUrl is a remote https URL that notify-send cannot render.
# So: follow MPRIS, cache the artwork to a local file, and notify with that.

set -uo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/music-art"
mkdir -p "$CACHE"

# Keep only the newest $KEEP covers (~30KB each, so the cap is a few MB).
# This runs on a counter inside the loop, not just at startup: a Hyprland
# session can stay up for days, and a startup-only prune would let the cache
# grow unbounded for the whole session.
KEEP=100
PRUNE_EVERY=25
prune() {
  # shellcheck disable=SC2012
  ls -1t "$CACHE" 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
    rm -f "$CACHE/$old"
  done
}
prune

# -F follows changes. It also fires on play/pause and position updates, so
# dedupe on trackid or every seek would re-notify.
last=""
since_prune=0
playerctl -F metadata \
  --format '{{mpris:trackid}}|{{xesam:title}}|{{xesam:artist}}|{{mpris:artUrl}}' \
  2>/dev/null |
while IFS='|' read -r id title artist art; do
  [[ -z "$title" ]] && continue
  [[ "$id" == "$last" ]] && continue
  last="$id"

  if (( ++since_prune >= PRUNE_EVERY )); then
    since_prune=0
    prune
  fi

  icon=""
  case "$art" in
    file://*)
      icon="${art#file://}"
      ;;
    http*)
      # Cache by the URL's basename - the same track reuses the same file.
      icon="$CACHE/${art##*/}"
      if [[ ! -s "$icon" ]]; then
        curl -sfL --max-time 5 "$art" -o "$icon" || { rm -f "$icon"; icon=""; }
      fi
      ;;
  esac
  [[ -n "$icon" && ! -s "$icon" ]] && icon=""

  # The synchronous hint makes each new track replace the previous popup
  # instead of stacking one notification per song.
  notify-send -a "Music" \
    -i "${icon:-audio-x-generic-symbolic}" \
    -h string:x-canonical-private-synchronous:music \
    "$title" "$artist"
done
