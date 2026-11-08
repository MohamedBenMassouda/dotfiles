#!/usr/bin/env bash
# Desktop sounds (synthesized, in ~/.config/hypr/assets/sounds):
#   Sounds.sh --screenshot   web-shooter "thwip"
#   Sounds.sh --notify       softer thwip (Quickshell plays it for new notifications)
#   Sounds.sh --error        spider-sense tingle (also warnings in the flyout)
# Set mute=true to silence them all.
mute=false
$mute && exit 0

dir="$HOME/.config/hypr/assets/sounds"
case $1 in
  --screenshot) f=thwip.wav; vol=0.7 ;;
  --notify) f=thwip-soft.wav; vol=0.4 ;;
  --error) f=spider-sense.wav; vol=0.6 ;;
  *) echo "Available sounds: --screenshot, --notify, --error"; exit 0 ;;
esac
exec pw-play --volume "$vol" "$dir/$f"
