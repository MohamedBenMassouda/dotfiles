#!/usr/bin/env bash
# Screen recording with gpu-screen-recorder. Running it again stops and saves.
#   ScreenRecord.sh            focused monitor (SUPER+SHIFT+R)
#   ScreenRecord.sh --area     drag to choose an area
#   ScreenRecord.sh --window   the focused window
#   ... --mic                  also record the microphone
# Menu with all of these + your recordings: RecordMenu.sh (SUPER+CTRL+R)
set -euo pipefail
icon="$HOME/.config/hypr/assets/images/ja.png"
dir="$HOME/Videos/Recordings"
toast() { qs ipc call osd toast "$@" >/dev/null 2>&1 || notify-send -e -u low -i "$icon" " $2" "$3"; }

# match the full command: the process name is cut to 15 chars, so -x never matched
if pkill -SIGINT -f '^gpu-screen-recorder'; then
  toast record-off "Recording saved" "$dir"
  exit 0
fi

command -v gpu-screen-recorder >/dev/null || { toast record-off "Recording" "Install gpu-screen-recorder first"; exit 1; }

mode=screen mic=false
for arg in "$@"; do
  case $arg in
    --area) mode=area ;;
    --window) mode=window ;;
    --mic) mic=true ;;
  esac
done

case $mode in
  screen)
    monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
    target=(-w "$monitor") what="Recording $monitor" ;;
  area)
    geo=$(slurp -f '%wx%h+%x+%y') || exit 0
    target=(-w region -region "$geo") what="Recording area" ;;
  window)
    geo=$(hyprctl activewindow -j | jq -r '"\(.size[0])x\(.size[1])+\(.at[0])+\(.at[1])"')
    target=(-w region -region "$geo") what="Recording window" ;;
esac

audio=default_output
$mic && audio="default_output|default_input" what+=" + mic"

mkdir -p "$dir"
out="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
toast record "$what" "SUPER+SHIFT+R or the bar's red dot to stop"
exec gpu-screen-recorder "${target[@]}" -f 60 -a "$audio" -o "$out"
