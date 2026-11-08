#!/usr/bin/env bash
# Desktop sounds:
#   Sounds.sh --screenshot   (Spider-Man: web-shooter thwip)
#   Sounds.sh --notify       new notifications (softer thwip)
#   Sounds.sh --error        warnings in the flyout, errors (spider-sense)
# Set mute=true to silence them all.
mute=false
$mute && exit 0

# Sounds come from the theme pack (quickshell/packs/<name>/sounds). Your own
# files in ~/.local/share/sounds/desktop/ (same names) win over the pack's;
# that folder isn't in the dotfiles repo, so sounds you don't own the rights to
# stay on this machine. No pack ("none"): plain system sounds, silent notifications.
own="$HOME/.local/share/sounds/desktop"
dir=$("$HOME/.config/hypr/scripts/Pack.sh" dir)
case $1 in
  --screenshot) f=thwip.wav; vol=0.7; sys=screen-capture ;;
  --notify) f=thwip-soft.wav; vol=0.4; sys= ;;
  --error) f=spider-sense.wav; vol=0.6; sys=dialog-error ;;
  *) echo "Available sounds: --screenshot, --notify, --error"; exit 0 ;;
esac
if [[ -z $dir ]]; then
  [[ -n $sys ]] && exec pw-play --volume "$vol" "/usr/share/sounds/freedesktop/stereo/$sys.oga"
  exit 0
fi
src="$dir/sounds/$f"
[[ -f $own/$f ]] && src="$own/$f"
[[ -f $src ]] && exec pw-play --volume "$vol" "$src"
