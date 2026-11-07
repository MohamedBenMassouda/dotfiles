#!/usr/bin/env bash
# Cycle power profile: power-saver -> balanced -> performance (power-profiles-daemon)
set -euo pipefail

case "$(powerprofilesctl get)" in
  power-saver) next=balanced ;;
  balanced)    next=performance ;;
  *)           next=power-saver ;;
esac

powerprofilesctl set "$next"
qs ipc call osd toast "$next" "Power profile" "$(sed "s/-/ /; s/^./\U&/" <<<"$next")" >/dev/null 2>&1 && exit 0
notify-send -e -u low -h string:x-canonical-private-synchronous:power-profile \
  -i "$HOME/.config/hypr/assets/images/ja.png" " Power profile" "$next"
