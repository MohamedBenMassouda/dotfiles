#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for changing blurs on the fly


STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [ "${STATE}" == "2" ]; then
	hyprctl eval 'hl.config({ decoration = { blur = { size = 2, passes = 1 } } })'
	qs ipc call osd toast blur-off "Less blur" "Lighter on the GPU" >/dev/null 2>&1
else
	hyprctl eval 'hl.config({ decoration = { blur = { size = 5, passes = 2 } } })'
	qs ipc call osd toast blur "Normal blur" "" >/dev/null 2>&1
fi
