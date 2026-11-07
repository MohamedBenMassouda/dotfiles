#!/usr/bin/env bash
# Caps Lock flyout (bound to Caps_Lock on release, see configs/Keybinds.lua)
state=$(hyprctl devices -j | jq -r '[.keyboards[] | select(.main)][0].capsLock')
if [[ $state == true ]]; then
  qs ipc call osd toast caps-on "Caps Lock" "On"
else
  qs ipc call osd toast caps-off "Caps Lock" "Off"
fi
