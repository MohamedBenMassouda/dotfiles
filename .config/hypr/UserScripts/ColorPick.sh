#!/usr/bin/env bash
# Colour picker (SUPER+SHIFT+D): pick a pixel, hex code to the clipboard,
# flyout shows the colour.
color=$(hyprpicker -a -f hex) || exit 0
[[ -n $color ]] && { qs ipc call osd toast color "$color" "Copied to clipboard" >/dev/null 2>&1 || notify-send -u low "Colour" "$color"; }
