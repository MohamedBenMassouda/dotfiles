#!/usr/bin/env bash
# Shared helper for the rofi applets (source it, don't run it).
#   applet "Header text" "<glyph>|Label" "<glyph>|Label" ...
# Shows a row of big icon buttons (rofi/config-applet.rasi) and prints the
# index of the chosen one; returns non-zero if the menu was closed.
# Set APPLET_THEME to add extra rofi theme rules for one applet, and
# APPLET_ROW to choose which button starts selected (default: the first).
#   confirm "Shut down?"  -> succeeds only if Yes was picked

source "$(dirname "${BASH_SOURCE[0]}")/menu-toggle.sh"

applet() {
  local mesg=$1; shift
  local n=$# width=$(( $# * 110 + 40 ))
  local rows="" item
  for item in "$@"; do
    rows+="<span size=\"xx-large\">${item%%|*}</span>"$'\n'"<span size=\"small\">${item#*|}</span>|"
  done
  # Left/Right step through the buttons and wrap around (e.g. Left on the first
  # one jumps to the last); there's no text box, so they aren't needed for typing
  printf '%s' "${rows%|}" | rofi -dmenu -i -no-custom -markup-rows -sep '|' -eh 3 -format i -selected-row "${APPLET_ROW:-0}" \
    -kb-move-char-back "Control+b" -kb-move-char-forward "Control+f" \
    -kb-element-prev "Left,ISO_Left_Tab" -kb-element-next "Right,Tab" \
    -config "$HOME/.config/rofi/config-applet.rasi" -mesg "$mesg" \
    -theme-str "listview { columns: $n; } window { width: ${width}px; } ${APPLET_THEME:-}"
}

confirm() {
  local choice
  choice=$(applet "$1" $'\U000F012C|Yes' $'\U000F0156|No') && [[ "$choice" == 0 ]]
}
