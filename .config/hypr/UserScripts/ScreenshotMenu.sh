#!/usr/bin/env bash
# Screenshot applet (SUPER+SHIFT+P): screen, area, window, area + edit, in 5s, in 10s.
source "$(dirname "$(realpath "$0")")/applet.sh"
menu_toggle screenshot || exit 0
shot="$HOME/.config/hypr/scripts/ScreenShot.sh"

choice=$(applet "Screenshot" \
  $'\U000F0E51|Screen' \
  $'\U000F0489|Area' \
  $'\U000F05AF|Window' \
  $'\U000F03EB|Edit' \
  $'\U000F051B|In 5s' \
  $'\U000F051B|In 10s') || exit 0

sleep 0.3  # let rofi fade out so it isn't in the picture
case "$choice" in
  0) "$shot" --now ;;
  1) "$shot" --area ;;
  2) "$shot" --active ;;
  3) "$shot" --swappy ;;
  4) "$shot" --in5 ;;
  5) "$shot" --in10 ;;
esac
