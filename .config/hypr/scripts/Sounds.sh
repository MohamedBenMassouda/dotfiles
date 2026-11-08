#!/usr/bin/env bash
# Desktop sounds (synthesized, in ~/.config/hypr/assets/sounds):
#   Sounds.sh --screenshot   web-shooter "thwip"
#   Sounds.sh --notify       softer thwip (Quickshell plays it for new notifications)
#   Sounds.sh --error        spider-sense tingle (also warnings in the flyout)
# Set mute=true to silence them all.
mute=false
$mute && exit 0

# Your own sounds go in ~/.local/share/sounds/desktop/ (same file names) and win
# over the built-in ones; that folder isn't in the dotfiles repo, so sounds you
# don't own the rights to stay on this machine.
own="$HOME/.local/share/sounds/desktop"
dir="$HOME/.config/hypr/assets/sounds"
case $1 in
  --screenshot) f=thwip.wav; vol=0.7 ;;
  --notify) f=thwip-soft.wav; vol=0.4 ;;
  --error) f=spider-sense.wav; vol=0.6 ;;
  *) echo "Available sounds: --screenshot, --notify, --error"; exit 0 ;;
esac
[[ -f $own/$f ]] && dir=$own
exec pw-play --volume "$vol" "$dir/$f"
