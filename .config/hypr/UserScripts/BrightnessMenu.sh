#!/usr/bin/env bash
# Brightness applet (SUPER+SHIFT+L): down, up, and 25 / 50 / 100% presets for the laptop screen.
source "$(dirname "$(realpath "$0")")/applet.sh"
menu_toggle brightness || exit 0
bright="$HOME/.config/hypr/scripts/Brightness.sh"

level=$(brightnessctl -c backlight -m | cut -d, -f4)

choice=$(applet "Brightness  <b>$level</b>" \
  $'\U000F00DE|Down' \
  $'\U000F00E0|Up' \
  $'\U000F00DE|25%' \
  $'\U000F00DF|50%' \
  $'\U000F00E0|100%') || exit 0

case "$choice" in
  0) "$bright" --dec ;;
  1) "$bright" --inc ;;
  2) brightnessctl -q -c backlight set 25% ;;
  3) brightnessctl -q -c backlight set 50% ;;
  4) brightnessctl -q -c backlight set 100% ;;
esac
