#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# for changing Hyprland Layouts (Master or Dwindle) on the fly


LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

# Reverse layout value to reuse toggle logic. So layouts don't get swapped initially.
if [ "$1" = "init" ]; then
  if [ "$LAYOUT" = "master" ]; then
    LAYOUT="dwindle"
  else
    LAYOUT="master"
  fi
fi

case $LAYOUT in
"master")
  hyprctl eval '
    hl.config({ general = { layout = "dwindle" } })
    hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'
  qs ipc call osd toast layout "Dwindle layout" "SUPER+O flips the split" >/dev/null 2>&1
  ;;
"dwindle")
  hyprctl eval '
    hl.config({ general = { layout = "master" } })
    hl.unbind("SUPER + O")'
  qs ipc call osd toast layout "Master layout" "SUPER+I / SUPER+CTRL+D add / remove a master" >/dev/null 2>&1
  ;;
*) ;;

esac
