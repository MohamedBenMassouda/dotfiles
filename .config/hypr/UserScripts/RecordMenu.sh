#!/usr/bin/env bash
# Recording menu (SUPER+CTRL+R): record the screen / an area / a window,
# with or without the mic, or browse your recordings (open, rename, delete).
source "$HOME/.config/hypr/UserScripts/applet.sh"
menu_toggle record || exit 0
rec="$HOME/.config/hypr/UserScripts/ScreenRecord.sh"
dir="$HOME/Videos/Recordings"

if pgrep -f '^gpu-screen-recorder' >/dev/null; then
  confirm "Stop recording?" && exec "$rec"
  exit 0
fi

choice=$(applet "Screen recording" \
  $'\U000F0E51|Screen' $'\U000F0A6D|Area' $'\U000F0614|Window' \
  $'\U000F08B4|Screen + mic' $'\U000F0D19|Recordings') || exit 0

case $choice in
  0) exec "$rec" ;;
  1) exec "$rec" --area ;;
  2) exec "$rec" --window ;;
  3) exec "$rec" --mic ;;
esac

# ---- recordings: newest first ----
mapfile -t files < <(ls -t "$dir"/*.mp4 2>/dev/null)
[[ ${#files[@]} -gt 0 ]] || { qs ipc call osd toast record-off "Recordings" "None yet"; exit 0; }
pick=$(for f in "${files[@]}"; do
         printf '%s  ·  %s\0icon\x1f%s\n' "$(basename "$f" .mp4)" "$(du -h "$f" | cut -f1)" video-x-generic
       done | rofi -dmenu -i -p Recordings -show-icons -format i) || exit 0
file=${files[$pick]}

action=$(applet "$(basename "$file")" $'\U000F040A|Open' $'\U000F03EB|Rename' $'\U000F0256|Folder' $'\U000F01B4|Delete') || exit 0
case $action in
  0) xdg-open "$file" ;;
  1) name=$(rofi -dmenu -p Rename -lines 0 -theme-str 'entry { placeholder: "New name"; }' <<<"") || exit 0
     [[ -n $name ]] && mv -n "$file" "$dir/${name%.mp4}.mp4" ;;
  2) xdg-open "$dir" ;;
  3) confirm "Delete $(basename "$file")?" && rm -f "$file" ;;
esac
