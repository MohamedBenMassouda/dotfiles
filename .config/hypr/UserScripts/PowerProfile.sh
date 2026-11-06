#!/usr/bin/env bash
# Cycle power profile: power-saver -> balanced -> performance (power-profiles-daemon)
set -euo pipefail

case "$(powerprofilesctl get)" in
  power-saver) next=balanced ;;
  balanced)    next=performance ;;
  *)           next=power-saver ;;
esac

powerprofilesctl set "$next"
notify-send -e -u low -h string:x-canonical-private-synchronous:power-profile \
  -i "$HOME/.config/swaync/images/ja.png" " Power profile" "$next"
