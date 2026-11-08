#!/usr/bin/env bash
# Desktop sounds (synthesized, in ~/.config/hypr/assets/sounds):
#   Sounds.sh --screenshot   web-shooter "thwip"
#   Sounds.sh --notify       softer thwip (Quickshell plays it for new notifications)
#   Sounds.sh --error        spider-sense tingle (also warnings in the flyout)
# Set mute=true to silence them all. With the Spider-Man touches off (quick
# settings) the plain system sounds play instead.
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

# Spider-Man touches off (quick settings): plain system sounds, silent notifications
if [[ -e $HOME/.local/state/spidey-off ]]; then
  sys=/usr/share/sounds/freedesktop/stereo
  case $1 in
    --screenshot) exec pw-play --volume "$vol" "$sys/screen-capture.oga" ;;
    --error) exec pw-play --volume "$vol" "$sys/dialog-error.oga" ;;
    *) exit 0 ;;
  esac
fi
exec pw-play --volume "$vol" "$dir/$f"
